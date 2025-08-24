// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation

/// Returns the output of running `executable` with `args`. Throws an error if the process exits indicating failure.
@discardableResult
public func captureStdoutLaunch(_ command: String, _ input : String? = nil,
                                _ env : [String:String] = ProcessInfo.processInfo.environment) throws -> (Int32, String?, String?) {
  let process = Process()
  let output = Pipe()
  let stderr = Pipe()
  
  let inputs : Pipe? = if input != nil { Pipe() } else { nil }
  
  let execu = "/bin/sh"
  
  process.launchPath = execu
  process.arguments = ["-c", command]
  process.standardOutput = output
  process.standardInput = inputs
  process.standardError = stderr
  process.environment = env
  process.launch()

  var writeok = true
  
  if let inputs, let input {
    let ifw = inputs.fileHandleForWriting
    let dd = input.data(using: .utf8) ?? Data()
    if writeok {
      Task.detached {
        ifw.write( dd )
        try? ifw.close()
      }
    }
  }
  
  Task.detached {
    try await Task.sleep(nanoseconds: UInt64( Double(NSEC_PER_SEC) * 2 ) )
    process.interrupt()
  }
  
  process.waitUntilExit()
    writeok = false
  
  let k1 = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
  let k2 = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
  return (process.terminationStatus, k1, k2)

}


public func captureStdout(_ cmd : URL, _ args: [String], _ input : String? = nil,
                                _ env : [String:String] = ProcessInfo.processInfo.environment) async throws -> (Int32, String?, String?) {

  let process = Process()
  let output = Pipe()
  let stderr = Pipe()

  let inputs : Pipe? = if input != nil { Pipe() } else { nil }

  process.executableURL = cmd
  process.arguments = args
  process.standardOutput = output
  process.standardInput = inputs
  process.standardError = stderr
  process.environment = env
  try process.run()

  process.waitUntilExit()

  let k1 = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
  let k2 = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
  return (process.terminationStatus, k1, k2)
}

