//
//  LeafLinkedList.swift
//  IantheTests
//
//  Created by Graham Bing on 2024-09-08.
//

import Foundation

class LeafNode {
    enum NodeType {
        case cache           // <CACHE/>\n, <CACHE />\n, <cache/>\n
        case user            // user: ...\n
        case system          // system: ...\n
        case commentOpen     // <!--
        case commentClose    // -->\n
        case userBlockOpen   // ```user\n
        case systemBlockOpen // ```system\n
        case blockClose      // ```\n
    }
    enum BlockType {
        case user
        case system
    }
    var type: NodeType?
    var blockType: BlockType?
    var isComment: Bool = false
    var next: LeafNode?
    var prev: LeafNode?

    func leafToBranch() {
        self.type = nil
        self.blockType = nil
        self.isComment = false
        self.next = nil
        self.prev = nil
    }

    /// returns whether block changed
    func updateBlock() -> Bool {
        let wasComment = self.isComment
        let wasBlockType = self.blockType

        self.isComment = self.prev?.isComment ?? false
        self.blockType = self.prev?.blockType

        if self.type == .commentOpen {
            self.isComment = true
        }
        if self.isComment {
            if self.type == .commentClose {
                self.isComment = false
            } else {
                return wasComment != self.isComment || wasBlockType != self.blockType
            }
        }

        if self.blockType == nil {
            if self.type == .userBlockOpen {
                self.blockType = .user
            }
            if self.type == .systemBlockOpen {
                self.blockType = .system
            }
        } else if self.type == .blockClose {
            self.blockType = nil
        }

        return wasComment != self.isComment || wasBlockType != self.blockType
    }
}

struct NodeParser {
    static func consume(_ input: any StringProtocol) -> LeafNode.NodeType? {
//    case cache           // <CACHE/>\n, <CACHE />\n, <cache/>\n
//    case user            // user: ...\n
//    case system          // system: ...\n
//    case commentOpen     // <!--
//    case commentClose    // -->\n
//    case userBlockOpen   // ```user\n
//    case systemBlockOpen // ```system\n
//    case blockClose      // ```\n
        if input.hasPrefix("<CACHE") {
            return .cache
        }
        if input.hasPrefix("user:") {
            return .user
        }
        if input.hasPrefix("system:") {
            return .system
        }
        if input.hasPrefix("<!--") {
            return .commentOpen
        }
        if input.hasPrefix("-->") {
            return .commentClose
        }
        if input.hasPrefix("```user") {
            return .userBlockOpen
        }
        if input.hasPrefix("```system") {
            return .systemBlockOpen
        }
        if input.hasPrefix("```") {
            return .blockClose
        }

        return nil
    }
}
