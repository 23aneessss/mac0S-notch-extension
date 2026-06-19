#!/usr/bin/env swift
import AppKit
import CoreGraphics

// FocusNotch app icon, 1024×1024. `Tools/make_icons.sh` derives smaller sizes.
//
// Usage: generate_icon.swift [outPath] [style]
//   style ∈ { dark, vibrant, indigo, light }  (default: indigo)
//
// The centerpiece is a true **notch silhouette** — flat top, rounded bottom
// corners (not a capsule) — with a glass fill, accent rim-light, lens dot, and
// a drop shadow. The style varies the palette.

let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
let style = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "indigo"

let size = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("ctx") }

let s = CGFloat(size)
func col(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r/255, green: g/255, blue: b/255, alpha: a)
}
func grad(_ colors: [CGColor], _ locs: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: cs, colors: colors as CFArray, locations: locs)!
}

let inset = s * 0.085
let rect = CGRect(x: inset, y: inset, width: s - inset*2, height: s - inset*2)
let corner = rect.width * 0.2237
func squircle() -> CGPath { CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil) }

// Island geometry — a real notch: flat top, rounded bottom.
let iW = rect.width * 0.52
let iH = rect.height * 0.175
let iX = rect.midX - iW / 2
let iCenterY = rect.midY + rect.height * 0.03
let iY = iCenterY - iH / 2
let topR = iH * 0.16
let botR = iH * 0.46
func islandPath() -> CGPath {
    let r = CGRect(x: iX, y: iY, width: iW, height: iH)
    let p = CGMutablePath()
    p.move(to: CGPoint(x: r.minX, y: r.maxY - topR))
    p.addQuadCurve(to: CGPoint(x: r.minX + topR, y: r.maxY), control: CGPoint(x: r.minX, y: r.maxY))
    p.addLine(to: CGPoint(x: r.maxX - topR, y: r.maxY))
    p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY - topR), control: CGPoint(x: r.maxX, y: r.maxY))
    p.addLine(to: CGPoint(x: r.maxX, y: r.minY + botR))
    p.addQuadCurve(to: CGPoint(x: r.maxX - botR, y: r.minY), control: CGPoint(x: r.maxX, y: r.minY))
    p.addLine(to: CGPoint(x: r.minX + botR, y: r.minY))
    p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + botR), control: CGPoint(x: r.minX, y: r.minY))
    p.closeSubpath()
    return p
}

let isLight = (style == "light" || style == "warm")
let isVibrant = (style == "vibrant")

// Accent per style.
let accentA: CGColor, accentB: CGColor
switch style {
case "vibrant":        accentA = col(255,255,255); accentB = col(255,255,255)
case "indigo":         accentA = col(120,170,255); accentB = col(150,110,255)
case "light", "warm":  accentA = col(99,102,241);  accentB = col(139,92,246)   // indigo→violet
default:               accentA = col(255,138,92);   accentB = col(255,42,116)
}

// ---------- Background ----------
ctx.saveGState()
ctx.addPath(squircle()); ctx.clip()

switch style {
case "vibrant":
    ctx.drawLinearGradient(grad([col(255,122,80), col(255,46,120), col(150,70,255)], [0,0.55,1]),
        start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.minY), options: [])
