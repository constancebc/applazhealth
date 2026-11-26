import Foundation
import UIKit
import Combine
import FirebaseAuth

struct HabitItem: Codable, Identifiable, Equatable {
    var id = UUID().uuidString
    var title: String
    var detail: String = ""
    var checkedDates: Set<String> = []
    var recurrence: String? = nil
    var isWeekly = false
    func key(on date: Date) -> String { recurrence == "once" ? "once" : (isWeekly ? WellnessDate.week(date) : WellnessDate.day(date)) }
    func checked(on date: Date) -> Bool { checkedDates.contains(key(on: date)) }
}
struct WellnessNotebook: Codable, Identifiable {
    var id = UUID().uuidString
    var name: String
    var kind: String
    var items: [HabitItem]
    var notes: [WellnessTextNote] = []
    var createdAt = Date()
    var updatedAt = Date()
    var isDeleted = false
    var goal: WellnessGoal? = nil
    var isPrivate: Bool? = nil
    var visibilityRevision: Int? = nil
    var visibilityIntent: String? = nil
    var lastCheckinDay: String? = nil
    var lastCheckinWeek: String? = nil
}
struct WellnessGoal: Codable {
    var objective: String
    var dueDate: Date
}
struct WellnessTextNote: Codable, Identifiable {
    var id = UUID().uuidString
    var title: String
    var body: String
    var items: [HabitItem] = []
    var isChecklist = false
    var datedReflections: [String: String]? = nil
    var nextSteps: [String: String]? = nil
    var recurrence: String? = nil
    var workoutDays: [Int]? = nil
    var attachments: [String]? = nil
    var richHTML: String? = nil
    var updatedAt = Date()
}
struct MealItem: Codable, Identifiable {
    var id = UUID().uuidString
    var name: String
    var portion: String
    var calories: Int
}
struct MealEntry: Codable, Identifiable {
    var id = UUID().uuidString
    var date = Date()
    var meal: String
    var description: String
    var items: [MealItem]
    var estimated = true
    var updatedAt = Date()
    var isDeleted = false
    var total: Int { items.reduce(0) { $0 + max(0, $1.calories) } }
}
struct WellnessDocument: Codable {
    var notebooks: [WellnessNotebook] = []
    var meals: [MealEntry] = []
    var initialized = false
}
enum WellnessDate {
    static func day(_ date: Date) -> String {
        let f = DateFormatter(); f.calendar = Calendar(identifier: .gregorian); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }
    static func week(_ date: Date) -> String {
        let c = Calendar(identifier: .iso8601)
        return "\(c.component(.yearForWeekOfYear, from: date))-W\(c.component(.weekOfYear, from: date))"
    }
}
enum WellnessTemplate: String, CaseIterable, Identifiable {
    case blank = "Blank notebook", goals = "Health & fitness goals", wellness = "Daily wellness", workout = "Daily workout", food = "Food diary", training = "Fitness training"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .blank: return "book.closed"; case .goals: return "target"; case .wellness: return "checklist"; case .workout: return "figure.strengthtraining.traditional"; case .food: return "fork.knife"; case .training: return "calendar" }
    }
    var summary: String {
        switch self {
        case .blank: return "A blank space for text notes or your own checklist."
        case .goals: return "Set a goal and deadline, track milestones, and reflect each week."
        case .wellness: return "Morning and evening checklists for your own daily habits."
        case .workout: return "Plan workout days, check off exercises, and keep session notes."
        case .food: return "Log meals with text or photos, review estimates, and see your daily tally."
        case .training: return "Organize weekly training sessions and review your progress."
        }
    }
    var kind: String { switch self { case .blank: return "text"; case .food: return "food"; default: return "checklist" } }
    func notebook(name: String? = nil) -> WellnessNotebook {
        let rows: [(String, String)]
        switch self {
        case .blank: rows = []
        case .goals: rows = [("Choose a routine I can sustain", ""), ("Complete my first week", ""), ("Review what worked", ""), ("Build up gradually", ""), ("Celebrate my consistency", "")]
        case .wellness: rows = [("My usual vitamins", "As part of my own routine"), ("Lemon water", ""), ("10-minute walk", ""), ("Evening stretch", ""), ("A few lines of reflection", "")]
        case .workout: rows = [("Warm-up", "5 minutes"), ("Squats", "3 sets × 8 reps"), ("Dumbbell rows", "3 sets × 10 reps"), ("Push-ups", "3 sets × 8 reps"), ("Cool-down", "5 minutes")]
        case .food: rows = [("Log breakfast", ""), ("Log lunch", ""), ("Log dinner", ""), ("Water check-in", ""), ("Prepare tomorrow’s lunch", "")]
        case .training: rows = [("Monday · Strength", ""), ("Wednesday · Strength", ""), ("Friday · Cardio", ""), ("Sunday · Mobility", "")]
        }
        var notebook = WellnessNotebook(name: name ?? rawValue, kind: kind, items: [], notes: rows.isEmpty ? [] : [WellnessTextNote(title: self == .training ? "This week’s sessions" : self == .goals ? "My milestones" : self == .workout ? "Workout routine" : self == .food ? "Daily meal goals" : "Morning checklist", body: "", items: rows.map { HabitItem(title: $0.0, detail: $0.1, recurrence: self == .goals ? "once" : nil, isWeekly: self == .training) }, isChecklist: true, recurrence: self == .goals ? "once" : self == .training ? "weekly" : "daily", workoutDays: self == .workout ? [2, 4, 6] : nil)])
        if self == .wellness {
            notebook.notes.append(WellnessTextNote(title: "Evening check-in", body: "", items: [HabitItem(title: "Evening stretch"), HabitItem(title: "Prepare for tomorrow"), HabitItem(title: "A few lines of reflection")], isChecklist: true))
        }
        if self == .wellness || self == .goals || self == .training {
            notebook.notes.append(WellnessTextNote(title: "Weekly reflection", body: "", recurrence: "weekly"))
        }
        if self == .goals { notebook.goal = WellnessGoal(objective: "Build a routine that works for me", dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!) }
        return notebook
    }
}
@MainActor final class WellnessStore: ObservableObject {
    static let shared = WellnessStore()
    @Published private(set) var document = WellnessDocument()
    @Published var syncMessage: String?
    private var account = "guest"
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var scheduledSync: Task<Void, Never>?
    private var background: AnyCancellable?
    private var syncing = false
    private var generation = UUID()
    private var saveGeneration = UUID()
    private var localSaveSucceeded = false
    private var file: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PrivateWellness", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(Data(account.utf8).base64EncodedString().replacingOccurrences(of: "/", with: "_") + ".json")
    }
    init() {
        background = NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification).sink { [weak self] _ in
            Task { @MainActor in await self?.sync() }
        }
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.switchAccount(user?.uid ?? "guest") }
        }
        switchAccount(Auth.auth().currentUser?.uid ?? "guest")
    }
    var notebooks: [WellnessNotebook] { document.notebooks.filter { !$0.isDeleted } }
    var meals: [MealEntry] { document.meals.filter { !$0.isDeleted } }
    func switchAccount(_ uid: String) {
        guard uid != account || !document.initialized else { return }
        scheduledSync?.cancel(); scheduledSync = nil
        account = uid; localSaveSucceeded = false; generation = UUID(); syncing = false
        document = (try? WellnessCodec.decoder.decode(WellnessDocument.self, from: Data(contentsOf: file))) ?? WellnessDocument()
        if !document.initialized {
            document.initialized = true
            document.notebooks = [WellnessNotebook(id: "start-here-v1", name: "Start Here", kind: "text", items: [], notes: [
                WellnessTextNote(id: "welcome", title: "Welcome to Applaz", body: "This private notebook is yours. Your existing notebooks and notes stay as they are. Use the bottom Home button to explore the Newsfeed and the center plus to open Notebooks."),
                WellnessTextNote(id: "write", title: "Write your first note", body: "Tap + to create a notebook or add to an existing one. Choose Text for ordinary writing, or Checklist for habits. The save icon keeps your note. Checklists remember each day separately; training goals remember each week."),
                WellnessTextNote(id: "privacy", title: "Privacy, meals & AI", body: "Start Here is private. You can choose Public or Private for other notebooks. Public notes can appear in Newsfeed; meal logs, dated health reflections and AI conversations stay private. Type a meal or choose a photo to request a calorie estimate, then correct portions before confirming the daily tally. AI needs a verified subscription and your consent before selected content is sent for analysis."),
                WellnessTextNote(id: "guest", title: "Keep your work safe", body: "Sign in to save across devices. Guest work stays on this device and does not automatically move into another account. AI credits begin only after Apple confirms a subscription and the backend verifies it. Manage or restore purchases in Settings.")
            ])]
            document.notebooks[0].updatedAt = Date(timeIntervalSince1970: 0)
            persistLocal()
        }
        Task { await sync() }
    }
    var hasGuestWork: Bool {
        guard account != "guest", let guest = guestDocument else { return false }
        return guest.notebooks.contains { !$0.isDeleted && $0.id != "start-here-v1" } || guest.meals.contains { !$0.isDeleted }
    }
    private var guestDocument: WellnessDocument? {
        let name = Data("guest".utf8).base64EncodedString() + ".json"
        return try? WellnessCodec.decoder.decode(WellnessDocument.self, from: Data(contentsOf: file.deletingLastPathComponent().appendingPathComponent(name)))
    }
    func importGuestWork() {
        guard account != "guest", let guest = guestDocument else { return }
        for notebook in guest.notebooks where notebook.id != "start-here-v1" && !document.notebooks.contains(where: { $0.id == notebook.id }) { document.notebooks.append(notebook) }
        for meal in guest.meals where !document.meals.contains(where: { $0.id == meal.id }) { document.meals.append(meal) }
        changed()
    }
    func create(_ template: WellnessTemplate, name: String? = nil) -> String {
        let n = template.notebook(name: name); document.notebooks.append(n); changed(); return n.id
    }
    @discardableResult func savePublicCopy(_ note: NoteList) -> Bool {
        guard note.isPrivateNote == false else { return false }
        switchAccount(Auth.auth().currentUser?.uid ?? "guest")
        let id = notebooks.first(where: { $0.name == "Saved notes" && $0.isPrivate != false })?.id ?? create(.blank, name: "Saved notes")
        guard var notebook = notebooks.first(where: { $0.id == id }) else { return false }
        notebook.isPrivate = true
        let html = note.noteDescriptionText ?? ""
        notebook.notes.append(WellnessTextNote(title: note.noteTitleName ?? "Saved note", body: html.setAttributetext(fontsize: 16, fontName: "AvenirNext-Regular")?.string ?? html))
        update(notebook)
        return true
    }
    func update(_ notebook: WellnessNotebook) {
        guard let i = document.notebooks.firstIndex(where: { $0.id == notebook.id }) else { return }
        var value = notebook; value.updatedAt = Date(); value.lastCheckinDay = WellnessDate.day(Date()); value.lastCheckinWeek = WellnessDate.week(Date()); document.notebooks[i] = value; changed()
    }
    func toggle(_ itemID: String, notebookID: String, date: Date) {
        guard var n = notebooks.first(where: { $0.id == notebookID }), let i = n.items.firstIndex(where: { $0.id == itemID }) else { return }
        let key = n.items[i].key(on: date)
        if !n.items[i].checkedDates.insert(key).inserted { n.items[i].checkedDates.remove(key) }
        update(n)
    }
    func setVisibility(_ id: String, isPrivate: Bool) {
        guard var n = notebooks.first(where: { $0.id == id }), id != "start-here-v1" else { return }
        n.isPrivate = isPrivate; n.visibilityIntent = UUID().uuidString; update(n)
    }
    func deleteNotebook(_ id: String) {
        guard var n = notebooks.first(where: { $0.id == id }) else { return }; n.isDeleted = true; update(n)
    }
    func saveMeal(_ meal: MealEntry) {
        var m = meal; m.updatedAt = Date()
        if let i = document.meals.firstIndex(where: { $0.id == m.id }) { document.meals[i] = m } else { document.meals.append(m) }
        changed()
    }
    func deleteMeal(_ meal: MealEntry) { var m = meal; m.isDeleted = true; saveMeal(m) }
    private func changed() {
        persistLocal(); saveGeneration = UUID()
        guard scheduledSync == nil else { return }
        scheduledSync = Task {
            do { try await Task.sleep(nanoseconds: 15_000_000_000) } catch { return }
            scheduledSync = nil
            await sync()
        }
    }
    private func persistLocal() {
        do { let data = try WellnessCodec.encoder.encode(document); try data.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]); syncMessage = nil; localSaveSucceeded = true }
        catch { localSaveSucceeded = false; syncMessage = "Couldn’t save on this device: \(error.localizedDescription)" }
    }
    func sync() async {
        guard !syncing, account != "guest", Auth.auth().currentUser?.uid == account else { return }
        let token = generation; let owner = account; let editVersion = saveGeneration; syncing = true
        defer {
            if token == generation {
                syncing = false
                if editVersion != saveGeneration { Task { await sync() } }
            }
        }
        do {
            let sent = document
            let payload = try JSONSerialization.jsonObject(with: WellnessCodec.encoder.encode(sent))
            let response = try await WellnessAPI.call("wellnessSync", ["document": payload], expectedUID: owner)
            guard token == generation else { return }
            if let object = response["document"] {
                let remote = try WellnessCodec.decoder.decode(WellnessDocument.self, from: JSONSerialization.data(withJSONObject: object))
                var merged = document
                for n in remote.notebooks {
                    if let i = merged.notebooks.firstIndex(where: { $0.id == n.id }) {
                        let local = merged.notebooks[i]
                        let sentNotebook = sent.notebooks.first(where: { $0.id == n.id })
                        let sentIntent = sentNotebook?.visibilityIntent
                        let hasUnsentEdits = sentNotebook.map { local.updatedAt > $0.updatedAt } ?? true
                        if n.updatedAt > local.updatedAt && !hasUnsentEdits { merged.notebooks[i] = n }
                        if hasUnsentEdits && n.updatedAt >= local.updatedAt { merged.notebooks[i].updatedAt = max(Date(), n.updatedAt.addingTimeInterval(0.001)) }
                        if (n.visibilityRevision ?? 0) > (local.visibilityRevision ?? 0) {
                            merged.notebooks[i].visibilityRevision = n.visibilityRevision
                            if local.visibilityIntent == sentIntent { merged.notebooks[i].isPrivate = n.isPrivate; merged.notebooks[i].visibilityIntent = n.visibilityIntent }
                            else { merged.notebooks[i].isPrivate = local.isPrivate; merged.notebooks[i].visibilityIntent = local.visibilityIntent }
                        }
                    }
                    else { merged.notebooks.append(n) }
                }
                for m in remote.meals {
                    if let i = merged.meals.firstIndex(where: { $0.id == m.id }) { if m.updatedAt > merged.meals[i].updatedAt { merged.meals[i] = m } }
                    else { merged.meals.append(m) }
                }
                document = merged; persistLocal()
                if response["photoStorageFull"] as? Bool == true {
                    syncMessage = "Your notes are still syncing. Your photo storage is full. Delete a few photos to make room for more."
                    CloudSaveWarning.report(WellnessAPI.failure("Photo storage is full."), key: "photos:" + owner, savedLocally: localSaveSucceeded)
                } else { CloudSaveWarning.recovered("photos:" + owner) }
            }
        } catch { if token == generation {
            syncMessage = (localSaveSucceeded ? "Saved on this device. Cloud sync: " : "Couldn’t confirm a device save. Cloud sync: ") + error.localizedDescription
            CloudSaveWarning.report(error, key: "notebooks:" + owner, savedLocally: localSaveSucceeded)
        } }
    }
    func context(notebookID: String? = nil) -> String {
        let selected = notebooks.filter { notebookID == nil || $0.id == notebookID }
        let calendar = Calendar.current
        let rows = selected.map { n -> String in
            let tasks = (n.items + n.notes.flatMap(\.items)).map { item -> String in
                let count = (0..<7).filter { offset in item.checked(on: calendar.date(byAdding: .day, value: -offset, to: Date())!) }.count
                return "\(item.title): \(item.isWeekly ? "weekly goal" : "daily habit"), recorded check-offs: \(item.checkedDates.sorted().suffix(35).joined(separator: ",")); \(item.isWeekly ? "this week: " + (item.checked(on: Date()) ? "checked" : "not checked") : "last 7 days: \(count)/7")"
            }.joined(separator: "\n")
            return "Notebook: \(n.name); tracking began \(WellnessDate.day(n.createdAt))\n\(tasks)\n" + n.notes.map { "\($0.title): \($0.body)" }.joined(separator: "\n")
        }.joined(separator: "\n\n")
        let includesMeals = notebookID == nil || selected.contains { $0.kind == "food" }
        let food = includesMeals ? mealContext() : ""
        return String(rows.prefix(food.isEmpty ? 6500 : 4200)) + "\n" + String(food.prefix(2200))
    }
    func mealContext() -> String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recent = meals.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }.suffix(40)
        return "Confirmed food logs for the last 30 days (calories are user-reviewed estimates; missing logs are not skipped meals):\n" + recent.map { entry in
            "\(WellnessDate.day(entry.date)) · \(entry.meal): " + entry.items.map { "\($0.name), \($0.portion), \($0.calories) kcal" }.joined(separator: "; ") + "; total \(entry.total) kcal"
        }.joined(separator: "\n")
    }
    func consistency(_ date: Date) -> Double? {
        let items = notebooks.filter { Calendar.current.startOfDay(for: $0.createdAt) <= date }.flatMap { $0.items + $0.notes.flatMap(\.items) }.filter { !$0.isWeekly && $0.recurrence != "once" }
        guard !items.isEmpty else { return nil }
        return Double(items.filter { $0.checked(on: date) }.count) / Double(items.count)
    }
}
enum WellnessAPI {
    static let baseURL = "https://us-central1-applaz-32772.cloudfunctions.net/"
    static func call(_ endpoint: String, _ payload: [String: Any], expectedUID: String? = nil) async throws -> [String: Any] {
        var token: String?
        if endpoint != "wellnessStatus" {
        guard let user = Auth.auth().currentUser else { throw failure("Sign in to save across devices or use AI.") }
        if let expectedUID, user.uid != expectedUID { throw failure("Your account changed. Reopen this screen to continue.") }
        token = try await withCheckedThrowingContinuation { (c: CheckedContinuation<String, Error>) in user.getIDToken { token, error in
            if let error { c.resume(throwing: error) } else if let token { c.resume(returning: token) } else { c.resume(throwing: failure("Sign in again.")) }
        }}
        }
        var request = URLRequest(url: URL(string: baseURL + endpoint)!); request.httpMethod = "POST"
        request.timeoutInterval = 55; if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["data": payload])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode != 404 else { throw failure("Cloud features aren’t available right now. Your work remains saved on this device.") }
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        if let error = object["error"] as? [String: Any] { throw failure(error["message"] as? String ?? "This request couldn’t be completed.") }
        guard (200..<300).contains(http.statusCode), let result = object["result"] as? [String: Any] else { throw failure("Service unavailable. Please try again later.") }
        return result
    }
    static func failure(_ message: String) -> NSError { NSError(domain: "Applaz", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
}

enum WellnessCodec {
 static var encoder: JSONEncoder { let e = JSONEncoder(); e.dateEncodingStrategy = .millisecondsSince1970; return e }
 static var decoder: JSONDecoder { let d = JSONDecoder(); d.dateDecodingStrategy = .millisecondsSince1970; return d }
}
