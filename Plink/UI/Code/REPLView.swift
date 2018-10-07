//
//  REPLView.swift
//  REPLView
//
//  Created by acb on 17/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

/**
 A REPLView is an interface element which implements the interface for a Read-Eval-Print Loop (REPL), encapsulated within a NSView subclass.
 */
@IBDesignable
public class REPLView: NSView {
    
    // MARK: the REPL interface
    
    
    /// A possible response from the evaluator
    public enum EvalResponse {
        case output(String) // An output value to be printed
        case error(String) // An error message to be printed
    }
    
    /** The function the REPL calls when the user enters a line of text they wish to have evaluated; this function runs the evaluator process and returns either nothing (if there is no synchronous result to be printed), or a response (containing either output or an error message) */
    public var evaluator: ((String)->(EvalResponse?))?
    
    /* Functions for asynchronously printing output to the console */
    /** Print a response asynchronously. */
    public func println(response: EvalResponse) {
        switch(response) {
        case .output(let line): self.emit(line: line, withColor: self.outputColor)
        case .error(let line): self.emit(line: line, withColor: self.errorColor)
        }
    }
    /** Print an output string asynchronously. */
    public func printOutputLn(_ line: String) { self.println(response: .output(line)) }
    /** Print an error string asynchronously. */
    public func printErrorLn(_ line: String) { self.println(response: .error(line)) }
    /** insert the previous sessions' output into the scrollback window */
    public func outputRestoredScrollback(_ text: String) {
        self.scrollbackTextView.textStorage?.setAttributedString(NSAttributedString())
        self.emit(line: text, withColor: self.restoredScrollbackColor)
        if let delim = self.restoredScrollbackDelimiter {
            self.emit(line: delim, withColor: self.restoredScrollbackColor)
        }
    }

    // MARK: UI configuration
    
    @IBInspectable
    public var backgroundColor: NSColor {
        get {
            return self.scrollView.backgroundColor
        }
        set(v) {
            self.layer?.backgroundColor = v.cgColor
            self.scrollView.backgroundColor = v
            self.scrollbackTextView.backgroundColor = v
            self.inputTextView.backgroundColor = v
        }
    }
    /** An optional background colour for the text input area; if not provided, the background color will be used */
    public var inputBackgroundColor: NSColor? {
        didSet {
            self.inputTextView.backgroundColor = self.inputBackgroundColor ?? self.backgroundColor
        }
    }
    /** The colour for REPL non-error result output */
    @IBInspectable
    public var outputColor: NSColor = .darkGray {
        didSet {
            self.inputTextView.textColor = self.outputColor
            self.inputTextView.insertionPointColor = self.outputColor
        }
    }
    /** The colour for REPL error output */
    @IBInspectable
    public var errorColor: NSColor = .red
    /** The colour for echoes of the user's input, if enabled */
    @IBInspectable
    public var echoColor: NSColor = .lightGray
    
    /** if previous sessions' scrollback is saved as an unattributed string, discarding attributes, this is the colour to restore it with */
    @IBInspectable
    public var restoredScrollbackColor: NSColor = .darkGray
    
    /** text to append to the scrollback immediately after restored text  */
    public var restoredScrollbackDelimiter: String?

    /** A function for formatting a typed line to an echo */
    public var echoFormatter: ((String)->(String))? = { ">>> \($0)" }
    
    /** The maximum number of history lines to save*/
    @IBInspectable
    public var maxHistoryLines: Int = 20
    
    class KeyInterceptingTextView: NSTextView {
        var submitText: ((String)->())?
        var handleSpecialKey: ((SpecialKey)->())?
        
        enum SpecialKey: UInt16 {
            case up = 126
            case down = 125
        }
        
        override func keyDown(with event: NSEvent) {
            if event.keyCode == 36 /* Enter */ && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                self.submitText?(self.string.trimmingCharacters(in: CharacterSet(charactersIn: "\n")))
                self.string = ""
            } else if let specialKey = SpecialKey(rawValue: event.keyCode) {
                self.handleSpecialKey?(specialKey)
            } else {
                super.keyDown(with: event)
            }
        }
        
