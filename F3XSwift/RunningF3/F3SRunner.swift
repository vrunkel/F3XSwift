//
//  F3SRunner.swift
//  F3SRunner
//
//  Created by Volker Runkel on 09.01.21.
//

import Foundation

class F3SRunner {
        
    typealias F3SRunnerProgressHandler = ((F3SRunner) -> Void)
    
    enum F3SRunnerState : Int {
        case F3SRunnerStateWaiting
        case F3SRunnerStateWriting
        case F3SRunnerStateReading
        case F3SRunnerStateFailed
        case F3SRunnerStateCancelled
        case F3SRunnerStateCompleted
    }
    
    var backgroundQueue = DispatchQueue.global(qos: .userInitiated)
    
    var writeTask: VRTask?
    var writeData: String?
    var readTask: VRTask?
    var readData: String?
    var results: F3STestResults?
    
    var state: F3SRunnerState? {
        didSet {
            if self.progressHandler != nil {
                DispatchQueue.main.async {
                    self.progressHandler!(self)
                }
            }
        }
    }
 
    deinit {
        print("Runner deinit")
    }
    
    init() {
        self.progressFormatter.format = "x.xx%"
        self.progressFormatter.decimalSeparator = "."
    }
 
    static func runnerWithVolume(at: URL, progressHandler:@escaping F3SRunnerProgressHandler) -> F3SRunner? {
        let runner = F3SRunner()
        runner.volumeURL = at
        runner.progressHandler = progressHandler
        return runner
    }
    
    /*
     
     @property (nonatomic, strong) F3TestResults *results;
     @property (nonatomic, copy) F3SRunnerProgressHandler progressHandler;

     + (F3SRunner *)runnerWithVolumeAtURL:(NSURL *)url progressHandler:(F3SRunnerProgressHandler)handler;

     - (void)run;
     - (void)cancel;
     */
    
    var progressHandler: F3SRunnerProgressHandler?
    var volumeURL: URL?
    var volumeID: String?
    
    //var F3SRunnerState:
    var progress: Double = 0 {
        didSet {
            DispatchQueue.main.async {
                self.progressHandler!(self)
            }
        }
    }
    var progressFormatter = NumberFormatter()
    var info: Dictionary<String, String>?
    
    func run(skipWrite: Bool = false) {
        self.backgroundQueue.async {
            if !skipWrite {
                self.state = .F3SRunnerStateWriting
                self.runWriteTask()
            } else {
                self.state = .F3SRunnerStateReading
                self.runReadTask()
            }
        }
    }
    
    func cancel() {
        if self.state == .F3SRunnerStateWriting {
            self.writeTask!.terminate()
        }
        if self.state == .F3SRunnerStateReading {
            self.readTask!.terminate()
        }
        self.state = .F3SRunnerStateCancelled;
    }

    private func runWriteTask() {
        guard let cmdURL = Bundle.main.url(forResource: "f3write", withExtension: nil) else {
            // ERROR HANDLING
            return
        }
        self.writeTask = VRTask(executableURL: cmdURL)
        self.writeTask?.arguments = ["--show-progress=1", self.volumeURL!.path]
        self.writeData = String()
        weak var weakself = self
        
        self.writeTask!.setOutputHandler { (output) in
            weakself?.writeData?.append(output)
            if output.contains("Average writing speed:") {
                weakself?.finishedWriting()
            }
            weakself!.parseProgressOutput(output: output)
        }
        
        self.writeTask?.launch()
    }
    
    func finishedWriting() {
        //try? self.writeData!.write(to: URL(fileURLWithPath: "/Users/vrunkel/Desktop/writedata.txt"), atomically: true, encoding: .utf8)
        self.info = nil
        self.progress = 0
        self.state = .F3SRunnerStateReading
        self.runReadTask()
    }
    
    func runReadTask() {
        guard let cmdURL = Bundle.main.url(forResource: "f3read", withExtension: nil) else {
            // ERROR HANDLING
            return
        }
        self.readTask = VRTask(executableURL: cmdURL)
        self.readTask?.arguments = ["--show-progress=1", self.volumeURL!.path]
        self.readData = String()
        weak var weakself = self
        
        self.readTask!.setOutputHandler { (output) in
            weakself?.readData?.append(output)
            if output.contains("Average reading speed:") {
                weakself?.finishedReading()
            }
            weakself!.parseProgressOutput(output: output)
        }
        
        self.readTask?.launch()
    }
    
    func finishedReading() {
        
        self.results = F3STestResults.testResultsWithRaw(writingData: self.writeData, readingData: self.readData)
        self.results!.volumeID = self.volumeID
        self.progress = 100
        self.state = .F3SRunnerStateCompleted
    }
    
    func parseProgressOutput(output: String) {
        let bs = String(UnicodeScalar(8))
        let cleanOutput1 = output.replacingOccurrences(of: bs, with: "")
        let cleanOutput = cleanOutput1.replacingOccurrences(of: " ", with: "")
        let components = cleanOutput.components(separatedBy: "--")
        let isValidProgressLine = [components.first?.range(of: "%", options: .caseInsensitive, range: nil, locale: nil)]
        
        if isValidProgressLine.count == 0 {
            return
        }
        
        var info = Dictionary<String,String>()
        if components.count >= 2 {
            info.updateValue(components[1], forKey: "speed")
        }
        if components.count >= 3 {
            info.updateValue(components[2], forKey: "eta")
        }
        self.info = info
        self.progress = (self.progressFormatter.number(from: components.first!)?.doubleValue ?? 0.0)
    }
    
}
