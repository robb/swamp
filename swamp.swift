#!/usr/bin/xcrun swift 

import AppKit

enum SwampError: ErrorType {
    case BitmapRepresentationError
}

extension NSImage {
    func bitmapRepresentation() throws -> NSBitmapImageRep {
        guard let cgRef = CGImageForProposedRect(nil, context: nil, hints: nil) else { throw SwampError.BitmapRepresentationError }
        return NSBitmapImageRep(CGImage: cgRef)
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
                let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                paragraphStyle.alignment = .Center
                paragraphStyle.lineBreakMode = .ByWordWrapping
                return paragraphStyle
            }(),
            NSForegroundColorAttributeName: NSColor.whiteColor()
        ]
    }

    func addText(text: String) {
        let offset = icon.size.height / 20
        let containerSize = CGSize(width: icon.size.width, height: icon.size.height - 2 * offset)
        var fontSize = icon.size.height / 4

        var textContainer: NSTextContainer
        var textStorage: NSTextStorage
        var layoutManager: NSLayoutManager

        var renderedRange: NSRange
        var usedRect: CGRect

        // Keep decreasing the font size until it's either 8 pts or the text
        // fits completely
        repeat {
            textContainer = NSTextContainer(containerSize: containerSize)

            textStorage = NSTextStorage(string: text, attributes: textAttributes)
            textStorage.font = NSFont(name: fontName, size: fontSize)

            layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(textContainer)
            layoutManager.textStorage = textStorage

            renderedRange = layoutManager.glyphRangeForTextContainer(textContainer)
            usedRect = layoutManager.usedRectForTextContainer(textContainer)

            fontSize -= 0.1
        } while renderedRange.length < text.characters.count && fontSize > 8

        let point = CGPointMake(0, icon.size.height - usedRect.size.height - offset)

        icon.lockFocusFlipped(true)
        layoutManager.drawGlyphsForGlyphRange(renderedRange, atPoint:point)
        icon.unlockFocus()
    }

    func save(path: String) throws {
        try icon.bitmapRepresentation()
                .representationUsingType(.NSPNGFileType, properties: [:])?
                .writeToFile(path, atomically: true)
    }
}

if Process.arguments.count < 4 {
    print("Usage: stamp.swift -- [input] [output] [text]")
    exit(1)
}

let input = Process.arguments[1]
let output = Process.arguments[2]
let text = Process.arguments[3]

guard let data = NSData(contentsOfFile: input), icon = NSImage(data: data) else {
    print("Could not load file \(input)")
    exit(1)
}

let swamp = Swamp(icon: icon)
swamp.addText(text)
do {
    try swamp.save(output)
} catch let error {
    print("Error creating icon. \(error)")
}
