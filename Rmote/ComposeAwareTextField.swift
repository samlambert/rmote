import AppKit
import SwiftUI

struct ComposeAwareTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onCommittedTextChange: (String) -> Void
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: text)
        field.placeholderString = placeholder
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.textColor = .white
        field.delegate = context.coordinator
        DispatchQueue.main.async { [weak field, coordinator = context.coordinator] in
            guard !coordinator.isAutofocusCancelled,
                  let field,
                  let window = field.window,
                  field.superview != nil,
                  window.isVisible else {
                return
            }
            NSApp.activate(ignoringOtherApps: true)
            window.makeFirstResponder(field)
        }
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.parent = self
        nsView.placeholderString = placeholder
        if nsView.currentEditor() == nil, nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    static func dismantleNSView(_ nsView: NSTextField, coordinator: Coordinator) {
        coordinator.isAutofocusCancelled = true
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ComposeAwareTextField
        var isAutofocusCancelled = false

        init(_ parent: ComposeAwareTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            let fullText = field.stringValue
            parent.text = fullText
            if let editor = field.currentEditor() as? NSTextView, editor.hasMarkedText() {
                return
            }
            parent.onCommittedTextChange(fullText)
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if textView.hasMarkedText() {
                    return false
                }
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}
