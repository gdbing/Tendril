import SwiftUI

struct DocumentView: View {
    @StateObject var controller = DocumentController()
    @State private var showAlert = false
    @Binding var document: Document?
    @EnvironmentObject private var settings: Settings

    var body: some View {
        ZStack(alignment: .topTrailing) {
            UIKitDocumentView(controller: controller, 
                              document: $document)
                .toolbar {
                    ToolbarItem  {
                        Button(action: {
                            showAlert.toggle()
                        }, label: {
                            Image(systemName: "figure.wave")
                        })
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("system message"), message: Text(settings.systemMessage), dismissButton: .default(Text("OK")))
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            controller.gptIfy()
                        }, label: {
                            Image(systemName: "bubble.left.fill")
                        })
                        .keyboardShortcut(.return, modifiers: [.command])
                        .disabled(controller.isWriting)
                    }
                }
            if let wordCount = controller.wordCount {
                VStack(alignment: .trailing) {
                    Button(action: {
                        controller.updateWordCount(isEaten: true)
                    }, label: {
                        Text("\(wordCount) words ")
                            .monospacedDigit()
                    })
                    if let time = controller.time {
                        Text(time)
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}

extension DocumentView {   
    struct UIKitDocumentView: UIViewRepresentable {
        var controller: DocumentController
        
        @State private var textView = UITextView()
        @Binding var document: Document?

        @ScaledMetric(relativeTo: .body) var maxWidth = 680

        init(controller: DocumentController, document: Binding<Document?>) {
            self.controller = controller
            _document = document

            let textContentStorage = NSTextContentStorage()
            let textLayoutManager = NSTextLayoutManager()
            textContentStorage.addTextLayoutManager(textLayoutManager)
            let textContainer = NSTextContainer()
            textLayoutManager.textContainer = textContainer
            self.textView = UITextView(frame: CGRect(x: 0, y: 20, width: 300, height: 0), textContainer: textContainer)
        }

        func makeUIView(context: Context) -> UITextView {
            self.controller.textView = textView
            if let document {
                let text = document.readText()
                textView.text = text
                controller.rope = TendrilRope(content: text)
                controller.updateWordCount()
                textView.becomeFirstResponder()
            }
            textView.delegate = context.coordinator
            textView.isScrollEnabled = true
            textView.isEditable = true
            textView.isUserInteractionEnabled = true

            textView.allowsEditingTextAttributes = false
            textView.autocorrectionType = .no
            textView.spellCheckingType = .no
            textView.smartInsertDeleteType = .no
            textView.smartDashesType = .no
            textView.smartQuotesType = .no

            textView.scrollsToTop = true
            textView.backgroundColor = UIColor.systemBackground
            textView.font = UIFont.systemFont(ofSize: 18)

            let layoutManager = textView.textContainer.textLayoutManager
            layoutManager?.delegate = context.coordinator
            let textStorage = layoutManager?.textContentManager as? NSTextContentStorage
            textStorage?.delegate = context.coordinator
            textView.textStorage.delegate = context.coordinator

            return textView
        }
        
        func updateUIView(_ uiView: UITextView, context: Context) {
            self.controller.textView = uiView
            if let document {
                let text = document.readText()
                let greys = document.readGreyRanges()
                if text != uiView.text {
                    controller.rope = TendrilRope()//content:text)
                    let attrText = NSMutableAttributedString(text, greyRanges: greys)
                    uiView.attributedText = attrText
                    controller.updateWordCount()
                    uiView.isEditable = true
                    let topOffset = CGPoint(x: 0, y: 0)
                    uiView.setContentOffset(topOffset, animated: false)
                }
            } else {
                uiView.text = ""
                controller.rope = nil
                uiView.isEditable = false
            }
        }
        
        func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
            if let width = proposal.width {
                let insetSize = width > maxWidth ? ((width - maxWidth) / 2) : 0.0 
                uiView.textContainerInset = UIEdgeInsets(top: 0.0,
                                                         left: insetSize, 
                                                         bottom: 300.0,
                                                         right: insetSize)
            }
            return nil // default behaviour, use proposed size
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UITextViewDelegate {        
            var parent: UIKitDocumentView
            
            init(_ parent: UIKitDocumentView) {
                self.parent = parent
            }
            
            
            func textViewDidChange(_ textView: UITextView) {
                self.parent.document?.write(text: textView.text)
                self.parent.document?.write(greyRanges: textView.attributedText.greyRanges)
            }
            
            func textViewDidChangeSelection(_ textView: UITextView) {
                self.parent.controller.updateWordCount() // this basically catches textViewDidChange too
            }
            
            func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
                textView.setTextColor(.label)
//                textView.setAuthor(nil)
//                print("rope before: \(self.parent.controller.rope?.toString() ?? "")")
//                if range.length > 0 {
//                    self.parent.controller.rope?.delete(range: range)
//                }
//                if !text.isEmpty {
//                    self.parent.controller.rope?.insert(content: text, at: range.location)
//                }
//                print("inserted \"\(text)\" at \(range.location),\(range.length)")
//                print("rope after: \(self.parent.controller.rope?.toString() ?? "")")
                return true
            }        
        }

    }
}

extension DocumentView.UIKitDocumentView.Coordinator : NSTextLayoutManagerDelegate {
    func textLayoutManager(_ textLayoutManager: NSTextLayoutManager,
                           textLayoutFragmentFor location: NSTextLocation,
                           in textElement: NSTextElement) -> NSTextLayoutFragment {
        let offset = textElement.textContentManager!.offset(from: textLayoutManager.documentRange.location, to: location)
        if let node = self.parent.controller.rope?.nodeAt(location: offset) {
            if node.isComment {
                return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
            }
            if node.type == .user {
                return BubbleLayoutFragment(textElement: textElement, range: textElement.elementRange)
            }
            if node.type == .system {
                return BubbleLayoutFragment(textElement: textElement, range: textElement.elementRange, bubbleColor: .systemBubble)
            }
            if node.type == .cache {
                return BubbleLayoutFragment(textElement: textElement, range: textElement.elementRange, bubbleColor: .cacheBubble)
            }
            if node.type == .none && node.blockType == .user {
                return BubbleLayoutFragment(textElement: textElement, range: textElement.elementRange)
            }
            if node.type == .none && node.blockType == .system {
                return BubbleLayoutFragment(textElement: textElement, range: textElement.elementRange, bubbleColor: .systemBubble)
            }
        }

        return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
    }
}

extension DocumentView.UIKitDocumentView.Coordinator : NSTextContentStorageDelegate {
    func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
        let originalText = textContentStorage.textStorage!.attributedSubstring(from: range)
        if let node = self.parent.controller.rope?.nodeAt(location: range.location) {
            if node.type == .cache || node.type == .user || node.type == .system {
                return nil
            }
            if node.isComment || node.type != .none {
                let displayAttributes: [NSAttributedString.Key: AnyObject] = [ .foregroundColor: UIColor.secondaryLabel ]
                let textWithDisplayAttributes = NSMutableAttributedString(attributedString: originalText)
                let rangeForDisplayAttributes = NSRange(location: 0, length: textWithDisplayAttributes.length)
                textWithDisplayAttributes.addAttributes(displayAttributes, range: rangeForDisplayAttributes)
                return NSTextParagraph(attributedString: textWithDisplayAttributes)
            }
        }

        return nil
    }
}

