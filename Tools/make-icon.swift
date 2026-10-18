// Draws App/Assets.xcassets/AppIcon.appiconset/AppIcon.png: a calendar page on the sunset gradient.
// iOS masks the corners itself and rejects an alpha channel, so this is a flat, opaque square.
//     swift Tools/make-icon.swift App/Assets.xcassets/AppIcon.appiconset/AppIcon.png
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png")
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

// Background: sunset → berry, top-left to bottom-right (CG's origin is bottom-left).
let bg = CGGradient(colorsSpace: space, colors: [rgb(0xFF8A5B), rgb(0xE8457C), rgb(0x8E3BB0)] as CFArray,
                    locations: [0, 0.55, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

// The page.
let page = CGRect(x: 222, y: 190, width: 580, height: 620)
let pagePath = CGPath(roundedRect: page, cornerWidth: 96, cornerHeight: 96, transform: nil)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 60, color: rgb(0x5A1A4A, 0.45))
ctx.addPath(pagePath)
ctx.setFillColor(rgb(0xFFFFFF))
ctx.fillPath()
ctx.restoreGState()

// Header band, clipped to the page's rounded top.
ctx.saveGState()
ctx.addPath(pagePath)
ctx.clip()
ctx.setFillColor(rgb(0xE8457C))
ctx.fill(CGRect(x: page.minX, y: page.maxY - 150, width: page.width, height: 150))
ctx.restoreGState()

// Binder rings.
for x in [page.minX + 150, page.maxX - 150] {
    let ring = CGRect(x: x - 22, y: page.maxY - 40, width: 44, height: 110)
    ctx.addPath(CGPath(roundedRect: ring, cornerWidth: 22, cornerHeight: 22, transform: nil))
    ctx.setFillColor(rgb(0x3B1F3A))
    ctx.fillPath()
}

// The number, in SF Pro Rounded heavy.
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
var font = NSFont.systemFont(ofSize: 330, weight: .heavy)
if let rounded = font.fontDescriptor.withDesign(.rounded) { font = NSFont(descriptor: rounded, size: 330) ?? font }
let text = NSAttributedString(string: "12", attributes: [.font: font, .foregroundColor: NSColor(cgColor: rgb(0x2E2340))!, .kern: -12])
let bounds = text.size()
text.draw(at: CGPoint(x: page.midX - bounds.width / 2, y: page.minY + (page.height - 150 - bounds.height) / 2 + 6))

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out.path)")
