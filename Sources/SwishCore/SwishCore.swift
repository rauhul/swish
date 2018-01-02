// 2107®©™🔥🔥🔥🔥🔥🔥

import Foundation

public final class SwishCore {

    public enum SwishCoreError: Error { }

    // MARK: Properties
    // Public
    public let description = "Swish Core"

    // Internal
    internal var shouldExit = false
    internal var history    = [Command]()

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
            guard let (commandString, arguments) = consoleIO.readCommand(in: self) else {
                continue
            }

            let command = Command.named(commandString, with: arguments, in: self)
            history.append(command)

            if history.count >= 250 {
                // Complexity: O(n), where n is the length of the collection.
                // should use a fixed size ring buffer
                history.removeFirst()
            }

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
