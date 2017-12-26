#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Foundation

internal final class ExternalCommand: Command {

    internal enum ExternalCommandError: Error {
        case commandNotFound
        case processSpawnFailure
    }

    // MARK: Manually managed memory
    private var argv: [UnsafeMutablePointer<CChar>?]? {
        willSet {
            //clean up
            argv?.forEach {
                if let pointer = $0 {
                    free(pointer)
                }
            }
        }
    }

    private var envp: [UnsafeMutablePointer<CChar>?]? {
        willSet {
            //clean up
            envp?.forEach {
                if let pointer = $0 {
                    free(pointer)
                }
            }
        }
    }

    // MARK: Properties
    internal var command: String
    private var pid: pid_t = -1

    // MARK: Object lifecycle
    internal init (_ command: String, with arguments: [String]) {
        self.command = command
        super.init(with: arguments)
        lookupCommand()
        envp = ProcessInfo.processInfo.environment.map { "\($0.0)=\($0.1)".withCString(strdup) }
    }

    deinit {
        // clean up manually managed memory
        argv = nil
        envp = nil
    }

    private func lookupCommand() {
        // if commandExists {
        state = .ready
        // } else {
        //     state = failed(reason: ExternalCommandError.commandNotFound)
        // }
    }

    // MARK: Launchable
    internal override func launch() throws {
        try super.launch()

        // Convert tokens to C Strings
        let tokens = [command] + arguments
        argv = tokens.map { $0.withCString(strdup) }
        guard let argv = argv else {
            fatalError("argv must not be nil")
        }
        var status = posix_spawnp(&pid, argv[0], nil, nil, argv + [nil], (envp ?? []) + [nil])

        // Essentially fork wait
        if pid < 0 {
            print ("Error spawning")
            state = .failed
            throw ExternalCommandError.processSpawnFailure
        } else {
            state = .exited
            exitCode = waitpid(pid, &status, 0)
            if exitCode == -1 {
                print("Exited with error")
            }
        }
    }

    // MARK: CustomStringConvertible
    override var description: String {
        return ([command] + arguments).joined(separator: " ")
    }

}
