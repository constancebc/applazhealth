import SwiftUI
import UIKit
import FirebaseAuth
import Combine

enum NotebookIcons {
    static let invitation: UIImage = {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { renderer in
            renderer.cgContext.scaleBy(x: 20 / 24, y: 20 / 24)
            UIColor.black.setStroke()
            let head = UIBezierPath(ovalIn: CGRect(x: 5.2, y: 2.7, width: 6.6, height: 6.6)); head.lineWidth = 1.5; head.stroke()
            let shoulders = UIBezierPath(); shoulders.move(to: CGPoint(x: 2, y: 20.5)); shoulders.addLine(to: CGPoint(x: 2, y: 17.5)); shoulders.addCurve(to: CGPoint(x: 15, y: 17.5), controlPoint1: CGPoint(x: 2, y: 10.5), controlPoint2: CGPoint(x: 15, y: 10.5)); shoulders.addLine(to: CGPoint(x: 15, y: 20.5)); shoulders.close(); shoulders.lineWidth = 1.5; shoulders.lineJoinStyle = .round; shoulders.stroke()
            let plus = UIBezierPath(); plus.move(to: CGPoint(x: 17, y: 11.5)); plus.addLine(to: CGPoint(x: 23, y: 11.5)); plus.move(to: CGPoint(x: 20, y: 8.5)); plus.addLine(to: CGPoint(x: 20, y: 14.5)); plus.lineWidth = 1.5; plus.lineCapStyle = .round; plus.stroke()
        }
        return image.withRenderingMode(.alwaysTemplate)
    }()
}
struct CollaborationPerson: Decodable, Identifiable {
    var id: String
    var name: String
    var photo: String
    var following: Bool
}
struct CollaborativeNotebook: Decodable, Identifiable {
    var id: String
    var name: String
    var owner: String
    var ownerName: String
    var kind: String
    var sourceID: String
    var role: String
    var editorCount: Int? = nil
}
struct CollaborationMember: Decodable, Identifiable {
    var id: String
    var name: String
    var photo: String
    var role: String
}
struct CollaborationMembersView: View {
    var notebookID: String
    var notebookName: String
    var sampleMembers: [CollaborationMember]? = nil
    @State private var members: [CollaborationMember] = []
    @State private var error: String?
    @State private var inviting = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack { WellnessBackground(); VStack(spacing: 20) {
            HStack { Text("Friends in this notebook").font(.system(size: 17, weight: .medium)); Spacer(); Button("Done") { dismiss() } }
            Text(notebookName).font(.system(size: 15)).foregroundColor(.black.opacity(0.6)).frame(maxWidth: .infinity, alignment: .leading)
            ScrollView { VStack(spacing: 0) {
                ForEach(members) { person in
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle").font(.system(size: 27, weight: .light)).foregroundColor(.applazAccent)
                        Text("@" + person.name).font(.system(size: 16)); Spacer()
                        Text(person.role == "owner" ? "Owner" : "Can edit").font(.system(size: 12)).foregroundColor(.black.opacity(0.55))
                    }.padding(.vertical, 15)
                    Divider().opacity(0.3)
                }
                if members.isEmpty && error == nil { ProgressView().padding() }
                if let error { Text(error).font(.footnote).padding() }
            }.padding(.horizontal, 16).background(Color.white.opacity(0.55)).clipShape(RoundedRectangle(cornerRadius: 18)) }
            Button { inviting = true } label: { Label("Invite friends", systemImage: "person.2").font(.system(size: 16)).frame(maxWidth: .infinity).padding(14).background(Color.white.opacity(0.65)).clipShape(Capsule()).overlay(Capsule().stroke(Color.applazAccent.opacity(0.15))) }
                .accessibilityIdentifier("InviteMoreNotebookFriends")
        }.padding(22) }.foregroundColor(.black).tint(.applazAccent)
        .task { await load() }
        .sheet(isPresented: $inviting, onDismiss: { Task { await load() } }) {
            CollaborationPeoplePicker(done: { people in inviting = false; guard !people.isEmpty, sampleMembers == nil else { return }; Task { do { _ = try await CollaborationStore.shared.invite(kind: "health", sourceID: "", people: people, notebookID: notebookID) } catch { self.error = error.localizedDescription } } }, cancel: { inviting = false })
        }
    }
    private func load() async {
        if let sampleMembers { members = sampleMembers; return }
        #if DEBUG
        if let samples = CollaborationStore.shared.previewMembers(notebookID) { members = samples; return }
        #endif
        do { let result = try await WellnessAPI.call("collaborationMembers", ["notebookID": notebookID]); members = try JSONDecoder().decode([CollaborationMember].self, from: JSONSerialization.data(withJSONObject: result["people"] ?? [])); error = nil }
        catch { self.error = error.localizedDescription }
    }
}
@MainActor final class CollaborationStore: ObservableObject {
    static let shared = CollaborationStore()
    @Published private(set) var notebooks: [CollaborativeNotebook] = []
    private var auth: AuthStateDidChangeListenerHandle?
    private var timer: Timer?
    private var refreshing = false
    private var dismissedInvitations: [String: Double] = [:]
    init() {
        auth = Auth.auth().addStateDidChangeListener { [weak self] _, _ in Task { @MainActor in self?.notebooks = []; self?.dismissedInvitations = [:]; await self?.refresh() } }
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in Task { @MainActor in
            guard UIApplication.shared.applicationState == .active else { return }; await self?.refresh()
        } }
    }
    func refresh() async {
        #if DEBUG
        if Auth.auth().currentUser == nil, ProcessInfo.processInfo.environment["APPLAZ_WELLNESS_PREVIEW"] == "collaboration-home-preview" { return }
        #endif
        guard let uid = Auth.auth().currentUser?.uid else { notebooks = []; ApplazActivityInbox.shared.setCollaborationEvents([]); return }
        guard !refreshing else { return }; refreshing = true; defer { refreshing = false }
        do {
            let response = try await WellnessAPI.call("collaborationList", [:], expectedUID: uid)
            let decoded = try JSONDecoder().decode([CollaborativeNotebook].self, from: JSONSerialization.data(withJSONObject: response["notebooks"] ?? []))
            if uid == Auth.auth().currentUser?.uid {
                notebooks = decoded
                let events = (response["alerts"] as? [[String: Any]] ?? []).compactMap { value -> NotificationList? in
                    guard let type = value["type"] as? String, let actor = value["actorID"] as? String, let notebookID = value["notebookID"] as? String else { return nil }
                    guard type == "notebookInvite" || type == "notebookAccepted" else { return nil }
                    if type == "notebookInvite", let id = value["invitationID"] as? String, let dismissedAt = dismissedInvitations[id], (value["timestamp"] as? Double ?? 0) <= dismissedAt { return nil }
                    var event = NotificationList(photo: value["photo"] as? String, userID: actor, userName: value["userName"] as? String ?? "Someone", noteKey: "", noteTitle: value["notebookName"] as? String ?? "Notebook", notificationType: type == "notebookInvite" ? .notebookInvite : .notebookAccepted, timestamp: value["timestamp"] as? Double ?? 0)
                    event.recipientID = uid; event.eventID = value["eventID"] as? String ?? ""; event.collaborationNotebookID = notebookID; event.collaborationInvitationID = value["invitationID"] as? String
                    return event
                }
                ApplazActivityInbox.shared.setCollaborationEvents(events)
            }
        } catch { /* Retain the last visible list while offline. */ }
    }
    #if DEBUG
    private var sampleEditingLists: [String: [CollaborationMember]] = [:]
    func previewMembers(_ id: String) -> [CollaborationMember]? {
        guard Auth.auth().currentUser == nil, ProcessInfo.processInfo.environment["APPLAZ_WELLNESS_PREVIEW"] == "collaboration-home-preview" else { return nil }; return sampleEditingLists[id]
    }
    func loadPreview(_ values: [CollaborativeNotebook], members: [String: [CollaborationMember]]) {
        guard Auth.auth().currentUser == nil, ProcessInfo.processInfo.environment["APPLAZ_WELLNESS_PREVIEW"] == "collaboration-home-preview" else { return }
        notebooks = values; sampleEditingLists = members
    }
    #endif
    func match(kind: String, sourceID: String) -> CollaborativeNotebook? {
        #if DEBUG
        if Auth.auth().currentUser == nil, ProcessInfo.processInfo.environment["APPLAZ_WELLNESS_PREVIEW"] == "collaboration-home-preview" { return notebooks.first { $0.kind == kind && $0.sourceID == sourceID } }
        #endif
        return notebooks.first { $0.kind == kind && $0.sourceID == sourceID && $0.owner == Auth.auth().currentUser?.uid }
    }
    func hasEditors(kind: String, sourceID: String) -> Bool { (match(kind: kind, sourceID: sourceID)?.editorCount ?? 0) > 0 }
    func image(kind: String, sourceID: String) -> UIImage { hasEditors(kind: kind, sourceID: sourceID) ? (UIImage(systemName: "person.2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)) ?? NotebookIcons.invitation) : NotebookIcons.invitation }
    var sharedWithMe: [CollaborativeNotebook] { notebooks.filter { $0.role != "owner" } }
    func invite(kind: String, sourceID: String, people: [CollaborationPerson], notebookID: String? = nil) async throws -> String {
        var data: [String: Any] = ["kind": kind, "sourceID": sourceID, "recipients": people.map(\.id)]
        if let notebookID { data["notebookID"] = notebookID }
        if kind == "health", let notebook = WellnessStore.shared.notebooks.first(where: { $0.id == sourceID }) {
            data["notebook"] = try JSONSerialization.jsonObject(with: WellnessCodec.encoder.encode(notebook))
        }
        let response = try await WellnessAPI.call("collaborationInvite", data)
        await refresh()
        guard let id = response["notebookID"] as? String else { throw WellnessAPI.failure("The invitation couldn’t be sent. Please try again.") }
        return id
    }
    func respond(_ id: String, accept: Bool) async throws -> String? {
        let result = try await WellnessAPI.call("collaborationRespond", ["invitationID": id, "accept": accept])
        dismissedInvitations[id] = ApplazActivityInbox.shared.notifications.first { $0.collaborationInvitationID == id }?.timestamp ?? 0
        ApplazActivityInbox.shared.removeCollaborationEvent(id)
        await refresh(); return accept ? result["notebookID"] as? String : nil
    }
}
@MainActor enum CollaborationPresentation {
    static func open(_ id: String, from controller: UIViewController) {
        let host = WellnessHostingController(rootView: NavigationView { CollaborativeNotebookView(notebookID: id, close: { [weak controller] in controller?.navigationController?.popViewController(animated: true) }) }.navigationViewStyle(.stack).modifier(WellnessMenuModifier(controller: controller, enabled: controller.tabBarController == nil)))
        controller.navigationController?.pushViewController(host, animated: true)
    }
    static func choose(from controller: UIViewController, selected: [CollaborationPerson] = [], completion: @escaping ([CollaborationPerson]) -> Void) {
        guard Auth.auth().currentUser != nil else {
            let alert = UIAlertController(title: "Invite friends", message: "Sign in to invite friends to your notebook.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default)); controller.present(alert, animated: true); return
        }
        var host: UIViewController?
        let picker = CollaborationPeoplePicker(selected: selected, done: { people in let current = host; host = nil; current?.dismiss(animated: true) { completion(people) } }, cancel: { let current = host; host = nil; current?.dismiss(animated: true) })
        let view = WellnessHostingController(rootView: picker); host = view
        view.modalPresentationStyle = .pageSheet
        view.sheetPresentationController?.detents = [.medium(), .large()]
        controller.present(view, animated: true)
    }
    static func invite(kind: String, sourceID: String, notebookID: String? = nil, from controller: UIViewController) {
        if let shared = notebookID.flatMap({ id in CollaborationStore.shared.notebooks.first { $0.id == id } }) ?? CollaborationStore.shared.match(kind: kind, sourceID: sourceID), (shared.editorCount ?? 0) > 0 {
            let host = WellnessHostingController(rootView: CollaborationMembersView(notebookID: shared.id, notebookName: shared.name))
            host.modalPresentationStyle = .pageSheet
            host.sheetPresentationController?.detents = [.medium(), .large()]
            controller.present(host, animated: true)
            return
        }
        choose(from: controller) { [weak controller] people in
            guard !people.isEmpty else { return }
            Task { do {
                _ = try await CollaborationStore.shared.invite(kind: kind, sourceID: sourceID, people: people, notebookID: notebookID)
                guard let controller else { return }
                let alert = UIAlertController(title: "Invitations sent", message: "Your friends can join from their alerts.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default)); controller.present(alert, animated: true)
            } catch {
                guard let controller else { return }
                let alert = UIAlertController(title: "Couldn’t send invitations", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default)); controller.present(alert, animated: true)
            } }
        }
    }
}
struct CollaborationPeoplePicker: View {
    @State var selected: [CollaborationPerson] = []
    var done: ([CollaborationPerson]) -> Void
    var cancel: () -> Void
    var loadPeople: ((String) async throws -> [CollaborationPerson])? = nil
    @State private var query = ""
    @State private var people: [CollaborationPerson] = []
    @State private var loading = false
    @State private var error: String?
    var body: some View {
        ZStack { WellnessBackground(); VStack(spacing: 18) {
            HStack { Button("Cancel", action: cancel); Spacer(); Text("Invite friends").font(.system(size: 17, weight: .medium)); Spacer(); Button("Done") { done(selected) } }
            HStack { Image(systemName: "magnifyingglass"); TextField("Search usernames", text: $query).autocapitalization(.none).disableAutocorrection(true).accessibilityIdentifier("CollaboratorSearch") }.padding(13).background(Color.white.opacity(0.7)).clipShape(Capsule())
            if !selected.isEmpty { Text(selected.map { "@" + $0.name }.joined(separator: ", ")).font(.footnote).frame(maxWidth: .infinity, alignment: .leading) }
            ScrollView { VStack(spacing: 0) {
                if query.isEmpty { Text("People you follow").font(.system(size: 14)).foregroundColor(.black.opacity(0.6)).frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 10) }
                ForEach(people) { person in Button {
                    if selected.contains(where: { $0.id == person.id }) { selected.removeAll { $0.id == person.id } } else { selected.append(person) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle").font(.system(size: 27, weight: .light)).foregroundColor(.applazAccent)
                        Text("@" + person.name).font(.system(size: 16)); Spacer()
                        Image(systemName: selected.contains(where: { $0.id == person.id }) ? "checkmark.circle.fill" : "circle").foregroundColor(.applazAccent)
                    }.padding(.vertical, 13)
                }.buttonStyle(.plain); Divider().opacity(0.3) }
                if loading { ProgressView().padding() }
                if !loading && people.isEmpty { Text(query.isEmpty ? "Search a username to invite someone." : "No matching usernames.").font(.subheadline).foregroundColor(.black.opacity(0.6)).padding(.top, 18) }
                if let error { Text(error).font(.footnote) }
            }.padding(16).background(Color.white.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 18)) }
        }.padding(22) }.foregroundColor(.black).tint(.applazAccent)
            .task(id: query) {
                loading = true; error = nil
                do {
                    if !query.isEmpty { try await Task.sleep(nanoseconds: 250_000_000) }
                    let found: [CollaborationPerson]
                    if let loadPeople { found = try await loadPeople(query) }
                    else {
                        let result = try await WellnessAPI.call("collaborationDirectory", ["query": query])
                        found = try JSONDecoder().decode([CollaborationPerson].self, from: JSONSerialization.data(withJSONObject: result["people"] ?? []))
                    }
                    guard !Task.isCancelled else { return }
                    people = found
                } catch { if !Task.isCancelled { self.error = error.localizedDescription } }
                if !Task.isCancelled { loading = false }
            }
    }
}
struct CollaborativeNotebookView: View {
    var notebookID: String
    var close: (() -> Void)? = nil
    @ObservedObject private var collaboration = CollaborationStore.shared
    @State private var notebook: WellnessNotebook?
    @State private var role = "editor"
    @State private var error: String?
    @State private var inviting = false
    @State private var deleting = false
    @State private var gone = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack { WellnessBackground(); ScrollView { VStack(spacing: 16) {
            if let notebook {
                ForEach(notebook.notes) { note in NavigationLink(destination: CollaborativeNoteEditor(notebookID: notebookID, original: note)) {
                    HStack(spacing: 12) {
                        Image(systemName: note.isChecklist ? "checklist" : "doc.text").font(.system(size: 23, weight: .light)).foregroundColor(.applazAccent)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(note.title).font(.system(size: 17, weight: .medium))
                            Text(String(note.body.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression).prefix(90))).font(.system(size: 13)).foregroundColor(.black.opacity(0.6))
                        }; Spacer(); Image(systemName: "chevron.right").font(.system(size: 13))
                    }.frame(maxWidth: .infinity, alignment: .leading).wellnessCard()
                }.buttonStyle(.plain) }
                NavigationLink(destination: CollaborativeNoteEditor(notebookID: notebookID, original: WellnessTextNote(title: "", body: ""), isNew: true)) { Label("Add note", systemImage: "plus").frame(maxWidth: .infinity).wellnessPill() }
                if notebook.notes.isEmpty { Text("A little space to build something together.").font(.subheadline).foregroundColor(.black.opacity(0.6)).padding() }
            } else if !gone { ProgressView().padding(40) }
            if let error { Text(error).font(.footnote) }
        }.padding(20) }}.foregroundColor(.black).tint(.applazAccent)
            .navigationTitle(notebook?.name ?? "").navigationBarTitleDisplayMode(.inline).navigationBarHidden(false)
            .toolbar {
                if let close { ToolbarItem(placement: .navigationBarLeading) { Button(action: close) { Image(systemName: "chevron.left") }.accessibilityLabel("Back") } }
                ToolbarItem(placement: .navigationBarTrailing) { Button { inviting = true } label: { Image(systemName: "person.2") }.accessibilityLabel("Invite friends") }
                if role == "owner" { ToolbarItem(placement: .navigationBarTrailing) { Menu { Button("Delete notebook", role: .destructive) { deleting = true } } label: { Image(systemName: "ellipsis") } } }
            }
            .sheet(isPresented: $inviting) { CollaborationMembersView(notebookID: notebookID, notebookName: notebook?.name ?? "Notebook") }
            .alert("Delete notebook?", isPresented: $deleting) { Button("Delete", role: .destructive) { Task { do { _ = try await WellnessAPI.call("collaborationDelete", ["notebookID": notebookID]); await collaboration.refresh(); await WellnessStore.shared.sync(); if let close { close() } else { dismiss() } } catch { self.error = error.localizedDescription } } }; Button("Cancel", role: .cancel) {} }
            .task {
                repeat { await load(); do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return } } while !Task.isCancelled
            }
    }
    private func load() async {
        do { let result = try await WellnessAPI.call("collaborationRead", ["notebookID": notebookID]); guard !Task.isCancelled else { return }; notebook = try WellnessCodec.decoder.decode(WellnessNotebook.self, from: JSONSerialization.data(withJSONObject: result["notebook"] ?? [:])); role = result["role"] as? String ?? "editor"; error = nil }
        catch { if !Task.isCancelled { self.error = error.localizedDescription; if notebook == nil { gone = true } } }
    }
}
struct CollaborativeNoteEditor: View {
    var notebookID: String
    var original: WellnessTextNote
    var isNew = false
    @State private var note: WellnessTextNote
    @State private var base: Date?
    @State private var dirty = false
    @State private var saving = false
    @State private var error: String?
    @State private var photoPicker = false
    @State private var lastSavedData: Data?
    @State private var recoveredDraft: WellnessTextNote?
    @State private var draftSaved = false
    init(notebookID: String, original: WellnessTextNote, isNew: Bool = false) {
        self.notebookID = notebookID; self.original = original; self.isNew = isNew
        _note = State(initialValue: original); _base = State(initialValue: isNew ? nil : original.updatedAt)
    }
    private var encoded: Data { (try? WellnessCodec.encoder.encode(note)) ?? Data() }
    private var draftURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("CollaborationDrafts", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let uid = Auth.auth().currentUser?.uid ?? "guest"
        return dir.appendingPathComponent(Data((uid + notebookID + note.id).utf8).base64EncodedString().replacingOccurrences(of: "/", with: "_") + ".json")
    }
    var body: some View {
        ZStack { WellnessBackground(); ScrollView { VStack(alignment: .leading, spacing: 16) {
            if let draft = recoveredDraft {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You have a saved draft on this device.").font(.subheadline)
                    Button("Open my draft") { note = draft; dirty = true; recoveredDraft = nil }
                }.wellnessCard()
            }
            TextField("Note title", text: $note.title).font(.system(size: 18, weight: .medium)).padding(14).background(Color.white.opacity(0.7)).cornerRadius(14)
            Picker("Layout", selection: $note.isChecklist) { Text("Text").tag(false); Text("Checklist").tag(true) }.pickerStyle(.segmented)
            if note.isChecklist { VStack(spacing: 12) {
                ForEach($note.items) { $item in HStack {
                    Button { let day = item.key(on: Date()); if !item.checkedDates.insert(day).inserted { item.checkedDates.remove(day) } } label: { Image(systemName: item.checked(on: Date()) ? "checkmark.square.fill" : "square").font(.system(size: 23)) }
                    VStack { TextField("Item", text: $item.title); TextField("Details", text: $item.detail).font(.caption) }
                }; Divider().opacity(0.4) }
                Button { note.items.append(HabitItem(title: "")) } label: { Label("Add item", systemImage: "plus") }
            }.wellnessCard() }
            WellnessRichEditor(html: Binding(get: { note.richHTML ?? note.body }, set: { value in note.richHTML = value; note.body = value.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression) })).frame(height: 260).cornerRadius(14)
            ScrollView(.horizontal) { HStack { ForEach(Array((note.attachments ?? []).enumerated()), id: \.offset) { index, photo in
                if let data = Data(base64Encoded: photo), let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill().frame(width: 110, height: 110).clipped().cornerRadius(12).contextMenu { Button("Remove photo", role: .destructive) { note.attachments?.remove(at: index) } } }
            } } }
            Button { photoPicker = true } label: { Label("Add photo", systemImage: "photo") }
            if saving { Text("Saving…").font(.caption) }
            if let error { Text(error).font(.footnote) }
            InlineAIChat(scope: .note(note.title + "\n" + note.body, key: "collaboration-note:" + notebookID + ":" + note.id), title: "Ask about this note", compact: true)
        }.padding(20) }}.foregroundColor(.black).tint(.applazAccent).navigationTitle("Add Note").navigationBarTitleDisplayMode(.inline).navigationBarHidden(false)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { Task { await save() } } label: { Image(systemName: "square.and.arrow.down") }.accessibilityLabel("Save note").disabled(saving) } }
            .sheet(isPresented: $photoPicker) { MealPhotoPicker { image in if let data = ApplazImagePayload.jpeg(from: image) { if note.attachments == nil { note.attachments = [] }; note.attachments?.append(data.base64EncodedString()) } } }
            .onChange(of: encoded) { value in guard value != lastSavedData else { return }; dirty = true; do { try value.write(to: draftURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]); draftSaved = true } catch { draftSaved = false; self.error = "Your draft couldn’t be saved on this device." } }
            .task { if let data = try? Data(contentsOf: draftURL), let draft = try? WellnessCodec.decoder.decode(WellnessTextNote.self, from: data) { draftSaved = true; if draft.updatedAt >= original.updatedAt { note = draft; dirty = true } else { recoveredDraft = draft } }; while !Task.isCancelled { do { try await Task.sleep(nanoseconds: 15_000_000_000) } catch { return }; if dirty { await save() } } }
            .onDisappear { if dirty { Task { await save() } } }
    }
    private func save() async {
        guard !saving else { return }
        guard !note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { error = "Give your note a title before saving."; return }
        guard dirty || isNew else { return }
        saving = true; defer { saving = false }
        let submitted = note
        do {
            var data: [String: Any] = ["notebookID": notebookID, "note": try JSONSerialization.jsonObject(with: WellnessCodec.encoder.encode(submitted))]
            if let base { data["baseUpdatedAt"] = base.timeIntervalSince1970 * 1000 }
            let result = try await WellnessAPI.call("collaborationEdit", data)
            let notebook = try WellnessCodec.decoder.decode(WellnessNotebook.self, from: JSONSerialization.data(withJSONObject: result["notebook"] ?? [:]))
            if let saved = notebook.notes.first(where: { $0.id == submitted.id }) {
                base = saved.updatedAt
                if result["photoStorageFull"] as? Bool == true {
                    note.updatedAt = saved.updatedAt
                    CloudSaveWarning.report(WellnessAPI.failure("Photo storage is full."), key: "collaboration-photos:" + notebookID, savedLocally: true)
                } else if (try? WellnessCodec.encoder.encode(note)) == (try? WellnessCodec.encoder.encode(submitted)) { lastSavedData = try? WellnessCodec.encoder.encode(saved); note = saved; dirty = false; try? FileManager.default.removeItem(at: draftURL) }
            }
            if result["photoStorageFull"] as? Bool != true { CloudSaveWarning.recovered("collaboration-photos:" + notebookID) }
            error = nil
        } catch { self.error = error.localizedDescription + (draftSaved ? " Your draft is saved on this device." : "") }
    }
}
