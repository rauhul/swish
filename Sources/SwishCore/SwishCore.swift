// 2107®©™🔥🔥🔥🔥🔥🔥

import Foundation

#if os(Linux)
    // https://developer.apple.com/documentation/foundation/nstask
    typealias Task = Foundation.Task
#else
    // https://developer.apple.com/documentation/foundation/process
    typealias Task = Foundation.Process
#endif

public final class Core {

    // MARK: - Object lifecycle
    public init() { }

    deinit {
        unregisterForNotifications()
    }

    // MARK: - Notification Center
    var fileHandleDataAvailableObserver: NSObjectProtocol?

    func unregisterForNotifications() {
        if let observer = fileHandleDataAvailableObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    //
    public func run() throws {
        var shouldExit = false
        repeat {
            // https://developer.apple.com/documentation/swift/1641199-readline
            guard let line = readLine(strippingNewline: true) else {
                shouldExit = true
                continue
            }

            let separators = CharacterSet(charactersIn: " \t\r\n")
            var tokens = line.components(separatedBy: separators).filter { !$0.isEmpty }

            guard tokens.count > 0 else { continue }

            // https://developer.apple.com/documentation/foundation/pipe
            // let inputPipe  = Pipe()
            let outputPipe = Pipe()
            // let errorPipe  = Pipe()
            outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            fileHandleDataAvailableObserver = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) {
                notification in

                let output = outputPipe.fileHandleForReading.availableData
                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                print("<hello>", outputString)
                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            }

            let task = Task()
            task.launchPath = "/bin/bash"
            tokens.insert("-c", at: 0)
            task.arguments = tokens
            // task.standardInput  = FileHandle.standardInput
            task.standardOutput = outputPipe
            // task.standardError  = FileHandle.standardError
            //


            // https://developer.apple.com/documentation/foundation/processinfo
            // task.environment = ProcessInfo.processInfo.environment
            task.launch()
            print("before exit")
            task.waitUntilExit()
            print("after exit")

            print(task.environment ?? "no env", task.processIdentifier)

        } while(!shouldExit)
    }
}
