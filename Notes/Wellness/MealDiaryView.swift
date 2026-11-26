import SwiftUI
import UIKit
import PhotosUI

struct MealPhotoPicker: UIViewControllerRepresentable {
    var selected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(); config.filter = .images; config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config); picker.delegate = context.coordinator; return picker
    }
    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MealPhotoPicker
        init(_ parent: MealPhotoPicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            results.first?.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage else { return }; DispatchQueue.main.async { self.parent.selected(image) }
            }
        }
    }
}
struct MealDiaryView: View {
    @ObservedObject private var store = WellnessStore.shared
    @State private var day = Date()
    @State private var add = false
    @State private var insights = false
    @State private var editing: MealEntry?
    private var meals: [MealEntry] { store.meals.filter { Calendar.current.isDate($0.date, inSameDayAs: day) } }
    var body: some View {
        ZStack { WellnessBackground(); ScrollView { VStack(alignment: .leading, spacing: 18) {
            DatePicker("Day", selection: $day, displayedComponents: .date)
            Text("\(meals.reduce(0) { $0 + $1.total }) kcal").font(.system(size: 30, weight: .medium))
            Text("Daily total · Confirmed estimates").font(.caption)
            Button { insights = true } label: { Label("Find my food patterns", systemImage: "sparkles") }.font(.subheadline)
            ForEach(meals) { meal in HStack { Button { editing = meal } label: { VStack(alignment: .leading, spacing: 6) { Text(meal.meal).font(.headline); Text(meal.items.map(\.name).joined(separator: ", ")).font(.subheadline); Text("\(meal.total) kcal · Edit estimate").font(.caption) } }.buttonStyle(.plain); Spacer(); Menu { Button("Delete meal", role: .destructive) { store.deleteMeal(meal) } } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) } }.wellnessCard() }
            Button { add = true } label: { Label("Add meal", systemImage: "plus.circle").wellnessCard() }
            Text("Photo and text estimates can be inaccurate. Correct food, portions and calories before confirming. No calorie target is assigned.").font(.footnote).foregroundColor(.black.opacity(0.6))
        }.padding(22) }}.foregroundColor(.black).navigationTitle("Food diary").navigationBarTitleDisplayMode(.inline).navigationBarHidden(false)
            .sheet(isPresented: $insights) { AIChatView(context: store.mealContext(), openingQuestion: "Reflect on my recorded meals. Find practical patterns in variety, meal logging and portions without prescribing a calorie target. Missing logs do not mean skipped meals.") }
            .sheet(isPresented: $add) { MealEntryView(day: day) }
            .sheet(item: $editing) { meal in MealEntryView(day: meal.date, existing: meal) }
    }
}
struct MealEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscription = SubscriptionCenter.shared
    var day: Date
    var existing: MealEntry? = nil
    @State private var meal = "Breakfast"
    @State private var description = ""
    @State private var photo: Data?
    @State private var items: [MealItem] = []
    @State private var picker = false
    @State private var paywall = false
    @State private var busy = false
    @State private var error: String?
    var body: some View {
        NavigationView { ZStack { WellnessBackground(); ScrollView { VStack(alignment: .leading, spacing: 18) {
            HStack { Text("Add meal").font(.system(size: 17, weight: .medium)); Spacer(); Button("Done") { dismiss() } }
            Picker("Meal", selection: $meal) { ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { Text($0) } }
            TextField("What did you eat? Include portions", text: $description).padding(14).background(Color.white.opacity(0.7)).cornerRadius(12)
            Button { picker = true } label: { Label(photo == nil ? "Choose a food photo" : "Photo ready · under 20 KB", systemImage: "camera") }
            if let photo, let image = UIImage(data: photo) { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 160).cornerRadius(12) }
            Button { estimate() } label: { Label("Estimate meal · \(photo == nil ? 1 : 2) credits", systemImage: "sparkles") }.disabled(busy || (description.isEmpty && photo == nil))
            if busy { HStack { Spacer(); AIThinkingOrb(); Spacer() } }
            if !subscription.aiConsent { NavigationLink("Allow AI processing", destination: AIPrivacyView()) }
            if let error { Text(error).font(.footnote) }
            if !items.isEmpty { Text("Review your estimate").font(.headline) }
            ForEach($items) { $item in VStack(alignment: .leading, spacing: 8) {
                TextField("Food", text: $item.name)
                TextField("Portion", text: $item.portion).font(.subheadline)
                HStack { Text("Calories"); TextField("kcal", value: $item.calories, formatter: NumberFormatter()).keyboardType(.numberPad) }
                Button("Remove") { items.removeAll { $0.id == item.id } }.font(.caption)
            }.wellnessCard() }
            Button("Add food manually") { items.append(MealItem(name: "", portion: "", calories: 0)) }
            if !items.isEmpty {
                Text("Total: \(items.reduce(0) { $0 + max(0, $1.calories) }) kcal").font(.headline)
                Button("Confirm & save meal") {
                    guard items.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (0...10000).contains($0.calories) }) else { error = "Give each food a name and valid calories."; return }
                    var entry = existing ?? MealEntry(date: day, meal: meal, description: description, items: items)
                    entry.meal = meal; entry.description = description; entry.items = items
                    WellnessStore.shared.saveMeal(entry); dismiss()
                }.buttonStyle(.borderedProminent).tint(.applazAccent)
            }
            Text("Only confirmed meals enter your daily tally. Photos are sent for this estimate and are not added to the public photo bucket.").font(.caption)
        }.padding(24) }}.foregroundColor(.black).navigationBarHidden(true) }.navigationViewStyle(.stack)
            .onAppear { if let existing { meal = existing.meal; description = existing.description; items = existing.items } }
            .sheet(isPresented: $picker) { MealPhotoPicker { image in photo = ApplazImagePayload.jpeg(from: image); if photo == nil { error = "This image couldn’t be prepared. Please choose another." } } }
            .sheet(isPresented: $paywall) { NavigationView { SubscriptionWelcomeView(onClose: { paywall = false }, onPurchased: { paywall = false }) } }
    }
    private func estimate() {
        guard subscription.hasAppleSubscription else { paywall = true; return }
        busy = true; error = nil
        Task { do {
            let result = try await subscription.ask(question: description, context: "Meal: \(meal). Estimate foods and portions; do not assign a dietary target.", image: photo, meal: true)
            guard let values = result["items"] as? [[String: Any]] else { throw WellnessAPI.failure("No food estimate was returned. Try describing the portions.") }
            items = values.compactMap { item in guard let name = item["name"] as? String, let portion = item["portion"] as? String, let calories = item["calories"] as? Int else { return nil }; return MealItem(name: name, portion: portion, calories: calories) }
        } catch { self.error = error.localizedDescription }; busy = false }
    }
}

