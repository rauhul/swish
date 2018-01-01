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
    internal func readCommand(in core: SwishCore) -> (command: String, arguments: [CommandArgument])? {
        // https://developer.apple.com/documentation/swift/1641199-readline
        guard var line = readLine(strippingNewline: true) else {
            core.shouldExit = true
            return nil
        }


        let separators = CharacterSet(charactersIn: " \t\r\n")
        let tokens = line.components(separatedBy: separators).filter { !$0.isEmpty }
        guard tokens.count > 0 else { return nil }

        expand(line: tokens[1...].joined(separator: " "))

        return (command: tokens[0], arguments: Array(tokens[1...]))
    }

    private func expand(line: String) -> [String] {
        // 1. Brace Expansion
        print(braceExpand(line: line).joined(separator: " "))
        // 2. Tilde Expansion
        // 3. Shell parameter and variable Expansion
        // 4. Command substitution
        // 5. Arithmetic Expansion
        // 6. Process substitution
        // 7. Word Splitting
        // 8. File name expansion

        // {,{,gotta have{ ,\, again\, }}more }cowbell!
        return []
    }

    private func braceExpand(line: String) -> [String] {
        // Wrap entire thing in braces, replace spaces with commas
        let wrappedLine = "{" + line.replacingOccurrences(of: " ", with: ",") + "}"
        // The number of brackets and iterator marks
        let numBrackets = wrappedLine.components(separatedBy: "{").count - 1
        let numIterator = wrappedLine.components(separatedBy: "..")

        // Just a regular string, return it

        if numBrackets < 1 {
            print("here1")
            return [wrappedLine]
        }
        let bIndex = wrappedLine.distance(from: wrappedLine.startIndex, to: wrappedLine.index(of: "{")!)
        let oBIndex = indexOfCharacterAfterFirstClosingBracket(in: wrappedLine)

        if (numBrackets < 2) && ((numIterator.count - 1) > 0) && (bIndex < 1){
            //TODO: Implement this case
            print("here2")
        }

        if (bIndex > 0) || (oBIndex < wrappedLine.count) {
            print("here3")
            let s1 = wrappedLine.index(wrappedLine.startIndex, offsetBy: bIndex)
            let e1 = wrappedLine.index(wrappedLine.endIndex, offsetBy: -1 * oBIndex)
            return buildCombinations(a: braceExpand(line: String(wrappedLine.prefix(bIndex))), b: buildCombinations(a: braceExpand(line: String(wrappedLine[s1..<e1])), b: braceExpand(line: String(wrappedLine.suffix(oBIndex)))))
        }

        print("here4")
        let idx = wrappedLine.index(wrappedLine.startIndex, offsetBy: 1)
        let idy = wrappedLine.index(wrappedLine.endIndex, offsetBy: -1)

        //TODO: map here
        //let x = splitElements(line: String(wrappedLine[idx..<idy])).map { braceExpand(line: $0) }
        //print(x)
        print(findRange(start: "1", end: "10", step: 1))
        print(findRange(start: "a", end: "7", step: 1))
        print(findRange(start: "1", end: "10", step: Int("2")!))
        print(findRange(start: "a", end: "g", step: Int("3")!))
        print(findRange(start: "A", end: "Z", step: Int("5")!))
        return splitElements(line: String(wrappedLine[idx..<idy]))
    }

    private func indexOfCharacterAfterFirstClosingBracket(in line: String) -> Int {
        var i = 0
        var s = 0
        for idx in line.indices {
            switch line[idx] {
            case "{": s += 1
            case "}": s -= 1
            default:  break
            }
            i = i + 1
            if s == 0 {
                return i
            }
        }
        return i
    }

    private func buildCombinations(a: [String], b: [String]) -> [String] {
        var ret = [String]()
        for idx in a {
            for idy in b {
                ret.append(idx + idy)
            }
        }
        if ret.count > 0 {
            return ret
        } else if a.count > 0 {
            return a
        } else {
            return b
        }
    }

    private func splitElements(line: String) -> [String] {
        if line.count < 1 {
            return [String]()
        }
        if line.last! == "," {
            return splitElements(line: String(line.prefix(line.count - 1))) + [""]
        }

        var i = 0
        var idx = line.index(line.startIndex, offsetBy: i)

        while (i < line.count) && (line[idx] != ",") {
            i = i + indexOfCharacterAfterFirstClosingBracket(in: String(line.suffix(line.count - i)))
            idx = line.index(line.startIndex, offsetBy: i)
        }

        var idz = line.count - (i + 1)
        if idz < 0 {
            idz = 0
        }

        return [String(line.prefix(i))] + splitElements(line: String(line.suffix(idz)))
    }

    /**
     * Takes in a start and end of either numbers or characters, and a startIndex
     * Example: Start 1, End 5, Stride 0 -> 1, 2, 3, 4, 5
     *          Start a, End e, Stride 2 -> a, c, e
     */
    private func findRange(start: String, end: String, step: Int) -> [String] {
        var step = step
        var startIdx: Int
        var endIdx: Int
        var f = false

        if let s = Int(start), let e = Int(end) {
            startIdx = s
            endIdx = e
            f = true
        } else {
            startIdx = Int(start.unicodeScalars.map { $0.value }.reduce(0, +))
            endIdx = Int(end.unicodeScalars.map { $0.value }.reduce(0, +))
        }

        if endIdx < startIdx {
            step = -step
        }

        var ret = [String]()
        for x in stride(from: startIdx, through: endIdx, by: step) {
            if !f {
                ret.append(String(Unicode.Scalar(x)!))
            } else {
                ret.append(String(x))
            }
        }
        return ret
    }
}
