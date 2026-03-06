import Foundation

func formatDisplayTime(_ isoString: String?) -> String {
    guard let isoString = isoString, !isoString.isEmpty else { return "" }
    let parts = isoString.split(separator: "T")
    guard parts.count >= 2 else {
        // Try space separator
        let spaceParts = isoString.split(separator: " ")
        if spaceParts.count >= 2 {
            let timeParts = spaceParts[1].split(separator: ":")
            if timeParts.count >= 2 { return "\(timeParts[0]):\(timeParts[1])" }
        }
        return isoString
    }
    let timeParts = parts[1].split(separator: ":")
    if timeParts.count >= 2 { return "\(timeParts[0]):\(timeParts[1])" }
    return String(parts[1])
}

func formatDisplayDate(_ isoString: String?) -> String {
    guard let isoString = isoString, !isoString.isEmpty else { return "" }
    let parts = isoString.split(separator: "T")
    return String(parts.first ?? Substring(isoString))
}

func formatDisplayDateTime(_ isoString: String?) -> String {
    guard let isoString = isoString, !isoString.isEmpty else { return "" }
    let date = formatDisplayDate(isoString)
    let time = formatDisplayTime(isoString)
    if !date.isEmpty && !time.isEmpty { return "\(date) \(time)" }
    return date + time
}

func nowCopenhagenISO() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    formatter.timeZone = TimeZone(identifier: "Europe/Copenhagen")
    return formatter.string(from: Date())
}

func buildEtaValue(_ input: String) -> String? {
    let trimmed = input.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return nil }
    if trimmed.contains(" ") || trimmed.contains("T") { return trimmed }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "Europe/Copenhagen")
    let today = formatter.string(from: Date())
    return "\(today) \(trimmed)"
}

func extractTimeComponent(_ etaTime: String) -> String {
    guard !etaTime.isEmpty else { return "" }
    let timePart: String
    if etaTime.contains("T") {
        timePart = String(etaTime.split(separator: "T").last ?? "")
    } else if etaTime.contains(" ") {
        timePart = String(etaTime.split(separator: " ").last ?? "")
    } else {
        timePart = etaTime
    }
    return String(timePart.prefix(5))
}

struct ValidationError {
    let field: String
    let message: String
}

func validateNewArrival(unitno: String, carrier: String, type: String) -> [ValidationError] {
    var errors: [ValidationError] = []
    if unitno.trimmingCharacters(in: .whitespaces).isEmpty { errors.append(ValidationError(field: "unitno", message: "Unit number is required")) }
    if carrier.trimmingCharacters(in: .whitespaces).isEmpty { errors.append(ValidationError(field: "carrier", message: "Carrier is required")) }
    if type.trimmingCharacters(in: .whitespaces).isEmpty { errors.append(ValidationError(field: "type", message: "Type is required")) }
    return errors
}
