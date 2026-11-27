//
//  SettingsVC.swift
//  Notes
//
//  Created by Sevenstar Infotech on 17/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit
import TOPasscodeViewController
//import Toaster
import AudioToolbox
import MessageUI
import FirebaseAuth

class SettingsVC: UIViewController, TOPasscodeViewControllerDelegate {
    

    //MARK:- OBJECTS & OUTLETS
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var lblNavigationTitle: UILabel!
    //@IBOutlet weak var btnChangePasscode: UIButton!
    //@IBOutlet weak var btnRemovePasscode: UIButton!
    @IBOutlet weak var timerButton: UIButton!
    //@IBOutlet weak var lblTurnOnThumbID: UILabel!
    //@IBOutlet weak var switchThurnOnThumbID: UISwitch!
    @IBOutlet weak var navigationBarView1: UIView!
    @IBOutlet weak var viewDeleteAccount: UIView!
    @IBOutlet weak var navigationBarView2: UIView!
    //no linked constraint in storyboard causes fatal errors NMaks
    //@IBOutlet weak var thumbIDViewTopConstraint: NSLayoutConstraint!
    //@IBOutlet weak var thumbIDView: UIView!
    // @IBOutlet weak var poweredByLeadingConstraint: NSLayoutConstraint!
    //  @IBOutlet weak var btnPoweredBy: UIButton!
    // @IBOutlet weak var btnShare: UIButton!
    // @IBOutlet weak var btnMoreApps: UIButton!
    // @IBOutlet weak var btnShareTopConstraint: NSLayoutConstraint!
    //@IBOutlet weak var imgeViewThumbIDBackGround: UIImageView!
    
    @IBOutlet weak var btnPremiumMember: UIButton!
    @IBOutlet weak var btnTheme: UIButton!
    @IBOutlet weak var btnFont: UIButton!
    
    @IBOutlet weak var imgPremium: UIImageView!
    
    @IBOutlet weak var btnBottomPremium: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var sharedObj: Shared?
    let iapObj = IAPHelper()
    private let showsAppearanceSettings = false
    private var visibleSettingIndices: [Int] { themeArray.indices.filter { showsAppearanceSettings || $0 > 1 } }
    var themeArray = [ThemeSetting(title: "Choose Theme", icon: UIImage(named: "theme")!),ThemeSetting(title: "Choose Font", icon: UIImage(named: "text")!),ThemeSetting(title: "Start 10 Minute Timer", icon: UIImage(named: "stopwatch")!),ThemeSetting(title: "Restore", icon: UIImage(named: "house-repair")!),ThemeSetting(title: "Support", icon: UIImage(named: "customer-service")!),ThemeSetting(title: "Privacy Policy", icon: UIImage(named: "privacy")!),ThemeSetting(title: "Terms & Conditions", icon: UIImage(named: "document")!),ThemeSetting(title: "Delete Account", icon: UIImage(named: "deleteAccount")!),ThemeSetting(title: "Sign Out", icon: UIImage(named: "exit")!)]
    
    static var parentViewController: SettingsVC!
    
    var arrLoginCredential = [Any]()
    var isOLDPasscode      = true
    var isConformPasscode  = false
    var strOLDPasscode     = ""
    var strNewPasscode     = ""
    var isPasscodeSet      = false
    var strPasscode        = ""
    var isDelete           = false
    var passcodeViewController : TOPasscodeViewController?
    
    private var firebaseAuth = FirebaseAuthoriztion()
    private var facebookAuth = FacebookAuth()
    
    var dropDownClicked: Bool = false
    
    //MARK:- VIEW LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        themeArray.append(ThemeSetting(title: "Applaz Plus · Subscription & AI privacy", icon: UIImage(systemName: "sparkles")!))
        btnTheme.isHidden = !showsAppearanceSettings
        btnFont.isHidden = !showsAppearanceSettings
        
        self.tableView.register(UINib(nibName: "ThemeSettingTableViewCell", bundle: nil), forCellReuseIdentifier: "ThemeSettingTableViewCell")
        self.tableView.backgroundColor = ApplazAppearance.canvas
        let settingsBackdrop = ApplazAlignedBackdropView(frame: self.tableView.bounds)
        settingsBackdrop.isUserInteractionEnabled = false
        self.tableView.backgroundView = settingsBackdrop
        
