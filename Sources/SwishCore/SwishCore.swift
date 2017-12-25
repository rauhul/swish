// 2107®©™🔥🔥🔥🔥🔥🔥

import Foundation

public final class SwishCore {

    public enum SwishCoreError: Error { }

    public let description = "Swish Core"

    public init() { }

    public func run() throws {
        var shouldExit = false
        repeat {
            print("$> ", terminator: "")

            // https://developer.apple.com/documentation/swift/1641199-readline
            guard let line = readLine(strippingNewline: true) else {
                shouldExit = true
                continue
            }

            let separators = CharacterSet(charactersIn: " \t\r\n")
            let tokens = line.components(separatedBy: separators).filter { !$0.isEmpty }
            guard tokens.count > 0 else { continue }

            // FIXME: get command from CommandParser

        } while !shouldExit
    }
}
