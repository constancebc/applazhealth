/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import StoreKit

/// Compatibility entry points for older screens. Apple-signed StoreKit 2
/// entitlements replace the former client-side shared-secret receipt checks.
open class IAPHelper: NSObject {
    func autoRenewableGetInfo() { Task { @MainActor in await SubscriptionCenter.shared.loadProduct() } }
    func autoRenewablePurchase() { Task { @MainActor in
        guard let controller = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        var top = controller
        while let presented = top.presentedViewController { top = presented }
        WellnessPresentation.paywall(from: top)
    } }
    func autoRenewableVerifyPurchase() { verifyReceipt() }
    func restorePurchases() { Task { @MainActor in await SubscriptionCenter.shared.restore(); await restoreLegacyAccess() } }
    func verifyReceipt() { Task { @MainActor in await SubscriptionCenter.shared.refresh(); await restoreLegacyAccess() } }
    @MainActor private func restoreLegacyAccess() async {
        let legacy = "com.sevenstar.whirlpost.autoRenewableMonthly"
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, transaction.productID == legacy,
                  transaction.revocationDate == nil,
                  transaction.expirationDate.map({ $0 > Date() }) == true else { continue }
            // Existing ad-free access is retained; it does not grant new AI credits.
            Shared.sharedInstance.isProductPurchased = true
        }
    }
}
