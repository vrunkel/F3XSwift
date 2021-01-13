//
//  VRTask.swift
//  F3SRunner
//
//  Created by Volker Runkel on 09.01.21.
//

import Foundation
import Cocoa

//class VRTask: Process {
class VRTask {
    private var _task: Process?
    var arguments: Array<String>? {
        didSet {
            self._task?.arguments = self.arguments
        }
    }
    var executableURL: URL?
    var launchPath: String? {
        self.executableURL?.path
    }
    /**
     Text encoding for the task's input and output. The default is NSUTF8StringEncoding.
     */
    var encoding: String.Encoding?

    /**
     Invoked when more output is ready. Can happen many times while the task is running.
     */
    var outputHandler: ((String) -> Void)?

    /**
     Invoked when more error output is ready. Can happen many times while the task is running.
     */
    //@property (nonatomic, strong) void (^errorHandler)(NSString *);

    /**
     Invoked when the task is completed.

     This block is not guaranteed to be fully executed prior to waitUntilExit returning.
     */
    
    var completionHandler: ((VRTask) -> Void)?
    
    //@property (nonatomic, strong) void (^completionHandler)(NTBTask *);

    /**
     Stops the file handle from reading. Should be called before replacing/releasing standard output and standard error.

     @param standardoutputorerror  NSTask standardOutput or standardError.
     */
    
    static func stopFileHandle(standardoutputorerror:Any?) {
        if let pipe = standardoutputorerror as? Pipe {
            pipe.fileHandleForReading.readabilityHandler = nil
        }
    }
        
    /**
     Finds the full path for the given command. If the command begins with a "." or a "/" it just returns the command since it then presumably
     already contains the path.

     @param command  The command

     @return  The full path, or nil if the command was not found.
     */
    static func pathForShellCommand(command: String) -> String? {
        if command.hasPrefix(".") || command.hasPrefix("/") {
            return command
        }
        else {
            let pathFinder = VRTask(executableURL: URL(fileURLWithPath: "/usr/bin/which"))
            pathFinder.arguments = [command]
            let pipe = Pipe()
            pathFinder._task!.standardOutput = pipe
            pathFinder.launch()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let string = String(data: data, encoding: .ascii), string.count > 0 {
                return string
            }
            
            return nil
        }
    }
    
    /**
     Initialises a new task. Unless launchPath begins with a "." or a "/" NTBTask will try to find the full path automatically, using the search
     path of the current process.

     @param launchPath  The path for the executable to be launched.
     */
    
    
    init(executableURL: URL) {
        self.executableURL = executableURL
        self._task = Process()//Process.launchedProcess(launchPath: self.launchPath!, arguments: [])
        self.encoding = .utf8
        let path = VRTask.pathForShellCommand(command: self.launchPath!)
        self._task!.launchPath = path ?? self.launchPath
    }

    /**
     Launches the task in its own process, and returns before the task is finished.
     @throws  NSInvalidArgumentException if the launch path has not been set or is invalid or if it fails to create a process.
     */
    

    /**
     Writes text to the standard input of the task. Works both before and after it is launched.
     @warning When used together with "launch" the last write must use "writeAndCloseInput:" instead, otherwise the task will never end.

     @param input  The text to send to the task.
     */
    func write(input: String) {
        guard let _ = self._task?.standardInput as? Pipe else {
            if let data = input.data(using: self.encoding!) {
                (self._task?.standardInput as! Pipe).fileHandleForWriting.write(data)
            }
            return
        }
        self._task?.standardInput = Pipe()
        if let data = input.data(using: self.encoding!) {
            (self._task?.standardInput as! Pipe).fileHandleForWriting.write(data)
        }
    }

    /**
     Writes text to the standard input of the task, and then closes standard input. Works both before and after the task is launched.

     @param input  The text to send to the task.
     */
    
    func writeAndCloseInput(input: String) {
        self.write(input: input)
        (self._task?.standardInput as! Pipe).fileHandleForWriting.closeFile()
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
        if !self._task!.isRunning {
            self._task?.launch()
        }
        self._task?.waitUntilExit()
        
        let read = output.fileHandleForReading
        let data = read.readDataToEndOfFile()
        let stringRead = String(data: data, encoding: self.encoding!)
        return stringRead
    }
    
    /*
    func waitUntilExit() {}
    func interrupt() {} // Not always possible. Sends SIGINT.
    func terminate() {} // Not always possible. Sends SIGTERM.

    func suspend() -> Bool {
        return false
    }
    func resume() -> Bool {
        return false
    }
 */
    
    // http://stackoverflow.com/a/16274586
    func setOutputHandler(outputHandler: @escaping (String) -> Void) {
        VRTask.stopFileHandle(standardoutputorerror: self._task?.standardOutput)
        self.outputHandler = outputHandler
        self._task!.standardOutput = Pipe()
        (self._task!.standardOutput! as! Pipe).fileHandleForReading.readabilityHandler = ((FileHandle) -> Void)? {
            handle in
            let data = handle.availableData
            let output = String(data: data, encoding: self.encoding!)!
            self.outputHandler!(output)
        }
    }
    
    func launch() {
        if self._task!.standardError == nil {
            self._task!.standardError = self._task?.standardOutput
        }
        weak var weakself = self
        self._task!.terminationHandler = ((Process) -> Void)? {
            process in
            VRTask.stopFileHandle(standardoutputorerror: process.standardOutput)
            VRTask.stopFileHandle(standardoutputorerror: process.standardError)

            if weakself?.completionHandler != nil {
                weakself!.completionHandler!(weakself!)
            }
        }
        self._task?.launch()
        self._task?.waitUntilExit()
    }
    
    func terminate() {
        self._task?.terminate()
    }
    
}
