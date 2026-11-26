import SwiftUI
import UIKit

extension Color {
    static let applazInk = Color.black
    static let applazAccent = Color(red: 0.02, green: 0.06, blue: 0.26)
}
struct WellnessBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.83, green: 0.88, blue: 0.98), Color(red: 0.99, green: 0.94, blue: 0.90), Color(red: 0.99, green: 0.87, blue: 0.77), Color(red: 0.83, green: 0.82, blue: 0.96)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
    }
}
extension View {
    @ViewBuilder func wellnessCard(embedded: Bool = false) -> some View {
        if embedded { self }
        else { self.padding(16).background(Color.white.opacity(0.65)).clipShape(RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(red: 0.70, green: 0.66, blue: 0.88).opacity(0.42), lineWidth: 1)) }
    }
}
struct WellnessNavigationBar: View {
    var title: String
    var back: () -> Void
    var add: (() -> Void)? = nil
    var body: some View {
        HStack {
            Button(action: back) { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel("Back")
            Spacer()
            Text(title).font(.system(size: 17, weight: .medium)).lineLimit(1)
            Spacer()
            if let add { Button(action: add) { Image(systemName: "plus").frame(width: 44, height: 44) }.accessibilityLabel("Add") }
            else { Color.clear.frame(width: 44, height: 44) }
        }.foregroundColor(.applazInk).background(Color.white.opacity(0.12))
    }
}
final class WellnessHostingController<Content: View>: UIHostingController<Content> {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}
@MainActor enum WellnessPresentation {
    static func addNote(to id: String, from controller: UIViewController) {
        let store = WellnessStore.shared
        guard var notebook = store.notebooks.first(where: { $0.id == id }) else { return }
        let note = WellnessTextNote(title: "New note", body: "", isChecklist: notebook.kind != "text")
        notebook.notes.append(note); store.update(notebook)
        noteEditor(notebookID: id, noteID: note.id, from: controller)
    }
    static func noteEditor(notebookID: String, noteID: String, from controller: UIViewController) {
        let host = WellnessHostingController(rootView: NavigationView {
            WellnessNoteEditor(notebookID: notebookID, noteID: noteID).toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { controller.navigationController?.popViewController(animated: true) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Back")
                }
            }
        }.navigationViewStyle(.stack).modifier(WellnessMenuModifier(controller: controller, enabled: controller.tabBarController == nil)))
        controller.navigationController?.pushViewController(host, animated: true)
    }
    static func notebook(_ id: String, from controller: UIViewController) {
        let host = WellnessHostingController(rootView: NavigationView { WellnessNotebookView(notebookID: id, close: { [weak controller] in controller?.navigationController?.popViewController(animated: true) }) }.navigationViewStyle(.stack).modifier(WellnessMenuModifier(controller: controller, enabled: controller.tabBarController == nil)))
        controller.navigationController?.pushViewController(host, animated: true)
    }
    static func chat(from controller: UIViewController, context: String, scope: AIScope? = nil) {
        let host = WellnessHostingController(rootView: AIChatView(context: context, scope: scope))
        controller.present(host, animated: true)
    }
    static func publicNoteChat(_ note: NoteList, from controller: UIViewController) {
        guard note.isPrivateNote == false else { return }
        let html = note.noteDescriptionText ?? ""
        let body = html.setAttributetext(fontsize: 16, fontName: "AvenirNext-Regular")?.string ?? html
        let context = "Public note: " + (note.noteTitleName ?? "") + "\n" + body
        let key = note.noteKey.map { "public-note:" + (note.user_id ?? "") + ":" + (note.parentCategoryKey ?? "") + ":" + $0 }
        chat(from: controller, context: context, scope: .note(context, key: key))
    }
    static func library(from controller: UIViewController) {
        let host = WellnessHostingController(rootView: WellnessLibraryView(close: { [weak controller] in controller?.navigationController?.popViewController(animated: true) }).modifier(WellnessMenuModifier(controller: controller, enabled: controller.tabBarController == nil)))
        controller.navigationController?.pushViewController(host, animated: true)
    }
    static func signInAfterPurchase() {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        UserDefaults.standard.set(false, forKey: Guest_Key)
        let signIn = UIStoryboard(name: "Authorization", bundle: nil).instantiateViewController(withIdentifier: "SignInScene")
        let nav = UINavigationController(rootViewController: signIn); nav.setNavigationBarHidden(true, animated: false)
        app.window?.rootViewController = nav
    }
    static func paywall(from controller: UIViewController) {
        let host = WellnessHostingController(rootView: NavigationView { SubscriptionWelcomeView(onClose: { [weak controller] in controller?.dismiss(animated: true) }, onPurchased: { [weak controller] in controller?.dismiss(animated: true) }) }.navigationViewStyle(.stack))
        host.modalPresentationStyle = .pageSheet
        controller.present(host, animated: true)
    }
    static func privacy(from controller: UIViewController) {
        let host = WellnessHostingController(rootView: NavigationView { AIPrivacyView().toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done") { controller.dismiss(animated: true) } } } }.navigationViewStyle(.stack))
        controller.present(host, animated: true)
    }
    static func subscription(from controller: UIViewController) {
        let host = WellnessHostingController(rootView: NavigationView { SubscriptionSettingsView(close: { [weak controller] in controller?.navigationController?.popViewController(animated: true) }).navigationBarHidden(true) }.navigationViewStyle(.stack))
        controller.navigationController?.pushViewController(host, animated: true)
    }
}

struct WellnessCheckbox: View {
    var checked: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5).fill(checked ? Color.applazAccent : Color.white.opacity(0.6))
            RoundedRectangle(cornerRadius: 5).stroke(Color.applazAccent.opacity(checked ? 1 : 0.75), lineWidth: 1.5)
            if checked { Image(systemName: "checkmark").font(.system(size: 15, weight: .medium)).foregroundColor(.white) }
        }.frame(width: 26, height: 26).accessibilityHidden(true)
    }
}
struct WellnessProgress: View {
    var done: Int
    var total: Int
    var body: some View {
        GeometryReader { geometry in
            Capsule().fill(Color(red: 0.83, green: 0.80, blue: 0.93))
            Capsule().fill(Color.applazAccent).frame(width: geometry.size.width * min(1, max(0, Double(done) / Double(max(1, total)))))
        }.frame(height: 8).accessibilityElement(children: .ignore).accessibilityIdentifier("ChecklistProgress").accessibilityLabel("Progress").accessibilityValue("\(done) of \(total)")
    }
}
extension View {
    func wellnessField() -> some View {
        padding(14).background(Color.white.opacity(0.65)).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.70, green: 0.66, blue: 0.88).opacity(0.35)))
    }
    func wellnessPill() -> some View {
        padding(.horizontal, 14).padding(.vertical, 10).background(Color.white.opacity(0.55)).clipShape(Capsule())
            .overlay(Capsule().stroke(Color(red: 0.70, green: 0.66, blue: 0.88).opacity(0.65)))
    }
}

