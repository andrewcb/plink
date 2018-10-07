//
//  ColorfulTextButton.swift
//  Plink
//
//  Created by acb on 13/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

@IBDesignable
class ColorfulTextButton: NSButton {
    @IBInspectable var textColor: NSColor?
    
    override func awakeFromNib()
    {
        if let textColor = textColor, let font = font
        {
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            
            let attributes: [NSAttributedString.Key:Any] =
                [
                    .foregroundColor : textColor,
                    .font: font,
                    .paragraphStyle: style
                ]
            self.attributedTitle = NSAttributedString(string: self.title, attributes: attributes)
        }
    }

}