case "indigo":
    ctx.drawLinearGradient(grad([col(46,52,96), col(10,11,22)], [0,1]),
        start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
    let gc = CGPoint(x: rect.midX, y: rect.midY + rect.height*0.06)
    ctx.drawRadialGradient(grad([col(90,140,255,0.42), col(90,140,255,0)], [0,1]),
        startCenter: gc, startRadius: 0, endCenter: gc, endRadius: rect.width*0.52, options: [])
case "light":
    // Cool off-white / light gray — not stark white.
    ctx.drawLinearGradient(grad([col(229,231,238), col(202,206,218)], [0,1]),
        start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
    let gc = CGPoint(x: rect.midX, y: rect.midY + rect.height*0.04)
    ctx.drawRadialGradient(grad([col(120,110,250,0.18), col(120,110,250,0)], [0,1]),
        startCenter: gc, startRadius: 0, endCenter: gc, endRadius: rect.width*0.55, options: [])
case "warm":
    // Warm porcelain / greige — soft and premium.
    ctx.drawLinearGradient(grad([col(238,233,227), col(214,205,194)], [0,1]),
        start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
    let gc = CGPoint(x: rect.midX, y: rect.midY + rect.height*0.04)
    ctx.drawRadialGradient(grad([col(150,120,230,0.14), col(150,120,230,0)], [0,1]),
        startCenter: gc, startRadius: 0, endCenter: gc, endRadius: rect.width*0.55, options: [])
default:
    ctx.drawLinearGradient(grad([col(20,20,26), col(6,6,9)], [0,1]),
        start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
    let gc = CGPoint(x: rect.midX, y: rect.midY + rect.height*0.06)
    ctx.drawRadialGradient(grad([col(255,70,115,0.40), col(255,70,115,0)], [0,1]),
        startCenter: gc, startRadius: 0, endCenter: gc, endRadius: rect.width*0.52, options: [])
}

// Sheen + vignette.
ctx.drawLinearGradient(grad([col(255,255,255, isLight ? 0.5 : 0.10), col(255,255,255,0)], [0,1]),
    start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.34), options: [])
ctx.drawRadialGradient(grad([col(0,0,0,0), col(0,0,0, isLight ? 0.10 : (isVibrant ? 0.30 : 0.45))], [0.55,1]),
    startCenter: CGPoint(x: rect.midX, y: rect.midY), startRadius: rect.width*0.32,
    endCenter: CGPoint(x: rect.midX, y: rect.midY), endRadius: rect.width*0.74, options: [])
ctx.restoreGState()

// ---------- The notch ----------
let islandFill: CGColor = isLight ? col(12,12,16) : (isVibrant ? col(0,0,0) : col(18,18,22))

// Drop shadow + base.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -22), blur: isLight ? 36 : 55,
              color: col(0,0,0, isLight ? 0.28 : (isVibrant ? 0.5 : 0.65)))
ctx.addPath(islandPath()); ctx.setFillColor(islandFill); ctx.fillPath()
ctx.restoreGState()

// Form gradient + sheen for the dark glass styles.
if !isVibrant {
    ctx.saveGState()
    ctx.addPath(islandPath()); ctx.clip()
    let top: CGColor = isLight ? col(34,34,42) : col(44,44,54)
    let bot: CGColor = isLight ? col(6,6,9) : col(10,10,14)
    ctx.drawLinearGradient(grad([top, bot], [0,1]),
        start: CGPoint(x: rect.midX, y: iY + iH), end: CGPoint(x: rect.midX, y: iY), options: [])
    ctx.drawLinearGradient(grad([col(255,255,255,0.16), col(255,255,255,0)], [0,1]),
        start: CGPoint(x: rect.midX, y: iY + iH), end: CGPoint(x: rect.midX, y: iY + iH*0.45), options: [])
    ctx.restoreGState()
}

// Rim-light.
ctx.saveGState()
if isVibrant {
    ctx.addPath(islandPath())
    ctx.setStrokeColor(col(255,255,255,0.22)); ctx.setLineWidth(rect.width*0.004); ctx.strokePath()
} else {
    let glowCol = (style == "indigo") ? col(90,140,255,0.85) : (isLight ? col(120,110,250,0.55) : col(255,60,110,0.85))
    ctx.setShadow(offset: .zero, blur: isLight ? 16 : 26, color: glowCol)
    ctx.addPath(islandPath()); ctx.setLineWidth(rect.width*0.0095); ctx.replacePathWithStrokedPath(); ctx.clip()
    ctx.drawLinearGradient(grad([accentA, accentB], [0,1]),
        start: CGPoint(x: iX, y: iY + iH), end: CGPoint(x: iX + iW, y: iY), options: [])
}
ctx.restoreGState()

// Lens dot.
let dotR = iH * 0.082
ctx.setFillColor(col(230,230,236,0.92))
ctx.fillEllipse(in: CGRect(x: rect.midX - dotR, y: iCenterY - dotR, width: dotR*2, height: dotR*2))

// ---------- Write PNG ----------
guard let image = ctx.makeImage() else { fatalError("image") }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { fatalError("dest") }
CGImageDestinationAddImage(dest, image, nil)
if CGImageDestinationFinalize(dest) { print("Wrote \(outPath) [\(style)]") } else { fatalError("write") }
