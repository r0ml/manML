// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import Synchronization

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


public actor ShellProcess {
  var process : Process = Process()
  var output : Pipe = Pipe()
  var stderrx : Pipe = Pipe()

  var writeok = true
//  var edat : String? = nil

  let odat = Mutex(Data())
  let edat = Mutex(Data())

  public func interrupt() {
    defer {
      Task { await cleanup() }
    }
    process.interrupt()
  }

  public init(_ executable: String, _ args : String..., env: [String: String] = [:], cd: URL? = nil) {
    self.init(URL(fileURLWithPath: executable), args, env: env, cd: cd)
  }

  public init(_ execu: URL, _ args : [String], env: [String:String] = [:], cd: URL? = nil) {
    let envv = ProcessInfo.processInfo.environment
    var envx = ProcessInfo.processInfo.environment
    env.forEach { envx[$0] = $1 }

    let cur = cd ?? FileManager.default.temporaryDirectory

    process.arguments = args
    process.environment = envx
    process.currentDirectoryURL = cur
    process.standardOutput = output
    process.executableURL = execu
  }

/*  public func setDirectory(_ dir : URL) {
    process.currentDirectoryURL = dir
  }
  */

  /// Returns the output of running `executable` with `args`. Throws an error if the process exits indicating failure.
  @discardableResult
  public func   run(_ input : String?) async throws -> (Int32, String?, String?) {
    return try await run( input?.data(using: .utf8)! )
  }

  // ============================================================
  // passing in bytes instead of strings ....


  /// Returns the output of running `executable` with `args`. Throws an error if the process exits indicating failure.
  @discardableResult
  public func run( _ input : Data?) async throws -> (Int32, String?, String?) {
    let asi = if let input { AsyncDataActor([input]).stream }
    else { nil as AsyncStream<Data>?}
    return try await run(asi)
  }


  /// Returns the output of running `executable` with `args`. Throws an error if the process exits indicating failure.
  @discardableResult
  public func runBinary( _ input : Data) async throws -> (Int32, Data, String) {
    let asi = AsyncDataActor([input]).stream
    return try await runBinary(asi)
  }

  @discardableResult
  public func runBinary(_ input : String) async throws -> (Int32, Data, String) {
    return try await runBinary( input.data(using: .utf8)! )
  }

  @discardableResult
  public func runBinary(_ input : FileHandle) async throws -> (Int32, Data, String) {
    try theLaunch(input)
    return await theCaptureAsData()
  }



  // ==========================================================

  /// Returns the output of running `executable` with `args`. Throws an error if the process exits indicating failure.
  ///  The easiest way to generate the required AsyncStream is with:
  ///      AsyncDataActor(input).stream // where input : [Data]
  @discardableResult
  public func run(_ input : AsyncStream<Data>? = nil) async throws -> (Int32, String?, String?) {
    try theLaunch(input)
    return await theCapture()
  }

  @discardableResult
  public func runBinary(_ input : AsyncStream<Data>? = nil) async throws -> (Int32, Data, String) {
    try theLaunch(input)
    return await theCaptureAsData()
  }


  @discardableResult
  public func run(_ input : FileHandle) async throws -> (Int32, String?, String?) {
    try theLaunch(input)
    return await theCapture()
  }

  public func setOutput(_ o : FileHandle) {
    process.standardOutput = o
    try? output.fileHandleForWriting.close()
  }

  public func theLaunch(_ input : FileHandle) throws {

    process.standardInput = input
    process.standardError = stderrx

    output.fileHandleForReading.readabilityHandler = { x in
      self.odat.withLock { $0.append(x.availableData) }
    }

    stderrx.fileHandleForReading.readabilityHandler = { x in
      self.edat.withLock { $0.append(x.availableData) }
    }
    process.terminationHandler = { x in
      Task {
        await self.doTermination()
      }
    }

    do {
      try process.run()
    } catch(let e) {
      print(e.localizedDescription)
      throw e
    }
  }




  public func theLaunch(_ input : AsyncStream<Data>? = nil) throws {

    let inputs : Pipe? = if input != nil { Pipe() } else { nil }

    process.standardInput = inputs
    process.standardError = stderrx

    output.fileHandleForReading.readabilityHandler = { x in
      self.odat.withLock { $0.append(x.availableData) }
    }

    stderrx.fileHandleForReading.readabilityHandler = { x in
      self.edat.withLock { $0.append(x.availableData) }
    }

    process.terminationHandler = { x in
      Task {
        await self.doTermination()
      }
    }

    if let inputs, let input {
      Task.detached {
        for await d in input {
          if await self.writeok {
            do {
              try inputs.fileHandleForWriting.write(contentsOf: d )
            } catch(let e) {
              print("writing \(e.localizedDescription)")
              break
            }
          }
        }
        try? inputs.fileHandleForWriting.close()
        try? inputs.fileHandleForReading.close()
      }
    }

    do {
      try process.run()
    } catch(let e) {
      print(e.localizedDescription)
      throw e
    }
  }

  func doTermination() async {
    self.stopWriting()
    do {
      if let d = try self.stderrx.fileHandleForReading.readToEnd() {
        self.appendError(d)
      }
      if let k3 = try self.output.fileHandleForReading.readToEnd() {
        self.append(k3)
      }
    } catch(let e) {
      print("doTermination: ",e.localizedDescription)
    }
    await  self.cleanup()
  }

  func stopWriting() {
    writeok = false
  }

  public func midCapture() -> Data {
    return odat.withLock { let r = $0; $0.removeAll(); return r }
  }

  public func append(_ x : Data) {
    odat.withLock { $0.append(x) }
  }

  public func appendError(_ x : Data) {
    edat.withLock { $0.append(x) }
  }

  public func theCapture() async -> (Int32, String?, String?) {
    await process.waitUntilExitAsync()
    let k1 = String(data: odat.withLock { $0 }, encoding: .utf8)
    let k2 = String(data: edat.withLock { $0 }, encoding: .utf8)
    return (process.terminationStatus, k1, k2)
  }

  public func theCaptureAsData() async -> (Int32, Data, String ) {
    await process.waitUntilExitAsync()
    let k1 = odat.withLock { $0 }
    let k2 = String(data: edat.withLock { $0 }, encoding: .utf8) ?? "unable to convert error to utf8"
    return (process.terminationStatus, k1, k2 )
  }

  func cleanup() async {
    try? output.fileHandleForWriting.close()
    try? stderrx.fileHandleForWriting.close()
    await Task.yield()
    try? output.fileHandleForReading.close()
    try? stderrx.fileHandleForReading.close()
  }
}

extension Process {
    func waitUntilExitAsync() async {
        await withCheckedContinuation { c in
          let t = self.terminationHandler
            self.terminationHandler = { _ in
              t?(self)
              c.resume()
            }
        }
    }
}


public final actor AsyncDataActor {
  var d : [Data]
  var delay : Double
  var first = true

  public init(_ d : [Data], delay : Double = 0.5) {
    self.d = d
    self.delay = delay
  }

  func consumeD() -> Data? {
    if self.d.isEmpty { return nil }
    let d = self.d.removeFirst()
    return d
  }

  func notFirst() {
    self.first = false
  }

  public nonisolated var stream : AsyncStream<Data> {
    return AsyncStream(unfolding: {
      if await self.first {
        await self.notFirst()
      } else {
        try? await Task.sleep(nanoseconds: UInt64(Double(NSEC_PER_SEC) * self.delay) )
      }
      let d = await self.consumeD()
      return d
    })
  }
}

