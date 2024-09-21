import Foundation

struct HashAnnotationParser {
    static func consume(_ input: any StringProtocol) -> (annotation: HashAnnotation, remainder: any StringProtocol)? {
        var remainder = input

        remainder = WhitespaceParser().consume(remainder) ?? remainder

        guard let result = CharacterSequenceParser("Annotations:").consume(remainder) else {
            return nil
        }
        remainder = result

        remainder = WhitespaceParser(includeNewlines: false).consume(remainder) ?? remainder

        guard let result = RangeParser.consume(remainder) else {
            return nil
        }
        let range = result.range
        remainder = result.remainder

        remainder = WhitespaceParser(includeNewlines: false).consume(remainder) ?? remainder

        guard let result = CharacterSequenceParser("SHA-256").consume(remainder) else {
            return nil
        }
        remainder = result

        remainder = WhitespaceParser(includeNewlines: false).consume(remainder) ?? remainder

        guard let result = HexParser.consume(remainder),
              result.hexString.count >= 32,
              result.hexString.count <= 64
        else {
            return nil
        }
        let hashString = String(result.hexString)
        remainder = result.remainder

        return (annotation: HashAnnotation(range: range, hashString: hashString), remainder: remainder)
    }
}
