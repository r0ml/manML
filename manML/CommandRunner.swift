// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation

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

