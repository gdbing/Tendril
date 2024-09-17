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
//                            self.nextSection()
                            self.commentSelection()
//                            showAlert.toggle()
                        }, label: {
                            Image(systemName: "figure.wave")
                        })
                        .hidden()
                        .keyboardShortcut(.init("/"), modifiers: [.command])
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

                    if self.controller.tokenInput > 0, self.controller.tokenOutput > 0 {
                        Text("✏️ \(self.controller.tokenInput)")
                            .monospacedDigit()
                        Text("🤖 \(self.controller.tokenOutput)")
                            .monospacedDigit()
                    }
                    if let time = controller.time, time > 0 {
                        let cacheWriteString = self.controller.cacheTokenWrite > 0 ? "\(self.controller.cacheTokenWrite) → " : ""
                        let cacheReadString = self.controller.cacheTokenRead > 0 ? " → \(self.controller.cacheTokenRead)" : ""
                        Text("\(cacheWriteString)💾\(cacheReadString)")

                        let minutes = Int(time) / 60
                        let seconds = Int(time) % 60
                        let timeString = String(format: "%d:%02d", minutes, seconds)
                        Text(timeString)
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}

extension DocumentView {
    func commentSelection() {
        if self.uncommentSelection() {
            return
        }
        // This could be "smarter" but to what end?
        guard let selection = self.controller.textView?.selectedRange, let rope = self.controller.rope, let textView = self.controller.textView else { 
            return 
        }

        let firstNode = rope.nodeAt(location: selection.location)!
        let lastNode = rope.nodeAt(location: selection.location + selection.length)!
        let length = lastNode.location() + lastNode.weight - firstNode.location()

        let belowNewline = lastNode.location() + lastNode.weight
        textView.selectedRange = NSMakeRange(belowNewline, 0)
        textView.insertText("-->\n")

        let aboveNewline = firstNode.location()
        textView.selectedRange = NSMakeRange(aboveNewline, 0)
        textView.insertText("<!--\n")
        
        let newLocation = aboveNewline + "<!--\n".nsLength
        textView.selectedRange = NSMakeRange(newLocation, length)
    }
    
    private func uncommentSelection() -> Bool {
        // How should this behave?
        guard let selection = self.controller.textView?.selectedRange, let rope = self.controller.rope, let textView = self.controller.textView else {
            return false
        }

        let firstNode = rope.nodeAt(location: selection.location)!
        if firstNode.isComment {
            var openNode: TendrilRope.Node = firstNode
            while openNode.type != .commentOpen || openNode.prev?.isComment == true {
                openNode = openNode.prev as! TendrilRope.Node
            }
            var closeNode: TendrilRope.Node? = firstNode
            while closeNode != nil && closeNode!.type != .commentClose {
                closeNode = closeNode?.next as? TendrilRope.Node
            }

            let openNodeLocation = openNode.location()
            let openNodeWeight = openNode.weight
            let selectionLength = (closeNode != nil ? closeNode!.location() - 1 : textView.text.nsLength) - (openNodeLocation + openNodeWeight)
            if let closeNode {
                let closeNodeSelection = NSMakeRange(closeNode.location(), closeNode.weight)
                textView.selectedRange = closeNodeSelection
                textView.insertText("")
            }
            textView.selectedRange = NSMakeRange(openNodeLocation, openNodeWeight)
            textView.insertText("")

            textView.selectedRange = NSMakeRange(openNodeLocation, selectionLength)

            return true
        }

        return false
    }
    
    func nextSection() {
        // option down
        guard let selection = self.controller.textView?.selectedRange, let rope = self.controller.rope, let textView = self.controller.textView else { 
            return 
        }
        
        var node: TendrilRope.Node? = rope.nodeAt(location: selection.location)!
        let isComment = node!.isComment
        let blockType = node!.blockType
        if node!.next != nil {
            node = node!.next as? TendrilRope.Node
        }
        while node!.next != nil {
            if node!.isComment != isComment || 
                node!.blockType != blockType ||
                node?.type == .user ||
                node?.type == .system ||
                node?.type == .cache {
                textView.selectedRange = NSMakeRange(node!.location(), 0)
//                textView.scrollRangeToVisible(NSMakeRange(node!.location(), 0))
                return
            }
            
            node = node!.next as? TendrilRope.Node
        }
        textView.selectedRange = NSMakeRange(node!.location() + node!.weight, 0)
//        textView.scrollRangeToVisible(NSMakeRange(node!.location() + node!.weight, 0))
    }
    
    func prevSection() {
        // option up
        
    }
}
