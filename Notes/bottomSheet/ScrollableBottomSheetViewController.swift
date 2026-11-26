//
//  ScrollableBottomSheetViewController.swift
//  BottomSheet
//
//  Created by Ahmed Elassuty on 10/15/16.
//  Copyright © 2016 Ahmed Elassuty. All rights reserved.
//

import UIKit

class ScrollableBottomSheetViewController: UIViewController {
    
    var selectedColorIndex = 0
    var selectedFontIndex = 0
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet var mainView: UIView!
    
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var view2: UIView!
    @IBOutlet weak var view3: UIView!
    @IBOutlet weak var view4: UIView!
    @IBOutlet weak var view5: UIView!
    
    @IBOutlet weak var myselview1: UIView!
    @IBOutlet weak var myselview2: UIView!
    @IBOutlet weak var myselview3: UIView!
    @IBOutlet weak var myselview4: UIView!
    @IBOutlet weak var myselview5: UIView!
    
    @IBOutlet weak var fontView1: UIView!
    @IBOutlet weak var fontView2: UIView!
    @IBOutlet weak var fontView3: UIView!
    @IBOutlet weak var fontView4: UIView!
    @IBOutlet weak var fontView5: UIView!
    
    @IBOutlet weak var check1: UIImageView!
    @IBOutlet weak var check2: UIImageView!
    @IBOutlet weak var check3: UIImageView!
    @IBOutlet weak var check4: UIImageView!
    @IBOutlet weak var check5: UIImageView!
    
    @IBOutlet weak var themeOkayButton: UIButton!
    
    let fullView: CGFloat = 150
    var partialView: CGFloat {
        //return UIScreen.main.bounds.height - 70
        return 100
    }
    
