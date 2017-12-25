// lul ☠️

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

internal typealias CommandArgument = String

internal protocol Launchable {
    func launch() throws
    // internal func launchAsync() throws
    // internal func launchToFile() throws
}

internal class Command {

    internal enum CommandError: Error {
        case invalidState
        case invalidStateTransition(from: CommandState, to: CommandState)
    }

    internal enum CommandState: Equatable {
        case setup
        case ready
        case running
        case cancelled
        case exited(code: Int32)
        case failed(reason: Error)

        internal static func ==(lhs: CommandState, rhs: CommandState) -> Bool {
            switch (lhs, rhs) {
            case (.setup, .setup):
                return true

            case (.ready, .ready):
                return true

            case (.running, .running):
                return true

            case (.cancelled, .cancelled):
                return true

            case (let .exited(lhsCode), let .exited(rhsCode)):
                return lhsCode == rhsCode

            case (let .failed(_), let .failed(_)):
                return false

            default:
                return false
            }
        }
    }

    // MARK: Command Parser
    private static lazy var swishCommands: [String: SwishCommand] = {
        let swishCommands = [String: SwishCommand]()
        swishCommands["cd"] = SwishCommandChangeDirectory.launch() // pointer to constructor
        return swishCommands
    }()

    internal static func commandFor(_ command: String, with arguments: [CommandArgument], in core: SwishCore) -> Launchable {
        // if let swishCommandConstructor = swishCommands[command] {
        //     return swishCommandConstructor(with: arguments, in: core)
        // }
        return ExternalCommand(command, with: arguments)
    }

    // MARK: Properties
    internal var state: CommandState = .setup
    internal var arguments = [CommandArgument]()

    // internal updateState() throws {
    //
    // }

    // MARK: Default launch implementation
    internal func launch() throws {
        guard state == Command.CommandState.ready else {
            throw CommandError.invalidState
            return
        }
        state = .running
    }
}

internal class SwishCommand: Command {

    internal enum SwishCommandError: Error { }

    internal weak var core: SwishCore?

    internal init(with arguments: [CommandArgument], in core: SwishCore) {
        self.arguments = arguments
        self.core = core
        state = .ready
    }
}

internal final class SwishCommandChangeDirectory: SwishCommand, Launchable {

    internal enum SwishCommandChangeDirectoryError: Error { }

    internal override func launch() throws {
        try super.launch()
        guard let core = core else { fatalError("Core must exist for all SwishCommands") }
        print(core.description)
        // do stuff
    }
}

internal final class ExternalCommand: Command, Launchable {

    internal enum ExternalCommandError: Error {
        case commandNotFound
        case processSpawnFailure
    }

    // MARK: Manually managed memory
    var argv: [UnsafeMutablePointer<CChar>?]? {
        willSet {
            //clean up
            if let argv = argv {
                argv.forEach {
                    if let pointer = $0 {
                        free(pointer)
                    }
                }
            }
        }
    }

    // MARK: Properties
    internal var command: String
    var pid: pid_t = -1

    // MARK: Object lifecycle
    internal init (_ command: String, with arguments: [String]) {
        self.command = command
        self.arguments = arguments
        //lookupCommand
    }

    deinit {
        // clean up manually managed memory
        argv = nil
    }

    // private func lookupCommand() throws {
    //     if commandExists {
    //         state = ready
    //     } else {
    //         state = failed(reason: ExternalCommandError.commandNotFound)
    //     }
    // }

    // MARK: Launchable
    internal override func launch() throws {
        try super.launch()

        // Convert tokens to C Strings
        let tokens = [command] + arguments
        argv = tokens.map { $0.withCString(strdup) }
        guard let argv = argv else {
            fatalError("argv must not be nil")
        }
        var status = posix_spawnp(&pid, argv[0], nil, nil, argv + [nil], nil)

        // Essentially fork wait
        if pid < 0 {
            print ("Error spawning")
            throw ExternalCommandError.processSpawnFailure
            state = .failed(reason: ExternalCommandError.processSpawnFailure)
        } else {
            let exitCode = waitpid(pid, &status, 0)
            if exitCode == -1 {
                print("Exited with error")
            }
            state = .exited(code: exitCode)
        }
    }

}
