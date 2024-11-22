// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation

// see command manpath -- might not need the pathhelper stuff

actor Manpath {
  
  // only adjust manpath if already set

  private var manpath : [URL]?
  var mansect : [String]?

  var defaultMansect = "1:2:3:4:5:6:7:8:9:n"
  
  public init() async {
    await initManpath()
  }
  
  
  func initManpath() async {
    if let mp = ProcessInfo.processInfo.environment["MANPATH"] {
      manpath = mp.components(separatedBy: ":").map { URL(fileURLWithPath: $0) }
      mansect = defaultMansect.components(separatedBy: ":")
    } else {
      manpath = []
      mansect = []
      manpath = await parsePathForMan()
      let (mp2, ms) = manConf()

      if manpath != nil {
        for i in mp2 { if !manpath!.contains(i) { manpath!.append(i) } }
      }

      mansect = ms
    }
  }
  
  func parsePathForMan() async -> [URL] {
    var res = [URL]()

    let path = (ProcessInfo.processInfo.environment["PATH"] ?? "" ).components(separatedBy: ":")
    for p in path {
      let u = URL(fileURLWithPath: p)
      if u.lastPathComponent == "bin" {
        var q = u.deletingLastPathComponent().appendingPathComponent("man")
/*        if let qp = try? FileManager.default.destinationOfSymbolicLink(atPath: q.path) {
          res.append(qp)
        }
 */
        if FileManager.default.fileExists(atPath: q.path) {
          if !res.contains(q) { res.append(q) }
          }
      q = u.deletingLastPathComponent().appendingPathComponent("share").appendingPathComponent("man")
        if FileManager.default.fileExists(atPath: q.path ) {
          if !res.contains(q) { res.append(q) }
        }
      }
      }

    let j = try! await captureStdout( URL(fileURLWithPath: "/usr/bin/xcode-select"), ["--show-manpaths"])
//    if let j {
      let (a,b,c) = j
      if let b {
        let n = b.split(whereSeparator: (\.isNewline))
        for i in n {
          let q = URL(fileURLWithPath: String(i))
          if !res.contains(q) { res.append(q) }
        }
      }
//    }
    
    
    return res
    }
    
  
  func find(_ name : String, _ section : String?) -> [URL] {
    var res = [URL]()
    var sect : [String]
    if let section {
      sect = [section]
    } else {
      sect = mansect ?? []
    }
    
    for p in manpath ?? [] {
      if let s = section {

//        for s in sect {
        let pp = p.appendingPathComponent("man\(s.first!)").appendingPathComponent(name).appendingPathExtension(s)
        if FileManager.default.fileExists(atPath: pp.path) {
          res.append( pp )
        }
      } else {
        let ll = try? FileManager.default.contentsOfDirectory(at: p, includingPropertiesForKeys: nil)
        for j in ll ?? [] {
//          let rr = j.appendingPathComponent(j)
          if let kk = try? FileManager.default.contentsOfDirectory( at: j, includingPropertiesForKeys: nil ) {
            for z in kk {
              if z.deletingPathExtension().lastPathComponent == name {
                res.append(z)
              }
            }
          }
        }
      }
    }
    return res
  }
  
  
  func link(_ link : String) -> URL? {
    for p in manpath ?? [] {
      let pg = URL(fileURLWithPath: link, relativeTo: p)
//      let pp = "\(p)/\(link)"
      if FileManager.default.fileExists(atPath: pg.path) {
        return pg
      }
    }
    return nil
  }
  
  func manConf() -> ([URL],[String]) {
    let k = try! String(contentsOf: URL(fileURLWithPath: "/etc/man.conf"), encoding: .utf8)
    let l = k.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    let s = l.filter { !$0.hasPrefix("#") }
    
    var res = [URL]()
    var ms = defaultMansect
    
    for a in s {
      if a.hasPrefix("MANPATH") {
        res.append( URL(fileURLWithPath: String(a.dropFirst("MANPATH".count).trimmingCharacters(in: .whitespaces)) ) )
      }
      if a.hasPrefix("MANSECT") {
        ms = String(a.dropFirst("MANSECT".count).trimmingCharacters(in: .whitespaces))
      }
    }
    return (res, ms.components(separatedBy: ":"))
  }
}
