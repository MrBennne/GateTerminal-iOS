import SwiftUI

struct StatusDot: View {
    let status: UnitStatus
    var size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: size, height: size)
    }
}

struct StatusPicker: View {
    let selected: UnitStatus?
    let onSelect: (UnitStatus) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(UnitStatus.sorted) { status in
                    let isSelected = status == selected
                    Button {
                        onSelect(status)
                    } label: {
                        HStack(spacing: 4) {
                            StatusDot(status: status, size: 8)
                            Text(status.label)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(isSelected ? status.color.opacity(0.2) : Color.clear)
                        .foregroundStyle(isSelected ? status.color : AppColors.onSurface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isSelected ? status.color.opacity(0.5) : AppColors.outline.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
    }
}

struct DeckLocationPicker: View {
    let selected: String?
    let onSelect: (String?) -> Void
    var enabled: Bool = true

    private let locations = ["WD", "MD", "LH"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Deck Location")
                .font(.caption)
                .foregroundStyle(AppColors.onSurfaceVariant)

            HStack(spacing: 8) {
                ForEach(locations, id: \.self) { loc in
                    let isSelected = loc == selected
                    let color: Color = {
                        switch loc {
                        case "WD": return LocationColors.WD
                        case "MD": return LocationColors.MD
                        case "LH": return LocationColors.LH
                        default: return AppColors.primary
                        }
                    }()

                    Button {
                        onSelect(isSelected ? nil : loc)
                    } label: {
                        Text(loc)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? color.opacity(0.2) : Color.clear)
                            .foregroundStyle(isSelected ? color : AppColors.onSurface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isSelected ? color.opacity(0.5) : AppColors.outline.opacity(0.3), lineWidth: 1))
                    }
                    .disabled(!enabled)
                }
            }
        }
    }
}

struct TraLocationPicker: View {
    let selected: String?
    let onSelect: (String?) -> Void
    var enabled: Bool = true

    private let locations = ["Import", "Export", "Farlig Gods Række"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TRA Location")
                .font(.caption)
                .foregroundStyle(AppColors.onSurfaceVariant)

            HStack(spacing: 8) {
                ForEach(locations, id: \.self) { loc in
                    let isSelected = loc == selected
                    Button {
                        onSelect(isSelected ? nil : loc)
                    } label: {
                        Text(loc == "Farlig Gods Række" ? "FG" : loc)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? AppColors.primary.opacity(0.2) : Color.clear)
                            .foregroundStyle(isSelected ? AppColors.primary : AppColors.onSurface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isSelected ? AppColors.primary.opacity(0.5) : AppColors.outline.opacity(0.3), lineWidth: 1))
                    }
                    .disabled(!enabled)
                }
            }
        }
    }
}

struct ConnectionStatusBar: View {
    let connectionState: ConnectionState
    @State private var showConnected = false

    var body: some View {
        let visible: Bool = {
            switch connectionState {
            case .connected: return showConnected
            case .disconnected, .reconnecting: return true
            }
        }()

        if visible {
            let (bgColor, text): (Color, String) = {
                switch connectionState {
                case .connected: return (Color(hex: 0x22C55E), "Connected")
                case .disconnected: return (Color(hex: 0xEF4444), "Disconnected")
                case .reconnecting: return (Color(hex: 0xF59E0B), "Reconnecting...")
                }
            }()

            Text(text)
                .font(.caption2)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .background(bgColor)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
