// 2107®©™🔥🔥🔥🔥🔥🔥

import Foundation

#if os(Linux)
    // https://developer.apple.com/documentation/foundation/nstask
    import Glibc
#else
    // https://developer.apple.com/documentation/foundation/process
    import Darwin.C
#endif

public final class Core {
    let description = "Swish Core"

    var builtins:Dictionary = ["tryme": Builtins.tryme]

    public init() { }

    public func run() throws {
        var shouldExit = false
        repeat {
            print("$> ", terminator:"")

            // https://developer.apple.com/documentation/swift/1641199-readline
            guard let line = readLine(strippingNewline: true) else {
                shouldExit = true
                continue
            }

            let separators = CharacterSet(charactersIn: " \t\r\n")
            let tokens = line.components(separatedBy: separators).filter { !$0.isEmpty }
            guard tokens.count > 0 else { continue }

            if builtins[tokens[0]] != nil {
                let _ = (builtins[tokens[0]])!(Array(tokens[1...]))
            } else {
                var pid: pid_t = 0

                // Convert tokens to C Strings
                let argv: [UnsafeMutablePointer<CChar>?] = tokens.map { $0.withCString(strdup)}
                var status: Int32 = posix_spawnp(&pid, argv[0], nil, nil, argv + [nil], nil)

                //(builtins["tryme"])!(["test"])
                // Essentially fork wait
                if pid < 0 {
                    print ("Error spawning")
                    return;
                } else {
                    // Clear memory for args
                    argv.forEach {
                        if let pointer = $0 {
                            free(pointer)
                        }
                    }
                    if waitpid(pid, &status, 0) == -1 {
                        print("Exited with error")
                    }
                }
            }
        } while(!shouldExit)
    }
}
