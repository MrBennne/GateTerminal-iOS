import Foundation

@Observable
@MainActor
final class UnitRepository {
    private let pb: PocketBaseClient
    private let authService: AuthService

    private(set) var units: [GateUnit] = []
    private(set) var lists: [BookingList] = []
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var isLoading: Bool = false

    private var sseTask: Task<Void, Never>?
    private var retryCount: Int = 0
    private let maxRetryDelay: Double = 30.0

    init(pb: PocketBaseClient, authService: AuthService) {
        self.pb = pb
        self.authService = authService
    }

    // MARK: - Data fetching

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetchedUnits: [GateUnit] = try await pb.listRecords("gate_units", sort: "-updated")
            let fetchedLists: [BookingList] = try await pb.listRecords("booking_lists", sort: "-created")
            units = fetchedUnits
            lists = fetchedLists
        } catch {
            // Non-fatal
        }
    }

    func fetchHistory(_ unitId: String) async -> [AuditLog] {
        do {
            let logs: [AuditLog] = try await pb.listRecords("audit_logs", filter: "resource=\"\(unitId)\"", sort: "-created")
            return logs
        } catch {
            return []
        }
    }

    // MARK: - CRUD

    func updateUnit(_ id: String, _ updates: [String: Any]) async throws -> GateUnit {
        let updated: GateUnit = try await pb.updateRecord("gate_units", id: id, body: updates)
        if let idx = units.firstIndex(where: { $0.id == id }) {
            units[idx] = updated
        }
        return updated
    }

    func createUnit(_ fields: [String: Any]) async throws -> GateUnit {
        let created: GateUnit = try await pb.createRecord("gate_units", body: fields)
        units.insert(created, at: 0)
        return created
    }

    func deleteUnit(_ id: String) async throws {
        try await pb.deleteRecord("gate_units", id: id)
        units.removeAll { $0.id == id }
    }

    // MARK: - List CRUD

    func createList(name: String) async -> Result<BookingList, Error> {
        do {
            let created: BookingList = try await pb.createRecord("booking_lists", body: ["name": name])
            lists.insert(created, at: 0)
            return .success(created)
        } catch {
            return .failure(error)
        }
    }

    func renameList(id: String, name: String) async -> Result<BookingList, Error> {
        do {
            let updated: BookingList = try await pb.updateRecord("booking_lists", id: id, body: ["name": name])
            if let idx = lists.firstIndex(where: { $0.id == id }) {
                lists[idx] = updated
            }
            return .success(updated)
        } catch {
            return .failure(error)
        }
    }

    func deleteList(id: String) async -> Result<Void, Error> {
        do {
            try await pb.deleteRecord("booking_lists", id: id)
            lists.removeAll { $0.id == id }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func saveTypeOrder(listId: String, order: String) async -> Result<BookingList, Error> {
        do {
            let updated: BookingList = try await pb.updateRecord("booking_lists", id: listId, body: ["type_order": order])
            if let idx = lists.firstIndex(where: { $0.id == listId }) {
                lists[idx] = updated
            }
            return .success(updated)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - SSE

    func connect() {
        guard sseTask == nil else { return }
        connectionState = .reconnecting
        sseTask = Task { [weak self] in
            await self?.sseLoop()
        }
    }

    func disconnect() {
        sseTask?.cancel()
        sseTask = nil
        connectionState = .disconnected
    }

    private func sseLoop() async {
        while !Task.isCancelled {
            do {
                // Initial fetch
                await refresh()

                guard let baseURL = await pb.currentBaseURL() as String?,
                      let token = await pb.currentToken() as String?,
                      let url = URL(string: "\(baseURL)/api/realtime") else {
                    throw PBError.invalidURL
                }

                var request = URLRequest(url: url)
                request.setValue(token, forHTTPHeaderField: "Authorization")
                request.timeoutInterval = 300

                let (stream, response) = try await URLSession.shared.bytes(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw PBError.serverError("SSE connection failed")
                }

                await MainActor.run {
                    self.connectionState = .connected
                    self.retryCount = 0
                }

                var clientId: String?
                var currentEvent = SseEvent()

                for try await line in stream.lines {
                    if Task.isCancelled { break }

                    if line.isEmpty {
                        // Process event
                        if !currentEvent.data.isEmpty {
                            await processSseEvent(currentEvent, clientId: &clientId)
                        }
                        currentEvent = SseEvent()
                        continue
                    }

                    if line.hasPrefix("event:") {
                        currentEvent.event = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("data:") {
                        currentEvent.data = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("id:") {
                        currentEvent.id = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    }
                }

            } catch {
                if Task.isCancelled { break }
                await MainActor.run {
                    self.connectionState = .reconnecting
                }
            }

            if Task.isCancelled { break }

            // Exponential backoff
            let delay = min(pow(2.0, Double(retryCount)) * 1.0, maxRetryDelay)
            retryCount += 1
            try? await Task.sleep(for: .seconds(delay))
        }
    }

    private func processSseEvent(_ event: SseEvent, clientId: inout String?) async {
        guard let data = event.data.data(using: .utf8) else { return }

        // Handle PB_CONNECT event
        if event.event == "PB_CONNECT" {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let id = json["clientId"] as? String {
                clientId = id
                // Subscribe to gate_units collection
                await subscribeToCollection(clientId: id)
            }
            return
        }

        // Handle record change events
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let action = json["action"] as? String,
              let record = json["record"] as? [String: Any] else { return }

        do {
            let recordData = try JSONSerialization.data(withJSONObject: record)
            let unit = try JSONDecoder().decode(GateUnit.self, from: recordData)

            await MainActor.run {
                switch action {
                case "create":
                    if !self.units.contains(where: { $0.id == unit.id }) {
                        self.units.insert(unit, at: 0)
                    }
                case "update":
                    if let idx = self.units.firstIndex(where: { $0.id == unit.id }) {
                        self.units[idx] = unit
                    }
                case "delete":
                    self.units.removeAll { $0.id == unit.id }
                default:
                    break
                }
            }
        } catch {
            // Decoding failed, skip
        }
    }

    private func subscribeToCollection(clientId: String) async {
        guard let baseURL = await pb.currentBaseURL() as String?,
              let token = await pb.currentToken() as String?,
              let url = URL(string: "\(baseURL)/api/realtime") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "clientId": clientId,
            "subscriptions": ["gate_units"]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        _ = try? await URLSession.shared.data(for: request)
    }
}
