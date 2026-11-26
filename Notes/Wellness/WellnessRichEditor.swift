import SwiftUI
import UIKit
import RichEditorView

struct WellnessRichEditor: UIViewRepresentable {
    @Binding var html: String
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> RichEditorView {
        let editor = RichEditorView()
        editor.delegate = context.coordinator
        editor.placeholder = "Write a few thoughts…"
        editor.backgroundColor = ApplazAppearance.surface
        editor.webView.isOpaque = false; editor.webView.backgroundColor = .clear
        let toolbar = RichEditorToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.options = [RichEditorDefaultOption.bold, RichEditorDefaultOption.italic, RichEditorDefaultOption.orderedList, RichEditorDefaultOption.unorderedList]
        toolbar.editor = editor; editor.inputAccessoryView = toolbar
        context.coordinator.toolbar = toolbar
        editor.html = html
        return editor
    }
    func updateUIView(_ view: RichEditorView, context: Context) {
        context.coordinator.parent = self
        if view.html != html { view.html = html }
    }
    final class Coordinator: NSObject, RichEditorDelegate {
        var parent: WellnessRichEditor
        var toolbar: RichEditorToolbar?
        init(_ parent: WellnessRichEditor) { self.parent = parent }
        func richEditor(_ editor: RichEditorView, contentDidChange content: String) { if parent.html != content { parent.html = content } }
        func richEditorDidLoad(_ editor: RichEditorView) {
            editor.setFontSize(16)
            editor.runJS("(function(){var s=document.createElement('style');s.textContent='html,body{background:transparent;color:black}#editor{box-sizing:border-box;padding:16px;line-height:1.5}';document.head.appendChild(s)})();")
        }
    }
}
struct WellnessNotePhotos: View {
    @ObservedObject private var store = WellnessStore.shared
    var notebookID: String
    var noteID: String
    @State private var picker = false
    @State private var error: String?
    private var photos: [String] { store.notebooks.first { $0.id == notebookID }?.notes.first { $0.id == noteID }?.attachments ?? [] }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { picker = true } label: { Label("Add photo", systemImage: "photo") }.font(.subheadline)
            ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(Array(photos.enumerated()), id: \.offset) { index, encoded in
                if let data = Data(base64Encoded: encoded), let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill().frame(width: 110, height: 110).clipped().cornerRadius(12).contextMenu { Button("Remove photo", role: .destructive) { update { $0.remove(at: index) } } } }
            } } }
            if let error { Text(error).font(.caption) }
        }.sheet(isPresented: $picker) { MealPhotoPicker { image in
            guard let data = ApplazImagePayload.jpeg(from: image) else { error = "This photo couldn’t be prepared. Please choose another."; return }
            let used = store.notebooks.flatMap { $0.notes }.flatMap { $0.attachments ?? [] }.reduce(0) { $0 + (Data(base64Encoded: $1)?.count ?? 0) }
            guard used + data.count <= 500_000 else {
                CloudSaveWarning.report(WellnessAPI.failure("Photo storage is full."), key: "photo-picker", savedLocally: true)
                return
            }
            CloudSaveWarning.recovered("photo-picker")
            update { $0.append(data.base64EncodedString()) }
        } }
    }
    private func update(_ edit: (inout [String]) -> Void) {
        guard var n = store.notebooks.first(where: { $0.id == notebookID }), let i = n.notes.firstIndex(where: { $0.id == noteID }) else { return }
        var value = n.notes[i].attachments ?? []; edit(&value); n.notes[i].attachments = value; store.update(n)
    }
}