struct WellnessMenuModifier: ViewModifier {
    weak var controller: UIViewController?
    var enabled: Bool
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
            if enabled {
                WellnessBottomMenu { index in
                    guard let navigation = controller?.navigationController,
                          let home = navigation.viewControllers.compactMap({ $0 as? NoteCategoryListVC }).first else { return }
                    if index == 2 { navigation.popToViewController(home, animated: true) }
                    else { home.openSocialTab(index) }
                }
            }
        }
    }
}
struct WellnessBottomMenu: View {
    var select: (Int) -> Void
    private let names = ["Home", "Search", "Open notebooks", "Messages", "Profile"]
    private let symbols = ["house", "magnifyingglass", "plus.circle", "bubble.left.and.bubble.right", "person.crop.circle"]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                Button { select(index) } label: {
                    Image(systemName: symbols[index]).font(.system(size: index == 2 ? 25 : 22, weight: .regular))
                        .foregroundColor(index == 2 ? .applazAccent : .black)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Group { if index == 2 { Capsule().fill(Color.applazAccent.opacity(0.07)).padding(.horizontal, 3) } })
                }.buttonStyle(.plain).accessibilityLabel(names[index]).accessibilityIdentifier("WellnessTab" + names[index])
            }
        }.padding(.horizontal, 8).padding(.vertical, 4).background(Color.white.opacity(0.8)).clipShape(Capsule())
            .overlay(Capsule().stroke(Color.applazAccent.opacity(0.1)))
            .padding(.horizontal, 12).padding(.top, 6).padding(.bottom, 4)
    }
}

/// Shared translucent surface for large primary actions.
struct ApplazBubbleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18).padding(.vertical, 14)
            .foregroundColor(Color.black.opacity(enabled ? 1 : 0.4))
            .background(Color.white.opacity(configuration.isPressed ? 0.38 : 0.58))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.applazAccent.opacity(0.16)))
    }
}

/// One warning per failure episode, shared by notebook and chat sync.
@MainActor enum CloudSaveWarning {
    private static var shown: Set<String> = []
    static func recovered(_ key: String) { shown.remove(key) }
    static func report(_ error: Error, key: String, savedLocally: Bool) {
        let reason = error.localizedDescription
        let limited = reason.localizedCaseInsensitiveContains("photo storage is full")
        guard limited, !shown.contains(key) else { return }
        present(key: key, reason: reason, savedLocally: savedLocally)
    }
    private static func present(key: String, reason: String, savedLocally: Bool) {
        guard !shown.contains(key) else { return }
        guard UIApplication.shared.applicationState == .active,
              let presenter = UIApplication.topViewController(), presenter.viewIfLoaded?.window != nil,
              !(presenter is UIAlertController), !presenter.isBeingDismissed else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { present(key: key, reason: reason, savedLocally: savedLocally) }
            return
        }
        shown.insert(key)
        let popup = UIHostingController(rootView: PhotoStoragePopup())
        popup.modalPresentationStyle = .overFullScreen
        popup.modalTransitionStyle = .crossDissolve
        popup.view.backgroundColor = .clear
        presenter.present(popup, animated: true)

    }
}


struct PhotoStoragePopup: View {
    @Environment(\.presentationMode) private var presentation
    var body: some View {
        ZStack {
            Color.black.opacity(0.16).ignoresSafeArea()
                .onTapGesture { presentation.wrappedValue.dismiss() }
            VStack(spacing: 20) {
                Text("Your notes are still syncing. Your photo storage is full. Delete a few photos to make room for more.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.black).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("PhotoStorageWarning")
                Button("OK") { presentation.wrappedValue.dismiss() }
                    .buttonStyle(ApplazBubbleButtonStyle())
            }
            .padding(24)
            .background(ZStack { WellnessBackground(); Color.white.opacity(0.4) }.clipShape(RoundedRectangle(cornerRadius: 24)))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.applazAccent.opacity(0.15)))
            .shadow(color: Color.applazAccent.opacity(0.12), radius: 22, y: 8)
            .padding(32).frame(maxWidth: 410)
        }.accessibilityAddTraits(.isModal)
    }
}
