import AppKit

public class CustomMenuBarIcon {
    public static func createIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }

            let center = CGPoint(x: 9, y: 9)
            let strokeColor = NSColor.black

            context.saveGState()

            // 1. Draw outer gauge arc (240-degree sweeping meter)
            let arcPath = NSBezierPath()
            arcPath.appendArc(
                withCenter: center,
                radius: 7.2,
                startAngle: -210,
                endAngle: 30,
                clockwise: false
            )
            arcPath.lineWidth = 1.7
            arcPath.lineCapStyle = .round
            strokeColor.setStroke()
            arcPath.stroke()

            // 2. Draw dual metering dots at the lower endpoints
            let dot1 = NSBezierPath(ovalIn: NSRect(x: 2.2, y: 4.2, width: 1.8, height: 1.8))
            let dot2 = NSBezierPath(ovalIn: NSRect(x: 14.0, y: 4.2, width: 1.8, height: 1.8))
            strokeColor.setFill()
            dot1.fill()
            dot2.fill()

            // 3. Draw central AI energy spark (custom stylized diamond star)
            let sparkPath = NSBezierPath()
            let cx = 9.0
            let cy = 9.0
            let rOuter = 3.8
            let rInner = 1.3

            sparkPath.move(to: NSPoint(x: cx, y: cy + rOuter)) // Top
            sparkPath.curve(to: NSPoint(x: cx + rOuter, y: cy), controlPoint1: NSPoint(x: cx + rInner, y: cy + rInner), controlPoint2: NSPoint(x: cx + rInner, y: cy + rInner)) // Right
            sparkPath.curve(to: NSPoint(x: cx, y: cy - rOuter), controlPoint1: NSPoint(x: cx + rInner, y: cy - rInner), controlPoint2: NSPoint(x: cx + rInner, y: cy - rInner)) // Bottom
            sparkPath.curve(to: NSPoint(x: cx - rOuter, y: cy), controlPoint1: NSPoint(x: cx - rInner, y: cy - rInner), controlPoint2: NSPoint(x: cx - rInner, y: cy - rInner)) // Left
            sparkPath.curve(to: NSPoint(x: cx, y: cy + rOuter), controlPoint1: NSPoint(x: cx - rInner, y: cy + rInner), controlPoint2: NSPoint(x: cx - rInner, y: cy + rInner)) // Top

            sparkPath.close()
            strokeColor.setFill()
            sparkPath.fill()

            context.restoreGState()
            return true
        }

        image.isTemplate = true // macOS automatically adapts color to light/dark menu bar
        return image
    }
}
