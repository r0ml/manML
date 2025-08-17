// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import AppKit

class Mandoc {

  static let closingDelimiters = ".,:;)]?!"
  static let openingDelimiters = "(["
  static let middleDelimiters = "|"

  private var origInput : [Substring]
  private var input : String
  var date : String?
  var title : String?
  var os : String = ""
  var name : String?
  var argument : String?

//  var parseState : ParseState
  // ============================

  var lines : ArraySlice<Substring>

  var rsState : RsState?

  // ============================
  var inSynopsis = false

  var authorSplit = false

  var spacingMode = true

  // ============================
  var definedString = [String:String]()
  var definedMacro = [String: [Substring] ]()

  // ============================
  var ifNestingDepth = 0


  var string : Substring
  var nextWord : Substring?
  var nextToken : Token?


  var fontStyling = false
  var fontSizing = false





  init(_ s : String) {
    input = s
    origInput = input.split(omittingEmptySubsequences: false,  whereSeparator: \.isNewline)
    lines = ArraySlice(origInput)
    string = "" // set it to the first line?
//    parseState = ParseState(self, lnSlice)
  }
  
  func macroPrefix(_ lin : Substring) -> (String, String)? {
    if lin.first != "." { return nil }
    let k = lin.dropFirst().drop(while: { $0.isWhitespace })
    let j = k.prefix(2)
    let h = k.dropFirst(2).first?.isWhitespace ?? (j.count == 2)
    if h { return (String(j), String(k.dropFirst(2).drop(while: { $0.isWhitespace } ))) }
    else { return nil }
  }
  
  func generateBody() throws(ThrowRedirect) -> String {

    var output = ""

    while !lines.isEmpty {
      var line = lines.first!

      if line.hasPrefix(".\\\"") {
        output.append(commentBlock(&lines))
        if lines.isEmpty { return output }
        line = lines.first!
      }
      
      var cc : String? = nil
      if let k = line.firstMatch(of: /\\\"/) {
        cc = String(line.suffix(from: k.endIndex))
        line = line.prefix(upTo: k.startIndex)
      }
      
      lines.removeFirst()

      try output.append(handleLine(line))

      if let cc {
        output.append( "<!-- \(cc) -->\n")
      } else {
        output.append("\n")
      }
      
    }
    return output
  }
  
  func toHTML() throws(ThrowRedirect) -> String {

    let tt = Bundle.main.url(forResource: "Mandoc", withExtension: "css")!
    let kk = try! String(contentsOf: tt, encoding: .utf8)
    let header = "<html><head><meta charset=\"UTF-8\"><title>Mandoc</title><style>\(kk)</style></head><body>"

    let output = try generateBody()

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

  
  func handleLine( _ line : Substring) throws(ThrowRedirect) -> String {
    if line.isEmpty {
      return "<p>\n"
    } else if line.first != "." {
      return span("body", String(escaped(line)), lineNo)
    } else {
      setz(line.dropFirst())
      return try parseLine()
    }
  }

  static func mandocFind( _ k : URL, _ manpath : Manpath) -> [URL] {
    if k.scheme == "mandoc" {
      let j = k.pathComponents
      if j.count < 2 { return [] }
      let j1 = j[1]
      var j2 = j.count > 2 ? j[2] : nil
      if j2?.isEmpty == true { j2 = nil }
      let pp = manpath.find(j1, j2)
      return pp
    } else {
      return [k]
    }
  }

  static func getTheHTML(_ man : String, _ manpath : Manpath) -> (String, String) {
    var error = ""
    do {
      let (_, o, e) = try captureStdoutLaunch("mandoc -T html `man -w \(man)`", "", ["MANPATH": manpath.defaultManpath.joined(separator: ":") ])

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
      let md = Mandoc(mx)
      do {
        let h = try md.toHTML()
        return ("", h, mx)
      } catch let e {
        switch e {
          case .to(let z):
            let k = z.split(separator: "/").last ?? ""
            let j = k.split(separator: ".").joined(separator: " ")
            let (e, m) = await readManFile(j, manpath)
            if !e.isEmpty { return (e, "", m) }
            mx = m
            continue
        }
      }
    }
  }

  static func canonicalize(_ man : String) -> String {
    let manx = man.split(separator: " ", omittingEmptySubsequences: true)
    var manu : String
    if manx.count == 1 {
      manu = String(manx[0])
    } else if man.count >= 2 {
      if let i = Int(manx[0]) {
        manu = "\(manx[1])/\(manx[0])"
      } else if let i = Int(manx[1]) {
        manu = "\(manx[0])/\(manx[1])"
      } else {
        manu = ""
      }
    } else {
      manu = ""
    }
    return manu
  }

  static func readManFile(_ man : String, _ manpath : Manpath) async -> (String, String) {
//    let ad = (NSApp.delegate) as? AppDelegate
    let manu = canonicalize(man)
    let pp = Mandoc.mandocFind( URL(string: "mandoc:///\(manu)")!, manpath)
    var error = ""
    if pp.count == 0 {
      error = "not found: \(man)"
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
//        return (error, "")
      }
    }
    error = "not found: \(man)"
    return (error, "")
  }

}

enum ThrowRedirect : Error {
  case to(String)
}
