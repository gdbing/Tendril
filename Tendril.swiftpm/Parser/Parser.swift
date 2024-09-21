import Foundation

protocol Parser {
    func consume(_ input: any StringProtocol) -> (eaten: any StringProtocol, remainder: any StringProtocol)?
}

struct CharacterSequenceParser {
    let sequence: String

    init(_ sequence: String) {
        self.sequence = sequence
    }

    /// Attempts to consume the defined sequence from the beginning of the input string.
    /// - Parameter input: The input string to parse.
    /// - Returns:
    /// If input prefix matches sequence, returns remaining substring
    /// If sequence is not found, returns nil
    func consume(_ input: any StringProtocol) -> (any StringProtocol)? {
        guard input.hasPrefix(sequence) else { return nil }

        return input.suffix(from: input.index(input.startIndex, offsetBy: sequence.count))
    }
}

struct UntilCharacterSequenceParser : Parser {
    let sequences: [String]

    init(_ sequence: String) {
        self.sequences = [sequence]
    }

    init(_ sequences: [String]) {
        self.sequences = sequences
    }

    /// Attempts to consume characters from the input string until the defined sequence is encountered.
    /// - Parameter input: The input string to parse.
    /// - Returns:
    /// If sequence is found, returns tuple of `(eaten: Substring, remainder: Substring)`
    /// where `eaten` is consumed string up to (not including) matched sequence, and `remainder` is the remainder (including matched sequence)
    /// If sequence is not matched, returns nil
    func consume(_ input: any StringProtocol) -> (eaten: any StringProtocol, remainder: any StringProtocol)? {
        for idx in input.indices {
            let remainder = input.suffix(from: idx)

            for sequence in sequences {
                if remainder.hasPrefix(sequence) {
                    return (eaten: input.prefix(upTo: idx), remainder: input.suffix(from: idx))
                }
            }
        }

        return nil
    }
}

struct CharacterSetParser {
    let charSet: CharacterSet

    init(_ charSet: CharacterSet) {
        self.charSet = charSet
    }
    
    /// Consumes prefix which matches init charSet`
    /// - Parameter input: String to be consumed
    /// - Returns:
    /// If a prefix of any length matches `charSet`, returns tuple of `(eaten: Substring, remainder: Substring)` where `eaten` is the consumed sequence, and `remainder` is the remainder
    /// If no chars match, returns nil
    func consume(_ input: any StringProtocol) -> (eaten: any StringProtocol, remainder: any StringProtocol)? {
        guard let first = input.first else { return nil }
        for scalar in first.unicodeScalars {
            if !charSet.contains(scalar) {
                return nil
            }
        }
        for idx in input.indices {
            for scalar in input[idx].unicodeScalars {
                if !charSet.contains(scalar) {
                    return (eaten: input.prefix(upTo: idx), input.suffix(from: idx))
                }
            }
        }
        return (eaten: input, remainder: "")
    }
}

struct RangeParser {
    /// Consume string, emit NSRange
    /// handles "<int1>,<int2>" as `NSRange(location: int1, length: int2)`
    /// or "<int>" as `NSRange(location: int, length: 1)`
    /// - Parameter input: String to be consumed
    /// - Returns: (range: NSRange, remainder: Substring)
    static func consume(_ input: any StringProtocol) -> (range: NSRange, remainder: any StringProtocol)? {
        var remainder = input
        guard let result = CharacterSetParser(.decimalDigits).consume(remainder) else { return nil }
        guard let location = Int(result.eaten) else { return nil }
        remainder = result.remainder

        if remainder.first?.isWhitespace ?? true {
            return (range: NSRange(location: location, length: 1), remainder: remainder)
        }

        if remainder.first != "," {
            return nil
        }
        remainder = remainder.dropFirst()

        guard let result = CharacterSetParser(.decimalDigits).consume(remainder) else { return nil }
        guard let length = Int(result.eaten) else { return nil }
        remainder = result.remainder

        return (range: NSRange(location: location, length: length), remainder: remainder)
    }
}

struct WhitespaceParser {
    let charSet: CharacterSet

    init(includeNewlines: Bool = true) {
        self.charSet = includeNewlines ? .whitespacesAndNewlines : .whitespaces
    }

    /// Consume `.whitespaceAndNewlines`, emit nothing
    /// - Parameter input: String to be consumed
    /// - Returns: remaining Substring following consumed whitespace
    func consume(_ input: any StringProtocol) -> (any StringProtocol)? {
        return CharacterSetParser(charSet).consume(input)?.remainder
    }
}

struct HexParser {
    /// Consume hexidecimal sequence
    /// e.g. a SHA-256 hash
    /// - Parameter input: String to be consumed
    /// - Returns: (hexString: consumed Substring, remainder: Substring)
    static func consume(_ input: any StringProtocol) -> (hexString: any StringProtocol, remainder: any StringProtocol)? {
        guard input.first?.isHexDigit ?? false else { return nil }
        for idx in input.indices {
            if !input[idx].isHexDigit {
                return (hexString: input.prefix(upTo: idx), remainder: input.suffix(from: idx))
            }
        }
        return (hexString: input, remainder: "")
    }
}
