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
        guard let line = readLine(strippingNewline: true) else {
            core.shouldExit = true
            return nil
        }

        let separators = CharacterSet(charactersIn: " \t\r\n")
        let tokens = line.components(separatedBy: separators).filter { !$0.isEmpty }
        guard tokens.count > 0 else { return nil }

        let args = parseLine(line: tokens[1...].joined(separator: " "))
        //let expanded = expand(line: tokens[1...].joined(separator: " "))

        return (command: tokens[0], arguments: Array(args))
    }

    private func parseLine(line: String) -> [String] {
        // 1. Read Data to execute -- Done already
        // 2. Process quotes
        return processQuotes(line: line).filter{$0 != ""}
        // 3. Split read data into commands
        // 4. Parse Special operators
        // 5. Perform Expansions
        // 6. Split command into name and args
        // 7. Run command
    }

    private func processQuotes(line: String) -> [String] {
        return splitQuotes(line: line)
    }

    private func splitQuotes(line: String) -> [String] {
        var stringArr : [String] = []
        stringArr.append("")
        // 0 is not in quotes
        // 1 is in double quotes
        // 2 is in single quotes
        var inQuotes = 0
        var idx = 0
        var seenQuotes = false
        var insertedPlain = false
        for char in line {
            if char == "\"" || char == "'"{
                seenQuotes = true
                if inQuotes == 0 {
                    // We are about to go to quotes, process
                    stringArr[idx] = expand(line: stringArr[idx]).joined(separator: " ")
                    let sVals = stringArr[idx].components(separatedBy: " ").filter{!$0.isEmpty}
                    var tIdx = idx
                    for val in sVals.reversed() {
                        stringArr.insert(val, at: idx)
                        tIdx = tIdx + 1
                    }
                    idx = (idx + (tIdx - idx) - 1)
                    stringArr.remove(at: tIdx)
                }
                idx = idx + 1
                stringArr.append("")
                if char == "'" {
                    if inQuotes == 2 {
                        // Going back to normal text, so process it as single quoted
                        insertedPlain = false
                        inQuotes = 0
                    } else if inQuotes == 1 {
                        // Do nothing, quotes within quotes
                    } else {
                        inQuotes = 2
                    }
                } else {
                    if inQuotes == 1 {
                        // Going back to normal text, so process it as double quoted
                        insertedPlain = false
                        inQuotes = 0
                    } else if inQuotes == 2 {
                        // Do nothing, quotes within quotes
                    } else {
                        inQuotes = 1
                    }

                }
            } else {
                insertedPlain = true
                stringArr[idx].append(char)
            }
        }

        if !seenQuotes {
            // We never saw quotes, so just expand the whole string
            stringArr[idx] = expand(line: stringArr[idx]).joined(separator: " ")
            let sVals = stringArr[idx].components(separatedBy: " ").filter{!$0.isEmpty}
            var tIdx = idx
            for val in sVals.reversed() {
                stringArr.insert(val, at: idx)
                tIdx = tIdx + 1
            }
            stringArr.remove(at: tIdx)
        } else {
            if insertedPlain {
                let sVals = stringArr[idx].components(separatedBy: " ").filter{!$0.isEmpty}
                var tIdx = idx
                for val in sVals.reversed() {
                    stringArr.insert(val, at: idx)
                    tIdx = tIdx + 1
                }
                stringArr.remove(at: tIdx)
            }
        }
        return stringArr
    }

    private func expand(line: String) -> [String] {
        // 1. Brace Expansion
        var retVal : [String]
        retVal = braceExpand(line: "{" + line.replacingOccurrences(of: " ", with: ",") + "}")
        // 2. Tilde Expansion
        retVal = tildeExpand(splitLine: retVal)
        // 3. Shell parameter and variable Expansion
        // 4. Command substitution
        // 5. Arithmetic Expansion
        // 6. Process substitution
        // 7. Word Splitting
        // 8. File name expansion
        return retVal
    }

    private func tildeExpand(splitLine: [String]) -> [String] {
        var retVal : [String] = []
        for line in splitLine {
            var str : String = line
            let firstChar = line.prefix(1)
            if firstChar == "~" {
                if line.count > 1 {
                    let secondChar = String(line.prefix(2).suffix(1))
                    if secondChar == "+" {
                        print("ERROR: NOT IMPLEMENTED")
                    } else if secondChar == "-" {
                        print("ERROR: NOT IMPLEMENTED")
                    } else {
                        str = NSString(string: line).expandingTildeInPath
                    }
                } else {
                    str = NSString(string: line).expandingTildeInPath
                }
            }
            retVal.append(str)
        }
        return retVal
    }

    private func braceExpand(line: String) -> [String] {
        // Wrap entire thing in braces, replace spaces with commas
        let wrappedLine = line
        // The number of brackets and iterator marks
        let numBrackets = wrappedLine.components(separatedBy: "{").count - 1
        let numIterator = wrappedLine.components(separatedBy: "..")

        // Just a regular string, return it
        if numBrackets < 1 {
            return [wrappedLine]
        }

        let bIndex = wrappedLine.distance(from: wrappedLine.startIndex, to: wrappedLine.index(of: "{")!)
        let oBIndex = indexOfCharacterAfterFirstClosingBracket(in: wrappedLine)

        let idx = wrappedLine.index(wrappedLine.startIndex, offsetBy: 1)
        let idy = wrappedLine.index(wrappedLine.endIndex, offsetBy: -1)


        if (numBrackets < 2) && ((numIterator.count - 1) > 0) && (bIndex < 1){
            let splitIterators = String(wrappedLine[idx..<idy]).components(separatedBy: "..")
            if splitIterators.count > 2 {
                let stepVal = Int(splitIterators[2]) ?? 1
                return findRange(start: splitIterators[0], end: splitIterators[1], step: stepVal)
            } else {
                return findRange(start: splitIterators[0], end: splitIterators[1], step: 1)
            }
        }

        if (bIndex > 0) || (oBIndex < wrappedLine.count) {
            let s1 = wrappedLine.index(wrappedLine.startIndex, offsetBy: bIndex)
            let e1 = wrappedLine.index(wrappedLine.endIndex, offsetBy: -1 * (wrappedLine.count - oBIndex))
            return buildCombinations(a: braceExpand(line: String(wrappedLine.prefix(bIndex))), b: buildCombinations(a: braceExpand(line: String(wrappedLine[s1..<e1])), b: braceExpand(line: String(wrappedLine.suffix(wrappedLine.count - oBIndex)))))
        }

        if wrappedLine.distance(from: wrappedLine.startIndex, to: idx) > wrappedLine.distance(from: wrappedLine.startIndex, to: idy) {
            return Array(splitElements(line: "").map { braceExpand(line: $0) }).reduce([], +)
        }
        return Array(splitElements(line: String(wrappedLine[idx..<idy])).map { braceExpand(line: $0) }).reduce([], +)
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
