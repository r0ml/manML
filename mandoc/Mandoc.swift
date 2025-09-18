// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import AppKit

// FIXME: I'm not really Sendable
class Mandoc : @unchecked Sendable {

  private var origInput : [Substring] = []
  //  private var input : String = ""
  var date : String?
  var title : String?
  var os : String = ""
  var name : String?
  var argument : String?
  var lineNoOffset : Int = 0

  // ============================

  var lines : ArraySlice<Substring> = []

  var rsState : RsState?

  // ============================
  var inSynopsis = false

  var authorSplit = false

  // ============================

  // ============================
  var sourceWrapper : SourceWrapper!
  var ifCondition : Bool = true
  var ifNestingDepth = 0
  var definedRegisters = [String : String]()

  func setSourceWrapper(_ sw : SourceWrapper) async {
    sourceWrapper = sw
    let ll = coalesceLines(sw.manSource)
    sw.manSource = Array(ll)
    origInput = Array(ll)
    //    origInput = input.split(omittingEmptySubsequences: false,  whereSeparator: \.isNewline)
    lines = ll
  }

  func macroPrefix(_ lin : Substring) -> (String, String)? {
    if lin.first != "." && lin.first != "'" { return nil }
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


      /*      if line.isEmpty {
       output.append("<br>")
       lines.removeFirst()
       continue
       }
       */

      if line.hasPrefix(".\\\"") || line.hasPrefix("./\"") {
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

      try await output.append(handleLine(Substring(line), enders: []))

      if let cc {
        // FIXME: took this out for debuggery
//        output.append( "<!-- \(cc) -->")
      }
      output.append("\n")

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


  func handleLine( _ line : Substring, enders: [String]) async throws(ThrowRedirect) -> String {
    if line.isEmpty {
      return "<p>\n"
    } else if line.first != "." && line.first != "'" {
      return await span("body", String(Tokenizer.shared.escaped(line)), lineNo)
    } else {
      await setz(String(line.dropFirst()))
      return try await parseLine(enders: enders)
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

  static func newParse(_ ap : AppState) async -> (String, String, [Substring]) {
    // Now, in theory, for handling a .so, I can throw an error from toHTML(), catch the error, load a new source text, parse it, and return it.
    //    var mx = ap.manSource
    var n = 0
    while n < 2 {
      await Tokenizer.shared.setMandoc(ap.manSource )
      do {
        let h = try await Tokenizer.shared.toHTML()
        return ("", h, ap.manSource.manSource)
      } catch let e {
        n += 1
        switch e {
          case .to(let z):
            let k = z.split(separator: "/").last ?? ""
            let j = (k.split(separator: ".").map { String($0) })+["", ""]

            if let u = URL(string: "\(scheme)://\(j[1])/\(j[0])") {
              let (e, mm) = await readManFile( u, ap.manpath)
              let m = mm.split(omittingEmptySubsequences: false,  whereSeparator: \.isNewline)
              if !e.isEmpty { return (e, "", m) }
              // FIXME: infinite loops can happen here.
              // if mx == m it is a tight loop.  In theory, it can alternate.  Needs to be fixed.
              if ap.manSource.manSource == m { return ("indirection loop detected", "", []) }
              ap.manSource.manSource = m
              continue
            } else {
              return ("invalid redirection: \(z)", "", [])
            }
        }
      }
    }
    return ("repeated redirects", "", [])
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
    let manx = "\(j[2]) \(j[1])"
    let (pp, defered) = Mandoc.mandocFind( manu, manpath)
    defer {
      for i in defered { i.stopAccessingSecurityScopedResource() }
    }
    var error = ""
    if pp.count == 0 {
      return ("not found: \(manx)", "")
      /*    } else if pp.count > 1 {
       error = "multiple found"
       let a = makeMenu(pp)
       a.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
       */    } else if pp.count >= 1 {
         error = ""
         do {
           return try (error, String(contentsOf: pp[0], encoding: .utf8))
         } catch(let e) {
           return (e.localizedDescription, "")
         }
       }
    return ("not found: \(manx)", "")
  }

}


extension Mandoc {


  /// parse the remainder of a line contained by the Tokenizer.  This assumes the line needs to be parsed for macro evaluation.
  /// Returns the HTML output as a result of the parsing.
  /// The blockstate is primarily used for lists (to determine if I'm starting a new list item or not -- for example)
  func parseLine(_ bs : BlockState? = nil, enders: [String], flag: Bool = false) async throws(ThrowRedirect) -> String {
    var output = Substring("")
    while let thisCommand = try await macro(bs, enders: enders, flag: flag) {
      output.append(contentsOf: thisCommand.value)
      output.append(contentsOf: thisCommand.closingDelimiter)
    }
    return String(output)
  }

  func doConditional() async {
    if let j = await next()  {
      switch j.value {
        case "n": // terminal output -- skip this
          ifCondition = false
        case "t": // typeset output -- skip this
          ifCondition = true
        case "o": // current page is odd -- not going to implement this
          ifCondition = true
        case "e": // current page is even -- not going to implement this
          ifCondition = false
        default: // some other test case -- not yet implemented
          let z = evalCondition(j.value)
          ifCondition = z
      }
    } else {
      ifCondition = false
    }
  }

  func evalCondition(_ s : any StringProtocol) -> Bool {
    // FIXME: need to actually parse this, for now: punt
//    print("condition: \(s)")
    if s.hasPrefix("n") {
      if let r = s.dropFirst().first {
        let rv = definedRegisters[String(r)]
        var ss = s.dropFirst(2)
        if ss.first == "=" {
          ss = ss.dropFirst()
          return String(ss) == rv
        }
      }
    }
    return false
  }

  func doIf(_ b : Bool, enders: [String]) async throws(ThrowRedirect) -> String {
    var ifNest = 0
    var output = ""
    if b != ifCondition {
      let k = await rest().value
      // FIXME: doesnt handle { embedded in strings
      ifNest += k.count { $0 == "{" }
      ifNest -= k.count { $0 == "}" }
//      print("skip: \(k)")
          // FIXME: instead of using lines.first and nextLine -- need a parser function to read/advance through source
          while ifNest > 0,
                let j = lines.first {
            ifNest += j.count { $0 == "{" }
            ifNest -= j.count { $0 == "}" }
//            print("skip: \(lines.first!)")
            nextLine()
          }
    } else {
      // FIXME: I need to evaluate command lines until end.
      let k = await rest().value
      if k.hasPrefix("{") {
        var j = k.dropFirst()
        ifNest = 1
        if j.hasSuffix("\\}") { j.removeLast(2); ifNest -= 1}
        if j.hasSuffix("}") { j.removeLast(); ifNest -= 1 }
        j = Substring(j.trimmingCharacters(in: .whitespaces))
//        print("eval: \(j)")
        try await output.append(handleLine(j, enders: []))
        while ifNest > 0, !lines.isEmpty {
          var k = lines.removeFirst()
          ifNest += k.count { $0 == "{" }
          ifNest -= k.count { $0 == "}" }
//          print("eval: \(k)")
          if k.hasSuffix("\\}") { k.removeLast(2) }
          else if k.hasSuffix("}") { k.removeLast() }
          try await output.append(handleLine(k, enders: enders))
        }
      } else {
//        print("eval: \(k)")
        try await output.append(handleLine(k, enders: enders))
      }
    }
    return output
  }

}

extension Mandoc {
  var lineNo : Int {
    lineNoOffset + lines.startIndex - 1
  }

  func nextLine() {
    if !lines.isEmpty {
      lines.removeFirst()
    }
  }

  var atEnd : Bool {
    return lines.isEmpty
  }

  var peekLine : Substring {
    return lines.first!
  }

  func getLines() -> ArraySlice<Substring> {
    return lines
  }

  func setz(_ s : String) async {
    await Tokenizer.shared.setz(s)
  }

  func clearz(_ s : String) async {
    await Tokenizer.shared.clearz(s)
  }

}


enum ThrowRedirect : Error {
  case to(String)
}