        sharedObj = Shared.sharedInstance
        SettingsVC.parentViewController = self
        
        /*
         self.lblTurnOnThumbID.text = kTHURN_ON_THUMB_ID
         
         self.btnChangePasscode.setBackgroundImage(UIImage(named:  IS_IPHONE ? "save_btn" : "blank_btn"), for: .normal)
         self.btnRemovePasscode.setBackgroundImage(UIImage(named:  IS_IPHONE ? "save_btn" : "blank_btn"), for: .normal)
         //        self.btnShare.setBackgroundImage(UIImage(named:  IS_IPHONE ? "save_btn" : "blank_btn"), for: .normal)
         //        self.btnMoreApps.setBackgroundImage(UIImage(named:  IS_IPHONE ? "save_btn" : "blank_btn"), for: .normal)
         self.imgeViewThumbIDBackGround.image = UIImage(named:  IS_IPHONE ? "save_btn" : "blank_btn")
         
         */
        checkDropDown()
    }
    
    func checkDropDown() {
        viewDeleteAccount.isHidden = !dropDownClicked
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
       
        
//        if sharedObj!.isProductPurchased == false {
//
//            imgPremium.image = UIImage(named: "Premium")
//            btnBottomPremium.isUserInteractionEnabled = true
//        } else {
//
//            imgPremium.image = UIImage(named: "Freemium")
//            btnBottomPremium.isUserInteractionEnabled = false
//        }
        
        self.invalidateComponents()
        
        if Auth.auth().currentUser?.uid != nil {}else{
            viewDeleteAccount.isHidden = true
        }
        
        /*
         switchThurnOnThumbID.layer.cornerRadius = 16
         
         if !switchThurnOnThumbID.isOn {
         switchThurnOnThumbID.tintColor = .white
         switchThurnOnThumbID.thumbTintColor = BLUE_COLOR
         switchThurnOnThumbID.backgroundColor = .white
         } else {
         switchThurnOnThumbID.onTintColor = .white
         switchThurnOnThumbID.thumbTintColor = BLUE_COLOR
         }
         */
        /*
         if APP_DELEGATE.isBiomatriAvailable() {
         self.thumbIDView.isHidden = false  //!APP_DELEGATE.isBiomatriAvailable()
         }
         else {
         self.thumbIDView.isHidden = true
         }
         
         self.switchThurnOnThumbID.isOn = isThumbIDAllowed()
         */
        
//        if sharedObj!.isProductPurchased == false {
//
//            btnPremiumMember.setBackgroundImage(UIImage(named: "Paid_Feature"), for: .normal)
//            btnTheme.setBackgroundImage(UIImage(named: "Paid_Feature"), for: .normal)
//            btnFont.setBackgroundImage(UIImage(named: "Paid_Feature"), for: .normal)
//            timerButton.setBackgroundImage(UIImage(named: "Paid_Feature"), for: .normal)
//        }
        
        
        self.getPasscode()
    }
    
    override func viewWillLayoutSubviews() {
        
        if self.arrLoginCredential.count > 0 {
            // fix same NMaks
            //self.thumbIDViewTopConstraint.constant = IS_IPHONE ? 95 : 130
            
            //            self.btnShareTopConstraint.constant = IS_IPHONE_X ? 170 : IS_IPHONE_6PLUS_OR_7PLUS ? 160 : IS_IPHONE_6_OR_7 && APP_DELEGATE.isBiomatriAvailable() ? 160 : IS_IPHONE_4_OR_5 ? 85 : IS_IPAD_PRO ? 130 : IS_IPHONE_6_OR_7 ? 90 : 115
        } else {
            // fix same NMaks
            //self.thumbIDViewTopConstraint.constant = 25
            //            self.btnShareTopConstraint.constant = IS_IPHONE_X ? 100 : IS_IPHONE_6PLUS_OR_7PLUS ? 80 : IS_IPHONE_6_OR_7 && APP_DELEGATE.isBiomatriAvailable() ? 85 : IS_IPHONE_4_OR_5 ? 25 : IS_IPHONE_6_OR_7 ? 25 : 25
        }
        //        self.poweredByLeadingConstraint.constant = IS_IPHONE_X ? 60 : IS_IPHONE_6PLUS_OR_7PLUS ? 75 : IS_IPHONE_6_OR_7 ? 57 : IS_IPHONE_4_OR_5 ? 30 : IS_IPAD_PRO ? 340 : 240
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func moreOptionAclicked(_ sender: UIButton) {
        dropDownClicked = !dropDownClicked
        checkDropDown()
    }
    //MARK:- BUTTON'S ACTIONS
    @IBAction func btnBackPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func runSupportVC(_ sender: Any) {
        showEmailController()
    }
    
    @objc private func showPopUpScreen() {
        
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "PopUpTimerSceneVC") as! PopUpTimerSceneVC
        settingsVC.modalPresentationStyle = .overCurrentContext
        self.navigationController?.modalPresentationStyle = .overCurrentContext
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.present(settingsVC, animated: true, completion: nil)
    }
    
    @IBAction func runTimer(_ sender: Any) {
        
        /*if sharedObj!.isProductPurchased == false {
            
            //iapObj.purchase()
            
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PurchaseIntroVC") as! PurchaseIntroVC
            self.present(vc, animated: true, completion: nil)
            
            return
        }*/
        
        let alertVC = UIAlertController(title: "Timer is running", message: nil, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            let _ = Timer.scheduledTimer(timeInterval: 600, target: self!, selector: #selector(self?.showPopUpScreen), userInfo: nil, repeats: false)
            
        }
        alertVC.addAction(alertAction)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    @objc func btnCancelPressed(_ sender : UIButton) {
        
        self.isOLDPasscode     = true
        self.isConformPasscode = false
        self.strNewPasscode    = ""
        self.isPasscodeSet     = false
        self.strPasscode       = ""
        self.isDelete          = false
        
        self.passcodeViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signOut(_ sender: Any) {
        
        let alertVC = UIAlertController(title: "Sign out", message: nil, preferredStyle: .alert)
        let alertCancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let alertSignOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { (_) in
            self.logoout()
        }
        alertVC.addAction(alertCancelAction)
        alertVC.addAction(alertSignOutAction)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    @IBAction func btnDeleteAccount(_ sender: Any) {
        print("disabl account")
        
        let alertVC = UIAlertController(title: "Delete Account", message: nil, preferredStyle: .alert)
        let alertCancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let alertSignOutAction = UIAlertAction(title: "Delete ", style: .destructive) { (_) in
            FirebaseAuthoriztion.sharedInstance.updateAccountStatus(account_status: "true") { isDisable in
                if isDisable{
                    self.logoout()
                }
            }
        }
        alertVC.addAction(alertCancelAction)
        alertVC.addAction(alertSignOutAction)
        self.present(alertVC, animated: true, completion: nil)
    }
    @IBAction func restoreAction(_ sender: Any) {
        
        if (self.sharedObj?.isReachable)! {
            
            iapObj.restorePurchases()
            
        } else {
            
            DispatchQueue.main.async(execute: {
                
                let alert = UIAlertController(title: "", message: "Please check your internet connection and try again.", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    @IBAction func membershipAction(_ sender: Any) {
        WellnessPresentation.subscription(from: self)
    }
    
    @IBAction func themeAction(_ sender: Any) {
   
//        if sharedObj!.isProductPurchased == false {
//            
//            //iapObj.purchase()
//            
//            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PurchaseIntroVC") as! PurchaseIntroVC
//            self.present(vc, animated: true, completion: nil)
//            
//            return
//        }
        
        addBottomSheetView()
    }
    
    @IBAction func privacyPolicyActions(_ sender: Any) {
        WellnessPresentation.privacy(from: self)
    }
    @IBAction func btnTermsConditionAction(_ sender: Any) {
        guard let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") else {
          return //be safe
        }

        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    //MARK: Logout
    func logoout(){
        if (UserDefaults.standard.bool(forKey: SignInKeysItems.LoginKeysUserDefaults.isLoginKeyFirebase)) {
            UserDefaults.standard.set(false, forKey: SignInKeysItems.LoginKeysUserDefaults.isLoginKeyFirebase)
            self.firebaseAuth.logoutFirebaseAccount()
        }
        
        if (UserDefaults.standard.bool(forKey: SignInKeysItems.LoginKeysUserDefaults.isLoginKeyFB)) {
            UserDefaults.standard.set(false, forKey: SignInKeysItems.LoginKeysUserDefaults.isLoginKeyFB)
            self.facebookAuth.signOutFacebookAccount()
        }
        // delete notes
        let databaseManager = FileManager.default
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent("notes").appendingPathExtension("sqlite")
            
            try databaseManager.removeItem(at: fileURL)
            
        } catch {
            print("Delete error: \(error.localizedDescription)")
        }
        
        Coordinator.rootViewContoller(isFirstTime: false)
        
        (DBManager.sharedManager() as AnyObject).createEditableCopyOfSQLIteIfNeeded()
    }
    
    func invalidateComponents() {
        
        let defaults = UserDefaults.standard
        
        let colorIndex = defaults.integer(forKey: MYTHEMECOLORINDEX)
        
        print("selected ColorIndex")
        print(colorIndex)
        
        if colorIndex != 0 {
            
            //updateColor(view: navigationBarView1, index: colorIndex)
        }
        
        updateFont()
        
    }
    
    func updateFont() {
        
        let defaults = UserDefaults.standard
        let fontIndex = defaults.integer(forKey: MYTHEMEFONTINDEX)
        
        print("font change")
        print(fontIndex)
        
        if fontIndex == 0 {
            return
        }
        
        let fontsize: CGFloat = 17
        
        switch fontIndex {
        case 1:
            lblNavigationTitle.font = UIFont(name: "SanFranciscoDisplay-Regular", size: fontsize)
        case 2:
            lblNavigationTitle.font = UIFont(name: "Comic Sans MS", size: fontsize)
        case 3:
            lblNavigationTitle.font = UIFont(name: "Helvetica", size: fontsize)
        case 4:
            lblNavigationTitle.font = UIFont(name: "Times New Roman", size: fontsize)
        case 5:
            lblNavigationTitle.font = UIFont(name: "Bodoni 72 Book", size: fontsize)
        default:
            lblNavigationTitle.font = UIFont(name: "Times New Roman", size: fontsize)
        }
        
    }
    
    func updateColor(view: UIView, index: Int) {
        
        var mythemecolor1 = mythemeColor1_1
        var mythemecolor2 = mythemeColor1_2
        
        switch index {
        case 1:
            mythemecolor1 = mythemeColor1_1
            mythemecolor2 = mythemeColor1_2
        case 2:
            mythemecolor1 = mythemeColor2_1
            mythemecolor2 = mythemeColor2_2
        case 3:
            mythemecolor1 = mythemeColor3_1
            mythemecolor2 = mythemeColor3_2
        case 4:
            mythemecolor1 = mythemeColor4_1
            mythemecolor2 = mythemeColor4_2
        case 5:
            mythemecolor1 = mythemeColor5_1
            mythemecolor2 = mythemeColor5_2
        default:
            mythemecolor1 = mythemeColor1_1
            mythemecolor2 = mythemeColor1_2
        }
        
        /*
        var firstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(0.0)
        if index == 5 {
            firstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(1.0)
        }
        let secondColor = UIColor(rgb: mythemecolor2).withAlphaComponent(1.0)
        */
        
//        let layer = view.layer as! CAGradientLayer
//        layer.colors = [mythemecolor1,mythemecolor2].map({$0.cgColor})
//        layer.startPoint = CGPoint(x: 0, y: 1)
//        layer.endPoint = CGPoint(x: 1, y: 0.0)
        
    }
    
    func addBottomSheetView() {
        
        let bottomSheetVC = ScrollableBottomSheetViewController()
        
        self.addChild(bottomSheetVC)
        self.view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParent: self)
        
        let height = view.frame.height
        let width  = view.frame.width
        bottomSheetVC.view.frame = CGRect(x: 0, y: height, width: width, height: height)
       
    }
    
    @IBAction func fontAction(_ sender: Any) {
        
        if sharedObj!.isProductPurchased == false {
            
            //iapObj.purchase()
            
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PurchaseIntroVC") as! PurchaseIntroVC
            self.present(vc, animated: true, completion: nil)
            
            return
        }
    }
    
    //MARK:- TOPASSCODE VIEW CONTROLLER DELEGATE METHODS
    func didTapCancel(in passcodeViewController: TOPasscodeViewController) {
        passcodeViewController.dismiss(animated: true, completion: nil)
    }
    
    func passcodeViewController(_ passcodeViewController: TOPasscodeViewController, isCorrectCode code: String) -> Bool {
        
        if self.isDelete {
            if code == self.strOLDPasscode {
                let isRecordDeletd  = (DBManager.sharedManager() as AnyObject).removePasscode(self.strOLDPasscode)
                
                if isRecordDeletd {
                    self.isOLDPasscode     = true
                    self.strOLDPasscode    = ""
                    self.strNewPasscode    = ""
                    self.isPasscodeSet     = false
                    self.isConformPasscode = false
                    self.isDelete          = false
                    
                    //self.btnRemovePasscode.isHidden = true
                    // fix same NMaks
                    //self.thumbIDViewTopConstraint.constant = 95
                    
                    //self.btnChangePasscode.setTitle("SET PASSCODE", for: .normal)
                    self.arrLoginCredential.removeAll()
                    // Toast(text: kPASSCODE_REMOVED).show()
                    
                    self.getPasscode()
                    
                    return true
                }
            } else {
                // Toast(text: kENTER_VALID_OLD_PASSCODE).show()
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            }
            
        } else {
            if self.isPasscodeSet {
                OperationQueue.main.addOperation {
                    if !self.isOLDPasscode && code == self.strOLDPasscode {
                        // Toast(text: kNEW_PASSCODE_NOT_WITH_PASSCODE).show()
                        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                        
//                        self.passcodeViewController?.changeTopText(kNEW_PASSCODE)
                                            }
                    else if code == self.strOLDPasscode {
                        self.isOLDPasscode = false
                        self.strNewPasscode = code
//                        self.passcodeViewController?.changeTopText(kNEW_PASSCODE)
                    }
                    else if self.isOLDPasscode && code != self.strOLDPasscode {
                        // Toast(text: kENTER_VALID_OLD_PASSCODE).show()
//                        self.passcodeViewController?.changeTopText(kOLD_PASSCODE)
                        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                    }
                    else if code == self.strNewPasscode {
                        self.passcodeViewController?.dismiss(animated: true, completion: nil)
                        let isPasscodeUpdated = (DBManager.sharedManager() as AnyObject).updatepasscode(code, strLoginOLDPasscode: self.strOLDPasscode)
                        
                        if isPasscodeUpdated {
                            // Toast(text: kPASSCODE_UPDATED).show()
                            passcodeViewController.dismiss(animated: true, completion: nil)
                            
                            self.isOLDPasscode     = true
                            self.strOLDPasscode    = ""
                            self.strNewPasscode    = ""
                            self.isPasscodeSet     = false
                            self.isConformPasscode = false
                            
                            self.getPasscode()
                        } else {
                            // Toast(text: kPASSCODE_NOT_UPDATED).show()
                        }
                    }
                    else if self.isConformPasscode && code != self.strNewPasscode {
                        // Toast(text: kCONFIRM_PASSCODE_NOT_SAME_AS_PASSCODE).show()
                        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                        
//                        self.passcodeViewController?.changeTopText(kCONFIRM_PASSCODE)
                    }
                    else {
                        self.strNewPasscode = code
//                        self.passcodeViewController?.changeTopText(kCONFIRM_PASSCODE)
                        self.isConformPasscode = true
                    }
                }
            } else {
                if !isConformPasscode {
                    OperationQueue.main.addOperation {
                        self.isConformPasscode = true
                        self.strPasscode = code
//                        self.passcodeViewController?.changeTopText(kCONFIRM_PASSCODE)
                    }
                } else {
                    if code != self.strPasscode {
                        // Toast(text: kCONFIRM_PASSCODE_NOT_SAME_AS_PASSCODE).show()
                        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                        
//                        self.passcodeViewController?.changeTopText(kCONFIRM_PASSCODE)
                    } else {
                        let isSaved = (DBManager.sharedManager() as AnyObject).setPasscode(code)
                        
                        if isSaved {
                            let noteCategoryListVC = self.storyboard?.instantiateViewController(withIdentifier: "NoteCategoryListVC") as! NoteCategoryListVC
                            self.navigationController?.pushViewController(noteCategoryListVC, animated: true)
                            
                            UserDefaults.standard.removeObject(forKey: kIS_SKIPPED)
                            self.isConformPasscode = false
                            self.strPasscode       = ""
                            
                            self.getPasscode()
                        } else {
                            // Toast(text: kPASSCODE_NOTE_SET).show()
                        }
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func presentPasscodeSetVC(_ isAnimated : Bool, _ title : String) {
        self.passcodeViewController = TOPasscodeViewController(style: .translucentDark, passcodeType: .fourDigits)
        self.passcodeViewController?.delegate = self
        
        self.passcodeViewController?.allowBiometricValidation = false
//        self.passcodeViewController?.strTitleText = title
        self.passcodeViewController?.biometricButton.isHidden = true
//        self.passcodeViewController?.thumbIDYPosition = thumbID_YPosition
        
        let xPosition = (self.view.frame.size.width / 2) - 35
        
        let yPosition = IS_IPHONE ? SCREEN_HEIGHT - 50 : ((self.view.frame.size.height / 4) * 3) + (IS_IPAD_PRO ? 0 : 20)
        
        let btnSkip : UIButton = UIButton(frame: CGRect(x: xPosition, y: yPosition, width: 70, height: 35))
        btnSkip.setTitle("Cancel", for: .normal)
        btnSkip.setTitleColor(.white, for: .normal)
        btnSkip.addTarget(self, action: #selector(self.btnCancelPressed(_:)), for: .touchUpInside)
        self.passcodeViewController?.view.addSubview(btnSkip)
        
        self.present(self.passcodeViewController!, animated: isAnimated, completion: nil)
    }
    
    //MARK:- SHOW EMAIL SCENE
    private func showEmailController() {
        
        if (MFMailComposeViewController.canSendMail()) {
            
            let emailAddress = "info@whirlpost.co"
            let titleLetter = "What can we help you with?"
            let message = "Please tell us a little about what you need help with."
            
            let emailVC = MFMailComposeViewController()
            emailVC.mailComposeDelegate = self
            emailVC.setToRecipients([emailAddress])
            emailVC.setSubject(titleLetter)
            emailVC.setMessageBody(message, isHTML: false)
            self.present(emailVC, animated: true, completion: nil)
        } else {
            print("Device not supported sending emailS")
            
            let alert = UIAlertController(title: "", message: "Please email our Customer Support team at info@whirlpost.co", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertAction.Style.default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK:- GET PASSCODE
    func getPasscode() {
        
        self.arrLoginCredential = (DBManager.sharedManager() as AnyObject).getResultForSQLQuery("select passcode from login") as! [Any]
        
        if self.arrLoginCredential.count > 0 {
            //self.btnRemovePasscode.isHidden = false
            // fix same NMaks
            //self.thumbIDViewTopConstraint.constant = 95
            self.strOLDPasscode = String(describing: (self.arrLoginCredential[0] as! [String : Any])["passcode"]!)
        } else {
            //self.btnRemovePasscode.isHidden = true
            //this cause a fatal error, possibly deletion of constraint from storyboard cause this error. NMaks
            //self.thumbIDViewTopConstraint.constant = 30
            //self.btnChangePasscode.setTitle("SET PASSCODE", for: .normal)
        }
    }
    deinit {
        print("Settings screen is deinit")
    }
}

extension SettingsVC: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let error = error {
            print("Error with Email Controller: \(error.localizedDescription)")
        }
        
        // Observe result of process email controller
        
        switch (result) {
            
        case MFMailComposeResult.failed:
            print("Email was Failed")
            
        case MFMailComposeResult.cancelled:
            print("Email was Canselled")
            
        case MFMailComposeResult.saved:
            print("Email was Saved")
            
        case MFMailComposeResult.sent:
            print("Email was sent")
        }
        
        dismiss(animated: true, completion: nil)
    }
}

/*
 
 @IBAction func btnChangePasscodePressed(_ sender: UIButton) {
 
 if self.arrLoginCredential.count > 0 {
 self.isPasscodeSet = true
 self.presentPasscodeSetVC(false, kOLD_PASSCODE)
 } else {
 self.presentPasscodeSetVC(false, kSET_PASSCODE)
 }
 }
 
 @IBAction func btnRemovePasscodePressed(_ sender: UIButton) {
 self.isDelete = true
 self.presentPasscodeSetVC(false, KENTER_OLR_PASSCODE)
 }
 
 @IBAction func btnPoweredByPressed(_ sender: UIButton) {
 let webViewVC = self.storyboard?.instantiateViewController(withIdentifier: "WebViewVC") as! WebViewVC
 self.present(webViewVC, animated: true, completion: nil)
 }
 
 @IBAction func btnSharePressed(_ sender: UIButton) {
 
 let vc = UIActivityViewController(activityItems: ["Download this nice notes app from appstore: <appstore link>"], applicationActivities: [])
 vc.popoverPresentationController?.sourceView = self.view
 vc.popoverPresentationController?.sourceRect = sender.frame
 
 self.present(vc, animated: true)
 }
 
 @IBAction func btnMoreAppsPressed(_ sender: UIButton) {
 
 if UIApplication.shared.canOpenURL(URL(string: "https://itunes.apple.com/us/developer/mubin-lakadia/id411686342")!) {
 
 UIApplication.shared.openURL(URL(string: "https://itunes.apple.com/us/developer/mubin-lakadia/id411686342")!)
 } else {
 alertView(nil, "Unable to show more apps", ["OK"], completionHandler: { (index) in })
 }
 }
 
 @IBAction func switchThurnOnThumbIDChanged(_ sender: UISwitch) {
 
 DispatchQueue.main.async {
 if !sender.isOn {
 sender.tintColor = .white
 sender.thumbTintColor = BLUE_COLOR
 sender.backgroundColor = .white
 UserDefaults.standard.removeObject(forKey: kIS_THUMB_ID_ALLOWED)
 } else {
 sender.onTintColor = .white // BLUE_COLOR
 sender.thumbTintColor = BLUE_COLOR // .white
 UserDefaults.standard.set(true, forKey: kIS_THUMB_ID_ALLOWED)
 }
 }
 }
 */

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleSettingIndices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThemeSettingTableViewCell", for: indexPath) as! ThemeSettingTableViewCell
        let settingIndex = visibleSettingIndices[indexPath.row]
        let item = themeArray[settingIndex]
        let symbols = ["paintpalette", "textformat", "timer", "arrow.clockwise", "questionmark.circle", "hand.raised", "doc.text", "person.crop.circle.badge.minus", "rectangle.portrait.and.arrow.right"]
        let symbol = symbols.indices.contains(settingIndex) ? symbols[settingIndex] : "circle"
        cell.iconImageView.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)) ?? item.icon
        cell.titleLable.text = item.title
        cell.titleLable.textColor = ApplazAppearance.ink
        cell.iconImageView.tintColor = cell.titleLable.textColor
        cell.themeContainerView.layer.cornerRadius = 14
        cell.themeContainerView.clipsToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch visibleSettingIndices[indexPath.row] {
        case 0:
            self.themeAction(self)
        case 1:
            self.fontAction(self)
        case 2:
            self.runTimer(self)
        case 3:
            Task { await SubscriptionCenter.shared.restore() }
        case 4:
            self.runSupportVC(self)
        case 5:
            self.privacyPolicyActions(self)
        case 6:
            self.btnTermsConditionAction(self)
        case 7:
            self.btnDeleteAccount(self)
        case 8:
            self.signOut(self)
        case 9:
            WellnessPresentation.subscription(from: self)
        default:
            break
        }
    }
}

struct ThemeSetting {
    let title: String
    let icon: UIImage
}
