import SwiftUI
import UIKit
import Combine
import FirebaseAuth
import FirebaseDatabase
import CryptoKit

struct AIChartPoint: Codable, Identifiable {
    var label: String
    var value: Double
    var id: String { label }
}
struct AIMetric: Codable, Identifiable {
    var id: String
    var title: String
    var unit: String
    var points: [AIChartPoint]
}
struct AISavedChart: Codable, Identifiable {
    var id = UUID().uuidString
    var title: String
    var kind: String
    var unit: String
    var points: [AIChartPoint]
    var caption: String
}
struct AIChatMessage: Codable, Identifiable {
    var id = UUID().uuidString
    var role: String
    var text: String
    var chart: AISavedChart? = nil
    var sources: [String] = []
    var sourceLinks: [AIScope]? = nil
}
struct AIScope: Codable, Identifiable {
    var id: String { key }
    var key: String
    var title: String
    var fixedContext: String = ""
    var regularID: String? = nil
    var wellnessID: String? = nil
    var noteID: String? = nil
    var includeAll = false
    var period = "weekly"
    var anchor: Date? = nil
    static var all: AIScope { AIScope(key: "all-notebooks", title: "All my notebooks", includeAll: true) }
    static func wellness(_ id: String, title: String) -> AIScope { AIScope(key: "wellness:" + id, title: title, wellnessID: id) }
    static func healthNote(notebookID: String, noteID: String, title: String, context: String) -> AIScope {
        AIScope(key: "wellness-note:" + notebookID + ":" + noteID, title: title, fixedContext: context, wellnessID: notebookID, noteID: noteID)
    }
    static func note(_ context: String, key: String? = nil) -> AIScope {
        let hash = SHA256.hash(data: Data(context.utf8)).prefix(10).map { String(format: "%02x", $0) }.joined()
        return AIScope(key: key ?? "note:" + hash, title: "This note", fixedContext: context)
    }
}
struct AIConversation: Codable, Identifiable {
    var id = UUID().uuidString
    var title: String
    var scope: AIScope
    var messages: [AIChatMessage] = []
    var updatedAt = Date()
    var isDeleted = false
}
@MainActor final class AIChatStore: ObservableObject {
    static let shared = AIChatStore()
    @Published private(set) var conversations: [AIConversation] = []
    @Published var syncNotice: String?
    private var account = "guest"
    private var generation = UUID()
    private var listener: AuthStateDidChangeListenerHandle?
    private var pending: Task<Void, Never>?
    private var syncing = false
    private var revision = UUID()
    private var dirty: Set<String> = []
    private var lastSync: Double = 0
    private var file: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PrivateAIChats", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(Data(account.utf8).base64EncodedString().replacingOccurrences(of: "/", with: "_") + ".json")
    }
    var visible: [AIConversation] { conversations.filter { !$0.isDeleted }.sorted { $0.updatedAt > $1.updatedAt } }
    init() {
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in Task { @MainActor in self?.switchAccount(user?.uid ?? "guest") } }
        switchAccount(Auth.auth().currentUser?.uid ?? "guest")
    }
    private func switchAccount(_ uid: String) {
        guard uid != account || conversations.isEmpty else { return }
        account = uid; generation = UUID(); pending?.cancel(); pending = nil; syncing = false; dirty = []; lastSync = 0
        conversations = (try? WellnessCodec.decoder.decode([AIConversation].self, from: Data(contentsOf: file))) ?? []
        Task { await sync() }
    }
    func thread(for scope: AIScope) -> AIConversation { visible.first { $0.scope.key == scope.key } ?? AIConversation(title: scope.title, scope: scope) }
    func save(_ thread: AIConversation) {
        var value = thread; value.updatedAt = Date()
        if conversations.contains(where: { $0.id == value.id && $0.isDeleted }) && !value.isDeleted { return }
        if let i = conversations.firstIndex(where: { $0.id == value.id }) { conversations[i] = value } else { conversations.append(value) }
        revision = UUID(); dirty.insert(value.id); persist()
        guard pending == nil else { return }
        pending = Task { do { try await Task.sleep(nanoseconds: 2_000_000_000) } catch { return }; pending = nil; await sync() }
    }
    func delete(_ thread: AIConversation) {
        var deleted = thread; deleted.isDeleted = true; deleted.messages = []; deleted.title = ""; deleted.scope = AIScope(key: "deleted", title: ""); save(deleted)
    }
    private func persist() {
        do { try WellnessCodec.encoder.encode(conversations).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]) }
        catch { syncNotice = "Your conversation couldn’t be saved: " + error.localizedDescription }
    }
    func sync() async {
        guard account != "guest", Auth.auth().currentUser?.uid == account, !syncing else { return }
        syncing = true; let token = generation; let version = revision; let owner = account
        defer { if token == generation { syncing = false; if version != revision { Task { await sync() } } } }
        do {
            // Each thread has its own private cloud document; notebook storage remains separate.
            for thread in conversations.filter({ dirty.contains($0.id) }) {
                let object = try JSONSerialization.jsonObject(with: WellnessCodec.encoder.encode(thread))
                _ = try await WellnessAPI.call("wellnessChatSync", ["thread": object], expectedUID: owner)
                guard token == generation else { return }
                if conversations.first(where: { $0.id == thread.id })?.updatedAt == thread.updatedAt { dirty.remove(thread.id) }
            }
            var cursor: [String: Any]? = nil
            repeat {
                var payload: [String: Any] = ["since": max(0, lastSync - 1000)]
                if let cursor { payload["cursor"] = cursor }
                let response = try await WellnessAPI.call("wellnessChatSync", payload, expectedUID: owner)
                guard token == generation else { return }
                if let values = response["threads"] {
                    let remote = try WellnessCodec.decoder.decode([AIConversation].self, from: JSONSerialization.data(withJSONObject: values))
                    for item in remote {
                        if let i = conversations.firstIndex(where: { $0.id == item.id }) { if item.updatedAt > conversations[i].updatedAt { conversations[i] = item } }
                        else { conversations.append(item) }
                    }
                }
                cursor = response["cursor"] as? [String: Any]
            } while cursor != nil
            lastSync = conversations.map { $0.updatedAt.timeIntervalSince1970 * 1000 }.max() ?? lastSync
            persist(); syncNotice = nil
        } catch { if token == generation { syncNotice = "Chats are saved on this device. Cloud sync is unavailable right now." } }
    }
}
struct AINoteRecord {
    var id: String
    var notebookID: String
    var notebook: String
    var title: String
    var body: String
    var isRegular = true
}
struct AIContextSnapshot {
    var context: String
    var metrics: [AIMetric]
    var sources: [String]
    var sourceScopes: [AIScope]
}
@MainActor enum AINotebookContext {
    static func load(_ scope: AIScope, question: String) async throws -> AIContextSnapshot {
        let uid = Auth.auth().currentUser?.uid
        var records: [AINoteRecord] = []
        let store = WellnessStore.shared
        if scope.includeAll || scope.wellnessID != nil { store.switchAccount(uid ?? "guest") }
        if let id = scope.wellnessID, !store.notebooks.contains(where: { $0.id == id }) { throw WellnessAPI.failure("This notebook was deleted. Choose another notebook.") }
        if scope.includeAll || scope.wellnessID != nil {
            for n in store.notebooks where scope.includeAll || n.id == scope.wellnessID {
                if let goal = n.goal, scope.noteID == nil {
                    records.append(AINoteRecord(id: n.id + "-goal", notebookID: n.id, notebook: n.name, title: "Health goal", body: goal.objective + " · Target date: " + WellnessDate.day(goal.dueDate), isRegular: false))
                }
                for note in n.notes where scope.noteID == nil || note.id == scope.noteID {
                    let tasks = note.items.map { "\($0.title) · \($0.detail): checked on \($0.checkedDates.sorted().suffix(35).joined(separator: ", "))" }.joined(separator: "\n")
                    records.append(AINoteRecord(id: note.id, notebookID: n.id, notebook: n.name, title: note.title, body: note.body + "\n" + (note.datedReflections ?? [:]).sorted { $0.key < $1.key }.suffix(20).map { "\($0.key): \($0.value)" }.joined(separator: "\n") + "\n" + (note.nextSteps ?? [:]).sorted { $0.key < $1.key }.suffix(10).map { "Next step \($0.key): \($0.value)" }.joined(separator: "\n") + "\n" + tasks, isRegular: false))
                }
            }
        }
        if scope.includeAll || scope.regularID != nil {
            guard uid != nil else { throw WellnessAPI.failure("Sign in to ask across your saved notebooks.") }
            let regular = try await RegularNotebookAIIndex.shared.load()
            records += regular.filter { scope.includeAll || $0.notebookID == scope.regularID }
        }
        guard uid == Auth.auth().currentUser?.uid else { throw WellnessAPI.failure("Your account changed. Please reopen this chat.") }
        let stop = Set(["the", "and", "what", "have", "been", "with", "from", "this", "that", "about", "notebooks", "notes", "show", "chart"])
        var words = Set(question.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count >= 3 && !stop.contains($0) })
        if !words.isDisjoint(with: ["food", "meal", "diet", "calories"]) { words.formUnion(["food", "meal", "calorie", "kcal"]) }
        if !words.isDisjoint(with: ["fitness", "workout", "training"]) { words.formUnion(["workout", "exercise", "training"]) }
        func excerpt(_ text: String) -> String {
            if text.utf8.count < 1300 { return text }
            var blocks: [(Int, String)] = []; var index = text.startIndex; var number = 0
            while index < text.endIndex {
                let end = text.index(index, offsetBy: 550, limitedBy: text.endIndex) ?? text.endIndex
                blocks.append((number, String(text[index..<end]))); index = end; number += 1
            }
            let best = blocks.sorted { a, b in let left = words.filter { a.1.lowercased().contains($0) }.count; let right = words.filter { b.1.lowercased().contains($0) }.count; return left == right ? a.0 < b.0 : left > right }.prefix(2).sorted { $0.0 < $1.0 }
            return best.map(\.1).joined(separator: "\n…\n")
        }
        func score(_ note: AINoteRecord) -> Int { let text = (note.notebook + " " + note.title + " " + note.body).lowercased(); return words.reduce(0) { $0 + (text.contains($1) ? 1 : 0) } }
        records.sort { score($0) > score($1) }
        if scope.includeAll {
            var first: [AINoteRecord] = []; var rest: [AINoteRecord] = []; var seen: Set<String> = []
            for record in records { if seen.insert(record.notebookID).inserted { first.append(record) } else { rest.append(record) } }
            records = first + rest
        }
        var sources: [String] = []; var context = ""
        for record in records {
            let entry = "[\(record.notebook)] \(record.title)\n\(excerpt(record.body))\n"
            if context.utf8.count + entry.utf8.count > 4800 { continue }
            context += entry
            if !sources.contains(record.notebook) { sources.append(record.notebook) }
        }
        if let anchor = scope.anchor {
            let c = scope.period == "weekly" ? Calendar(identifier: .iso8601) : Calendar.current
            let unit: Calendar.Component = scope.period == "daily" ? .day : scope.period == "monthly" ? .month : .weekOfYear
            if let range = c.dateInterval(of: unit, for: anchor) { context = "Requested period: " + WellnessDate.day(range.start) + " through " + WellnessDate.day(range.end.addingTimeInterval(-1)) + ". Do not treat other dates as this period.\n" + context }
        }
        if !scope.fixedContext.isEmpty { context = String(decoding: (excerpt(scope.fixedContext) + "\n" + context).utf8.prefix(4800), as: UTF8.self) }
        if scope.includeAll || (scope.noteID == nil && store.notebooks.contains(where: { $0.id == scope.wellnessID && $0.kind == "food" })) { context += "\n" + String(store.mealContext().prefix(600)) }
        var metrics = metricsFor(scope: scope)
        let query = question.lowercased()
        let preferred = ["goal", "milestone"].contains(where: { query.contains($0) }) ? "milestones" : ["meal", "food", "calorie", "kcal"].contains(where: { query.contains($0) }) ? "meals" : ["miss", "unchecked", "skip"].contains(where: { query.contains($0) }) ? "unchecked" : "consistency"
        metrics.sort { ($0.id == preferred ? 0 : 1) < ($1.id == preferred ? 0 : 1) }
        // Explicit numeric values from regular notes can also become grounded charts.
        for record in records.filter({ $0.isRegular }).prefix(5) {
            let lines = record.body.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            var points: [AIChartPoint] = []
            for line in lines.prefix(40) {
                let measured = line.contains(":") ? String(line.split(separator: ":", maxSplits: 1).last ?? "") : line
                guard let range = measured.range(of: #"[-+]?\d+(?:\.\d+)?"#, options: .regularExpression), let value = Double(measured[range]), value.isFinite else { continue }
                points.append(AIChartPoint(label: String(line.prefix(32)), value: value)); if points.count == 7 { break }
            }
            if points.count > 1 { metrics.append(AIMetric(id: "record-" + record.id, title: String((record.title + " · " + record.notebook).prefix(120)), unit: "as written", points: points)) }
        }
        metrics.sort { left, right in
            let l = words.filter { left.title.lowercased().contains($0) }.count * 10 + (left.id == preferred ? 2 : 0)
            let r = words.filter { right.title.lowercased().contains($0) }.count * 10 + (right.id == preferred ? 2 : 0)
            return l > r
        }
        metrics = Array(metrics.prefix(5))
        while metrics.count > 1 && ((try? JSONEncoder().encode(metrics).count) ?? 0) > 3000 { metrics.removeLast() }
        var links: [AIScope] = []
        for record in records where sources.contains(record.notebook) && !links.contains(where: { $0.title == record.notebook }) {
            if store.notebooks.contains(where: { $0.id == record.notebookID }) { links.append(.wellness(record.notebookID, title: record.notebook)) }
            else { links.append(AIScope(key: "regular:" + record.notebookID, title: record.notebook, regularID: record.notebookID)) }
        }
        return AIContextSnapshot(context: context, metrics: metrics, sources: sources, sourceScopes: links)
    }
    static func metricsFor(scope: AIScope) -> [AIMetric] {
        guard scope.includeAll || scope.wellnessID != nil else { return [] }
        let store = WellnessStore.shared; let calendar = Calendar.current
        let reference = scope.anchor ?? Date()
        let periodCalendar = scope.period == "weekly" ? Calendar(identifier: .iso8601) : calendar
        let unit: Calendar.Component = scope.period == "daily" ? .day : scope.period == "monthly" ? .month : .weekOfYear
        let interval = periodCalendar.dateInterval(of: unit, for: reference)!
        let dates: [Date]
        if scope.anchor == nil {
            let count = scope.period == "daily" ? 1 : scope.period == "monthly" ? 30 : 7
            dates = (0..<count).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
        } else {
            dates = (0..<32).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }.filter { $0 < interval.end && $0 <= Date() }
        }
        let notebooks = store.notebooks.filter { scope.wellnessID == nil || $0.id == scope.wellnessID }.map { value -> WellnessNotebook in
            var copy = value
            if let noteID = scope.noteID { copy.notes = value.notes.filter { $0.id == noteID }; copy.items = [] }
            return copy
        }
        let items = notebooks.flatMap { $0.items + $0.notes.flatMap(\.items) }.filter { !$0.isWeekly && $0.recurrence != "once" }
        var result: [AIMetric] = []
        let milestones = (scope.anchor == nil || interval.contains(Date()) ? notebooks : []).flatMap { $0.notes.flatMap(\.items) }.filter { $0.recurrence == "once" }
        if !milestones.isEmpty {
            let done = milestones.filter { $0.checked(on: Date()) }.count
            result.append(AIMetric(id: "milestones", title: "Current goal milestones · not a timeline", unit: "milestones", points: [AIChartPoint(label: "Complete", value: Double(done)), AIChartPoint(label: "Remaining", value: Double(milestones.count - done))]))
        }
        let consistency = dates.compactMap { date -> AIChartPoint? in
            let active = notebooks.filter { calendar.startOfDay(for: $0.createdAt) <= date }.flatMap { $0.items + $0.notes.flatMap(\.items) }.filter { !$0.isWeekly && $0.recurrence != "once" }
            guard !active.isEmpty else { return nil }
            return AIChartPoint(label: WellnessDate.day(date), value: Double(active.filter { $0.checked(on: date) }.count) / Double(active.count) * 100)
        }
        if !consistency.isEmpty { result.append(AIMetric(id: "consistency", title: "Routine consistency", unit: "%", points: consistency)) }
        let missed = items.prefix(8).map { item in AIChartPoint(label: String(item.title.prefix(28)), value: Double(dates.filter { day in let created = notebooks.first(where: { n in n.items.contains(where: { $0.id == item.id }) || n.notes.contains(where: { $0.items.contains(where: { $0.id == item.id }) }) })?.createdAt ?? day; return day >= calendar.startOfDay(for: created) && !item.checked(on: day) }.count)) }
        if !missed.isEmpty { result.append(AIMetric(id: "unchecked", title: "Unchecked recorded days", unit: "days", points: missed)) }
        var weeks: [Date] = []; var seenWeeks: Set<String> = []
        for date in dates { if seenWeeks.insert(WellnessDate.week(date)).inserted { weeks.append(date) } }
        let weeklyPoints = weeks.compactMap { date -> AIChartPoint? in
            let active = notebooks.filter { Calendar(identifier: .iso8601).dateInterval(of: .weekOfYear, for: $0.createdAt)!.start <= date }.flatMap { $0.items + $0.notes.flatMap(\.items) }.filter { $0.isWeekly && $0.recurrence != "once" }
            guard !active.isEmpty else { return nil }
            return AIChartPoint(label: WellnessDate.week(date), value: Double(active.filter { $0.checked(on: date) }.count) / Double(active.count) * 100)
        }
        if !weeklyPoints.isEmpty { result.append(AIMetric(id: "weekly-training", title: "Weekly training check-offs", unit: "%", points: weeklyPoints)) }
        let includeMeals = scope.includeAll || (scope.noteID == nil && notebooks.contains { $0.kind == "food" })
        let calories = (includeMeals ? dates : []).compactMap { date -> AIChartPoint? in
            let meals = store.meals.filter { calendar.isDate($0.date, inSameDayAs: date) }
            return meals.isEmpty ? nil : AIChartPoint(label: WellnessDate.day(date), value: Double(meals.reduce(0) { $0 + $1.total }))
        }
        if !calories.isEmpty { result.append(AIMetric(id: "meals", title: "Confirmed meal estimates", unit: "kcal", points: calories)) }
        return result
    }
}
@MainActor final class AIConversationModel: ObservableObject {
    @Published var thread: AIConversation
    @Published var busy = false
    @Published var error: String?
    private let account = Auth.auth().currentUser?.uid
    init(scope: AIScope, thread: AIConversation? = nil) { self.thread = thread ?? AIChatStore.shared.thread(for: scope) }
    func startNew(scope: AIScope) { guard !busy else { return }; thread = AIConversation(title: scope.title, scope: scope); error = nil }
    func send(_ question: String, scope: AIScope) async {
        guard !busy else { return }; busy = true; error = nil
        defer { busy = false }
        do {
            guard account == Auth.auth().currentUser?.uid else { throw WellnessAPI.failure("Reopen chat after switching accounts.") }
            guard thread.messages.count < 120 else { throw WellnessAPI.failure("This conversation is full. Start another chat; this history stays saved.") }
            var requestScope = scope
            if scope.anchor == nil {
                requestScope.period = thread.scope.period
                let q = question.lowercased()
                if q.contains("month") || q.contains("30 days") { requestScope.period = "monthly" }
                else if q.contains("week") || q.contains("7 days") { requestScope.period = "weekly" }
                else if q.contains("today") || q.contains("daily") { requestScope.period = "daily" }
            }
            let snapshot = try await AINotebookContext.load(requestScope, question: question)
            let history = thread.messages.suffix(6).map { "\($0.role): \($0.text)" }.joined(separator: "\n")
            let result = try await SubscriptionCenter.shared.ask(question: question, context: snapshot.context + "\nRecent conversation:\n" + String(history.suffix(900)), metrics: snapshot.metrics, structured: true, expectedUID: account)
            guard account == Auth.auth().currentUser?.uid else { return }
            if AIChatStore.shared.conversations.contains(where: { $0.id == thread.id && $0.isDeleted }) { thread = AIConversation(title: scope.title, scope: scope); throw WellnessAPI.failure("That conversation was deleted. Start a new chat to continue.") }
            let allowedSources = Set(snapshot.sources)
            let sources = (result["sources"] as? [String] ?? []).filter { allowedSources.contains($0) }
            var chart: AISavedChart?
            if let c = result["chart"] as? [String: Any], let metricID = c["metricID"] as? String, let metric = snapshot.metrics.first(where: { $0.id == metricID }) {
                chart = AISavedChart(title: c["title"] as? String ?? metric.title, kind: c["kind"] as? String ?? "bar", unit: metric.unit, points: metric.points, caption: "Based on your recorded data · " + requestScope.period.capitalized)
            }
            if thread.messages.isEmpty { thread.title = String(question.prefix(65)) }
            thread.scope = requestScope
            thread.messages.append(AIChatMessage(role: "user", text: question))
            thread.messages.append(AIChatMessage(role: "assistant", text: result["answer"] as? String ?? "", chart: chart, sources: sources, sourceLinks: snapshot.sourceScopes.filter { sources.contains($0.title) }))
            AIChatStore.shared.save(thread)
        } catch { self.error = error.localizedDescription }
    }
}
struct NotebookTrendPlot: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    var points: [AIChartPoint]
    var unit: String
    var height: CGFloat = 125
    private let lilac = Color(red: 0.56, green: 0.49, blue: 0.91)
    private var low: Double { min(0, points.map(\.value).min() ?? 0) }
    private var high: Double { unit == "%" ? 100 : max(low + 1, points.map(\.value).max() ?? 1) }
    private var labels: [Int] {
        guard !points.isEmpty else { return [] }
        if points.count <= 7 { return Array(points.indices) }
        return Array(Set([0, points.count / 4, points.count / 2, points.count * 3 / 4, points.count - 1])).sorted()
    }
    private func label(_ value: String) -> String {
        let parser = DateFormatter(); parser.locale = Locale(identifier: "en_US_POSIX"); parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: value) else { return String(value.prefix(12)) }
        return points.count <= 7 ? date.formatted(.dateTime.weekday(.abbreviated)) : date.formatted(.dateTime.month(.abbreviated).day())
    }
    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geometry in
                let width = max(1, geometry.size.width - 8)
                let plotHeight = max(1, geometry.size.height - 8)
                let locations = points.enumerated().map { index, point in
                    CGPoint(x: 4 + CGFloat(index) / CGFloat(max(1, points.count - 1)) * width, y: 4 + plotHeight - CGFloat((point.value - low) / (high - low)) * plotHeight)
                }
                Path { path in
                    guard let first = locations.first, let last = locations.last else { return }
                    path.move(to: CGPoint(x: first.x, y: geometry.size.height))
                    for point in locations { path.addLine(to: point) }
                    path.addLine(to: CGPoint(x: last.x, y: geometry.size.height)); path.closeSubpath()
                }.fill(LinearGradient(colors: [lilac.opacity(0.19), lilac.opacity(0.03)], startPoint: .top, endPoint: .bottom))
                Path { path in for (index, point) in locations.enumerated() { if index == 0 { path.move(to: point) } else { path.addLine(to: point) } } }.stroke(lilac, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                ForEach(Array(locations.indices), id: \.self) { index in
                    if locations.count <= 10 || index % max(1, locations.count / 7) == 0 || index == locations.count - 1 {
                        Circle().fill(Color.white).frame(width: 7, height: 7).overlay(Circle().stroke(lilac, lineWidth: 1.6)).position(locations[index])
                    }
                }
            }.frame(height: sizeClass == .regular ? max(180, height) : height).accessibilityElement(children: .ignore).accessibilityLabel("Trend chart").accessibilityValue("\(points.count) recorded values")
            HStack(spacing: 0) { ForEach(labels, id: \.self) { index in Text(label(points[index].label)).font(.system(size: 11)).foregroundColor(.black.opacity(0.55)).frame(maxWidth: .infinity) } }
        }
    }
}
struct AIChartCard: View {
    var chart: AISavedChart
    var summary: String? = nil
    var compact = false
    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            HStack(alignment: .firstTextBaseline) { Text(chart.title).font(.system(size: 17, weight: .medium)); Spacer(); Text(chart.unit).font(.system(size: 12)).foregroundColor(.black.opacity(0.5)) }
            if let summary { Text(summary).font(.system(size: 15)).foregroundColor(.black.opacity(0.65)) }
            if chart.kind == "line", chart.points.count > 1 {
                NotebookTrendPlot(points: chart.points, unit: chart.unit, height: compact ? 82 : 125)
                DisclosureGroup("Recorded values") { values }.font(.caption).tint(.applazAccent)
            } else { values }
            Text(chart.caption).font(.caption2).foregroundColor(.black.opacity(0.5))
        }.fixedSize(horizontal: false, vertical: true).wellnessCard().tint(.applazAccent)
    }
    private var values: some View {
        ForEach(Array(chart.points.enumerated()), id: \.offset) { _, point in
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text(point.label).fixedSize(horizontal: false, vertical: true); Spacer(); Text(String(format: "%.0f", point.value) + " " + chart.unit) }.font(.caption)
                if chart.kind != "line" { GeometryReader { geometry in Capsule().fill(Color.applazAccent.opacity(0.65)).frame(width: geometry.size.width * CGFloat(abs(point.value) / max(1, chart.points.map { abs($0.value) }.max() ?? 1))) }.frame(height: 6).background(Color.black.opacity(0.05)).cornerRadius(3) }
            }.padding(.vertical, 3)
        }
    }
}
struct InlineAIChat: View {
    var scope: AIScope
    var title = "Ask my notebooks"
    var openingQuestion: String? = nil
    var compact = false
    var embedded = false
    var overview = false
    var scopeProvider: (() -> AIScope)? = nil
    @StateObject private var model: AIConversationModel
    @ObservedObject private var subscription = SubscriptionCenter.shared
    @State private var question = ""
    @State private var paywall = false
    @State private var started = false
    @State private var privacy = false
    @State private var history = false
    @State private var source: AIScope?
    init(scope: AIScope, title: String = "Ask my notebooks", openingQuestion: String? = nil, compact: Bool = false, thread: AIConversation? = nil, scopeProvider: (() -> AIScope)? = nil, embedded: Bool = false, overview: Bool = false) {
        self.overview = overview
        self.embedded = embedded
        self.scope = scope; self.title = title; self.openingQuestion = openingQuestion; self.compact = compact; self.scopeProvider = scopeProvider
        _model = StateObject(wrappedValue: AIConversationModel(scope: scope, thread: thread))
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(overview ? "Across my notebooks" : title).font(.system(size: 17, weight: .medium))
                if !overview { Image(systemName: "sparkle").font(.system(size: 21, weight: .light)).foregroundColor(.applazAccent) }
                Spacer(minLength: 0)
                Menu {
                    Button { history = true } label: { Label("Saved chats", systemImage: "clock.arrow.circlepath") }
                    Button { model.startNew(scope: scopeProvider?() ?? scope); question = "" } label: { Label("New chat", systemImage: "plus") }
                    Button { privacy = true } label: { Label("AI privacy preferences", systemImage: "hand.raised") }
                } label: { Image(systemName: "ellipsis").frame(width: 32, height: 32).foregroundColor(.applazAccent) }.accessibilityLabel("AI options").disabled(model.busy)
            }
            if overview { NotebookWeekSummary(embedded: true, showHeading: false) }
            if !compact { Text(scope.title).font(.caption).foregroundColor(.black.opacity(0.55)) }
            ForEach(compact ? Array(model.thread.messages.suffix(4)) : model.thread.messages) { message in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if message.role == "user" { Spacer(minLength: 32) }
                        Text(message.text).font(.system(size: 15)).fixedSize(horizontal: false, vertical: true).padding(12)
                            .background(message.role == "user" ? Color(red: 0.87, green: 0.83, blue: 0.98).opacity(0.7) : Color.white.opacity(0.75)).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(message.role == "user" ? Color.clear : Color.applazAccent.opacity(0.10)))
                        if message.role != "user" { Spacer(minLength: 16) }
                    }
                    if let chart = message.chart { AIChartCard(chart: chart, compact: compact) }
                    if let links = message.sourceLinks, !links.isEmpty {
                        DisclosureGroup("Sources") {
                            ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(links) { link in Button { source = link } label: { Label(link.title, systemImage: "doc.text").font(.caption).padding(8).background(Color.white.opacity(0.6)).cornerRadius(12) } } } }
                        }.font(.caption).tint(.applazAccent)
                    } else if !message.sources.isEmpty {
                        DisclosureGroup("Sources") { Text(message.sources.joined(separator: " · ")).font(.caption).foregroundColor(.black.opacity(0.6)) }.font(.caption).tint(.applazAccent)
                    }
                }
            }
            if model.busy { HStack { Spacer(); AIThinkingOrb(); Spacer() } }
            if let error = model.error { Text(error).font(.footnote) }
            HStack { TextField(model.thread.messages.isEmpty ? (scope.includeAll ? "Ask all my notebooks…" : scope.noteID != nil || !scope.fixedContext.isEmpty ? "Ask about this note…" : "Ask this notebook…") : "Ask a follow-up…", text: $question).accessibilityIdentifier("AIQuestion"); Button { send() } label: { Image(systemName: "arrow.up.circle").font(.system(size: 25)).foregroundColor(.applazAccent) }.accessibilityLabel("Send question").disabled(model.busy || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }.padding(12).background(Color.white.opacity(0.75)).clipShape(Capsule()).overlay(Capsule().stroke(Color.applazAccent.opacity(0.15)))
            if !compact && !model.thread.messages.isEmpty { Text("Private · Conversation saved").font(.caption2).foregroundColor(.black.opacity(0.5)) }
        }.foregroundColor(.black).wellnessCard(embedded: embedded)
            .onAppear { if let openingQuestion, !started { started = true; question = openingQuestion; send() } }
            .sheet(isPresented: $paywall) { NavigationView { SubscriptionWelcomeView(onClose: { paywall = false }, onPurchased: { paywall = false }) } }
            .sheet(isPresented: $privacy) { NavigationView { AIPrivacyView().toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done") { privacy = false } } } } }
            .sheet(isPresented: $history) { NavigationView { SavedAIChatsView() } }
            .sheet(item: $source) { value in NavigationView { AINotebookSourceView(scope: value) } }
            .onReceive(AIChatStore.shared.$conversations) { threads in
                if threads.contains(where: { $0.id == model.thread.id && $0.isDeleted }) { model.startNew(scope: scopeProvider?() ?? scope) }
            }
    }
    private func send() {
        guard subscription.hasAppleSubscription else { paywall = true; return }
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { await model.send(text, scope: scopeProvider?() ?? scope); if model.error == nil { question = "" } }
    }
}
struct SavedAIChatsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = AIChatStore.shared
    @State private var search = ""
    @State private var deleting: AIConversation?
    var body: some View {
        ZStack { WellnessBackground(); ScrollView { VStack(alignment: .leading, spacing: 16) {
            TextField("Search conversations", text: $search).padding(12).background(Color.white.opacity(0.7)).cornerRadius(12)
            ForEach(store.visible.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) }) { thread in
                NavigationLink(destination: ScrollView { InlineAIChat(scope: thread.scope, thread: thread).padding(20) }.background(WellnessBackground()).navigationTitle(thread.scope.title).navigationBarTitleDisplayMode(.inline)) {
                    VStack(alignment: .leading, spacing: 6) { Text(thread.title).font(.headline); Text(thread.scope.title + " · " + thread.updatedAt.formatted(date: .abbreviated, time: .omitted)).font(.caption) }.frame(maxWidth: .infinity, alignment: .leading).wellnessCard()
                }.buttonStyle(.plain).contextMenu { Button("Delete conversation", role: .destructive) { deleting = thread } }
            }
            if store.visible.isEmpty { Text("Your conversations will appear here after your first AI reply.").font(.subheadline) }
            if let notice = store.syncNotice { Text(notice).font(.caption) }
        }.padding(20) }}.foregroundColor(.black).navigationTitle("Your chats").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done") { dismiss() } }
            ToolbarItem(placement: .navigationBarTrailing) { NavigationLink(destination: ScrollView { InlineAIChat(scope: .all, thread: AIConversation(title: "All my notebooks", scope: .all)).padding(20) }.background(WellnessBackground()).navigationTitle("New chat").navigationBarTitleDisplayMode(.inline)) { Image(systemName: "plus") }.accessibilityLabel("New chat") }
        }.confirmationDialog("Delete this conversation?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) { Button("Delete conversation", role: .destructive) { if let deleting { store.delete(deleting) }; deleting = nil } }
    }
}

