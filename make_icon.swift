import AppKit

let S: CGFloat = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r/255, green: g/255, blue: b/255, alpha: a)
}

// --- Rounded squircle background ---
let inset: CGFloat = 96
let rect = CGRect(x: inset, y: inset, width: S - inset*2, height: S - inset*2)
let radius: CGFloat = 200
let bgPath = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()

// Diagonal navy gradient (lighter top-left -> darker bottom-right)
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [color(40, 86, 140), color(22, 52, 90), color(14, 33, 58)] as CFArray,
    locations: [0.0, 0.55, 1.0])!
ctx.drawLinearGradient(grad,
    start: CGPoint(x: rect.minX, y: rect.maxY),
    end: CGPoint(x: rect.maxX, y: rect.minY),
    options: [])

// Subtle top sheen
let sheen = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [color(255, 255, 255, 0.10), color(255, 255, 255, 0.0)] as CFArray,
    locations: [0.0, 0.5])!
ctx.drawLinearGradient(sheen,
    start: CGPoint(x: rect.midX, y: rect.maxY),
    end: CGPoint(x: rect.midX, y: rect.midY),
    options: [])
ctx.restoreGState()

// Soft inner border highlight
ctx.saveGState()
ctx.addPath(bgPath)
ctx.setStrokeColor(color(255, 255, 255, 0.08))
ctx.setLineWidth(3)
ctx.strokePath()
ctx.restoreGState()

// --- Helper to draw text ---
func draw(_ s: String, font: NSFont, color: NSColor, centerX: CGFloat, centerY: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let str = NSAttributedString(string: s, attributes: attrs)
    let size = str.size()
    str.draw(at: CGPoint(x: centerX - size.width/2, y: centerY - size.height/2))
}

// --- Braces with a blue gradient via clipping ---
func drawBrace(_ s: String, centerX: CGFloat) {
    let font = NSFont.systemFont(ofSize: 560, weight: .light)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
    let str = NSAttributedString(string: s, attributes: attrs)
    let size = str.size()
    let origin = CGPoint(x: centerX - size.width/2, y: S/2 - size.height/2)

    ctx.saveGState()
    // Use the glyph as a clip, then fill with gradient
    str.draw(at: origin) // draw white first to establish coverage in a layer
    ctx.restoreGState()
}

// Draw braces in bright blue (gradient look) using two passes: text path fill.
func brace(_ s: String, centerX: CGFloat) {
    let font = NSFont.systemFont(ofSize: 660, weight: .medium)
    let str = NSAttributedString(string: s, attributes: [.font: font])
    let size = str.size()
    let x = centerX - size.width/2
    let y = S/2 - size.height/2

    let blue = NSColor(calibratedRed: 0.20, green: 0.62, blue: 0.98, alpha: 1.0)
    let strBlue = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: blue])
    strBlue.draw(at: CGPoint(x: x, y: y))
}

brace("{", centerX: S*0.255)
brace("}", centerX: S*0.745)

// --- JSON wordmark ---
draw("JSON", font: NSFont.systemFont(ofSize: 196, weight: .bold), color: .white,
     centerX: S/2, centerY: S/2 + 6)

NSGraphicsContext.restoreGraphicsState()

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
if let data = rep.representation(using: .png, properties: [:]) {
    try! data.write(to: URL(fileURLWithPath: outPath))
    print("Wrote \(outPath)")
}
