import SwiftUI

struct BenchmarkTile: View {
    let title: String
    let value: String
    let highlight: Bool
    var holdProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(highlight ? Color.accentColor : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(highlight ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.05))
        }
        .overlay(alignment: .leading) {
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.accentColor.opacity(0.18))
                    .frame(width: proxy.size.width * holdProgress)
            }
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
