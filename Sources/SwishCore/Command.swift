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
        // case invalidStateTransition(from: CommandState, to: CommandState)
    }

    internal enum CommandState: Equatable {
        case setup
        case ready
        case running
        case cancelled
        case exited
        case failed
    }

    // MARK: Command Parser
    private static var swishCommands: [String: SwishCommand.Type] = {
        var swishCommands = [String: SwishCommand.Type]()
        swishCommands["cd"] = SwishCommandChangeDirectory.self
        return swishCommands
    }()

    internal static func named(_ command: String, with arguments: [CommandArgument], in core: SwishCore) -> Launchable {
        if let SwishCommandType = swishCommands[command] {
            return SwishCommandType.init(with: arguments, in: core)
        }
        return ExternalCommand(command, with: arguments)
    }

    // MARK: Properties
    internal var exitCode: Int32 = -1
    internal var state: CommandState = .setup
    internal var arguments: [CommandArgument]

    // internal updateState() throws {
    //
    // }

    // MARK: Object lifecycle
    internal init(with arguments: [CommandArgument]) {
        self.arguments = arguments
    }


    // MARK: Default launch implementation
    internal func launch() throws {
        guard state == Command.CommandState.ready else {
            throw CommandError.invalidState
        }
        state = .running
    }
}

internal class SwishCommand: Command, Launchable {

    internal enum SwishCommandError: Error { }

    internal weak var core: SwishCore?

    internal required init(with arguments: [CommandArgument], in core: SwishCore) {
        self.core = core
        super.init(with: arguments)
        state = .ready
    }
}

internal final class SwishCommandChangeDirectory: SwishCommand {

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
        super.init(with: arguments)
        lookupCommand()
    }

    deinit {
        // clean up manually managed memory
        argv = nil
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
        var status = posix_spawnp(&pid, argv[0], nil, nil, argv + [nil], nil)

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

}
