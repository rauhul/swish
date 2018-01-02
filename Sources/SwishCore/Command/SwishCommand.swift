#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Foundation

internal class SwishCommand: Command {

    internal enum SwishCommandError: Error { }

    internal weak var core: SwishCore?

    internal required init(with arguments: [CommandArgument], in core: SwishCore) {
        self.core = core
        super.init(with: arguments)
        update(state: .ready)
    }

    // MARK: CustomStringConvertible
    override var description: String {
        return "Abstract SwishCommand Type"
    }
}

internal final class SwishCommandChangeDirectory: SwishCommand {

    internal enum SwishCommandChangeDirectoryError: Error { }

    internal override func launch() throws {
        try super.launch()
        guard let _ = core else { fatalError("Core must exist for all SwishCommands") }
        // TODO: ERROR CHECKING
        if arguments.count > 0 {
            let code = chdir(self.arguments[0])
            update(state: .exited, exitCode: code == -1 ? errno : 0)
        } else if let home = ProcessInfo.processInfo.environment["HOME"] {
            let code = chdir(home)
            update(state: .exited, exitCode: code == -1 ? errno : 0)
        } else {
            update(state: .failed)
        }
    }

    // MARK: CustomStringConvertible
    override var description: String {
        return (["cd"] + arguments).joined(separator: " ")
    }
}

// // MARK: CustomStringConvertible
// extension SwishCommandChangeDirectory: CustomStringConvertible {
//     let description = "Abstract SwishCommand Type"
// }


internal final class SwishCommandExit: SwishCommand {

    internal enum SwishCommandExitError: Error { }

    internal override func launch() throws {
        try super.launch()
        guard let core = core else { fatalError("Core must exist for all SwishCommands") }
        // TODO: Change the state on swish core
        core.shouldExit = true
        update(state: .exited, exitCode: 0)
    }

    // MARK: CustomStringConvertible
    override var description: String {
        return (["exit"] + arguments).joined(separator: " ")
    }
}

internal final class SwishCommandEcho: SwishCommand {

    internal enum SwishCommandEchoError: Error { }

    internal override func launch() throws {
        try super.launch()
        guard let _ = core else { fatalError("Core must exist for all SwishCommands") }

        var nflag = 0
        // Echo may not do getopt(3) command parsing
        if arguments.first == "-n" {
            nflag = 1
            arguments.removeFirst(1)
        }

        print(arguments.joined(separator: " "), terminator: nflag != 0 ? "" : "\n")

        update(state: .exited, exitCode: 0)
    }

    // MARK: CustomStringConvertible
    override var description: String {
        return (["echo"] + arguments).joined(separator: " ")
    }
}


internal final class SwishCommandHistory: SwishCommand {

    internal enum SwishCommandHistoryError: Error { }

    internal override func launch() throws {
        try super.launch()
        guard let core = core else { fatalError("Core must exist for all SwishCommands") }

        for command in core.history {
            print(command)
        }
        update(state: .exited, exitCode: 0)
    }

    // MARK: CustomStringConvertible
    override var description: String {
        return (["history"] + arguments).joined(separator: " ")
    }
}
