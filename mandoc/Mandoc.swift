// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import AppKit

// FIXME: I'm not really Sendable
class Mandoc : @unchecked Sendable {

  private var origInput : [Substring] = []
  private var input : String = ""
  var date : String?
  var title : String?
  var os : String = ""
  var name : String?
  var argument : String?

  // ============================

  var lines : ArraySlice<Substring> = []

  var rsState : RsState?

  // ============================
  var inSynopsis = false

  var authorSplit = false

  // ============================

  // ============================
  var ifNestingDepth = 0





  func setString(_ s : String) {
    input = s
    origInput = input.split(omittingEmptySubsequences: false,  whereSeparator: \.isNewline)
    lines = ArraySlice(origInput)
  }
  
  func macroPrefix(_ lin : Substring) -> (String, String)? {
    if lin.first != "." { return nil }
    let k = lin.dropFirst().drop(while: { $0.isWhitespace })
    let j = k.prefix(2)
    let h = k.dropFirst(2).first?.isWhitespace ?? (j.count == 2)
    if h { return (String(j), String(k.dropFirst(2).drop(while: { $0.isWhitespace } ))) }
    else { return nil }
  }
  
  func generateBody() async throws(ThrowRedirect) -> String {

    var output = ""

    while !lines.isEmpty {
      var line = String(lines.first!)

      if line.hasPrefix(".\\\"") {
        output.append(commentBlock())
        if lines.isEmpty { return output }
        line = String(lines.first!)
      }
      
      var cc : String? = nil
      if let k = line.firstMatch(of: /\\\"/) {
        cc = String(line.suffix(from: k.endIndex))
        line = String(line.prefix(upTo: k.startIndex))
      }
      
      lines.removeFirst()

      try await output.append(handleLine(Substring(line)))

      if let cc {
        output.append( "<!-- \(cc) -->\n")
      } else {
        output.append("\n")
      }
      
    }
    return output
  }
  
  func toHTML() async throws(ThrowRedirect) -> String {

    let tt = Bundle.main.url(forResource: "Mandoc", withExtension: "css")!
    let kk = try! String(contentsOf: tt, encoding: .utf8)
    let header = "<!DOCTYPE html>\n<html><head><meta charset=\"UTF-8\"><title>Mandoc</title><style>\(kk)</style></head><body>"

    let output = try await generateBody()

    return """
\(header)
\(output)

<div style="margin-left: -2.5em; margin-top: 1em;" >
<div style="float: left">\(os)</div>
<div style="float: right">\(os)</div>
<div style="margin: 0 auto; width: 100%; text-align: center;">\(date ?? "")</div>
</div>
</body></html>
"""
  }

  
  func handleLine( _ line : Substring) async throws(ThrowRedirect) -> String {
    if line.isEmpty {
      return "<p>\n"
    } else if line.first != "." {
      return await span("body", String(Tokenizer.shared.escaped(line)), lineNo)
    } else {
      await setz(String(line.dropFirst()))
      return try await parseLine()
    }
  }

  static func mandocFind( _ k : URL, _ manpath : Manpath) -> ([URL], [URL]) {
    if k.scheme == scheme {
      let j = k.pathComponents
      if j.count < 2 { return ([], []) }
      let j1 = j[1]
      var j2 = j.count > 2 ? j[2] : nil
      if j2?.isEmpty == true { j2 = nil }
      let pp = manpath.find(j1, j2)
      return pp
    } else {
      return ([k],[])
    }
  }

  static func getTheHTML(_ man : URL, _ manpath : Manpath) -> (String, String) {
    var error = ""
    let m = man.pathComponents
    let mm = "\(m[1]) \(m[0])"
    do {
      let (_, o, e) = try captureStdoutLaunch("mandoc -T html `man -w \(mm)`", "", ["MANPATH": manpath.defaultManpath.joined(separator: ":") ])

      error = e!
      return (e!, o!)

    } catch(let e) {
      error = e.localizedDescription
    }
    return (error, "")
  }

  static func newParse(_ mm : String, _ manpath : Manpath) async -> (String, String, String) {
    // Now, in theory, for handling a .so, I can throw an error from toHTML(), catch the error, load a new source text, parse it, and return it.
    var mx = mm
    while true {
      await Tokenizer.shared.setMandoc(mx)
      do {
        let h = try await Tokenizer.shared.toHTML()
        return ("", h, mx)
      } catch let e {
        switch e {
          case .to(let z):
            let k = z.split(separator: "/").last ?? ""
            let j = k.split(separator: ".")
            let (e, m) = await readManFile( URL(string: "\(scheme)://\(j[1])/\(j[0])")!, manpath)
            if !e.isEmpty { return (e, "", m) }
            mx = m
            continue
        }
      }
    }
  }

  static func canonicalize(_ man : String) -> URL? {
    let manx = man.split(separator: " ", omittingEmptySubsequences: true)
    var manu : URL? = nil
    if manx.count == 1 {
      manu = URL(string: "\(scheme):///\(String(manx[0]))")!
    } else if man.count >= 2 {
      if let _ = Int(manx[0]) {
        manu = URL(string: "\(scheme):///\(manx[1])/\(manx[0])")!
      } else if let _ = Int(manx[1]) {
        manu = URL(string: "\(scheme):///\(manx[0])/\(manx[1])")!
      }
    }
    return manu
  }

  static func readManFile(_ manu : URL, _ manpath : Manpath) async -> (String, String) {
//    let ad = (NSApp.delegate) as? AppDelegate
//    let manu = canonicalize(man)
    let j = manu.pathComponents + ["",""]
    let manx = "\(j[1]) \(j[0])"
    let (pp, defered) = Mandoc.mandocFind( manu, manpath)
    defer {
      for i in defered { i.stopAccessingSecurityScopedResource() }
    }
    var error = ""
    if pp.count == 0 {
      error = "not found: \(manx)"
/*    } else if pp.count > 1 {
      error = "multiple found"
      let a = makeMenu(pp)
      a.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
*/    } else if pp.count >= 1 {
      error = ""
      do {
        return try (error, String(contentsOf: pp[0], encoding: .utf8))
      } catch(let e) {
        error = e.localizedDescription
      }
    }
    error = "not found: \(manx)"
    return (error, "")
  }

}

enum ThrowRedirect : Error {
  case to(String)
}
