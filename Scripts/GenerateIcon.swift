import AppKit
import CoreGraphics

// Original vector/Core Graphics artwork, rendered at each native pixel size.
func icon(_ size: Int) -> CGImage {
    let c = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.scaleBy(x: Double(size) / 1024, y: Double(size) / 1024)
    let ns = NSGraphicsContext(cgContext: c, flipped: false)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ns
    defer { NSGraphicsContext.restoreGraphicsState() }
    let shell = CGRect(x: 64, y: 64, width: 896, height: 896)
    let silhouette = CGPath(roundedRect: shell, cornerWidth: 190, cornerHeight: 190, transform: nil)
    c.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: CGColor(gray: 0, alpha: 0.35))
    c.addPath(silhouette); c.setFillColor(CGColor(gray: 0.065, alpha: 1)); c.fillPath()
    c.setShadow(offset: .zero, blur: 0)
    c.addPath(silhouette); c.setStrokeColor(CGColor(gray: 0.3, alpha: 0.45)); c.setLineWidth(2); c.strokePath()
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [CGColor(gray: 0.11, alpha: 1), CGColor(gray: 0.035, alpha: 1)] as CFArray, locations: [0, 1])!
    c.saveGState(); c.addPath(silhouette); c.clip(); c.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 960), end: CGPoint(x: 512, y: 64), options: []); c.restoreGState()
    for (index, text) in ["10", "08"].enumerated() {
        let rect = CGRect(x: index == 0 ? 112 : 542, y: 320, width: 370, height: 400)
        let card = CGPath(roundedRect: rect, cornerWidth: 35, cornerHeight: 35, transform: nil)
        c.setShadow(offset: CGSize(width: 0, height: -16), blur: 22, color: CGColor(gray: 0, alpha: 0.65))
        c.setFillColor(CGColor(gray: 0.12, alpha: 1)); c.addPath(card); c.fillPath(); c.setShadow(offset: .zero, blur: 0)
        c.saveGState(); c.addPath(card); c.clip()
        let cardGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [CGColor(gray: 0.155, alpha: 1), CGColor(gray: 0.085, alpha: 1)] as CFArray, locations: [0, 1])!
        c.drawLinearGradient(cardGradient, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
        let font = NSFont.monospacedDigitSystemFont(ofSize: 260, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
        let dimensions = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: rect.midX - dimensions.width / 2, y: rect.midY - dimensions.height / 2 + 3), withAttributes: attrs)
        c.setFillColor(CGColor(gray: 0, alpha: 0.85)); c.fill(CGRect(x: rect.minX, y: rect.midY - 3, width: rect.width, height: 6))
        c.setFillColor(CGColor(gray: 0, alpha: 0.08)); c.fill(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height / 2))
        c.restoreGState()
        c.addPath(card); c.setLineWidth(1.5); c.setStrokeColor(CGColor(gray: 0.45, alpha: 0.35)); c.strokePath()
        for x in [rect.minX + 5, rect.maxX - 11] {
            c.setFillColor(CGColor(gray: 0.32, alpha: 1)); c.addPath(CGPath(roundedRect: CGRect(x: x, y: rect.midY - 13, width: 6, height: 26), cornerWidth: 2, cornerHeight: 2, transform: nil)); c.fillPath()
        }
    }
    c.setFillColor(CGColor(gray: 0.8, alpha: 1))
    for y in [480.0, 560.0] { c.fillEllipse(in: CGRect(x: 505, y: y, width: 14, height: 14)) }
    let lettering: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 48, weight: .medium), .foregroundColor: NSColor(white: 0.60, alpha: 1), .kern: 18]
    let label = NSAttributedString(string: "FLIP", attributes: lettering)
    label.draw(at: CGPoint(x: 512 - label.size().width / 2 + 9, y: 190))
    return c.makeImage()!
}
func save(_ image: CGImage, _ path: String) throws {
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    try data.write(to: URL(fileURLWithPath: path))
}
try save(icon(1024), "Resources/FLIP-master-1024.png")
for base in [16, 32, 128, 256, 512] {
    try save(icon(base), "Resources/FLIP.iconset/icon_\(base)x\(base).png")
    try save(icon(base * 2), "Resources/FLIP.iconset/icon_\(base)x\(base)@2x.png")
}
print("Original FLIP icon: 1024px master and ten native macOS sizes generated")
