import Foundation

internal final class ConsoleIO {

    // MARK: Properties
    // Private
    private let bufferSize: Int
    private let buffer: UnsafeMutablePointer<Int8>!

    internal init() {
        bufferSize = Int(MAXPATHLEN)
        buffer = UnsafeMutablePointer<Int8>.allocate(capacity: bufferSize)
    }

    deinit {
        buffer.deallocate(capacity: bufferSize)
    }

    // MARK:
    internal func printPrompt() {
        let cwd = currentWorkingDirectory ?? "<lookup failed>"
        print(cwd + " $>", terminator: "")
    }

    private var currentWorkingDirectory: String? {
        if getcwd(buffer, bufferSize) == nil {
            return nil
        } else {
            return String(cString: buffer!)
        }
    }

    internal func readCommand() -> (command: String, arguments: [CommandArgument])? {
        // https://developer.apple.com/documentation/swift/1641199-readline
        guard let line = readLine(strippingNewline: true) else {
            return nil
        }

        let separators = CharacterSet(charactersIn: " \t\r\n")
        let tokens = line.components(separatedBy: separators).filter { !$0.isEmpty }
        guard tokens.count > 0 else { return nil }

        return (command: tokens[0], arguments: Array(tokens[1...]))
    }

}
