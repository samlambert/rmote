import AppKit
import SwiftUI
import XCTest
@testable import TVRemote

final class ComposeAwareTextFieldTests: XCTestCase {

    func testTextChangeWithMarkedTextUpdatesBindingWithoutCommitting() {
        var boundText = ""
        var committedValues: [String] = []
        let coordinator = makeCoordinator(
            text: Binding(get: { boundText }, set: { boundText = $0 }),
            onCommittedTextChange: { committedValues.append($0) }
        )
        let (window, textField) = makeHostedTextField(string: "ad")
        defer { window.close() }

        guard let editor = textField.currentEditor() as? NSTextView else {
            XCTFail("Expected a real NSTextView field editor")
            return
        }
        editor.setMarkedText(
            "X",
            selectedRange: NSRange(location: 0, length: 1),
            replacementRange: NSRange(location: 1, length: 0)
        )
        XCTAssertTrue(editor.hasMarkedText())

        coordinator.controlTextDidChange(
            Notification(name: NSControl.textDidChangeNotification, object: textField)
        )

        XCTAssertEqual(boundText, textField.stringValue)
        XCTAssertTrue(committedValues.isEmpty)
    }

    func testTextChangeWithoutMarkedTextCommitsFullValue() {
        var boundText = ""
        var committedValues: [String] = []
        let coordinator = makeCoordinator(
            text: Binding(get: { boundText }, set: { boundText = $0 }),
            onCommittedTextChange: { committedValues.append($0) }
        )
        let (window, textField) = makeHostedTextField(string: "hello")
        defer { window.close() }

        guard let editor = textField.currentEditor() as? NSTextView else {
            XCTFail("Expected a real NSTextView field editor")
            return
        }
        XCTAssertFalse(editor.hasMarkedText())

        coordinator.controlTextDidChange(
            Notification(name: NSControl.textDidChangeNotification, object: textField)
        )

        XCTAssertEqual(boundText, "hello")
        XCTAssertEqual(committedValues, ["hello"])
    }

    func testInsertNewlineWithMarkedTextDoesNotSubmit() {
        var submitCount = 0
        let field = ComposeAwareTextField(
            text: .constant(""),
            placeholder: "",
            onCommittedTextChange: { _ in },
            onSubmit: { submitCount += 1 }
        )
        let coordinator = field.makeCoordinator()
        let control = NSTextField()
        let textView = NSTextView()
        textView.setMarkedText(
            "あ",
            selectedRange: NSRange(location: 0, length: 1),
            replacementRange: NSRange(location: NSNotFound, length: 0)
        )

        let handled = coordinator.control(
            control,
            textView: textView,
            doCommandBy: #selector(NSResponder.insertNewline(_:))
        )

        XCTAssertTrue(textView.hasMarkedText())
        XCTAssertFalse(handled)
        XCTAssertEqual(submitCount, 0)
    }

    func testInsertNewlineWithoutMarkedTextSubmits() {
        var submitCount = 0
        let field = ComposeAwareTextField(
            text: .constant(""),
            placeholder: "",
            onCommittedTextChange: { _ in },
            onSubmit: { submitCount += 1 }
        )
        let coordinator = field.makeCoordinator()
        let control = NSTextField()
        let textView = NSTextView()

        let handled = coordinator.control(
            control,
            textView: textView,
            doCommandBy: #selector(NSResponder.insertNewline(_:))
        )

        XCTAssertFalse(textView.hasMarkedText())
        XCTAssertTrue(handled)
        XCTAssertEqual(submitCount, 1)
    }

    private func makeCoordinator(
        text: Binding<String>,
        onCommittedTextChange: @escaping (String) -> Void
    ) -> ComposeAwareTextField.Coordinator {
        let field = ComposeAwareTextField(
            text: text,
            placeholder: "",
            onCommittedTextChange: onCommittedTextChange,
            onSubmit: {}
        )
        return field.makeCoordinator()
    }

    private func makeHostedTextField(string: String) -> (NSWindow, NSTextField) {
        let textField = NSTextField(string: string)
        textField.frame = NSRect(x: 8, y: 8, width: 200, height: 24)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 40),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView?.addSubview(textField)
        window.makeKeyAndOrderFront(nil)
        XCTAssertTrue(
            window.makeFirstResponder(textField),
            "Expected the hosted text field to become first responder"
        )
        return (window, textField)
    }
}
