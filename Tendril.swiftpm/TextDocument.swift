import SwiftUI
import UniformTypeIdentifiers

struct TextDocument: FileDocument {    
    var text: String
    
    init(text: String = "") {
        self.text = text
    }
    
    static var readableContentTypes: [UTType] { [.plainText] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

class Appender {
    private var buffer: String = ""
    private var timer: Timer?
        
    func append(_ text: String, interval: TimeInterval = 1.0, reply: @escaping (inout String) -> Void) {
        self.buffer += text

        if self.timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { [self] _ in
                reply(&buffer)
                self.buffer = ""
                self.timer = nil
            })
        }
    }
}
