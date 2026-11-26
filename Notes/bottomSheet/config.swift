//
//  config.swift
//  Whirlpost
//
//  Created by Puma on 08/05/2019.
//  Copyright © 2019 Sevenstar Infotech. All rights reserved.
//

import Foundation

// Freemium
let mythemeColor0_1 = UIColor(rgb: 0xB7D9C8)                              //0x7bc9cf
let mythemeColor0_2 = UIColor(rgb: 0x7BC9CF)                              //0x7bc3cf

// Premium
let mythemeColor1_1 = UIColor(rgb: 0xff6f24)                              //0xff6f24
let mythemeColor1_2 = UIColor(rgb: 0xff9798)                              //0xff9798

let mythemeColor2_1 = UIColor(rgb: 0xffa320)                               //0xffa320
let mythemeColor2_2 = UIColor(rgb: 0xff1f21)                              //0xff1f21

let mythemeColor3_1 = UIColor(rgb: 0x24ff4e)                              //0x24ff4e
let mythemeColor3_2 = UIColor(rgb: 0x00e49b)                              //0x00e49b

let mythemeColor4_1 = UIColor(rgb: 0x808080)                              //0x5217ff
let mythemeColor4_2 = UIColor(rgb: 0x808080)                              //0x613bff

let mythemeColor5_1 = UIColor(rgb: 0x7bc9cf)                              //0x7bc9cf
let mythemeColor5_2 = UIColor(rgb: 0x7bc9cf)                              //0x7bc3cf

let MYTHEMECOLORINDEX = "themecolorindex"
let MYTHEMEFONTINDEX = "themefontindex"

let defaultRoundValue: CGFloat = 10.0


let bartColor = 0x061043

func getColorByHex(rgbHexValue:UInt32, alpha:Double = 1.0) -> UIColor {
    let red = Double((rgbHexValue & 0xFF0000) >> 16) / 256.0
    let green = Double((rgbHexValue & 0xFF00) >> 8) / 256.0
    let blue = Double((rgbHexValue & 0xFF)) / 256.0
    
    return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

