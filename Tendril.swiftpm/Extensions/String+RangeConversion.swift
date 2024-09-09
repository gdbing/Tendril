import Foundation

extension String {
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        
        return from ..< to
    }

    func nsRange(from range: Range<String.Index>) -> NSRange? {
        guard 
            let from = range.lowerBound.samePosition(in: utf16),
            let to = range.upperBound.samePosition(in: utf16)
        else { return nil }

        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                       length: utf16.distance(from: from, to: to))
    }

    func byteRange(charRange: NSRange) -> NSRange? {
        guard charRange.upperBound <= count else { return nil }
        
        let lowerBound = index(startIndex, offsetBy: charRange.lowerBound)
        let upperBound = index(startIndex, offsetBy: charRange.upperBound)
        let siRange: Range<String.Index> = lowerBound ..< upperBound
        return nsRange(from: siRange)
    }

    func charRange(byteRange: NSRange) -> NSRange? {
        guard let siRange: Range<String.Index> = range(from: byteRange) else {
            return nil
        }
        let location = distance(from: startIndex, to: siRange.lowerBound)
        let length = distance(from: siRange.lowerBound, to: siRange.upperBound)
        return NSRange(location: location, length: length)
    }

    public func charIndex(byteIndex: Int) -> String.Index? {
        guard let index16 = utf16.index(utf16.startIndex, offsetBy: byteIndex, limitedBy: utf16.endIndex)
        else { return nil }

        return String.Index(index16, within: self)
    }

    public func byteIndex(charIndex: String.Index) -> Int? {
        guard
            let from = charIndex.samePosition(in: utf16)
        else { return nil }

        return utf16.distance(from: utf16.startIndex, to: from)
    }
}

extension String {
//    @inline(__always)
//    var _indexOfLastCharacter: Index {
//      guard !isEmpty else { return endIndex }
//      return index(before: endIndex)
//    }
//
//    @inline(__always)
//    func _index(at offset: Int) -> Index {
//      self.index(self.startIndex, offsetBy: offset)
//    }
//
//    @inline(__always)
//    func _utf8Index(at offset: Int) -> Index {
//      self.utf8.index(startIndex, offsetBy: offset)
//    }
//
//    @inline(__always)
//    func _utf8ClampedIndex(at offset: Int) -> Index {
//      self.utf8.index(startIndex, offsetBy: offset, limitedBy: endIndex) ?? endIndex
//    }
//
//    @inline(__always)
//    func _utf8Offset(of index: Index) -> Int {
//      self.utf8.distance(from: startIndex, to: index)
//    }
//
//    public func index(offsetBy distance: Int) -> String.Index {
//        return self.index(self.startIndex, offsetBy: distance)
//    }

    var nsLength: Int {
        (self as NSString).length
    }
}