        override func menu(for event: NSEvent) -> NSMenu? {
            return nil
        }
    }
    
    var scrollView: NSScrollView = NSScrollView()
    var scrollbackTextView: NSTextView = NSTextView()
    var inputTextView: KeyInterceptingTextView = KeyInterceptingTextView()
    
    //MARK: history handling
    var history: [String] = []
    var currentlyEditedLine: String? = nil // the line being entered at the moment, which the user can return to
    // where the user is currently in navigating the history (or not)
    enum HistoryNavigationState: Equatable {
        case currentLine
        case historyItem(Int)
    }
    var historyNavigationState = HistoryNavigationState.currentLine {
        didSet(prev) {
            guard self.historyNavigationState != prev else { return }
            if prev == .currentLine { self.currentlyEditedLine = self.inputTextView.string }
            switch(self.historyNavigationState) {
            case .currentLine: self.inputTextView.string = self.currentlyEditedLine ?? ""
            case .historyItem(let index): self.inputTextView.string = self.history[index]
            }
            self.needsLayout = true
        }
    }
    func addToHistory(line: String) {
        if self.history.count >= self.maxHistoryLines {
            self.history.removeFirst(self.history.count - (self.maxHistoryLines - 1))
        }
        self.history.append(line)
    }
    
    //MARK: -----
    
    @IBInspectable
    var font: NSFont? {
        get {
            return scrollbackTextView.font
        }
        set(v) {
            self.scrollbackTextView.font = v
            self.inputTextView.font = v
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame:frameRect)
        self.configureSubviews()
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.configureSubviews()
    }
    
    private var scrollbackIsAtBottom: Bool {
        let visibleRect = self.scrollView.documentVisibleRect
        let docHeight = self.scrollView.documentView!.frame.size.height
        let distanceFromBottom = docHeight - (visibleRect.origin.y+visibleRect.size.height)
        return distanceFromBottom < self.font?.boundingRectForFont.height ?? 1.0
    }
    
    private func emit(line: String, withColor color: NSColor) {
        let wasAtBottom = self.scrollbackIsAtBottom

        guard let textStorage = self.scrollbackTextView.textStorage else { fatalError("No text storage?!") }
        if !self.scrollbackTextView.string.isEmpty {
            textStorage.append(NSAttributedString(string: "\n"))
        }
        let attStr = NSMutableAttributedString(string: line, attributes: [.foregroundColor : color,
             .font: self.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)])
        textStorage.append(attStr)
        if wasAtBottom {
            self.scrollView.documentView?.scrollToEndOfDocument(nil)
        }
        self.needsLayout = true
    }
    
    private func configureSubviews() {
        self.wantsLayer = true
        self.addSubview(self.scrollView)
        self.scrollView.documentView = self.scrollbackTextView
        self.scrollView.borderType = .noBorder
        self.scrollView.hasVerticalScroller = true
        self.scrollView.autohidesScrollers = true
        self.addSubview(self.inputTextView)
        self.inputTextView.string = ""
        self.inputTextView.delegate = self
        self.inputTextView.submitText = { [weak self] (line) in self?.submitText(line) }
        self.inputTextView.handleSpecialKey = { [weak self] (key) in self?.handleInputSpecialKey(key) }
        self.inputTextView.isAutomaticQuoteSubstitutionEnabled = false
        self.inputTextView.isGrammarCheckingEnabled = false
        self.inputTextView.isAutomaticDashSubstitutionEnabled = false
        self.inputTextView.isAutomaticTextCompletionEnabled = false
        self.inputTextView.isAutomaticDataDetectionEnabled = false
        self.inputTextView.isAutomaticTextReplacementEnabled = false
        self.inputTextView.isAutomaticSpellingCorrectionEnabled = false
        self.inputTextView.isRichText = false
        self.scrollbackTextView.isEditable = false
        
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(self.scrollbackClicked(_:)))
        self.addGestureRecognizer(clickRecognizer)
        
        
        self.backgroundColor = self.scrollView.backgroundColor
        self.needsLayout = true
    }
    
    override public func layout() {
        let wasAtBottom = self.scrollbackIsAtBottom
        super.layout()
        // prime widths of text elements to ensure correct line breaking
        if self.inputTextView.frame.size.width != self.frame.size.width {
            self.inputTextView.frame.size = CGSize(width: self.frame.size.width, height: self.inputTextView.frame.size.height)
        }
        if self.scrollbackTextView.frame.size.width != self.frame.size.width {
            self.scrollbackTextView.frame.size = CGSize(width: self.frame.size.width, height: self.scrollbackTextView.frame.size.height)
        }
        guard let inLayoutManager = inputTextView.layoutManager, let inTextCtr = inputTextView.textContainer else { fatalError(":-P")}
        inLayoutManager.ensureLayout(for: inTextCtr)
        let inTextSize = inLayoutManager.usedRect(for: inTextCtr)
        self.inputTextView.frame = NSRect(x: 0, y: 0, width: self.frame.width, height: ceil(inTextSize.height))
        
        if let layoutManager = self.scrollbackTextView.layoutManager, let textContainer = self.scrollbackTextView.textContainer {
            layoutManager.ensureLayout(for: textContainer)
            let textSize = layoutManager.usedRect(for: textContainer)
            let textHeight = textSize.height
            self.scrollView.frame = NSRect(
                x: 0.0,
                y: self.inputTextView.frame.height,
                width: self.frame.width,
                height: min(
                    self.frame.height - self.inputTextView.frame.height,
                    textHeight))
            self.scrollbackTextView.frame = NSRect(x: 0.0, y: 0.0, width: self.scrollView.frame.width, height: ceil(textHeight))
            if wasAtBottom {
                self.scrollView.documentView?.scrollToEndOfDocument(nil)
            }
        }
    }
    
    @objc func scrollbackClicked(_ sender: Any) {
        self.scrollbackTextView.setSelectedRange(NSMakeRange(0, 0))
        self.window?.makeFirstResponder(self.inputTextView)
    }
    
    func submitText( _ line: String) {
        if let echo = self.echoFormatter?(line) {
            self.emit(line: echo, withColor: self.echoColor)
        }
        if let output = self.evaluator?(line) {
            self.println(response: output)
        }
        self.addToHistory(line: line)
        self.historyNavigationState = .currentLine

    }
    
    func handleInputSpecialKey(_ key: KeyInterceptingTextView.SpecialKey) {
        switch(key) {
        case .up:
            if !self.history.isEmpty {
                switch(self.historyNavigationState) {
                case .currentLine:
                    self.historyNavigationState = .historyItem(self.history.count - 1)
                case .historyItem(let item):
                    if item > 0 {
                        self.historyNavigationState = .historyItem(item - 1)
                    }
                }
            }
        case .down:
            if case let .historyItem(item) = self.historyNavigationState {
                self.historyNavigationState = (item < self.history.count - 1) ? .historyItem(item+1) : .currentLine
            }
        }
    }
}

extension REPLView: NSTextViewDelegate {
    public func textDidChange(_ obj: Notification) {
        self.needsLayout = true
    }
}
