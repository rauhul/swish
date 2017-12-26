// lul ☠️

import Foundation

internal typealias CommandArgument = String

// internal protocol Launchable {
//     func launch() throws
//     // internal func launchAsync() throws
//     // internal func launchToFile() throws
// }

internal class Command: CustomStringConvertible {

    internal enum CommandError: Error {
        case invalidState
        // case invalidStateTransition(from: CommandState, to: CommandState)
    }

    internal enum CommandState: String {
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
        swishCommands["cd"]      = SwishCommandChangeDirectory.self
        swishCommands["exit"]    = SwishCommandExit.self
        swishCommands["echo"]    = SwishCommandEcho.self
        swishCommands["history"] = SwishCommandHistory.self
        return swishCommands
    }()

    internal static func named(_ command: String, with arguments: [CommandArgument], in core: SwishCore) -> Command {
        if let SwishCommandType = swishCommands[command] {
            return SwishCommandType.init(with: arguments, in: core)
        }
        return ExternalCommand(command, with: arguments)
    }

    // MARK: Properties
    // internal
    internal var state: Command.CommandState = .setup
    internal var arguments: [CommandArgument]
    internal var exitCode: Int32?

    // MARK: Object lifecycle
    internal init(with arguments: [CommandArgument]) {
        self.arguments = arguments
    }

    // MARK: State Change
    internal func update(state: Command.CommandState, exitCode: Int32? = nil) {
        if state == Command.CommandState.exited {
            guard let exitCode = exitCode else {
                fatalError("Must set Exit Code when setting state to exited.")
            }
            self.exitCode = exitCode
        }
        self.state = state
    }

    // MARK: Default launch implementation
    internal func launch() throws {
        guard state == .ready else {
            throw CommandError.invalidState
        }
        update(state: .running)
    }

    // MARK: CustomStringConvertible
    var description: String {
        return "Abstract Command Type"
    }
}
