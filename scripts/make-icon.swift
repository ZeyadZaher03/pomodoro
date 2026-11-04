// Draws the app icon and writes Resources/AppIcon.icns.
// Run from the repo root: swift scripts/make-icon.swift
import AppKit

let orange = NSColor(srgbRed: 0xEF / 255, green: 0x9F / 255, blue: 0x27 / 255, alpha: 1)

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px) / 1024

    // macOS icon grid: 824pt body centered in a 1024pt canvas.
    let body = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let cube = NSBezierPath(roundedRect: body, xRadius: 185 * s, yRadius: 185 * s)
    NSColor(white: 0.07, alpha: 1).setFill()
    cube.fill()
    NSColor(white: 0.22, alpha: 1).setStroke()
    cube.lineWidth = 6 * s
    cube.stroke()

    let c = NSPoint(x: 512 * s, y: 512 * s)
    let face = NSBezierPath(ovalIn: NSRect(x: c.x - 330 * s, y: c.y - 330 * s, width: 660 * s, height: 660 * s))
    NSColor(white: 0.02, alpha: 1).setFill()
    face.fill()

    let outer = 300 * s, inner = 240 * s
    orange.setStroke()
    for i in 0..<60 {
        let a = (90 - Double(i) * 6) * .pi / 180
        let tick = NSBezierPath()
        tick.move(to: NSPoint(x: c.x + inner * cos(a), y: c.y + inner * sin(a)))
        tick.line(to: NSPoint(x: c.x + outer * cos(a), y: c.y + outer * sin(a)))
        tick.lineWidth = 16 * s
        tick.lineCapStyle = .round
        tick.stroke()
    }

    let font = NSFont.monospacedDigitSystemFont(ofSize: 210 * s, weight: .semibold)
    let label = NSAttributedString(string: "25", attributes: [.font: font, .foregroundColor: NSColor.white])
    let size = label.size()
    label.draw(at: NSPoint(x: c.x - size.width / 2, y: c.y - size.height / 2))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? fm.removeItem(at: iconset)
try! fm.createDirectory(at: iconset, withIntermediateDirectories: true)
for pt in [16, 32, 128, 256, 512] {
    try! render(pt).write(to: iconset.appendingPathComponent("icon_\(pt)x\(pt).png"))
    try! render(pt * 2).write(to: iconset.appendingPathComponent("icon_\(pt)x\(pt)@2x.png"))
}
try! fm.createDirectory(atPath: "Resources", withIntermediateDirectories: true)
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! p.run()
p.waitUntilExit()
print(p.terminationStatus == 0 ? "Wrote Resources/AppIcon.icns" : "iconutil failed")