struct GoalSummaryCard: View {
    @ObservedObject private var store = WellnessStore.shared
    var notebookID: String
    private var notebook: WellnessNotebook? { store.notebooks.first { $0.id == notebookID } }
    var body: some View {
        if let notebook, let goal = notebook.goal {
            let milestones = notebook.notes.flatMap(\.items).filter { $0.recurrence == "once" }
            let done = milestones.filter { $0.checked(on: Date()) }.count
            VStack(alignment: .leading, spacing: 12) {
                TextField("My health or fitness goal", text: Binding(get: { goal.objective }, set: { value in update { $0.objective = value } })).font(.system(size: 17, weight: .medium))
                DatePicker("By", selection: Binding(get: { goal.dueDate }, set: { value in update { $0.dueDate = value } }), displayedComponents: .date).font(.subheadline)
                Text("\(done) of \(milestones.count) milestones").font(.subheadline)
                WellnessProgress(done: done, total: milestones.count)
            }.wellnessCard()
        }
    }
    private func update(_ change: (inout WellnessGoal) -> Void) { guard var n = notebook, var goal = n.goal else { return }; change(&goal); n.goal = goal; store.update(n) }
}
struct WorkoutWeekStrip: View {
    @Binding var date: Date
    var scheduled: [Int]
    private var days: [Date] {
        let c = Calendar(identifier: .iso8601); let start = c.dateInterval(of: .weekOfYear, for: date)!.start
        return (0..<7).compactMap { c.date(byAdding: .day, value: $0, to: start) }
    }
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) { ForEach(days, id: \.self) { day in
                Button { date = day } label: { Text(day.formatted(.dateTime.weekday(.narrow))).font(.system(size: 15, weight: .medium)).frame(maxWidth: .infinity).padding(.vertical, 10).background(Calendar.current.isDate(day, inSameDayAs: date) ? Color.applazAccent : Color.white.opacity(0.6)).foregroundColor(Calendar.current.isDate(day, inSameDayAs: date) ? .white : .black).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.applazAccent.opacity(0.12))) }.buttonStyle(.plain).accessibilityLabel(day.formatted(.dateTime.weekday(.wide)))
            } }
            Text((scheduled.contains(Calendar.current.component(.weekday, from: date)) ? "Training" : "Rest / optional movement") + " · " + date.formatted(.dateTime.weekday(.wide))).font(.subheadline).foregroundColor(.black.opacity(0.6))
        }
    }
}
struct PeriodInsightsView: View {
    var notebookID: String? = nil
    var initialPeriod = "weekly"
    @State private var period = "weekly"
    @State private var initializedPeriod = false
    @State private var anchor = Date()
    @ObservedObject private var store = WellnessStore.shared
    private var scope: AIScope {
        var value = notebookID.map { id in AIScope.wellness(id, title: store.notebooks.first { $0.id == id }?.name ?? "This notebook") } ?? .all
        value.period = period; value.anchor = anchor
        value.key = "insights:" + (notebookID ?? "all") + ":" + period + ":" + WellnessDate.day(anchor)
        return value
    }
    private var metrics: [AIMetric] { AINotebookContext.metricsFor(scope: scope) }
    var body: some View {
        ZStack { WellnessBackground(); ScrollView { VStack(alignment: .leading, spacing: 20) {
            Picker("Insight period", selection: $period) { Text("Daily").tag("daily"); Text("Weekly").tag("weekly"); Text("Monthly").tag("monthly") }.pickerStyle(.segmented)
            HStack {
                Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel("Previous period")
                Spacer(); Text(periodLabel).font(.subheadline); Spacer()
                Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }.accessibilityLabel("Next period").disabled(anchor >= Calendar.current.startOfDay(for: Date()))
            }
            if let metric = metrics.first(where: { $0.id == "consistency" }) {
                AIChartCard(chart: AISavedChart(title: period.capitalized + " consistency", kind: "line", unit: metric.unit, points: metric.points, caption: "Based on recorded check-offs. Untracked dates are omitted."), summary: "Average recorded completion: \(Int(metric.points.map(\.value).reduce(0, +) / Double(max(1, metric.points.count))))%")
            }
            if let missed = metrics.first(where: { $0.id == "unchecked" }) {
                let values = missed.points.sorted { $0.value > $1.value }.filter { $0.value > 0 }
                if !values.isEmpty { VStack(alignment: .leading, spacing: 10) { Text("Habits to revisit").font(.system(size: 17, weight: .medium)); ForEach(Array(values.prefix(3).enumerated()), id: \.offset) { _, point in HStack(alignment: .top, spacing: 12) { Circle().fill(Color.applazAccent.opacity(0.3)).frame(width: 6, height: 6).padding(.top, 6); Text(point.label).font(.system(size: 15)).fixedSize(horizontal: false, vertical: true); Spacer(); Text("\(Int(point.value)) days").font(.system(size: 13)).foregroundColor(.black.opacity(0.55)) }.padding(.vertical, 5) }; Text("Days with an unchecked box in your records.").font(.caption).foregroundColor(.black.opacity(0.5)) }.wellnessCard() }
            }
            InlineAIChat(scope: scope, title: period == "daily" ? "Daily check-in" : period == "weekly" ? "Weekly reflection" : "Monthly patterns", compact: true).id(scope.key)
            NavigationLink(destination: SavedAIChartsView()) { Label("Saved charts", systemImage: "chart.xyaxis.line").font(.system(size: 15)).wellnessPill() }.accessibilityLabel("View saved charts")
            DisclosureGroup("About these insights") { Text("Charts use recorded check-offs. An unchecked box does not prove a missed habit. AI charts select values from your records; they do not invent measurements.").font(.caption).foregroundColor(.black.opacity(0.55)) }.font(.caption)
        }.padding(20) }}.foregroundColor(.black).tint(.applazAccent).navigationTitle("Insights").navigationBarTitleDisplayMode(.inline).navigationBarHidden(false)
            .onAppear { if !initializedPeriod { period = initialPeriod; initializedPeriod = true } }
    }
    private var periodLabel: String {
        if period == "daily" { return anchor.formatted(date: .abbreviated, time: .omitted) }
        let component: Calendar.Component = period == "weekly" ? .weekOfYear : .month
        let c = period == "weekly" ? Calendar(identifier: .iso8601) : Calendar.current
        guard let interval = c.dateInterval(of: component, for: anchor) else { return "" }
        return interval.start.formatted(.dateTime.month(.abbreviated).day()) + "–" + interval.end.addingTimeInterval(-1).formatted(.dateTime.month(.abbreviated).day())
    }
    private func move(_ direction: Int) { anchor = Calendar.current.date(byAdding: period == "daily" ? .day : period == "weekly" ? .weekOfYear : .month, value: direction, to: anchor) ?? anchor }
}
struct SavedAIChartsView: View {
    @ObservedObject private var store = AIChatStore.shared
    var body: some View {
        ZStack { WellnessBackground(); ScrollView { VStack(spacing: 18) {
            let charts = store.visible.flatMap { $0.messages.compactMap(\.chart) }
            if charts.isEmpty { Text("Charts you create in chat will be saved here.").padding() }
            ForEach(charts) { AIChartCard(chart: $0) }
        }.padding(20) }}.navigationTitle("Saved charts").navigationBarTitleDisplayMode(.inline)
    }
}

