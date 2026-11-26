import UIKit
import SwiftUI
import FirebaseAuth

@MainActor enum WellnessOnboarding {
    static func home() -> UIViewController {
        let dashboard = UIStoryboard(name: "SocialMain", bundle: nil).instantiateViewController(withIdentifier: "DashboardController") as! DashboardController
        dashboard.loadViewIfNeeded(); dashboard.setupCenterButton(); dashboard.selectedIndex = 0
        return dashboard
    }
    static func welcome(navigation: UINavigationController) -> UIViewController {
        WellnessHostingController(rootView: NavigationView {
            SubscriptionWelcomeView(onClose: { [weak navigation] in
                UserDefaults.standard.set(true, forKey: "ApplazWelcomeSeen.v1")
                UserDefaults.standard.set(Auth.auth().currentUser == nil, forKey: Guest_Key)
                navigation?.setViewControllers([home()], animated: false)
            }, onPurchased: { [weak navigation] in
                UserDefaults.standard.set(true, forKey: "ApplazWelcomeSeen.v1")
                let destination = Auth.auth().currentUser == nil ? UIStoryboard(name: "Authorization", bundle: nil).instantiateViewController(withIdentifier: "SignInScene") : home()
                navigation?.setViewControllers([destination], animated: true)
            })
        }.navigationViewStyle(.stack))
    }
}