    func preSetup() {
        
        preFontSetup()
        
        let gesture1 = UITapGestureRecognizer(target: self, action: #selector(SelAction1(_:)))
        myselview1.addGestureRecognizer(gesture1)
        
        let gesture2 = UITapGestureRecognizer(target: self, action: #selector(SelAction2(_:)))
        myselview2.addGestureRecognizer(gesture2)
        
        let gesture3 = UITapGestureRecognizer(target: self, action: #selector(SelAction3(_:)))
        myselview3.addGestureRecognizer(gesture3)
        
        let gesture4 = UITapGestureRecognizer(target: self, action: #selector(SelAction4(_:)))
        myselview4.addGestureRecognizer(gesture4)
        
        let gesture5 = UITapGestureRecognizer(target: self, action: #selector(SelAction5(_:)))
        myselview5.addGestureRecognizer(gesture5)
        
        myselview1.layer.cornerRadius = defaultRoundValue
        myselview1.layer.masksToBounds = true
        
        myselview2.layer.cornerRadius = defaultRoundValue
        myselview2.layer.masksToBounds = true
        
        myselview3.layer.cornerRadius = defaultRoundValue
        myselview3.layer.masksToBounds = true
        
        myselview4.layer.cornerRadius = defaultRoundValue
        myselview4.layer.masksToBounds = true
        
        myselview5.layer.cornerRadius = defaultRoundValue
        myselview5.layer.masksToBounds = true
        
        updateColor(view: view1, firstColor: mythemeColor1_1.withAlphaComponent(0.0),secondColor: mythemeColor1_2.withAlphaComponent(1.0))
        
        updateColor(view: view2, firstColor: mythemeColor2_1.withAlphaComponent(0.0),secondColor: mythemeColor2_2.withAlphaComponent(1.0))
        
        updateColor(view: view3, firstColor: mythemeColor3_1.withAlphaComponent(0.0),secondColor: mythemeColor3_2.withAlphaComponent(1.0))
        
        updateColor(view: view4, firstColor: mythemeColor4_1.withAlphaComponent(0.0),secondColor: mythemeColor4_2.withAlphaComponent(1.0))
        
        updateColor(view: view5, firstColor: mythemeColor5_1.withAlphaComponent(1.0),secondColor: mythemeColor5_2.withAlphaComponent(1.0))
        
    }
    
    func preFontSetup() {
        
        let gesture1 = UITapGestureRecognizer(target: self, action: #selector(SelFontAction1(_:)))
        fontView1.addGestureRecognizer(gesture1)
        
        let gesture2 = UITapGestureRecognizer(target: self, action: #selector(SelFontAction2(_:)))
        fontView2.addGestureRecognizer(gesture2)
        
        let gesture3 = UITapGestureRecognizer(target: self, action: #selector(SelFontAction3(_:)))
        fontView3.addGestureRecognizer(gesture3)
        
        let gesture4 = UITapGestureRecognizer(target: self, action: #selector(SelFontAction4(_:)))
        fontView4.addGestureRecognizer(gesture4)
        
        let gesture5 = UITapGestureRecognizer(target: self, action: #selector(SelFontAction5(_:)))
        fontView5.addGestureRecognizer(gesture5)
        
    }
    
    func setColorInd(index:Int, view:UIView) {
        
        print(index)
        
        selectedColorIndex = index
        
        myselview1.backgroundColor = UIColor(rgb: 0xffffff).withAlphaComponent(0.0)
        myselview2.backgroundColor = UIColor(rgb: 0xffffff).withAlphaComponent(0.0)
        myselview3.backgroundColor = UIColor(rgb: 0xffffff).withAlphaComponent(0.0)
        myselview4.backgroundColor = UIColor(rgb: 0xffffff).withAlphaComponent(0.0)
        myselview5.backgroundColor = UIColor(rgb: 0xffffff).withAlphaComponent(0.0)
        
        view.backgroundColor = .gray
    }
    
    @objc func SelAction1(_ sender:UITapGestureRecognizer) {
        
        setColorInd(index: 1, view: self.myselview1)
    }
    
    @objc func SelAction2(_ sender:UITapGestureRecognizer) {
        
        setColorInd(index: 2, view: self.myselview2)
    }
    
    @objc func SelAction3(_ sender:UITapGestureRecognizer) {
        
        setColorInd(index: 3, view: self.myselview3)
    }
    
    @objc func SelAction4(_ sender:UITapGestureRecognizer) {
        
        setColorInd(index: 4, view: self.myselview4)
    }
    
    @objc func SelAction5(_ sender:UITapGestureRecognizer) {
        
        setColorInd(index: 5, view: self.myselview5)
    }
    
    
    @objc func SelFontAction1(_ sender:UITapGestureRecognizer) {
        
        setFontInd(index: 1, view: self.check1)
        
    }
    
    @objc func SelFontAction2(_ sender:UITapGestureRecognizer) {
        
        setFontInd(index: 2, view: self.check2)
        
    }
    
    @objc func SelFontAction3(_ sender:UITapGestureRecognizer) {
        
        setFontInd(index: 3, view: self.check3)
        
    }
    
    @objc func SelFontAction4(_ sender:UITapGestureRecognizer) {
        
        setFontInd(index: 4, view: self.check4)
        
    }
    
    @objc func SelFontAction5(_ sender:UITapGestureRecognizer) {
        
        setFontInd(index: 5, view: self.check5)
        
    }
    
    func setFontInd(index: Int, view: UIImageView) {
        
        print(index)
        selectedFontIndex = index
        
        check1.isHidden = true
        check2.isHidden = true
        check3.isHidden = true
        check4.isHidden = true
        check5.isHidden = true
        
        view.isHidden = false
        
    }
    
    
    func updateColor(view: UIView,firstColor: UIColor, secondColor: UIColor) {
        
        let frameWidth = view.frame.width
        
        view.layer.cornerRadius = frameWidth / 2
        view.layer.masksToBounds = true
        
        let layer = CAGradientLayer()
        //layer.frame = view.bounds
        layer.frame = CGRect(x: 0, y: 0, width: view.frame.size.width + 10, height: view.frame.size.height + 10)
        
        layer.colors = [firstColor,secondColor].map({$0.cgColor})
        
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        view.layer.addSublayer(layer)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        preSetup()
        
        mainView.layer.cornerRadius = 10
        mainView.layer.masksToBounds = true
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(ScrollableBottomSheetViewController.panGesture))
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareBackgroundView()
        
        mainView.backgroundColor = .white
    }
    
    @IBAction func onClickOkayButton(_ sender: Any) {
        
        let defaults = UserDefaults.standard
        
        if self.selectedColorIndex != 0 {
            defaults.set(self.selectedColorIndex, forKey: MYTHEMECOLORINDEX)
        }
        
        if self.selectedFontIndex != 0 {
            defaults.set(self.selectedFontIndex, forKey: MYTHEMEFONTINDEX)
        }
        
        self.view.frame = CGRect(x: 0, y: 1000,width: 0, height: 0)
        
        
        //invalidate color and font
        
        let parent: SettingsVC = SettingsVC.parentViewController as! SettingsVC
        parent.invalidateComponents()
        
        let parent1: NoteCategoryListVC = NoteCategoryListVC.parentViewController as! NoteCategoryListVC
        parent1.invalidateComponents()
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.6, animations: { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.partialView
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height - 100)
            })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: self.view)

        let y = self.view.frame.minY
        if (y + translation.y >= fullView) && (y + translation.y <= partialView) {
            self.view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
        
        if recognizer.state == .ended {
            var duration =  velocity.y < 0 ? Double((y - fullView) / -velocity.y) : Double((partialView - y) / velocity.y )
            
            duration = duration > 1.3 ? 1 : duration
            
            UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
                if  velocity.y >= 0 {
                    self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width, height: self.view.frame.height)
                } else {
                    self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width, height: self.view.frame.height)
                }
                
                }, completion: { [weak self] _ in
                    if ( velocity.y < 0 ) {
                        
                    }
            })
        }
    }
    
    
    func prepareBackgroundView(){
        let blurEffect = UIBlurEffect.init(style: .dark)
        let visualEffect = UIVisualEffectView.init(effect: blurEffect)
        let bluredView = UIVisualEffectView.init(effect: blurEffect)
        bluredView.contentView.addSubview(visualEffect)
        visualEffect.frame = UIScreen.main.bounds
        bluredView.frame = UIScreen.main.bounds
        view.insertSubview(bluredView, at: 0)
    }

}

extension ScrollableBottomSheetViewController: UIGestureRecognizerDelegate {

    // Solution
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let gesture = (gestureRecognizer as! UIPanGestureRecognizer)
        let direction = gesture.velocity(in: view).y

//        let y = view.frame.minY
//        if (y == fullView && tableView.contentOffset.y == 0 && direction > 0) || (y == partialView) {
//            tableView.isScrollEnabled = false
//        } else {
//            tableView.isScrollEnabled = true
//        }
        
        return false
    }
    
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }
    
    convenience init(rgb: Int, a: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            a: a
        )
    }
}
