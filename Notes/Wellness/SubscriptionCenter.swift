import UIKit
import Combine
import StoreKit
import FirebaseAuth
import Security

@MainActor final class SubscriptionCenter: ObservableObject {
    static let shared = SubscriptionCenter()
    static let productID = "299"
    @Published var serviceReady = false
    @Published private(set) var loadingProduct = false
    @Published var product: Product?
    @Published var eligibleTrial = false
    @Published private(set) var trialUnavailableReason: String?
    @Published var hasAppleSubscription = false
    @Published var credits = 0
    @Published var capacity = 0
    @Published var periodEnd: Date?
    @Published var isTrial = false
    @Published var busy = false
    @Published var message: String?
    @Published var aiConsent = false
    private var foreground: AnyCancellable?
    private var updates: Task<Void, Never>?
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var signedTransaction: String?
    init() {
        foreground = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).sink { [weak self] _ in
            Task { @MainActor in await self?.loadProduct(); await self?.refresh() }
        }
        updates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self?.accept(transaction, signed: result.jwsRepresentation)
                await transaction.finish()
            }
        }
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self else { return }
                self.credits = 0; self.capacity = 0; self.aiConsent = false
                if user != nil { await self.refresh() }
            }
        }
        Task { await loadProduct(); await refresh() }
    }
    func loadProduct() async {
        guard !loadingProduct else { return }
        loadingProduct = true
        defer { loadingProduct = false }
        message = nil
        serviceReady = (try? await WellnessAPI.call("wellnessStatus", [:])["ready"] as? Bool) == true
        do {
            product = try await Product.products(for: [Self.productID]).first
            guard let loaded = product else {
                eligibleTrial = false
                message = "Apple couldn’t load this subscription. Tap Continue to try again."
                return
            }
            let period = loaded.subscription?.subscriptionPeriod
            guard (period?.unit == .week && period?.value == 1) || (period?.unit == .day && period?.value == 7) else {
                product = nil; eligibleTrial = false
                message = "Apple returned a different subscription plan. Please try again later."
                return
            }
            if let subscription = loaded.subscription, let offer = subscription.introductoryOffer {
                let oneWeek = (offer.period.unit == .week && offer.period.value == 1) || (offer.period.unit == .day && offer.period.value == 7)
                let eligible = await subscription.isEligibleForIntroOffer
                eligibleTrial = offer.paymentMode == .freeTrial && oneWeek && eligible
                trialUnavailableReason = eligibleTrial ? nil : (offer.paymentMode == .freeTrial && oneWeek ? "A free trial isn’t available for this Apple Account." : "Apple isn’t currently offering a one-week free trial for this plan.")
            } else {
                eligibleTrial = false
                trialUnavailableReason = "Apple isn’t currently offering a free trial for this plan."
            }
            if !serviceReady { message = "We couldn’t connect to your membership. Tap Continue to try again." }
        } catch {
            message = "Apple couldn’t load this subscription. Check your connection and tap Continue to try again."
        }
    }
    var price: String { product?.displayPrice ?? "$2.99" }
    func purchase() async -> Bool {
        guard !busy, !loadingProduct else { return false }
        busy = true; message = nil
        defer { busy = false }
        if product == nil || !serviceReady { await loadProduct() }
        guard serviceReady, let product else {
            if message == nil { message = "We couldn’t connect to Apple. Please try again." }
            return false
        }
        do {
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified(let transaction) = result else { throw WellnessAPI.failure("Apple couldn’t verify this purchase.") }
                await accept(transaction, signed: result.jwsRepresentation)
                await transaction.finish()
                return Auth.auth().currentUser == nil || capacity > 0
            case .pending: message = "Your purchase is pending approval. Credits unlock after it is verified."; return false
            case .userCancelled: return false
            @unknown default: return false
            }
        } catch { message = error.localizedDescription; return false }
    }
    private func accept(_ transaction: StoreKit.Transaction, signed: String) async {
        guard transaction.productID == Self.productID else { return }
        guard transaction.revocationDate == nil, transaction.expirationDate.map({ $0 > Date() }) == true else {
            hasAppleSubscription = false; credits = 0; capacity = 0; return
        }
        hasAppleSubscription = true; signedTransaction = signed
        if Auth.auth().currentUser != nil { await syncEntitlement(signed) }
        else { message = "Subscription confirmed. Sign in to activate your AI credits and save your notebooks." }
    }
    func refresh() async {
        var found = false
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, transaction.productID == Self.productID else { continue }
            found = true; await accept(transaction, signed: result.jwsRepresentation)
        }
        if !found { hasAppleSubscription = false; credits = 0; capacity = 0 }
    }
    private func syncEntitlement(_ signed: String) async {
        let account = Auth.auth().currentUser?.uid
        do {
            let result = try await WellnessAPI.call("subscriptionAccess", ["signedTransaction": signed])
            guard account == Auth.auth().currentUser?.uid else { return }
            apply(result); message = nil
        } catch { credits = 0; capacity = 0; message = error.localizedDescription }
    }
    func apply(_ result: [String: Any]) {
        credits = result["credits"] as? Int ?? 0; capacity = result["capacity"] as? Int ?? 0
        isTrial = result["trial"] as? Bool ?? false
        aiConsent = result["consent"] as? Bool ?? aiConsent
        if let ms = result["expiresAt"] as? Double { periodEnd = Date(timeIntervalSince1970: ms / 1000) }
    }
    func restore() async {
        busy = true; defer { busy = false }
        do { try await AppStore.sync(); await refresh(); if !hasAppleSubscription { message = "No active Applaz Plus subscription was found for this Apple Account." } }
        catch { message = error.localizedDescription }
    }
    func manage() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        do { try await AppStore.showManageSubscriptions(in: scene); await refresh() }
        catch { message = error.localizedDescription }
    }
    func consent(_ allowed: Bool) async throws {
        guard let owner = Auth.auth().currentUser?.uid else { throw WellnessAPI.failure("Sign in to manage AI privacy.") }
        let result = try await WellnessAPI.call("wellnessConsent", ["allow": allowed], expectedUID: owner)
        guard owner == Auth.auth().currentUser?.uid else { return }
        aiConsent = result["consent"] as? Bool == true
    }
    func ask(question: String, context: String, image: Data? = nil, meal: Bool = false, metrics: [AIMetric] = [], structured: Bool = false, expectedUID: String? = nil) async throws -> [String: Any] {
        guard let owner = Auth.auth().currentUser?.uid else { throw WellnessAPI.failure("Sign in to use your AI credits.") }
        if let expectedUID, expectedUID != owner { throw WellnessAPI.failure("Your account changed. Reopen this chat.") }
        guard hasAppleSubscription else { throw WellnessAPI.failure("Applaz Plus includes AI chat, insights and meal estimates. Subscribe or restore a purchase to continue.") }
        guard aiConsent else { throw WellnessAPI.failure("Choose Allow in AI privacy before sharing selected content with AI.") }
        var payload: [String: Any] = ["question": question, "context": String(decoding: context.utf8.prefix(11000), as: UTF8.self), "meal": meal, "requestID": UUID().uuidString]
        if structured {
            payload["structured"] = true
            payload["context"] = String(decoding: context.utf8.prefix(5800), as: UTF8.self)
            payload["metrics"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(metrics))
        }
        if let image { payload["image"] = image.base64EncodedString() }
        let result = try await WellnessAPI.call("wellnessAI", payload, expectedUID: owner)
        if let balance = result["balance"] as? [String: Any] { apply(balance) }
        return result
    }
}
