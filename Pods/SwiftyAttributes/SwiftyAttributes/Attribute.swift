//
//  Attribute.swift
//  SwiftyAttributes
//
//  Created by Eddie Kaiger on 10/15/16.
//  Copyright © 2016 Eddie Kaiger. All rights reserved.
//

import Foundation

public typealias UnderlineStyle = NSUnderlineStyle
public typealias StrikethroughStyle = NSUnderlineStyle

/**
 Represents attributes that can be applied to NSAttributedStrings.
 */
public enum Attribute {

    /// Attachment attribute that allows items like images to be inserted into text.
    case attachment(NSTextAttachment)

    /// Value indicating the character's offset from the baseline, in points.
    case baselineOffset(Double)

    /// The background color of the attributed string.
    case backgroundColor(UIColor)

    /// Value indicating the log of the expansion factor to be applied to glyphs.
    case expansion(Double)

    /// The font of the attributed string.
    case font(UIFont)

    /// Specifies the number of points by which to adjust kern-pair characters. Kerning prevents unwanted space from occurring between specific characters and depends on the font. The value 0 means kerning is disabled (default).
    case kern(Double)

    /// Ligatures cause specific character combinations to be rendered using a single custom glyph that corresponds to those characters. See `Ligatures` for values.
    case ligatures(Ligatures)

    /// A URL link to attach to the attributed string.
    case link(URL)

    /// A value indicating the skew to be applied to glyphs.
    case obliqueness(Double)

    /// An `NSParagraphStyle` to be applied to the attributed string.
    case paragraphStyle(NSParagraphStyle)

    /// A shadow to be applied to the characters.
    case shadow(NSShadow)

    /// The color of the stroke (border) around the characters.
    case strokeColor(UIColor)

    /// The width/thickness of the stroke (border) around the characters.
    case strokeWidth(Double)

    /// The color of the strikethrough.
    case strikethroughColor(UIColor)

    /// The style of the strikethrough.
    case strikethroughStyle(StrikethroughStyle)

    /// The text color.
    case textColor(UIColor)

    /// The text effect to apply. See `TextEffect` for possible values.
    case textEffect(TextEffect)

    /// The color of the underline.
    case underlineColor(UIColor)

    /// The style of the underline.
    case underlineStyle(UnderlineStyle)

    /// The writing directions to apply to the attributed string. See `WritingDirection` for values. Only available on iOS 9.0+.
    case writingDirections([WritingDirection])

    init(name: Attribute.Name, value: Any) {
        func validate<Type>(_ val: Any) -> Type {
            return val as! Type
        }

        switch name {
        case .attachment: self = .attachment(validate(value))
        case .baselineOffset: self = .baselineOffset(validate(value))
        case .backgroundColor: self = .backgroundColor(validate(value))
        case .expansion: self = .expansion(validate(value))
        case .font: self = .font(validate(value))
        case .kern: self = .kern(validate(value))
        case .ligature: self = .ligatures(validate(value))
        case .link: self = .link(validate(value))
        case .obliqueness: self = .obliqueness(validate(value))
        case .paragraphStyle: self = .paragraphStyle(validate(value))
        case .shadow: self = .shadow(validate(value))
        case .strokeColor: self = .strokeColor(validate(value))
        case .strokeWidth: self = .strokeWidth(validate(value))
        case .strikethroughColor: self = .strikethroughColor(validate(value))
        case .strikethroughStyle: self = .strikethroughStyle(validate(value))
        case .textColor: self = .textColor(validate(value))
        case .textEffect: self = .textEffect(validate(value))
        case .underlineColor: self = .underlineColor(validate(value))
        case .underlineStyle: self = .underlineStyle(validate(value))
        case .writingDirection: self = .writingDirections(validate(value))
        }
    }

    /// The key name corresponding to the attribute.
    public var keyName: String {
        let name: Attribute.Name
        switch self {
        case .attachment(_): name = .attachment
        case .baselineOffset(_): name = .baselineOffset
        case .backgroundColor(_): name = .backgroundColor
        case .expansion(_): name = .expansion
        case .font(_): name = .font
        case .kern(_): name = .kern
        case .ligatures(_): name = .ligature
        case .link(_): name = .link
        case .obliqueness(_): name = .obliqueness
        case .paragraphStyle(_): name = .paragraphStyle
        case .shadow(_): name = .shadow
        case .strokeColor(_): name = .strokeColor
        case .strokeWidth(_): name = .strokeWidth
        case .strikethroughColor(_): name = .strikethroughColor
        case .strikethroughStyle(_): name = .strikethroughStyle
        case .textColor(_): name = .textColor
        case .textEffect(_): name = .textEffect
        case .underlineColor(_): name = .underlineColor
        case .underlineStyle(_): name = .underlineStyle
        case .writingDirections(_): name = .writingDirection
        }
        return name.rawValue
    }

