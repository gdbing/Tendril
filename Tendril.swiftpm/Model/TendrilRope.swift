//
//  ParagraphRope.swift
//  IantheTests
//
//  Created by Graham Bing on 2024-09-04.
//

import Foundation

class TendrilRope {
    class Node: LeafNode {
        /// weight, left, and right are the bare minimum requirements of a rope node
        var weight: Int = 0
        var left: Node? {
            didSet { left?.parent = self }
        }
        var right: Node? {
            didSet { right?.parent = self}
        }

        /// storing content isn't actually required but we might change our minds later, and it makes debugging easier
        /// removing all those text manipulations could be a nice little performance boost, if we cared we could wrap them in macros
        var content: String? {
            didSet {
                guard let content  else { return }

                let newType = NodeParser.consume(content)
                if newType != self.type {
                    self.type = newType
                    self.updateBlock()
                }
            }
        }

        /// pointers to cousins create a linked list of leafs
        /// twice as fast `toString`
        /// see LeafLinkedList or LeafNode
//        var next: Node?
//        var prev: Node?

        /// a ref to parent allows us to efficiently `bubbleUp` weight when it is added from a cousin
        private var parent: Node?

        /// currently all nodes have trailing newlines except the last one, which might not
        var hasTrailingNewline: Bool = true

        override init() { }
        init(_ content: String) {
            self.content = content
            self.weight = content.nsLength
            self.hasTrailingNewline = content.last == "\n"

            super.init()

            self.type = NodeParser.consume(content)
        }

        func nodeAt(offset:Int) -> Node? {
            if left == nil && offset < weight {
                return self
            }

            if offset < weight {
                return left?.nodeAt(offset: offset)
            }

            return right?.nodeAt(offset: offset - weight)
        }

        override func leafToBranch() {
            self.content = nil
            super.leafToBranch()
        }

        func insert(content: String, at offset: Int, hasTrailingNewline: Bool) {
            if offset == self.weight, !self.hasTrailingNewline
            {
                self.weight += content.nsLength
                self.content! += content
                self.hasTrailingNewline = hasTrailingNewline
            }
            else if offset == 0
            {
                if let left {
                    weight += content.nsLength
                    left.insert(content: content, at: 0, hasTrailingNewline: hasTrailingNewline)
                } else {
                    if hasTrailingNewline {
                        self.right = Node()
                        self.left = Node()

                        self.right!.weight = self.weight
                        self.right!.prev = self.left
                        self.right!.next = self.next
                        self.next?.prev = self.right
                        self.right!.content = self.content

                        self.left!.weight = content.nsLength
                        self.left!.next = self.right
                        self.left!.prev = self.prev
                        self.prev?.next = self.left
                        self.left!.content = content

                        self.leafToBranch()
                        self.weight = content.nsLength
                    } else {
                        self.content = content + self.content!
                        self.weight = content.nsLength + self.weight
                    }
                }
            }
            else if offset < weight
            {
                if let left {
                    self.weight += content.nsLength
                    left.insert(content: content, at: offset, hasTrailingNewline: hasTrailingNewline)
                } else {
                    let offsetIndex = self.content!.index(self.content!.startIndex, offsetBy: offset)
                    if hasTrailingNewline {
                        let subString1 = self.content!.prefix(upTo: offsetIndex)
                        let subString2 = self.content!.suffix(from: offsetIndex)
                        self.content = subString1 + content
                        self.weight = self.content!.nsLength
                        self.insert(content: String(subString2), at: self.weight, hasTrailingNewline: true)
                    } else {
                        self.weight += content.nsLength
                        self.content!.insert(contentsOf: content, at: offsetIndex)
                    }
                }
            }
            else
            {
                if let right {
                    right.insert(content: content, at: offset - weight, hasTrailingNewline: hasTrailingNewline)
                } else {
                    self.left = Node()
                    self.right = Node()

                    self.left!.content = self.content
                    self.left!.weight = self.weight
                    self.left!.prev = self.prev
                    self.prev?.next = self.left
                    self.left!.next = self.right
                    self.left!.updateBlock()

                    self.right!.content = content
                    self.right!.weight = content.nsLength
                    self.right!.prev = self.left
                    self.right!.next = self.next
                    self.next?.prev = self.right
                    self.right!.updateBlock()

                    self.right!.hasTrailingNewline = hasTrailingNewline

                    self.leafToBranch()
                }
            }

            self.balance()
        }

