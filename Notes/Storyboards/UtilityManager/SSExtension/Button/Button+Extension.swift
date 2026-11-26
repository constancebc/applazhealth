//
//  Button+Extension.swift
//  Whirlpost
//
//  Created by Sadaf Khan on 18/08/23.
//  Copyright © 2023 Sevenstar Infotech. All rights reserved.
//

import UIKit

extension UIView {
    
    func addCornerRadius(radius: CGFloat, borderWidth: CGFloat = 0, borderColor: UIColor = .clear) {
        self.layer.cornerRadius = radius
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
    }
    
    func madeCornerCircularWithShadow() {
        self.layer.cornerRadius = self.frame.size.height/2
        
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowColor = ApplazAppearance.ink.cgColor
        self.layer.shadowOpacity = 0.10
        self.layer.shadowRadius = 3
        self.layer.masksToBounds = false
    }
}

