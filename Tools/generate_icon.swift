#!/usr/bin/env swift
import AppKit
import CoreGraphics

// Renders FocusNotch's app icon at 1024×1024. `Tools/make_icons.sh` derives the
// smaller sizes with `sips`.
//
// Design — premium & on-brand: a deep graphite squircle with a soft top sheen
// and edge vignette for depth; a glowing black "notch" pill outlined in the
// focus-accent gradient (with a camera dot); and a slim accent progress bar
// beneath it that mirrors the in-app UI.

let size = 1024
let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png"

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("ctx") }

let s = CGFloat(size)
func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r/255, green: g/255, blue: b/255, alpha: a)
}
// Accent gradient (warm coral → magenta).
let accentA = c(255, 122, 89)
let accentB = c(255, 46, 120)

// Squircle.
let inset = s * 0.085
let rect = CGRect(x: inset, y: inset, width: s - inset*2, height: s - inset*2)
let corner = rect.width * 0.235
func squircle() -> CGPath { CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil) }

// --- Background: deep graphite gradient ---
ctx.saveGState()
ctx.addPath(squircle()); ctx.clip()
let bg = CGGradient(colorsSpace: cs, colors: [c(44,47,55), c(16,17,21)] as CFArray, locations: [0,1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])

// Soft accent glow rising from behind the notch.
let glow = CGGradient(colorsSpace: cs, colors: [c(255,80,110,0.34), c(255,80,110,0)] as CFArray, locations: [0,1])!
ctx.drawRadialGradient(glow,
    startCenter: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.30), startRadius: 0,
    endCenter: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.30), endRadius: rect.width*0.5, options: [])

// Top sheen (glass highlight).
let sheen = CGGradient(colorsSpace: cs, colors: [c(255,255,255,0.10), c(255,255,255,0)] as CFArray, locations: [0,1])!
ctx.drawLinearGradient(sheen, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.34), options: [])

// Edge vignette for depth.
let vig = CGGradient(colorsSpace: cs, colors: [c(0,0,0,0), c(0,0,0,0.28)] as CFArray, locations: [0.6,1])!
ctx.drawRadialGradient(vig,
    startCenter: CGPoint(x: rect.midX, y: rect.midY), startRadius: rect.width*0.30,
    endCenter: CGPoint(x: rect.midX, y: rect.midY), endRadius: rect.width*0.72, options: [])
ctx.restoreGState()

// --- The glowing notch ---
let nW = rect.width * 0.50
let nH = rect.height * 0.20
let nX = rect.midX - nW/2
let nY = rect.maxY - rect.height*0.25 - nH       // upper-middle, balanced
let nRadiusTop = nH * 0.28
let nRadiusBottom = nH * 0.46
func notchPath() -> CGPath {
    let p = CGMutablePath()
    let r = CGRect(x: nX, y: nY, width: nW, height: nH)
    p.move(to: CGPoint(x: r.minX, y: r.maxY - nRadiusTop))
    p.addQuadCurve(to: CGPoint(x: r.minX + nRadiusTop, y: r.maxY), control: CGPoint(x: r.minX, y: r.maxY))
    p.addLine(to: CGPoint(x: r.maxX - nRadiusTop, y: r.maxY))
    p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY - nRadiusTop), control: CGPoint(x: r.maxX, y: r.maxY))
    p.addLine(to: CGPoint(x: r.maxX, y: r.minY + nRadiusBottom))
    p.addQuadCurve(to: CGPoint(x: r.maxX - nRadiusBottom, y: r.minY), control: CGPoint(x: r.maxX, y: r.minY))
    p.addLine(to: CGPoint(x: r.minX + nRadiusBottom, y: r.minY))
    p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + nRadiusBottom), control: CGPoint(x: r.minX, y: r.minY))
    p.closeSubpath()
    return p
}

// Glow halo behind the notch.
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 55, color: c(255, 70, 110, 0.9))
ctx.addPath(notchPath()); ctx.setFillColor(c(8,8,10)); ctx.fillPath()
ctx.restoreGState()

// Accent-gradient outline around the notch.
ctx.saveGState()
ctx.addPath(notchPath())
ctx.setLineWidth(rect.width * 0.012)
ctx.replacePathWithStrokedPath()
ctx.clip()
let stroke = CGGradient(colorsSpace: cs, colors: [accentA, accentB] as CFArray, locations: [0,1])!
ctx.drawLinearGradient(stroke, start: CGPoint(x: nX, y: nY+nH), end: CGPoint(x: nX+nW, y: nY), options: [])
ctx.restoreGState()

// Camera dot.
let dotR = nH * 0.10
ctx.setFillColor(c(255,255,255,0.85))
ctx.fillEllipse(in: CGRect(x: rect.midX - dotR, y: nY + nH*0.5 - dotR, width: dotR*2, height: dotR*2))

// --- Progress bar beneath the notch ---
let barW = nW
let barH = rect.height * 0.052
let barX = rect.midX - barW/2
let barY = nY - rect.height*0.12 - barH
let barRadius = barH/2
// Track.
ctx.addPath(CGPath(roundedRect: CGRect(x: barX, y: barY, width: barW, height: barH), cornerWidth: barRadius, cornerHeight: barRadius, transform: nil))
ctx.setFillColor(c(255,255,255,0.14)); ctx.fillPath()
// Fill (~68%) with glow.
let fillW = barW * 0.68
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 22, color: c(255,70,110,0.7))
ctx.addPath(CGPath(roundedRect: CGRect(x: barX, y: barY, width: fillW, height: barH), cornerWidth: barRadius, cornerHeight: barRadius, transform: nil))
ctx.clip()
ctx.drawLinearGradient(stroke, start: CGPoint(x: barX, y: barY), end: CGPoint(x: barX+fillW, y: barY), options: [])
ctx.restoreGState()

// --- Write PNG ---
guard let image = ctx.makeImage() else { fatalError("image") }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { fatalError("dest") }
CGImageDestinationAddImage(dest, image, nil)
if CGImageDestinationFinalize(dest) { print("Wrote \(outPath)") } else { fatalError("write") }
