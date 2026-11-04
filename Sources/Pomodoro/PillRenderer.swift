import AppKit

/// Draws the menu bar pill. Idle is a template image so it follows the
/// menu bar's light/dark tint; running, paused and done are orange.
enum PillRenderer {
    static let orange = NSColor(srgbRed: 0xEF / 255, green: 0x9F / 255, blue: 0x27 / 255, alpha: 1)
    static let darkAmber = NSColor(srgbRed: 0x41 / 255, green: 0x24 / 255, blue: 0x02 / 255, alpha: 1)

    static func image(for model: TimerModel) -> NSImage {
        switch model.state {
        case .idle:
            return draw(text: formatClock(model.remaining), symbol: "hourglass",
                        fill: nil, stroke: nil, ink: .black, template: true)
        case .running:
            return draw(text: formatClock(model.remaining), symbol: "hourglass",
                        fill: orange, stroke: nil, ink: darkAmber, template: false)
        case .paused:
            return draw(text: formatClock(model.remaining), symbol: "pause.fill",
                        fill: nil, stroke: orange, ink: orange, template: false)
        case .done:
            return draw(text: "Done", symbol: "checkmark",
                        fill: orange, stroke: nil, ink: darkAmber, template: false)
        }
    }

    private static let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
    private static let height: CGFloat = 18
    private static let padX: CGFloat = 8
    private static let gap: CGFloat = 4
    private static let iconBox: CGFloat = 12
    private static let textBox: CGFloat = ceil(NSAttributedString(string: "00:00", attributes: [.font: font]).size().width)

    /// Every state draws at this width. If the status item changes width while
    /// the popover is open, macOS loses the anchor and moves the popover to the left.
    static let width: CGFloat = padX + iconBox + gap + textBox + padX

    private static func draw(text: String, symbol: String, fill: NSColor?, stroke: NSColor?,
                             ink: NSColor, template: Bool) -> NSImage {
        let str = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: ink])
        let textSize = str.size()

        let config = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let icon = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)

        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            let pill = NSBezierPath(roundedRect: rect.insetBy(dx: 0.75, dy: 0.75),
                                    xRadius: height / 2, yRadius: height / 2)
            if let fill { fill.setFill(); pill.fill() }
            if let stroke { stroke.setStroke(); pill.lineWidth = 1.5; pill.stroke() }

            if let icon {
                let s = icon.size
                let iconRect = NSRect(x: padX + (iconBox - s.width) / 2, y: (height - s.height) / 2,
                                      width: s.width, height: s.height)
                tinted(icon, ink).draw(in: iconRect)
            }
            let textX = padX + iconBox + gap + (textBox - textSize.width) / 2
            str.draw(at: NSPoint(x: textX, y: (height - textSize.height) / 2))
            return true
        }
        image.isTemplate = template
        return image
    }

    private static func tinted(_ image: NSImage, _ color: NSColor) -> NSImage {
        NSImage(size: image.size, flipped: false) { rect in
            image.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}
