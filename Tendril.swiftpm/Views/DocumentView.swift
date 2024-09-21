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
                    ToolbarItem {
                        ZStack {
                            Button("next section") {
                                self.nextSection()
                            }
                            .keyboardShortcut(.init("j"), modifiers: [.command])
                            Button("prev section") {
                                self.prevSection()
                            }
                            .keyboardShortcut(.init("k"), modifiers: [.command])
                            Button("comment") {
                                self.commentSelection()
                            }
                            .keyboardShortcut(.init("/"), modifiers: [.command])
                        }.hidden()
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
        guard let selection = self.controller.textView?.selectedRange,
              let rope = self.controller.rope,
              let textView = self.controller.textView,
              let firstNode = rope.nodeAt(location: selection.location) else {
            return
        }

        let lastNode = rope.nodeAt(location: selection.location + selection.length)!
        let length = lastNode.location() + lastNode.weight - firstNode.location()

        let belowNewline = lastNode.location() + lastNode.weight
        textView.selectedRange = NSMakeRange(belowNewline, 0)
        if lastNode.hasTrailingNewline {
            textView.insertText("-->\n")
        } else {
            textView.insertText("\n-->")
        }

        let aboveNewline = firstNode.location()
        textView.selectedRange = NSMakeRange(aboveNewline, 0)
        textView.insertText("<!--\n")
        
        let newLocation = aboveNewline + "<!--\n".nsLength
        textView.selectedRange = NSMakeRange(newLocation, length)
    }
    
    private func uncommentSelection() -> Bool {
        // How should this behave?
        guard let selection = self.controller.textView?.selectedRange,
              let rope = self.controller.rope,
              let textView = self.controller.textView,
              let firstNode = rope.nodeAt(location: selection.location)else {
            return false
        }

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
        guard let selection = self.controller.textView?.selectedRange,
              let rope = self.controller.rope,
              let textView = self.controller.textView else {
            return
        }

        var node: TendrilRope.Node? = rope.nodeAt(location: selection.location + selection.length)

        if node?.type == .userColon || node?.type == .systemColon {
            node = node?.next as? TendrilRope.Node
        } else {
            let blockType = node?.blockType
            node = node?.next as? TendrilRope.Node
            while node != nil {
                if node!.blockType != blockType {
                    break
                }
                if blockType == nil &&
                    (node!.type == .userColon || node!.type == .systemColon) {
                    break
                }
                node = node!.next as? TendrilRope.Node
            }
        }

        while node?.content?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            node = node?.next as? TendrilRope.Node
        }

        let range: NSRange
        if let node {
            range = NSMakeRange(node.location(), 0)
        } else {
            range = NSMakeRange(rope.length - 1, 0)
        }
        textView.scrollRangeToVisible(range)
        textView.selectedRange = range
    }

    func prevSection() {
        // option up
        guard let selection = self.controller.textView?.selectedRange,
              let rope = self.controller.rope,
              let textView = self.controller.textView else {
            return
        }

        func isEmpty(node: TendrilRope.Node?) -> Bool {
            return node?.content?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true
            || node?.type == .userBlockOpen
            || node?.type == .systemBlockOpen
        }

        // NB. this will jump to top of the prev section if cursor is above top !empty line
        // e.g. ```user\n(cursor)\n\nsome woooords\n\netc```
        func topNodeOfSection(section: TendrilRope.Node?) -> TendrilRope.Node? {
            guard section != nil else { return nil }

            var node:            TendrilRope.Node? = section
            var topNonEmptyNode: TendrilRope.Node? = !isEmpty(node: node) ? node : nil

            let blockType = node?.blockType
            
            while node != nil, node?.blockType == blockType {
                if blockType == nil &&
                    (node!.type == .userColon || node!.type == .systemColon) {
                    break
                }

                if !isEmpty(node: node) {
                    topNonEmptyNode =  node
                }
                node = node!.prev as? TendrilRope.Node
            }

            return topNonEmptyNode
        }

        // Start from the current location
        var node: TendrilRope.Node? = rope.nodeAt(location: selection.location)
        let node2 = topNodeOfSection(section: node)

        if node === node2 {
            let blockType = node!.blockType
            while node != nil, node?.blockType == blockType {
                node = node!.prev as? TendrilRope.Node
            }
            node = topNodeOfSection(section: node)
        } else {
            node = node2
        }

        let range: NSRange
        if let node {
            range = NSMakeRange(node.location(), 0)
        } else {
            range = NSMakeRange(0, 0)
        }
        textView.scrollRangeToVisible(range)
        textView.selectedRange = range
    }
}
