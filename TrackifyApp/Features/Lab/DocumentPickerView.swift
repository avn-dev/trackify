import SwiftUI
import UIKit
import PDFKit
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    var onPick: ([String]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick, onCancel: onCancel) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([String]) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping ([String]) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { onCancel(); return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            onPick(extractPDFText(url: url))
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}

func extractPDFText(url: URL) -> [String] {
    guard let pdf = PDFDocument(url: url) else { return [] }
    var lines: [String] = []
    for i in 0..<pdf.pageCount {
        guard let page = pdf.page(at: i), let text = page.string else { continue }
        lines.append(contentsOf: text.components(separatedBy: .newlines))
    }
    return lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
}
