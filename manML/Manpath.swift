// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation

// see command manpath -- might not need the pathhelper stuff

@Observable final class Manpath : @unchecked Sendable {

  let key = "manpath"
  let defaultMansect = "1:2:3:4:5:6:7:8:9:n"

  let defaultManpath: [String] = [
    "/usr/share/man",
    "/usr/local/share/man",
    "/opt/homebrew/share/man",
    "/opt/share/man",
    "/opt/local/share/man",
    "/Library/Developer/CommandLineTools/usr/share/man",
    "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/share/man",
    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/share/man",
    "/Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/share/man",
    "/Applications/Xcode.app/Contents/Developer/usr/share/man",
    "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man",
    "~/man",
    "~/share/man"
    ]

  // only adjust manpath if already set

  var addedManpath : [URL] = []
  var manpath : [URL] { addedManpath + defaultManpath.map { URL(fileURLWithPath: $0) } }
  var mansect : [String]?

  public init() {
    addedManpath = retrieveSecurityScopedBookmarks()
    
  }

  func remove(path: String?) {
    if let path {
      addedManpath = addedManpath.filter { $0.relativePath != path }
      let jj = URL(fileURLWithPath: path).absoluteString
      if var k = UserDefaults.standard.dictionary(forKey: key) as? [String: Data] {
        if k.contains(where: { (x) -> Bool in x.key == jj } ) {
          k.removeValue(forKey: jj)
          UserDefaults.standard.set(k, forKey: key)
          UserDefaults.standard.synchronize()
        }
      }

    }
  }
  
  func retrieveSecurityScopedBookmarks() -> [URL] {
      var retrievedURLs: [URL] = []
      
      // Retrieve the saved bookmarks dictionary from UserDefaults
      guard var bookmarks = UserDefaults.standard.dictionary(forKey: key) as? [String: Data] else {
          return []
      }
      
    var stale : [String] = []
      for (urlString, bookmarkData) in bookmarks {
          do {
              var isStale = false
              
              // Resolve the bookmark to a URL
              let resolvedURL = try URL(
                  resolvingBookmarkData: bookmarkData,
                  options: .withSecurityScope,
                  relativeTo: nil,
                  bookmarkDataIsStale: &isStale
              )
              
            if isStale || defaultManpath.contains(resolvedURL.relativePath) {
                stale.append(urlString)
//                  print("Bookmark for URL \(urlString) is stale.")
              } else {
                retrievedURLs.append(resolvedURL)
              }
          } catch {
              print("Failed to resolve bookmark for \(urlString): \(error.localizedDescription)")
          }
      }
    if !stale.isEmpty {
      stale.forEach { bookmarks.removeValue(forKey: $0) }
      UserDefaults.standard.set(bookmarks, forKey: key)
    }
    
    return retrievedURLs
  }

  func parsePathForMan() async -> [URL] {
    var res = [URL]()

    let path = (ProcessInfo.processInfo.environment["PATH"] ?? "" ).components(separatedBy: ":")
    for p in path {
      let u = URL(fileURLWithPath: p)
      if u.lastPathComponent == "bin" {
        var q = u.deletingLastPathComponent().appendingPathComponent("man")
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
      let (_,b,_) = j
      if let b {
        let n = b.split(whereSeparator: (\.isNewline))
        for i in n {
          let q = URL(fileURLWithPath: String(i))
          if !res.contains(q) { res.append(q) }
        }
      }
    return res
    }
    

  // returning the URLs found which are the man contents, and the URLs of the manpaths using security scope which need to be stopped
  func find(_ name : String, _ section : String?) -> ([URL],[URL]) {
    var res = [URL]()
    var defered = [URL]()
    var sect : [String]
    if let section {
      sect = [section]
    } else {
      sect = mansect ?? []
    }
    
    for p in manpath {
      let z = p.startAccessingSecurityScopedResource()

  //    if !z { continue }
      if z { defered.append(p) }

      // FIXME: I start but dont stop security scope
  //        defer { p.stopAccessingSecurityScopedResource() }
      if let s = section {
        
        //        for s in sect {
        let pp = p.appendingPathComponent("man\(s.first!)").appendingPathComponent(name).appendingPathExtension(s)
        let ppx = p.appendingPathComponent(name).appendingPathExtension(s)

        if FileManager.default.fileExists(atPath: pp.path) {
          res.append( pp )
        } else if FileManager.default.fileExists(atPath: ppx.path) {
          res.append( ppx)
        }
      } else {
        do {
          let ll = try FileManager.default.contentsOfDirectory(at: p, includingPropertiesForKeys: nil)
          for j in ll {
            //          let rr = j.appendingPathComponent(j)
            if j.hasDirectoryPath {
              do {
                let kk = try FileManager.default.contentsOfDirectory( at: j, includingPropertiesForKeys: nil )
                for z in kk {

                  if z.deletingPathExtension().lastPathComponent == name {
                    res.append(z)

                  }
                }
              } catch {
                // ignore the error
              }
            } else {
              if sections.keys.contains(j.pathExtension) {
                if j.deletingPathExtension().lastPathComponent == name {
                  res.append(j)
                }
              }
            }
          }
        } catch {
          // ignore the error
        }
        
      }
  }
    return (res, defered)
  }
  
  
  func link(_ link : String) -> URL? {
    for p in manpath {
      let pg = URL(fileURLWithPath: link, relativeTo: p)
//      let pp = "\(p)/\(link)"
      if FileManager.default.fileExists(atPath: pg.path) {
        return pg
      }
    }
    return nil
  }
  
  /*
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
   */
}