    // Convenience getter variable for the associated value of the attribute. See each case to determine the return type.
    public var value: Any {
        switch self {
        case .attachment(let attachment): return attachment
        case .baselineOffset(let offset): return offset
        case .backgroundColor(let color): return color
        case .expansion(let expansion): return expansion
        case .font(let font): return font
        case .kern(let kern): return kern
        case .ligatures(let ligatures): return ligatures
        case .link(let link): return link
        case .obliqueness(let value): return value
        case .paragraphStyle(let style): return style
        case .shadow(let shadow): return shadow
        case .strokeColor(let color): return color
        case .strokeWidth(let width): return width
        case .strikethroughColor(let color): return color
        case .strikethroughStyle(let style): return style
        case .textColor(let color): return color
        case .textEffect(let effect): return effect
        case .underlineColor(let color): return color
        case .underlineStyle(let style): return style
        case .writingDirections(let directions): return directions
        }
    }

    var foundationValue: Any {
        switch self {
        case .ligatures(let ligatures): return ligatures.rawValue
        case .strikethroughStyle(let style): return NSNumber(value: style.rawValue)
        case .textEffect(let effect): return effect.rawValue
        case .underlineStyle(let style): return NSNumber(value: style.rawValue)
        case .writingDirections(let directions): return directions.map { $0.rawValue }
        default: return value
        }
    }

    /**
     An enum that corresponds to `Attribute`, mapping attributes to their respective names.
    */
    public enum Name: RawRepresentable {
        case attachment
        case baselineOffset
        case backgroundColor
        case expansion
        case font
        case kern
        case ligature
        case link
        case obliqueness
        case paragraphStyle
        case shadow
        case strokeColor
        case strokeWidth
        case strikethroughColor
        case strikethroughStyle
        case textColor
        case textEffect
        case underlineColor
        case underlineStyle
        case writingDirection

        public init?(rawValue: String) {
            switch rawValue {
            case NSAttachmentAttributeName: self = .attachment
            case NSBaselineOffsetAttributeName: self = .baselineOffset
            case NSBackgroundColorAttributeName: self = .backgroundColor
            case NSExpansionAttributeName: self = .expansion
            case NSFontAttributeName: self = .font
            case NSKernAttributeName: self = .kern
            case NSLigatureAttributeName: self = .ligature
            case NSLinkAttributeName: self = .link
            case NSObliquenessAttributeName: self = .obliqueness
            case NSParagraphStyleAttributeName: self = .paragraphStyle
            case NSShadowAttributeName: self = .shadow
            case NSStrokeColorAttributeName: self = .strokeColor
            case NSStrokeWidthAttributeName: self = .strokeWidth
            case NSStrikethroughColorAttributeName: self = .strikethroughColor
            case NSStrikethroughStyleAttributeName: self = .strikethroughStyle
            case NSForegroundColorAttributeName: self = .textColor
            case NSTextEffectAttributeName: self = .textEffect
            case NSUnderlineColorAttributeName: self = .underlineColor
            case NSUnderlineStyleAttributeName: self = .underlineStyle
            case NSWritingDirectionAttributeName: self = .writingDirection
            default: return nil
            }
        }

        public var rawValue: String {
            switch self {
                case .attachment: return NSAttachmentAttributeName
                case .baselineOffset: return NSBaselineOffsetAttributeName
                case .backgroundColor: return NSBackgroundColorAttributeName
                case .expansion: return NSExpansionAttributeName
                case .font: return NSFontAttributeName
                case .kern: return NSKernAttributeName
                case .ligature: return NSLigatureAttributeName
                case .link: return NSLinkAttributeName
                case .obliqueness: return NSObliquenessAttributeName
                case .paragraphStyle: return NSParagraphStyleAttributeName
                case .shadow: return NSShadowAttributeName
                case .strokeColor: return NSStrokeColorAttributeName
                case .strokeWidth: return NSStrokeWidthAttributeName
                case .strikethroughColor: return NSStrikethroughColorAttributeName
                case .strikethroughStyle: return NSStrikethroughStyleAttributeName
                case .textColor: return NSForegroundColorAttributeName
                case .textEffect: return NSTextEffectAttributeName
                case .underlineColor: return NSUnderlineColorAttributeName
                case .underlineStyle: return NSUnderlineStyleAttributeName
                case .writingDirection: return NSWritingDirectionAttributeName
            }

        }
    }
}