        private func bubbleUp(_ addedWeight: Int) {
            self.weight += addedWeight

            if self.parent?.left === self {
                self.parent!.bubbleUp(addedWeight)
            }
        }

        func delete(range: NSRange) -> Node? {
            return delete(location: range.location, length:range.length)
        }

        func delete(location: Int, length: Int) -> Node? {
            guard length > 0 else { return self }

            if let content = self.content {
                let prefixIndex = content.charIndex(byteIndex: location)
                let prefix = content.prefix(upTo: prefixIndex ?? content.startIndex)
                let suffixIndex = content.charIndex(byteIndex: location + length)
                let suffix = content.suffix(from: suffixIndex ?? content.endIndex)
                if !suffix.isEmpty {
                    self.content = String(prefix + suffix)
                    self.weight = self.content!.nsLength
                    return self
                } else if !prefix.isEmpty {
                    if let next = self.next {
                        next.prev = self.prev
                        self.prev?.next = next
                        (next as! Node).content = prefix + (next as! Node).content!
                        (next as! Node).bubbleUp(location)
                        return nil
                    } else {
                        // only terminal node may end without newline
                        self.content = String(prefix)
                        self.weight = location
                        return self
                    }
                } else { /// delete the whole node
                    self.prev?.next = self.next
                    self.next?.prev = self.prev
                    self.next?.updateBlock()
                    return nil
                }
            }

            if location + length > weight {
                if location > weight {
                    self.right = self.right?.delete(location: location - weight, length: length)
                } else {
                    self.right = self.right?.delete(location: 0, length: location + length - weight)
                }
            }

            if location < weight {
                self.left = self.left?.delete(location: location, length: min(length, weight - location))
                self.weight -= min(length, weight - location)
            }

            if self.left == nil {
                return self.right
            }

            if self.right == nil {
                return self.left
            }

            self.balance()

            return self
        }

        /// Twice as fast as the original naive DFS search!
        /// Which makes sense because leaves are ~half of the nodes
        /// So skipping most non-leaf branches means skipping almost half the nodes
        func toString() -> String {
            var node: Node? = self
            while node?.left != nil {
                node = node!.left!
            }
            var output = ""
            while node != nil {
                output += "Node( "
                output += node!.blockType == .user ? "usr " : node!.blockType == .system ? "sys " : "    "
                output += node!.content!
                output += " ),"
                node = (node!.next as? Node)
            }
            return output
        }

        /// Linked list together the leaves of a rope
        /// Used when a tree is created with `parse`, instead of `insert`ing each leaf
        func link() -> (leftMost: Node, rightMost: Node) {
            var leftLeaf = self
            var rightLeaf = self
            var leftRight: Node?

            self.next = nil
            self.prev = nil

            if let leftEdges = self.left?.link() {
                leftLeaf = leftEdges.leftMost
                leftRight = leftEdges.rightMost
            }

            if let rightEdges = self.right?.link() {
                rightLeaf = rightEdges.rightMost

                let rightLeft = rightEdges.leftMost
                rightLeft.prev = leftRight
                leftRight?.next = rightLeft
            }

            return (leftLeaf, rightLeaf)
        }

        func height() -> Int {
            let leftHeight = left?.height() ?? 0
            let rightHeight = right?.height() ?? 0
            return max(leftHeight, rightHeight) + 1
        }

        /// Basic AVL balance function
        private func balance() {
            let balanceFactor = (left?.height() ?? 0) - (right?.height() ?? 0)
            if balanceFactor > 1 {
                if let left, (left.left?.height() ?? 0) < (left.right?.height() ?? 0) {
                    left.leftRotate()
                }
                rightRotate()
            } else if balanceFactor < -1 {
                if let right, (right.right?.height() ?? 0) < (right.left?.height() ?? 0) {
                    right.rightRotate()
                }
                leftRotate()
            }
        }

