import Foundation
import Rainbow

internal final class ConsoleIO {

    // MARK: Properties
    // internal
    internal var promptComponents: [PromptComponent]

    // Private
    private let bufferSize: Int
    private let buffer: UnsafeMutablePointer<Int8>!

    internal init() {
        bufferSize = Int(MAXPATHLEN)
        buffer = UnsafeMutablePointer<Int8>.allocate(capacity: bufferSize)

        promptComponents = [
            .text("Swish:"),
            .time,
            .user(fallback: "UnknownUser", followedByHost: true),
            .host(fallback: "UnknownHost"),
            .currentWorkingDirectory(fallback: nil),
            .formatting("\n"),
            .terminator("≫"),
        ]
    }

    deinit {
        buffer.deallocate(capacity: bufferSize)
    }

    // MARK: Prompt
    internal enum PromptComponent {
        case text(String)
        case formatting(String)
        case time
        case user(fallback: String?, followedByHost: Bool)
        case host(fallback: String?)
        case currentWorkingDirectory(fallback: String?)
        case terminator(String)
    }

    internal func printPrompt() {
        var prompt = ""
        var exitEarly = false
        for component in promptComponents {
            switch component {
            case .text(let text):
                prompt += text.green + " "

            case .formatting(let formatting):
                prompt += formatting

            case .time:
                prompt += currentTime.green + " "

            case .user(let fallback, let followedByHost):
                let spaceCharacter = followedByHost ? "@" : " "
                if let user = currentUser {
                    prompt += (user + spaceCharacter).yellow
                } else if let fallback = fallback {
                    prompt += (fallback + spaceCharacter).red
                }

            case .host(let fallback):
                if let host = currentHost {
                    prompt += host.yellow + " "
                } else if let fallback = fallback {
                    prompt += fallback.red + " "
                }

            case .currentWorkingDirectory(let fallback):
                if let cwd = currentWorkingDirectory {
                    prompt += cwd.blue + " "
                } else if let fallback = fallback {
                    prompt += fallback.red + " "
                }

            case .terminator(let value):
                prompt += value.cyan + " "
                exitEarly = true
            }

            if exitEarly {
                break
            }
        }

        print(prompt, terminator: "")
    }

    private var currentWorkingDirectory: String? {
        if getcwd(buffer, bufferSize) == nil {
            return nil
        } else {
            return String(cString: buffer!)
        }
    }

    private var currentTime: String {
        let date = Date()
        let calendar = Calendar.current
        let hour   = calendar.component(.hour,   from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        return String(format: "%02d:%02d:%02d", hour, minute, second)
    }

    private var currentUser: String? {
        return ProcessInfo.processInfo.environment["USER"]
    }

    private var currentHost: String? {
        guard var host = Host.current().localizedName else {
            return nil
        }
        host = host.replacingOccurrences(of: " ", with: "-")
        return host
    }

    // MARK:
    internal func readCommandIn(_ core: SwishCore) -> (command: String, arguments: [CommandArgument])? {
        // https://developer.apple.com/documentation/swift/1641199-readline
        guard let line = readLine(strippingNewline: true) else {
            core.shouldExit = true
            return nil
        }

        let separators = CharacterSet(charactersIn: " \t\r\n")
        let tokens = line.components(separatedBy: separators).filter { !$0.isEmpty }
        guard tokens.count > 0 else { return nil }

        return (command: tokens[0], arguments: Array(tokens[1...]))
    }

}
