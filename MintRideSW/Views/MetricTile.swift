import SwiftUI

struct MetricTile: View {
    let title: String
    let value: String
    let subtitle: String?
    var progressValue: CGFloat? = nil
    var valueColor: Color? = nil
    var progressColor: Color? = nil
    var holdProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            if let valueColor {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let progressValue {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))

                        Capsule()
                            .fill(progressColor ?? Color.accentColor)
                            .frame(width: proxy.size.width * min(max(progressValue, 0), 1))
                    }
                }
                .frame(height: 8)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.06))
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
