//
//  VRTask.swift
//  F3SRunner
//
//  Created by Volker Runkel on 09.01.21.
//

import Foundation

class VRTask {
    private var _task: Process?
    var arguments: Array<String>? {
        didSet {
            self._task?.arguments = self.arguments
        }
    }
    var executableURL: URL?

    /**
     Text encoding for the task's input and output. The default is NSUTF8StringEncoding.
     */
    var encoding: String.Encoding?

    /**
     Invoked when more output is ready. Can happen many times while the task is running.
     */
    var outputHandler: ((String) -> Void)?

    /**
     Invoked when the task is completed.

     This block is not guaranteed to be fully executed prior to waitUntilExit returning.
     */
    var completionHandler: ((VRTask) -> Void)?

    /**
     Stops the file handle from reading. Should be called before replacing/releasing standard output and standard error.

     @param standardoutputorerror  NSTask standardOutput or standardError.
     */
    static func stopFileHandle(standardoutputorerror: Any?) {
        if let pipe = standardoutputorerror as? Pipe {
            pipe.fileHandleForReading.readabilityHandler = nil
        }
    }

    /**
     Initialises a new task for the given executable URL.

     @param executableURL  The file URL of the executable to be launched.
     */
    init(executableURL: URL) {
        self.executableURL = executableURL
        self._task = Process()
        self._task!.executableURL = executableURL
        self.encoding = .utf8
    }

    /**
     Writes text to the standard input of the task. Works both before and after it is launched.
     @warning When used together with "launch" the last write must use "writeAndCloseInput:" instead, otherwise the task will never end.

     @param input  The text to send to the task.
     */
    func write(input: String) {
        if !(self._task?.standardInput is Pipe) {
            self._task?.standardInput = Pipe()
        }
        guard let pipe = self._task?.standardInput as? Pipe else {
            return
        }
        if let data = input.data(using: self.encoding ?? .utf8) {
            pipe.fileHandleForWriting.write(data)
        }
    }

    /**
     Writes text to the standard input of the task, and then closes standard input. Works both before and after the task is launched.

     @param input  The text to send to the task.
     */
    func writeAndCloseInput(input: String) {
        self.write(input: input)
        if let pipe = self._task?.standardInput as? Pipe {
            pipe.fileHandleForWriting.closeFile()
        }
    }

    /**
     Launches the task, waits until it's finished, and returns with the output.
     @warning  Any existing output handler will be replaced.

     @return  The standard output from the task. Also includes error output if no errorHandler is defined.
     */
    func waitForOutputString() -> String? {
        VRTask.stopFileHandle(standardoutputorerror: self._task?.standardOutput)
        let output = Pipe()
        self._task?.standardOutput = output
        if self._task?.standardError != nil {
            self._task?.standardError = self._task?.standardOutput
        }
        if let pipe = self._task?.standardInput as? Pipe {
            pipe.fileHandleForWriting.closeFile()
        }
        if !(self._task?.isRunning ?? false) {
            do {
                try self._task?.run()
            } catch {
                return nil
            }
        }
        self._task?.waitUntilExit()

        let read = output.fileHandleForReading
        let data = read.readDataToEndOfFile()
        return String(data: data, encoding: self.encoding ?? .utf8)
    }

    // http://stackoverflow.com/a/16274586
    func setOutputHandler(outputHandler: @escaping (String) -> Void) {
        VRTask.stopFileHandle(standardoutputorerror: self._task?.standardOutput)
        self.outputHandler = outputHandler
        let pipe = Pipe()
        self._task?.standardOutput = pipe
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }
            let data = handle.availableData
            if let output = String(data: data, encoding: self.encoding ?? .utf8) {
                self.outputHandler?(output)
            }
        }
    }

    /**
     Launches the task and blocks until it has finished. Call from a background queue.

     @return  true if the task was launched successfully.
     */
    @discardableResult
    func launch() -> Bool {
        guard let task = self._task else {
            return false
        }
        if task.standardError == nil {
            task.standardError = task.standardOutput
        }
        task.terminationHandler = { [weak self] process in
            VRTask.stopFileHandle(standardoutputorerror: process.standardOutput)
            VRTask.stopFileHandle(standardoutputorerror: process.standardError)

            if let self = self {
                self.completionHandler?(self)
            }
        }
        do {
            try task.run()
        } catch {
            return false
        }
        task.waitUntilExit()
        return true
    }

    func terminate() {
        self._task?.terminate()
    }

}
