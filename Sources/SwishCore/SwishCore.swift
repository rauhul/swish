// 2107®©™🔥🔥🔥🔥🔥🔥

import Foundation

public final class SwishCore {

    public enum SwishCoreError: Error { }

    // MARK: Properties
    // Public
    public let description = "Swish Core"

    // Internal
    internal var shouldExit = false

    // Private
    private let consoleIO = ConsoleIO()

    // MARK: Object lifecycle
    public init() { }

    deinit { }

    // MARK: Shell run loop
    public func run() throws {
        repeat {

            consoleIO.printPrompt()
            // Check for pipes
            // If pipe, then split by pipe and execute each one one after another
            guard let (commandString, arguments) = consoleIO.readCommandIn(self) else {
                continue
            }

            let command = Command.named(commandString, with: arguments, in: self)

            do {
                try command.launch()
            } catch let error {
                print(error)
            }

        } while !shouldExit
    }

    public func handleSIGINT() {
        // print("SIGINT")
    }
}
