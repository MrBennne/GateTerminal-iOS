import Foundation

actor PocketBaseClient {
    private(set) var baseURL: String
    private(set) var token: String?
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: String = "", token: String? = nil) {
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.token = token
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
    }

    func setBaseURL(_ url: String) {
        self.baseURL = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    private func makeRequest(path: String, method: String = "GET", body: [String: Any]? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/api/\(path)") else {
            throw PBError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    func authWithPassword(identity: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = ["identity": identity, "password": password]
        let request = try makeRequest(path: "collections/users/auth-with-password", method: "POST", body: body)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        return try decoder.decode(AuthResponse.self, from: data)
    }

    func listRecords<T: Decodable>(_ collection: String, filter: String? = nil, sort: String? = nil, perPage: Int = 500) async throws -> [T] {
        var path = "collections/\(collection)/records?perPage=\(perPage)"
        if let filter = filter {
            path += "&filter=\(filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? filter)"
        }
        if let sort = sort {
            path += "&sort=\(sort)"
        }
        let request = try makeRequest(path: path)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        let wrapper = try decoder.decode(ListResponse<T>.self, from: data)
        return wrapper.items
    }

    func getRecord<T: Decodable>(_ collection: String, id: String) async throws -> T {
        let request = try makeRequest(path: "collections/\(collection)/records/\(id)")
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    func createRecord<T: Decodable>(_ collection: String, body: [String: Any]) async throws -> T {
        let request = try makeRequest(path: "collections/\(collection)/records", method: "POST", body: body)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    func updateRecord<T: Decodable>(_ collection: String, id: String, body: [String: Any]) async throws -> T {
        let request = try makeRequest(path: "collections/\(collection)/records/\(id)", method: "PATCH", body: body)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    func deleteRecord(_ collection: String, id: String) async throws {
        let request = try makeRequest(path: "collections/\(collection)/records/\(id)", method: "DELETE")
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PBError.serverError("Delete failed")
        }
    }

    func getFirstListItem(_ collection: String, filter: String) async throws -> [String: Any]? {
        var path = "collections/\(collection)/records?perPage=1"
        path += "&filter=\(filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? filter)"
        let request = try makeRequest(path: path)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]],
              let first = items.first else {
            return nil
        }
        return first
    }

    func sseURL(collection: String) -> URL? {
        URL(string: "\(baseURL)/api/realtime")
    }

    func currentToken() -> String? {
        return token
    }

    func currentBaseURL() -> String {
        return baseURL
    }

    private func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PBError.serverError("Invalid response")
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                throw PBError.serverError(message)
            }
            throw PBError.serverError("HTTP \(httpResponse.statusCode): \(body)")
        }
    }
}

enum PBError: LocalizedError {
    case invalidURL
    case serverError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .serverError(let msg): return msg
        case .unauthorized: return "Unauthorized"
        }
    }
}

struct ListResponse<T: Decodable>: Decodable {
    let page: Int
    let perPage: Int
    let totalPages: Int
    let totalItems: Int
    let items: [T]
}