private struct AIInlineHeight: PreferenceKey {
    static var defaultValue: CGFloat = 220
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
private struct AIUIKitPanel: View {
    var scope: () -> AIScope
    var title: String
    var measured: (CGFloat) -> Void
    var guestAction: (() -> Void)?
    var body: some View {
        VStack(spacing: 14) {
            if let guestAction {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Guest mode").font(.headline)
                    Text("Guest notes are stored on this device and aren’t backed up to your account.").font(.subheadline).foregroundColor(.black.opacity(0.65))
                    Button("Back to Registration", action: guestAction).tint(.applazAccent)
                }.frame(maxWidth: .infinity, alignment: .leading).wellnessCard()
            }
            if scope().includeAll {
                InlineAIChat(scope: scope(), title: title, compact: true, scopeProvider: scope, overview: true)
            } else { InlineAIChat(scope: scope(), title: title, compact: true, scopeProvider: scope) }
        }.tint(.applazAccent).padding(.horizontal, 16).padding(.vertical, 12).fixedSize(horizontal: false, vertical: true)
            .background(GeometryReader { geo in Color.clear.preference(key: AIInlineHeight.self, value: geo.size.height) })
            .onPreferenceChange(AIInlineHeight.self, perform: measured)
    }
}
@MainActor final class AIInlinePanelController: UIViewController {
    var scope: () -> AIScope
    var panelTitle: String
    var guestAction: (() -> Void)?
    var heightChanged: ((CGFloat) -> Void)?
    private var host: UIHostingController<AIUIKitPanel>?
    private weak var table: UITableView?
    private var originalInsets = UIEdgeInsets.zero
    private var keyboardRaised = false
    init(title: String, scope: @escaping () -> AIScope) { self.scope = scope; panelTitle = title; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .clear
        NotificationCenter.default.addObserver(self, selector: #selector(adjustKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        let host = UIHostingController(rootView: AIUIKitPanel(scope: scope, title: panelTitle, measured: { [weak self] height in self?.heightChanged?(max(180, height)) }, guestAction: guestAction))
        self.host = host; host.view.backgroundColor = .clear
        addChild(host); view.addSubview(host.view); host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([host.view.topAnchor.constraint(equalTo: view.topAnchor), host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor), host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor), host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        host.didMove(toParent: self)
    }
    deinit { NotificationCenter.default.removeObserver(self) }
    @objc private func adjustKeyboard(_ notification: Notification) {
        guard let table, let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let window = table.window else { return }
        let keyboard = window.convert(frame, from: nil)
        let overlap = max(0, table.convert(table.bounds, to: window).intersection(keyboard).height)
        if !keyboardRaised { originalInsets = table.contentInset }
        keyboardRaised = overlap > 0
        var insets = originalInsets; insets.bottom += overlap
        table.contentInset = insets; table.verticalScrollIndicatorInsets.bottom = insets.bottom
        func responder(_ root: UIView) -> UIView? { if root.isFirstResponder { return root }; for child in root.subviews { if let found = responder(child) { return found } }; return nil }
        if overlap > 0, let field = responder(view) { table.scrollRectToVisible(field.convert(field.bounds, to: table).insetBy(dx: 0, dy: -12), animated: true) }
    }
    static func footer(in parent: UIViewController, table: UITableView, title: String, scope: @escaping () -> AIScope) -> AIInlinePanelController {
        let controller = AIInlinePanelController(title: title, scope: scope)
        if parent is NoteCategoryListVC, UserDefaults.standard.bool(forKey: Guest_Key) {
            controller.guestAction = { [weak parent] in parent?.navigationController?.popViewController(animated: true) }
        }
        controller.table = table; controller.originalInsets = table.contentInset
        parent.addChild(controller); controller.view.frame = CGRect(x: 0, y: 0, width: table.bounds.width, height: 220)
        table.tableFooterView = controller.view; controller.didMove(toParent: parent)
        controller.heightChanged = { [weak table, weak controller] height in
            guard let table, let view = controller?.view, abs(view.frame.height - height) > 2 else { return }
            view.frame.size = CGSize(width: table.bounds.width, height: height); table.tableFooterView = view
        }
        return controller
    }
}

/// One account-scoped observer reuses Firebase's incremental updates across questions.
@MainActor final class RegularNotebookAIIndex {
    static let shared = RegularNotebookAIIndex()
    private var uid: String?
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?
    private var auth: AuthStateDidChangeListenerHandle?
    private var ready = false
    private var failure: Error?
    private var records: [AINoteRecord] = []
    init() { auth = Auth.auth().addStateDidChangeListener { [weak self] _, user in Task { @MainActor in self?.bind(user?.uid) } } }
    private func bind(_ value: String?) {
        guard value != uid || ref == nil else { return }
        if let handle { ref?.removeObserver(withHandle: handle) }
        uid = value; ready = false; failure = nil; records = []; ref = nil; handle = nil
        guard let value else { return }
        let reference = Database.database().reference().child("Users").child(value).child("Notes"); ref = reference
        handle = reference.observe(.value, with: { [weak self] snapshot in
            Task { @MainActor in
                guard let self, self.uid == value, Auth.auth().currentUser?.uid == value else { return }
                var result: [AINoteRecord] = []
                for case let category as DataSnapshot in snapshot.children {
                    if category.childSnapshot(forPath: "wellnessManaged").value as? Bool == true { continue }
                    let name = category.childSnapshot(forPath: "Category Name").value as? String ?? "Notebook"
                    for case let note as DataSnapshot in category.children {
                        guard let data = note.value as? [String: Any], let title = data["Title name"] as? String else { continue }
                        let html = data["Note name"] as? String ?? ""
                        let lines = html.replacingOccurrences(of: #"</(?:p|div|li|h[1-6])>|<br\s*/?>"#, with: "\n", options: .regularExpression)
                        let plain = lines.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression).replacingOccurrences(of: "&nbsp;", with: " ").replacingOccurrences(of: "&amp;", with: "&")
                        result.append(AINoteRecord(id: note.key, notebookID: category.key, notebook: name, title: title, body: plain))
                    }
                }
                self.records = result; self.ready = true
            }
        }, withCancel: { [weak self] error in Task { @MainActor in if self?.uid == value { self?.failure = error } } })
    }
    func load() async throws -> [AINoteRecord] {
        guard let uid = Auth.auth().currentUser?.uid else { throw WellnessAPI.failure("Sign in to ask your notebooks.") }
        bind(uid)
        for _ in 0..<200 {
            guard Auth.auth().currentUser?.uid == uid else { throw WellnessAPI.failure("Your account changed. Reopen this chat.") }
            if let failure { throw failure }
            if ready { return records }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        throw WellnessAPI.failure("Your notebooks couldn’t be loaded. Check your connection and try again.")
    }
}

struct NotebookWeekSummary: View {
    var embedded = false
    var showHeading = true
    @ObservedObject private var store = WellnessStore.shared
    @State private var insights = false
    private var metric: AIMetric? { AINotebookContext.metricsFor(scope: .all).first { $0.id == "consistency" } }
    var body: some View {
        if let metric, !metric.points.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                if showHeading { Text("Across my notebooks").font(.system(size: 17, weight: .medium)) }
                Text("Your weekly consistency: \(Int(metric.points.map(\.value).reduce(0, +) / Double(metric.points.count)))%").font(.subheadline)
                NotebookTrendPlot(points: metric.points, unit: "%", height: 82)
                HStack { Spacer(); Button { insights = true } label: { Label("Find my patterns", systemImage: "sparkle").font(.system(size: 15)).wellnessPill() }; Spacer() }
            }.wellnessCard(embedded: embedded).sheet(isPresented: $insights) { NavigationView { PeriodInsightsView().toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done") { insights = false } } } } }
        }
    }
}
struct AINotebookSourceView: View {
    @Environment(\.dismiss) private var dismiss
    var scope: AIScope
    @State private var text = "Loading your notebook…"
    var body: some View {
        ZStack { WellnessBackground(); ScrollView { Text(text).font(.system(size: 16)).frame(maxWidth: .infinity, alignment: .leading).padding(22) } }.foregroundColor(.black).navigationTitle(scope.title).navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done") { dismiss() } } }
            .task { do { text = try await AINotebookContext.load(scope, question: "").context } catch { text = error.localizedDescription } }
    }
}

struct GoalMilestonesView: View {
    @ObservedObject private var store = WellnessStore.shared
    var notebookID: String
    @State private var newMilestone = ""
    private var notebook: WellnessNotebook? { store.notebooks.first { $0.id == notebookID } }
    var body: some View {
        if let notebook {
            VStack(alignment: .leading, spacing: 14) {
                Text("Milestones").font(.system(size: 16, weight: .medium))
                ForEach(notebook.notes.flatMap(\.items).filter { $0.recurrence == "once" }) { item in
                    Button { toggle(item.id) } label: { HStack(spacing: 12) { WellnessCheckbox(checked: item.checked(on: Date())); Text(item.title).font(.system(size: 16)).foregroundColor(item.checked(on: Date()) ? .black.opacity(0.55) : .black); Spacer() }.frame(minHeight: 46).contentShape(Rectangle()) }.buttonStyle(.plain).accessibilityValue(item.checked(on: Date()) ? "Completed" : "Not checked")
                    Rectangle().fill(Color.applazAccent.opacity(0.10)).frame(height: 1).padding(.leading, 38)
                }
                HStack { TextField("Add milestone", text: $newMilestone); Button { add() } label: { Image(systemName: "plus") }.accessibilityLabel("Add milestone") }
            }.wellnessCard()
        }
    }
    private func toggle(_ id: String) {
        guard var n = notebook else { return }
        for i in n.notes.indices { if let j = n.notes[i].items.firstIndex(where: { $0.id == id }) { if !n.notes[i].items[j].checkedDates.insert("once").inserted { n.notes[i].items[j].checkedDates.remove("once") } } }
        store.update(n)
    }
    private func add() {
        let name = newMilestone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, var n = notebook, let i = n.notes.firstIndex(where: { $0.isChecklist }) else { return }
        n.notes[i].items.append(HabitItem(title: name, recurrence: "once")); store.update(n); newMilestone = ""
    }
}
struct GoalWeeklyCheckin: View {
    @ObservedObject private var store = WellnessStore.shared
    var notebookID: String
    private var key: String { WellnessDate.week(Date()) }
    private var notebook: WellnessNotebook? { store.notebooks.first { $0.id == notebookID } }
    private var note: WellnessTextNote? { notebook?.notes.first { $0.recurrence == "weekly" && !$0.isChecklist } }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly check-in").font(.system(size: 16, weight: .medium))
            TextField("What moved forward?", text: Binding(get: { note?.datedReflections?[key] ?? "" }, set: { update($0, next: false) })).padding(12).background(Color.white.opacity(0.6)).cornerRadius(12)
            TextField("My next small step", text: Binding(get: { note?.nextSteps?[key] ?? "" }, set: { update($0, next: true) })).padding(12).background(Color.white.opacity(0.6)).cornerRadius(12)
        }.wellnessCard()
    }
    private func update(_ text: String, next: Bool) {
        guard var n = notebook, let id = note?.id, let i = n.notes.firstIndex(where: { $0.id == id }) else { return }
        if next { var values = n.notes[i].nextSteps ?? [:]; values[key] = text; n.notes[i].nextSteps = values }
        else { var values = n.notes[i].datedReflections ?? [:]; values[key] = text; n.notes[i].datedReflections = values }
        store.update(n)
    }
}