struct MealDiarySummary: View {
    @ObservedObject private var store = WellnessStore.shared
    @State private var add = false
    private var today: [MealEntry] { store.meals.filter { Calendar.current.isDateInToday($0.date) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Meals today").font(.system(size: 17, weight: .medium))
                    Text("\(today.reduce(0) { $0 + $1.total }) kcal").font(.system(size: 24, weight: .medium))
                    Text("Confirmed estimates").font(.caption).foregroundColor(.black.opacity(0.55))
                }
                Spacer()
                Button { add = true } label: { Label("Add meal", systemImage: "plus").font(.system(size: 14)).wellnessPill() }.accessibilityIdentifier("NotebookAddMeal")
            }
            if today.isEmpty { Text("Type your food or choose a photo. Review the estimate before adding it to your tally.").font(.subheadline).foregroundColor(.black.opacity(0.6)) }
            ForEach(today) { meal in
                HStack { Text(meal.meal).font(.subheadline); Spacer(); Text("\(meal.total) kcal").font(.subheadline) }
            }
            NavigationLink(destination: MealDiaryView()) { Label("View food diary", systemImage: "chevron.right").font(.subheadline) }
        }.wellnessCard().tint(.applazAccent)
            .sheet(isPresented: $add) { MealEntryView(day: Date()) }
    }
}