extension DocumentView.UIKitDocumentView.Coordinator: NSTextStorageDelegate {
    
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        if editedMask.contains(.editedCharacters) {
            let deletion = editedRange.length - delta
            if deletion > 0 {
                print("deleted \(editedRange.location),\(deletion)")
                self.parent.controller.rope?.delete(range: NSMakeRange(editedRange.location, deletion))
            }

            if editedRange.length > 0, let range = textStorage.string.range(from: editedRange) {
                let input = textStorage.string[range]
                self.parent.controller.rope?.insert(content: String(input), at: editedRange.location)
                print("inserted \(input) at \(editedRange.location)")
            }

            if let changedBlockRange = self.parent.controller.rope?.updateBlocks(in: editedRange) {
                textStorage.edited(.editedAttributes, range: changedBlockRange, changeInLength: 0)
            }

            print(self.parent.controller.rope?.toString() ?? "🚨")
        }
    }
}


extension UITextView {
    func setTextColor(_ color: UIColor) {
        var attributes = self.typingAttributes
        attributes.updateValue(color, forKey: NSAttributedString.Key.foregroundColor)
        self.typingAttributes = attributes
    }

//    func setAuthor(_ author: String?) {
//        var attributes = self.typingAttributes
//        attributes.updateValue(author ?? "", forKey: NSAttributedString.Key.author)
//        self.typingAttributes = attributes
//    }

    func precedingText() -> String? {
        if let selection = self.selectedTextRange,
           let precedingRange = self.textRange(from: self.beginningOfDocument, to: selection.end),
           let precedingText = self.text(in: precedingRange),
           precedingText.count > 0 {
            return precedingText
        } else {
            return nil
        }
    }
}