        /// NB: rotate should never involve leafs, don't worry about content
        private func leftRotate() {
            let newLeft = Node()
            newLeft.weight = self.weight
            newLeft.left = left
            newLeft.right = self.right!.left
            self.left = newLeft

            self.weight += self.right!.weight
            self.right = self.right!.right
        }

        private func rightRotate() {
            let newRight = Node()
            newRight.left = self.left!.right
            newRight.weight = self.weight - self.left!.weight
            newRight.right = self.right
            self.right = newRight

            self.weight = left!.weight
            self.left = left!.left
        }

        /// Take advantage of the fact that text nodes are already ordered
        /// almost 100x as fast as naively inserting each paragraph of moby dick
        static func parse<C: Collection>(paragraphs: C) -> (node: Node, weight: Int)? where C.Element == String {
            guard !paragraphs.isEmpty else { return nil }

            if paragraphs.count == 1 {
                return (Node(paragraphs.first! + "\n"), paragraphs.first!.count + 1)
            }

            if paragraphs.count == 2 {
                let node = Node()
                node.weight = paragraphs.first!.nsLength + 1
                node.left = Node(paragraphs.first! + "\n")
                let secondIndex = paragraphs.index(after: paragraphs.startIndex)
                node.right = Node(paragraphs[secondIndex] + "\n")
                return (node, node.weight + node.right!.weight)
            }

            let midIdx = paragraphs.index(paragraphs.startIndex, offsetBy: paragraphs.count / 2)

            let left = parse(paragraphs: paragraphs[..<midIdx])
            let right = parse(paragraphs: paragraphs[midIdx...])
            let node = Node()
            node.left = left?.node
            node.right = right?.node
            node.weight = left!.weight

            return (node, left!.weight + right!.weight)
        }

        /// offset is guaranteed to align with node widths
        func combine(rope: Node, at offset: Int) {
            if offset < self.weight {
                if let left {
                    left.combine(rope: rope, at: offset)
                    self.weight += rope.weight
                } else {
                    self.right = Node()
                    self.right!.content = self.content
                    self.right!.weight = self.weight

                    self.left = rope
                    self.weight = rope.weight
                }
            } else {
                self.right?.combine(rope: rope, at: offset - self.weight)
            }
            self.balance()
        }
    }

    var root: Node = Node("")

    init() { }

    init(content: String) {
        guard !content.isEmpty else { return }

        var paragraphs = content.components(separatedBy: .newlines)

        var lastParagraph: String?
        if content.last != "\n" {
            lastParagraph = paragraphs.last
            paragraphs = paragraphs.dropLast()
        }

        if let (root, weight) = Node.parse(paragraphs: paragraphs) {
            let _ = root.link()
            if let lastParagraph {
                root.insert(content: lastParagraph, at: weight, hasTrailingNewline: false)
            }
            var head = root
            while head.left != nil {
                head = head.left!
            }
            head.updateBlock(updateAll: true)
            self.root = root
        }
    }

    func nodeAt(location: Int) -> Node? {
        return self.root.nodeAt(offset: location)
    }

    func insert(content: String, at offset: Int) {
        guard content.count > 0 else {
            print("ERROR: ParagraphRope insert \"\"")
            return
        }

        var relativeOffset = offset
        var remainder: any StringProtocol = content
        var idx = remainder.startIndex
        while idx != remainder.endIndex {
            var hasTrailingNewline = true
            if let newLineIdx = remainder.firstIndex(of: "\n") {
                idx = remainder.index(newLineIdx, offsetBy: 1)
            } else {
                idx = remainder.endIndex
                hasTrailingNewline = false
            }
            let s = String(remainder.prefix(upTo: idx))
            root.insert(content: s, at: relativeOffset, hasTrailingNewline: hasTrailingNewline)
            remainder = remainder.suffix(from: idx)
            relativeOffset += s.nsLength
        }
    }

    func delete(range: NSRange) {
        self.root = root.delete(range: range) ?? Node("")
    }

    func toString() -> String {
        return root.toString()
    }
}
