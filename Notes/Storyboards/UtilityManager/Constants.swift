//
//  Constants.swift
//  Notes
//
//  Created by Sevenstar Infotech on 12/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import Foundation
import UIKit


//MARK:- MESSAGES

let kNO_NOTE_FOUND                         = "No Notes Found"
let kNO_CATEGORY_FOUND                     = "Write Your Thoughts"
let kNOTE_ADDED                            = "Note added successfully"
let kNOTE_UPDATED                          = "Note updated successfully"
let kNOTE_DELETED                          = "Note deleted successfully"
let kCATEGORY_ADDED                        = "Category added successfully"
let kCATEGORY_UPDATED                      = "Category updated successfully"
let kCATEGORY_DELETED                      = "Category deleted successfully"
let kDELETE_NOTE                           = "Do you want to delete this note?"
let kDELETE_CATEGORY                       = "Do you want to delete this cateory?"
let kNOTE_NOT_ADDED                        = "Note not added successfully"
let kNOTE_NOT_UPDATED                      = "Note not updated successfully"
let kNOTE_NOT_DELETED                      = "Note not deleted successfully"
let kCATEGORY_NOT_ADDED                    = "Category not added successfully"
let kCATEGORY_NOT_UPDATED                  = "Category not updated successfully"
let kCATEGORY_NOT_DELETED                  = "Category not deleted successfully"
let kTHURN_ON_THUMB_ID                     = "TOUCH ID"
let kOLD_PASSCODE                          = "Old Passcode"
let kSET_PASSCODE                          = "Please set passcode"
let kNEW_PASSCODE                          = "New Passcode"
let KENTER_OLR_PASSCODE                    = "Please enter old passcode"
let kPASSCODE_REMOVED                      = "Passcode removed"
let kENTER_VALID_OLD_PASSCODE              = "Please enter valid old passcode"
let kNEW_PASSCODE_NOT_WITH_PASSCODE        = "New passcode should not same as old passcode"
let kPASSCODE_UPDATED                      = "Passcode updated successfully"
let kPASSCODE_NOT_UPDATED                  = "Passcode not updated"
let kCONFIRM_PASSCODE_NOT_SAME_AS_PASSCODE = "Confirm Passcode must match with new passcode"
let kCONFIRM_PASSCODE                      = "Confirm Passcode"
let kPASSCODE_NOTE_SET                     = "Passcode not set"
let kENTER_VALID_PASSCODE                  = "Please enter valid passcode"
let kCATEGORY_NOT_AVALALBE                 = "There is no notebook added"
let kENTER_NOTE_CATEGORY                   = "Please enter Notebook"
let kSELECT_NOTE_CATEGORY                  = "Please select Notebook"
let kENTER_NOTE_TITLE                      = "Please enter note title"
let kENTER_NOTE_DESCRIPTION                = "Please enter note description"
let kADD_NEW_NOTE_CATEGORY                 = "Add new Notebook"




//MARK:- COLORS


let DARK_BLUE_COLOR =  UIColor.navBarColor
let BLUE_COLOR      = UIColor.navBarColor
//let DARK_BLUE_COLOR = UIColor(red: 63.0/255.0, green: 81.0/255.0, blue: 181.0/255.0, alpha: 1.0)
//let BLUE_COLOR      = UIColor(red: 59.0/255.0, green: 77.0/255.0, blue: 175.0/255.0, alpha: 1.0)
let kBORDER_COLOR   = UIColor(red: 194.0/255.0, green: 194.0/255.0, blue: 194.0/255.0, alpha: 1.0)


//MARK:-

var IS_USER_LOGGED_IN = false
let APP_DELEGATE = UIApplication.shared.delegate as! AppDelegate


//MARK:- CHECK DEVICES

let SCREEN_WIDTH  = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

let IS_IPAD_PRO = SCREEN_HEIGHT == 1366.0
let IS_IPAD     = UIDevice.current.userInterfaceIdiom == .pad
let IS_IPHONE   = UIDevice.current.userInterfaceIdiom == .phone

let IS_IPHONE_4_OR_5         = SCREEN_WIDTH == 320
let IS_IPHONE_6_OR_7         = SCREEN_WIDTH == 375
let IS_IPHONE_6PLUS_OR_7PLUS = SCREEN_WIDTH == 414
let IS_IPHONE_X              = UIScreen.main.nativeBounds.height == 2436


//MARK:- KEYS

let kIS_THUMB_ID_ALLOWED = "isThumbIDAllowed"
let kIS_SKIPPED          = "isSkipped"
let kIs_User_FirstTime     = "isUserFirstTime"

//MARK:- SET PASSCODE SCREEN SKIP AND CANCEL BUTTON'S Y POSITION

let thumbID_YPosition = IS_IPHONE_4_OR_5 ? SCREEN_HEIGHT - 95 : IS_IPHONE_6_OR_7 ? SCREEN_HEIGHT - 132 : IS_IPHONE_6PLUS_OR_7PLUS ? SCREEN_HEIGHT - 145 : IS_IPHONE_X ? SCREEN_HEIGHT - 205 : 50

let cancelBTN_YPosition = SCREEN_HEIGHT - (IS_IPHONE_4_OR_5 ? 50 : IS_IPHONE_6_OR_7 ? 60 : IS_IPHONE_6PLUS_OR_7PLUS ? 70 : IS_IPHONE_X ? 95 : 50)
