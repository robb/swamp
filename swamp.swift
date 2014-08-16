#!/usr/bin/xcrun swift

import AppKit

extension NSImage {
    func bitmapRepresentation() -> NSBitmapImageRep {
        let cgRef = self.CGImageForProposedRect(nil, context: nil, hints: nil)
        return NSBitmapImageRep(CGImage: cgRef.takeRetainedValue())
    }
}

struct Swamp {
    let icon: NSImage
    let textAttributes: Dictionary<String, AnyObject>
    let fontName = "HelveticaNeue-Light"

    init(icon: NSImage) {
        self.icon = icon
        self.textAttributes = [
            NSShadowAttributeName: {
                let unit = icon.size.height / 64

                let shadow = NSShadow()
                shadow.shadowOffset = CGSizeMake(0, -unit)
                shadow.shadowBlurRadius = unit
                shadow.shadowColor = NSColor.controlDarkShadowColor()
                return shadow
            }(),
            NSParagraphStyleAttributeName: {
                let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as NSMutableParagraphStyle!
                paragraphStyle.alignment = NSTextAlignment.CenterTextAlignment
                paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping;
                return paragraphStyle
            }(),
            NSForegroundColorAttributeName: NSColor.whiteColor()
        ]
    }

    func addText(text: String) {
        let offset = self.icon.size.height / 20
        let containerSize = CGSize(width: self.icon.size.width,
                                   height: self.icon.size.height - 2 * offset)
        var fontSize = self.icon.size.height / 4

        var textContainer: NSTextContainer
        var textStorage: NSTextStorage
        var layoutManager: NSLayoutManager

        var renderedRange: NSRange
        var usedRect: CGRect

        // Keep decreasing the font size until it's either 8 pts or the text
        // fits completely
        do {
            textContainer = NSTextContainer(containerSize: containerSize)

            textStorage = NSTextStorage(string: text, attributes:textAttributes)
            textStorage.font = NSFont(name:self.fontName, size: fontSize)

            layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(textContainer)
            layoutManager.textStorage = textStorage

            renderedRange = layoutManager.glyphRangeForTextContainer(textContainer)
            usedRect = layoutManager.usedRectForTextContainer(textContainer)

            fontSize -= 0.1
        } while renderedRange.length < countElements(text) && fontSize > 8

        let point = CGPointMake(0, self.icon.size.height - usedRect.size.height - offset)

        self.icon.lockFocusFlipped(true)
        layoutManager.drawGlyphsForGlyphRange(renderedRange, atPoint:point)
        self.icon.unlockFocus()
    }

    func save(path: String) {
        self.icon
            .bitmapRepresentation()
            .representationUsingType(NSBitmapImageFileType.NSPNGFileType,
                                     properties: nil)
            .writeToFile(path, atomically:true)
    }
}

if Process.arguments.count < 4 {
    println("Usage: stamp.swift -- [input] [output] [text]")
    exit(1)
}

let input = Process.arguments[1]
let output = Process.arguments[2]
let text = Process.arguments[3]

let icon: NSImage? = NSImage(data: NSData(contentsOfFile: input))

if icon == nil {
    println("Could not load file \(input)")
    exit(1)
}

let swamp = Swamp(icon: icon!)
swamp.addText(text)
swamp.save(output)
