import SwiftUI

extension Color {
    static let w95Face = Color(white: 0.753)
    static let w95Light = Color(white: 0.875)
    static let w95Shadow = Color(white: 0.502)
    static let w95Navy = Color(red: 0, green: 0, blue: 0.5)
    static let w95Blue = Color(red: 0.063, green: 0.518, blue: 0.816)
}

extension Font {
    static let w95 = Font.custom("Tahoma", size: 11)
}

/// The three Windows 95 edge styles: raised buttons and windows, pressed buttons and sunken fields.
enum BevelStyle {
    case raised, pressed, field

    /// Colors for the outer and inner ring, as (top-left, bottom-right).
    fileprivate var rings: [(Color, Color)] {
        switch self {
        case .raised: [(.white, .black), (.w95Light, .w95Shadow)]
        case .pressed: [(.black, .white), (.w95Shadow, .w95Light)]
        case .field: [(.w95Shadow, .white), (.black, .w95Light)]
        }
    }
}

extension View {
    /// Draws a 2px Windows 95 bevel on top of the view's edges.
    func bevel(_ style: BevelStyle) -> some View {
        overlay {
            Canvas { context, size in
                for (inset, (topLeft, bottomRight)) in style.rings.enumerated() {
                    let r = CGRect(origin: .zero, size: size).insetBy(dx: CGFloat(inset), dy: CGFloat(inset))
                    context.fill(Path(CGRect(x: r.minX, y: r.minY, width: r.width, height: 1)), with: .color(topLeft))
                    context.fill(Path(CGRect(x: r.minX, y: r.minY, width: 1, height: r.height)), with: .color(topLeft))
                    context.fill(Path(CGRect(x: r.minX, y: r.maxY - 1, width: r.width, height: 1)), with: .color(bottomRight))
                    context.fill(Path(CGRect(x: r.maxX - 1, y: r.minY, width: 1, height: r.height)), with: .color(bottomRight))
                }
            }
            .allowsHitTesting(false)
        }
    }
}

/// A gray bevelled push button. `isDefault` adds the bold label and dotted focus ring,
/// `isDown` keeps it pressed in (used for the pad that is playing).
struct Win95ButtonStyle: ButtonStyle {
    var isDefault = false
    var isDown = false
    var compact = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let down = isDown || configuration.isPressed
        configuration.label
            .fontWeight(isDefault ? .bold : nil)
            .foregroundStyle(isEnabled ? Color.black : Color.w95Shadow)
            .lineLimit(1)
            .padding(.horizontal, compact ? 0 : 12)
            .padding(.vertical, compact ? 0 : 6)
            .offset(x: down ? 1 : 0, y: down ? 1 : 0)
            .background(Color.w95Face)
            .overlay {
                if isDefault {
                    Rectangle()
                        .strokeBorder(.black, style: StrokeStyle(lineWidth: 1, dash: [1, 1]))
                        .padding(4)
                }
            }
            .bevel(down ? .pressed : .raised)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == Win95ButtonStyle {
    static func win95(isDefault: Bool = false, isDown: Bool = false, compact: Bool = false) -> Self {
        Win95ButtonStyle(isDefault: isDefault, isDown: isDown, compact: compact)
    }
}
