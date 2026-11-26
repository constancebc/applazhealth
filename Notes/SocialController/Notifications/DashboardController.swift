//
//  DashboardController.swift
//  Mustage
//
//  Created by Oleg Baidalka on 16/03/2018.
//  Copyright © 2018 Bossly. All rights reserved.
//

import UIKit
import Firebase

class DashboardController: UITabBarController, UITabBarControllerDelegate {
    private let backSwipeGuard = ApplazBackSwipeGuard()


    @IBOutlet var centerButton: UIButton!
    private var badgeReference: DatabaseReference?
    private var badgeObserver: DatabaseHandle?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        // subcribe for badge updates
        if let handle = badgeObserver { badgeReference?.removeObserver(withHandle: handle) }
        badgeReference = SocialUserModel.current?.ref
        badgeObserver = badgeReference?.observe(.value, with: { [weak self] data in
            guard let self else { return }
            // update unread count
            if data.exists(), let number = data.values?["unread"] as? Int {
                self.updateBadge("\(number)")
                UIApplication.shared.applicationIconBadgeNumber = number
            } else {
                self.updateBadge(nil)
            }
        })
        
        
        
        setupCenterButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        backSwipeGuard.install(on: navigationController)
        if let navigationController {
            let screens = navigationController.viewControllers.filter { !($0 is WelcomeViewController) }
            if screens.count != navigationController.viewControllers.count {
                navigationController.setViewControllers(screens, animated: false)
            }
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func updateBadge(_ badge:String?) {
        
        // update unread count
        if let tabItem = self.tabBar.items?.first(where: {(item) -> Bool in
            return item.tag == 1
        }), tabItem != tabBar.selectedItem { // and not currently selected
            tabItem.badgeValue = badge

        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let handle = badgeObserver { badgeReference?.removeObserver(withHandle: handle) }
        badgeObserver = nil
    }
    
    @IBAction func btnCenterAction(_ sender: Any) {
        showNotebooks()

    }
    
    func showNotebooks() {
        setupCenterButton()
        selectedIndex = 2
        (selectedViewController as? UINavigationController)?.popToRootViewController(animated: false)
    }

    //MARK: - SetupCenterButton
    
    func setupCenterButton() {
        delegate = self
        centerButton.isHidden = true
        centerButton.isUserInteractionEnabled = false
        if var controllers = viewControllers, controllers.count == 4 {
            let notebooks = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NoteCategoryListVC")
            let notebookAction = UINavigationController(rootViewController: notebooks)
            notebookAction.navigationBar.isHidden = true
            notebookAction.tabBarItem = UITabBarItem(title: nil, image: nil, tag: 999)
            controllers.insert(notebookAction, at: 2)
            setViewControllers(controllers, animated: false)
        }
        Self.styleTabBar(tabBar)
    }

    static func styleTabBar(_ tabBar: UITabBar) {
        let names = ["Home", "Search", "Open notebooks", "Messages", "Profile"]
        let symbols = ["house", "magnifyingglass", "plus.circle", "bubble.left.and.bubble.right", "person.crop.circle"]
        let selectedSymbols = ["house.fill", "magnifyingglass", "plus.circle", "bubble.left.and.bubble.right.fill", "person.crop.circle.fill"]
        for (index, item) in (tabBar.items ?? []).enumerated() where names.indices.contains(index) {
            let style = UIImage.SymbolConfiguration(pointSize: index == 2 ? 24 : 21, weight: .regular)
            item.title = nil
            item.image = UIImage(systemName: symbols[index], withConfiguration: style)
            item.selectedImage = UIImage(systemName: selectedSymbols[index], withConfiguration: style)
            item.imageInsets = .zero
            item.titlePositionAdjustment = .zero
            item.accessibilityLabel = names[index]
            item.accessibilityIdentifier = "ApplazTab" + names[index]
        }
        tabBar.tintColor = ApplazAppearance.accent
        tabBar.unselectedItemTintColor = ApplazAppearance.ink.withAlphaComponent(0.7)
        tabBar.itemPositioning = .fill
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.tabBarItem.tag == 999 {
            (viewController as? UINavigationController)?.popToRootViewController(animated: false)
        }
        return true
    }
}
