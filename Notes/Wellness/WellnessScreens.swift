import SwiftUI
import UIKit
import FirebaseAuth

struct AIThinkingOrb: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [.white.opacity(0.9), .purple.opacity(0.18), .applazAccent.opacity(0.20)], center: .topLeading, startRadius: 2, endRadius: 40))
                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                .overlay(Ellipse().fill(Color.white.opacity(0.8)).frame(width: 24, height: 10).blur(radius: 3).offset(x: -10, y: -17))
                .shadow(color: .purple.opacity(0.15), radius: breathe ? 18 : 8)
                .scaleEffect(breathe ? 1.06 : 0.92)
            Image(systemName: "sparkles").font(.system(size: 25, weight: .light)).foregroundColor(.applazAccent.opacity(0.8))
        }.frame(width: 68, height: 68).accessibilityLabel("AI is thinking")
            .onAppear { if !reduceMotion { withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { breathe = true } } }
    }
}
struct SubscriptionWelcomeView: View {
    @ObservedObject private var subscription = SubscriptionCenter.shared
    var onClose: () -> Void
    var onPurchased: () -> Void
    var body: some View {
        ZStack { WellnessBackground()
            ScrollView { VStack(alignment: .leading, spacing: 22) {
                Button(action: onClose) { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Continue without subscribing")
                Image(systemName: "sparkles").font(.system(size: 38, weight: .light)).foregroundColor(.applazAccent)
                Text("Applaz").font(.system(size: 30, weight: .semibold))
                Text("Goals Delivered").font(.system(size: 26, weight: .medium))
                Text("Reach your goals").font(.title3)
                VStack(alignment: .leading, spacing: 18) {
                    Label("Routines & checklists that fit your day", systemImage: "checklist")
                    Label("Ask your notebooks. Find your patterns.", systemImage: "sparkles")
                    Label("Meal estimates from words or a photo", systemImage: "camera")
                }.wellnessCard()
                Text(subscription.eligibleTrial ? "1 week free, then \(subscription.price)/week" : "\(subscription.price)/week").font(.system(size: 20, weight: .semibold))
                Text("Applaz Plus · Weekly AI credits for chat, insights and meal estimates.").font(.subheadline)
                Button { Task { if await subscription.purchase() {
                    onPurchased()
                    if Auth.auth().currentUser == nil { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { WellnessPresentation.signInAfterPurchase() } }
                } } } label: {
                    Text(subscription.busy ? "Connecting to Apple…" : (subscription.eligibleTrial ? "Start free trial" : "Continue"))
                        .font(.headline).frame(maxWidth: .infinity).padding(17).background(Color.applazAccent).foregroundColor(.white).clipShape(Capsule())
                }.disabled(subscription.busy || subscription.product == nil || !subscription.serviceReady)
                if let message = subscription.message { Text(message).font(.footnote) }
                if !subscription.serviceReady { Text("Subscriptions will be available soon. You can keep using your notebooks for free.").font(.footnote) }
                Text(subscription.eligibleTrial ? "No charge today. Your subscription renews at \(subscription.price)/week after the free week unless canceled at least 24 hours before it ends. Manage or cancel in Apple Account settings." : "Renews automatically at \(subscription.price)/week unless canceled at least 24 hours before the current period ends. Manage or cancel in Apple Account settings.").font(.caption).foregroundColor(.black.opacity(0.65))
                HStack { Button("Restore purchases") { Task {
                    await subscription.restore()
                    if subscription.hasAppleSubscription {
                        onPurchased()
                        if Auth.auth().currentUser == nil { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { WellnessPresentation.signInAfterPurchase() } }
                    }
                } }; Spacer(); Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) }
                    .font(.footnote)
                NavigationLink("Privacy & AI", destination: AIPrivacyView())
            }.padding(24) }.foregroundColor(.black).tint(.applazAccent)
        }.task { await subscription.loadProduct() }
    }
}
struct AIPrivacyView: View {
    @ObservedObject private var subscription = SubscriptionCenter.shared
    @State private var error: String?
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            Text("Your notebooks, your choice").font(.title3)
            Text("Account and social features use Firebase to save your account, profile pictures, messages and notes. Notes you mark public can be seen by other people; private health notebooks are not posted to Newsfeed.")
            Text("When you ask AI, Applaz sends your question and the selected notebook, note or routine history to OpenAI to generate an answer. Meal estimates also send the food description or photo you choose. Photos are compressed before processing. Your health notebooks are private and are not posted to Newsfeed.")
            Text("AI can make mistakes. Meal calories are estimates: review portions and calories before saving. Insights support reflection, not medical advice. Do not include information you do not want processed.")
            Text("Private notebook data, saved AI conversations and charts are kept on this device and, when signed in and cloud service is available, in your Firebase account. You can delete conversations in Your chats. Guest work stays on this device. Revoking consent prevents new AI requests; it does not erase saved notebooks.")
            Text("Ask my notebooks uses relevant excerpts from your own regular and health notebooks. Asking about one selected note does not include unrelated private notebooks or meal logs.")
            Toggle("Allow selected content to be sent to OpenAI", isOn: Binding(get: { subscription.aiConsent }, set: { allowed in Task { do { try await subscription.consent(allowed) } catch { self.error = error.localizedDescription } } }))
            if let error { Text(error).font(.footnote) }
            Link("OpenAI privacy policy", destination: URL(string: "https://openai.com/policies/privacy-policy/")!)
        }.padding(24) }.foregroundColor(.black).navigationTitle("AI privacy").navigationBarHidden(false)
    }
}
struct SubscriptionSettingsView: View {
    @ObservedObject private var subscription = SubscriptionCenter.shared
    @State private var showPaywall = false
    var close: () -> Void
    var body: some View {
        ZStack { WellnessBackground(); VStack {
            WellnessNavigationBar(title: "Applaz Plus", back: close)
            ScrollView { VStack(alignment: .leading, spacing: 20) {
                Text(subscription.hasAppleSubscription ? "Your Plus membership" : "Reach your goals with Plus").font(.title3)
                Text("\(subscription.credits) of \(subscription.capacity) AI credits remaining")
                if let end = subscription.periodEnd { Text("Current period ends \(end.formatted(date: .abbreviated, time: .omitted))").font(.footnote) }
                Text("Chat, typed meals and insights use 1 credit. Photo meal estimates use 2. Credits renew with a verified billing period and do not roll over.").font(.subheadline)
                Button(subscription.hasAppleSubscription ? "Manage subscription" : "Explore Plus") { if subscription.hasAppleSubscription { Task { await subscription.manage() } } else { showPaywall = true } }
                Button("Restore purchases") { Task { await subscription.restore() } }
                NavigationLink("AI privacy", destination: AIPrivacyView())
                if let message = subscription.message { Text(message).font(.footnote) }
            }.padding(24).wellnessCard().padding() }
        }}.foregroundColor(.black).tint(.applazAccent).sheet(isPresented: $showPaywall) { NavigationView { SubscriptionWelcomeView(onClose: { showPaywall = false }, onPurchased: { showPaywall = false }) } }
    }
}
struct WellnessLibraryView: View {
    @ObservedObject private var store = WellnessStore.shared
    @State private var importGuest = false
    @State private var create = false
    @State private var chat = false
    var close: () -> Void
    var body: some View {
        NavigationView { ZStack { WellnessBackground(); VStack(spacing: 0) {
            WellnessNavigationBar(title: "Notebooks", back: close, add: { create = true })
            ScrollView { VStack(alignment: .leading, spacing: 16) {
                HStack { Text("Your notebooks").font(.headline); Spacer(); Button { chat = true } label: { Image(systemName: "clock.arrow.circlepath") }.accessibilityLabel("Saved chats") }
                ForEach(store.notebooks) { notebook in NavigationLink(destination: WellnessNotebookView(notebookID: notebook.id)) {
                    HStack { Image(systemName: notebook.kind == "text" ? "book.closed" : "checklist").foregroundColor(.applazAccent); VStack(alignment: .leading, spacing: 4) { Text(notebook.name).font(.headline); Text("\(notebook.isPrivate == false ? "Public" : "Private") · \(notebook.notes.count) \(notebook.notes.count == 1 ? "note" : "notes")").font(.caption).foregroundColor(.black.opacity(0.55)) }; Spacer(); Image(systemName: "chevron.right").font(.caption) }.wellnessCard()
                }.buttonStyle(.plain) }
                if store.hasGuestWork { Button("Copy my guest work into this account") { importGuest = true }.font(.footnote) }
                InlineAIChat(scope: .all, title: "Ask my notebooks", compact: true, overview: true)
                NavigationLink("Consistency & insights", destination: WellnessInsightsView())
                NavigationLink("My food diary", destination: MealDiaryView())
                if let message = store.syncMessage { Text(message).font(.caption).foregroundColor(.black.opacity(0.55)) }
            }.padding(20) }
        }}.foregroundColor(.black).tint(.applazAccent).navigationBarHidden(true) }
        .navigationViewStyle(.stack).confirmationDialog("Copy guest notebooks and meals from this device into your signed-in account?", isPresented: $importGuest, titleVisibility: .visible) { Button("Copy my guest work") { store.importGuestWork() } }.sheet(isPresented: $create) { CreateWellnessNotebookView().modifier(WellnessHalfSheet()) }.sheet(isPresented: $chat) { NavigationView { SavedAIChatsView() } }
    }
}
struct CreateWellnessNotebookView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    func makeUIViewController(context: Context) -> NewNotebookViewController {
        let controller = NewNotebookViewController()
        controller.onCreate = { name, isPrivate in
            let id = WellnessStore.shared.create(.blank, name: name)
            if var notebook = WellnessStore.shared.notebooks.first(where: { $0.id == id }) {
                notebook.isPrivate = isPrivate
                WellnessStore.shared.update(notebook)
            }
        }
        controller.onFinish = { dismiss() }
        return controller
    }
    func updateUIViewController(_ controller: NewNotebookViewController, context: Context) {}
}
struct WellnessNotebookView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var deleting = false
    @State private var deletingNote: String?
    @State private var changingPrivacy = false
    @ObservedObject private var store = WellnessStore.shared
    var notebookID: String
    var close: (() -> Void)? = nil
    @State private var chat = false
    @State private var newNote = false
    private var notebook: WellnessNotebook? { store.notebooks.first { $0.id == notebookID } }
    var body: some View {
        ZStack { WellnessBackground(); ScrollView { VStack(alignment: .leading, spacing: 16) {
            if let notebook {
                HStack { Label(notebook.isPrivate == false ? "Public" : "Private", systemImage: notebook.isPrivate == false ? "globe" : "lock").font(.caption); Spacer(); Menu {
                    if notebook.id != "start-here-v1" { Button(notebook.isPrivate == false ? "Make private" : "Make public") { changingPrivacy = true } }
                    Button("Delete notebook", role: .destructive) { deleting = true }
                } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) } }
                if notebook.goal != nil {
                    GoalSummaryCard(notebookID: notebookID)
                    GoalMilestonesView(notebookID: notebookID)
                    GoalWeeklyCheckin(notebookID: notebookID)
                }
                if notebook.kind == "food" { MealDiarySummary() }
                Text("\(notebook.notes.count) \(notebook.notes.count == 1 ? "note" : "notes")").font(.subheadline).foregroundColor(.black.opacity(0.6))
                ForEach(notebook.notes) { note in NavigationLink(destination: WellnessNoteEditor(notebookID: notebookID, noteID: note.id)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack { Image(systemName: note.isChecklist ? "checklist" : "doc.text").font(.system(size: 23, weight: .light)).foregroundColor(.applazAccent).frame(width: 28); Text(note.title).font(.system(size: 16, weight: .medium)); Spacer(); Menu { Button("Delete note", role: .destructive) { deletingNote = note.id } } label: { Image(systemName: "ellipsis").frame(width: 36, height: 30) }.buttonStyle(.borderless).accessibilityLabel("More note options") }
                        if note.isChecklist {
                            let done = note.items.filter { $0.checked(on: Date()) }.count
                            Text("\(note.recurrence == "weekly" ? "This week" : note.recurrence == "once" ? "Milestones" : "Today") · \(done) of \(note.items.count) checked off").font(.caption)
                            WellnessProgress(done: done, total: note.items.count)
                        } else { Text(String(note.body.prefix(85))).font(.caption).foregroundColor(.black.opacity(0.55)) }
                    }.wellnessCard()
                }.buttonStyle(.plain) }
                HStack {
                    NavigationLink(destination: PeriodInsightsView(notebookID: notebookID, initialPeriod: "daily")) { Label("Daily check-in", systemImage: "sparkle").wellnessPill() }
                    NavigationLink(destination: PeriodInsightsView(notebookID: notebookID, initialPeriod: "weekly")) { Label("Weekly check-in", systemImage: "sparkle").wellnessPill() }
                }.font(.system(size: 14)).foregroundColor(.applazAccent)
                InlineAIChat(scope: .wellness(notebookID, title: notebook.name), title: "Ask this notebook", compact: true)
                if notebook.kind == "food" { NavigationLink("Meals & daily tally", destination: MealDiaryView()) }
                NavigationLink("Find my patterns", destination: WellnessInsightsView())
            }
        }.padding(20) }}.foregroundColor(.black).tint(.applazAccent).navigationTitle(notebook?.name ?? "").navigationBarTitleDisplayMode(.inline).navigationBarHidden(false)
            .toolbar {
                if let close { ToolbarItem(placement: .navigationBarLeading) { Button(action: close) { Image(systemName: "chevron.left") }.accessibilityLabel("Back") } }
                ToolbarItem(placement: .navigationBarTrailing) { Button { newNote = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add note") }
            }
            .sheet(isPresented: $chat) { AIChatView(context: store.context(notebookID: notebookID)) }
            .confirmationDialog("Change notebook visibility?", isPresented: $changingPrivacy, titleVisibility: .visible) {
                Button(notebook?.isPrivate == false ? "Make private" : "Make public") { guard let n = notebook else { return }; store.setVisibility(n.id, isPrivate: n.isPrivate == false) }
            } message: { Text("Public notes can appear in Newsfeed. Meal logs, dated reflections and AI chats stay private.") }
            .confirmationDialog("Delete note?", isPresented: Binding(get: { deletingNote != nil }, set: { if !$0 { deletingNote = nil } }), titleVisibility: .visible) {
                Button("Delete note", role: .destructive) { guard var n = notebook else { return }; n.notes.removeAll { $0.id == deletingNote }; store.update(n); deletingNote = nil }
            }
            .confirmationDialog("Delete this notebook?", isPresented: $deleting, titleVisibility: .visible) {
                Button("Delete notebook", role: .destructive) { store.deleteNotebook(notebookID); if let close { close() } else { dismiss() } }
            }
            .confirmationDialog("Add note", isPresented: $newNote, titleVisibility: .visible) {
                Button("Text note") { addNote(false) }; Button("Checklist") { addNote(true) }
            }
    }
    private func addNote(_ checklist: Bool) { guard var n = notebook else { return }; n.notes.append(WellnessTextNote(title: checklist ? "New checklist" : "New note", body: "", isChecklist: checklist)); store.update(n) }
}
struct WellnessNoteEditor: View {
    @ObservedObject private var store = WellnessStore.shared
    var notebookID: String
    var noteID: String
    @State private var title = ""
    @State private var text = ""
    @State private var task = ""
    @State private var date = Date()
    @State private var chat = false
    @State private var loaded = false
    @State private var editingItem: HabitItem?
    @State private var editingDetails = false
    private var note: WellnessTextNote? { store.notebooks.first { $0.id == notebookID }?.notes.first { $0.id == noteID } }
    var body: some View {
        ZStack { WellnessBackground(); ScrollView { VStack(alignment: .leading, spacing: 16) {
            if note?.workoutDays == nil {
            if let notebook = store.notebooks.first(where: { $0.id == notebookID }) {
                HStack { Text(notebook.name).font(.system(size: 16)); Spacer(); Image(systemName: "book.closed").font(.system(size: 18)).foregroundColor(.applazAccent) }.wellnessField()
            }
            TextField("Title", text: $title).font(.system(size: 17, weight: .medium)).wellnessField().onChange(of: title) { _ in save() }
            HStack(spacing: 12) {
                Picker("Layout", selection: Binding(get: { note?.isChecklist == true }, set: { value in mutate { $0.isChecklist = value } })) { Text("Text").tag(false); Text("Checklist").tag(true) }.pickerStyle(.segmented).frame(maxWidth: 220).accessibilityIdentifier("NoteLayout")
                if note?.isChecklist == true, let recurrence = note?.recurrence {
                    Spacer(minLength: 0)
                    Text(note?.workoutDays != nil ? "Workout template" : recurrence == "once" ? "Goal template" : recurrence == "weekly" ? "Weekly template" : "Routine template").font(.system(size: 12)).lineLimit(1).padding(.horizontal, 10).padding(.vertical, 7).background(Color.white.opacity(0.6)).clipShape(Capsule()).overlay(Capsule().stroke(Color.applazAccent.opacity(0.15)))
                }
            }
            }
            if note?.workoutDays != nil { WorkoutWeekStrip(date: $date, scheduled: note?.workoutDays ?? []) }
            if note?.isChecklist != true && note?.recurrence == "weekly" { DatePicker("Week", selection: $date, displayedComponents: .date) }
            if let note, note.isChecklist {
                if note.workoutDays == nil {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Text(note.recurrence == "weekly" ? "This week" : note.recurrence == "once" ? "Milestones" : "Today").font(.system(size: 18, weight: .semibold)); Spacer(); repeatMenu }
                        checklistProgress(note)
                    }.wellnessCard()
                }
                VStack(alignment: .leading, spacing: 0) {
                    if note.workoutDays != nil { HStack { checklistProgress(note); Spacer(minLength: 12); repeatMenu }.padding(.bottom, 14) }
                    ForEach(note.items) { item in
                        Button {
                            mutate { n in guard let i = n.items.firstIndex(where: { $0.id == item.id }) else { return }; let key = n.items[i].key(on: date); if !n.items[i].checkedDates.insert(key).inserted { n.items[i].checkedDates.remove(key) } }
                        } label: {
                            HStack(alignment: .center, spacing: 16) {
                                WellnessCheckbox(checked: item.checked(on: date))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title).font(.system(size: 16)).fixedSize(horizontal: false, vertical: true).foregroundColor(item.checked(on: date) && note.workoutDays == nil ? .black.opacity(0.5) : .black)
                                    if !item.detail.isEmpty { Text(item.detail).font(.system(size: 13)).fixedSize(horizontal: false, vertical: true).foregroundColor(.black.opacity(0.6)) }
                                }
                                Spacer(minLength: 0)
                            }.frame(minHeight: 44).padding(.vertical, 3).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityValue(item.checked(on: date) ? "Completed" : "Not checked").contextMenu {
                            Button("Edit goal") { editingItem = item }
                            Button("Remove goal", role: .destructive) { mutate { $0.items.removeAll { $0.id == item.id } } }
                        }
                        Rectangle().fill(Color.applazAccent.opacity(0.10)).frame(height: 1).padding(.leading, 42)
                    }
                    HStack(spacing: 16) {
                        Button(action: addChecklistItem) { Image(systemName: "plus").font(.system(size: 23, weight: .light)).frame(width: 26, height: 44) }.accessibilityLabel(note.workoutDays != nil ? "Add exercise" : "Add item")
                        TextField(note.workoutDays != nil ? "Add exercise" : "Add item", text: $task).font(.system(size: 16)).onSubmit(addChecklistItem)
                    }.padding(.top, 5)
                }.wellnessCard()
            }
            VStack(alignment: .leading, spacing: 12) {
                Text(note?.workoutDays != nil ? "Session notes" : note?.recurrence == "weekly" ? "What moved forward?" : "Notes for today").font(.system(size: 17, weight: .medium))
                if note?.isChecklist == true || note?.recurrence == "weekly" {
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty { Text(note?.workoutDays != nil ? "How did it feel? What will I adjust next time?" : "Write a few thoughts…").font(.system(size: 15)).foregroundColor(.black.opacity(0.4)).padding(.horizontal, 5).padding(.top, 8).allowsHitTesting(false) }
                        reflectionEditor
                    }.frame(height: 94)
                } else {
                    WellnessRichEditor(html: Binding(get: { note?.richHTML ?? note?.body ?? "" }, set: { value in mutate { $0.richHTML = value; $0.body = value.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression) } })).frame(height: 260).cornerRadius(14)
                }
            }.wellnessCard()
            WellnessNotePhotos(notebookID: notebookID, noteID: noteID)
            if note?.recurrence == "weekly" {
                TextField("My next small step", text: Binding(get: { note?.nextSteps?[WellnessDate.week(date)] ?? "" }, set: { value in mutate { var steps = $0.nextSteps ?? [:]; steps[WellnessDate.week(date)] = value; $0.nextSteps = steps } })).padding(12).background(Color.white.opacity(0.6)).cornerRadius(12)
            }
            InlineAIChat(scope: .healthNote(notebookID: notebookID, noteID: noteID, title: title, context: "\(title)\n\(note?.isChecklist == true ? text : note?.body ?? text)"), title: "Ask about this note", compact: true)
            Text("Saved automatically on this device").font(.caption).foregroundColor(.black.opacity(0.5))
        }.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 32) }}.foregroundColor(.black).tint(.applazAccent).navigationTitle(note?.workoutDays != nil ? title : "Add Note").navigationBarTitleDisplayMode(.inline).navigationBarHidden(false)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if note?.isChecklist == true { Button { editingDetails = true } label: { Image(systemName: "slider.horizontal.3") }.accessibilityLabel("Note options") }
                    Button { save() } label: { Image(systemName: "square.and.arrow.down") }.accessibilityLabel("Save note")
                }
            } }
            .onAppear { guard !loaded else { return }; title = note?.title ?? ""; loadReflection(); loaded = true }
            .onChange(of: date) { _ in loadReflection() }
            .sheet(isPresented: $chat) { AIChatView(context: "\(title)\n\(text)\n" + (note?.items.map { "\($0.title): \($0.checked(on: date) ? "complete" : "not checked")" }.joined(separator: "\n") ?? "")) }
            .sheet(isPresented: $editingDetails) {
                NavigationView { Form {
                    TextField("Title", text: $title).onChange(of: title) { _ in save() }
                    Picker("Layout", selection: Binding(get: { note?.isChecklist == true }, set: { value in mutate { $0.isChecklist = value } })) { Text("Text").tag(false); Text("Checklist").tag(true) }.pickerStyle(.segmented)
                    DatePicker("Review date", selection: $date, displayedComponents: .date)
                    repeatMenu
                }.navigationTitle("Note options").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { editingDetails = false } } }.tint(.applazAccent) }
            }
            .sheet(item: $editingItem) { item in HabitEditView(item: item) { updated in mutate { note in if let i = note.items.firstIndex(where: { $0.id == updated.id }) { note.items[i] = updated } } } }
    }
    private var repeatMenu: some View {
        Menu {
                        Button("Show workout day tabs") { mutate { $0.workoutDays = [2, 4, 6] } }
                        if note?.workoutDays != nil {
                            ForEach(1...7, id: \.self) { day in
                                Toggle(Calendar.current.weekdaySymbols[day - 1], isOn: Binding(get: { self.note?.workoutDays?.contains(day) == true }, set: { chosen in mutate { n in var days = n.workoutDays ?? []; if chosen && !days.contains(day) { days.append(day) }; if !chosen { days.removeAll { $0 == day } }; n.workoutDays = days.sorted() } }))
                            }
                        }
                        Button("Daily") { setRecurrence("daily") }; Button("Weekly") { setRecurrence("weekly") }; Button("Milestones · no reset") { setRecurrence("once") }
                    } label: { Label(note?.recurrence == "weekly" ? "Weekly" : note?.recurrence == "once" ? "Milestones" : "Daily", systemImage: "arrow.clockwise").font(.system(size: 14)).padding(.horizontal, 12).padding(.vertical, 8).background(Color.white.opacity(0.7)).clipShape(Capsule()).overlay(Capsule().stroke(Color.applazAccent.opacity(0.16))) }
    }
    private func checklistProgress(_ note: WellnessTextNote) -> some View {
        let done = note.items.filter { $0.checked(on: date) }.count
        return VStack(alignment: .leading, spacing: 12) {
            Text("\(done) of \(note.items.count) complete").font(.system(size: 15))
            WellnessProgress(done: done, total: note.items.count)
        }
    }
    @ViewBuilder private var reflectionEditor: some View {
        if #available(iOS 16.0, *) {
            TextEditor(text: $text).scrollContentBackground(.hidden).font(.system(size: 16)).onChange(of: text) { _ in save() }
        } else { TextEditor(text: $text).font(.system(size: 16)).onChange(of: text) { _ in save() } }
    }
    private func addChecklistItem() {
        let value = task.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        mutate { $0.items.append(HabitItem(title: value, recurrence: $0.recurrence == "once" ? "once" : nil, isWeekly: $0.recurrence == "weekly")) }
        task = ""
    }
    private func mutate(_ edit: (inout WellnessTextNote) -> Void) { guard var n = store.notebooks.first(where: { $0.id == notebookID }), let i = n.notes.firstIndex(where: { $0.id == noteID }) else { return }; edit(&n.notes[i]); n.notes[i].updatedAt = Date(); store.update(n) }
    private func loadReflection() {
        let key = note?.recurrence == "weekly" ? WellnessDate.week(date) : WellnessDate.day(date)
        text = note?.datedReflections?[key] ?? (note?.isChecklist == true && note?.datedReflections != nil ? "" : note?.body ?? "")
    }
    private func setRecurrence(_ value: String) { mutate { n in n.recurrence = value; for i in n.items.indices { n.items[i].isWeekly = value == "weekly"; n.items[i].recurrence = value == "once" ? "once" : nil } } }
    private func save() {
        guard loaded else { return }
        mutate { n in
            n.title = title
            if n.isChecklist || n.recurrence == "weekly" {
                let key = n.recurrence == "weekly" ? WellnessDate.week(date) : WellnessDate.day(date)
                var entries = n.datedReflections ?? [:]; entries[key] = text; n.datedReflections = entries
            } else { n.body = text }
        }
    }
}
struct AIChatView: View {
    @Environment(\.dismiss) private var dismiss
    var context: String
    var openingQuestion: String? = nil
    var scope: AIScope? = nil
    var body: some View {
        NavigationView { ZStack { WellnessBackground(); ScrollView {
            InlineAIChat(scope: scope ?? .note(context), openingQuestion: openingQuestion).padding(20)
        }}.navigationTitle("Ask Applaz").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done") { dismiss() } } } }.navigationViewStyle(.stack)
    }
}
struct WellnessInsightsView: View {
    var body: some View { PeriodInsightsView() }
}
struct HabitEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State var item: HabitItem
    var save: (HabitItem) -> Void
    var body: some View {
        NavigationView { Form {
            TextField("Goal", text: $item.title)
            TextField("Details, sets or reps", text: $item.detail)
            Toggle("Weekly goal", isOn: $item.isWeekly)
            Button("Save goal") { guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }; save(item); dismiss() }
        }.navigationTitle("Edit goal").navigationBarTitleDisplayMode(.inline) }
    }
}

struct WellnessHalfSheet: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) { content.presentationDetents([.medium, .large]).presentationDragIndicator(.visible) }
        else { content }
    }
}
