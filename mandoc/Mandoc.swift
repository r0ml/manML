// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import AppKit

// FIXME: I'm not really Sendable
class Mandoc : @unchecked Sendable {

  var date : String?
  var title : String?
  var os : String = ""
  var name : String?
  var argument : String?
  var lineNoOffset : Int = 0

  // ============================

  var lines : ArraySlice<String> = []
  var rsState : RsState?
  var relativeStart : [Int] = []

  // ============================
  var inSynopsis = false
  var inExample = false

  // ============================
  var sourceWrapper : SourceWrapper!
  var tagOffset : String = "3ch"

  func setSourceWrapper(_ ap : AppState) async {
    sourceWrapper = ap.manSource
    let mp = MacroProcessor(ap, sourceWrapper.manSource)
//    let ll = coalesceLines(sw.manSource)

      let lla = await mp.preprocess()
    let ll = coalesceLines(lla)
    sourceWrapper.manSource = Array(ll)
      lines = ArraySlice(ll)
  }

  func macroPrefix(_ lin : Substring) -> (String, String)? {
    if lin.first != "." && lin.first != "'" { return nil }
    let k = lin.dropFirst().drop(while: { $0.isWhitespace })
    let j = k.prefix(2)
    let h = k.dropFirst(2).first?.isWhitespace ?? (j.count == 2)
    if h { return (String(j), String(k.dropFirst(2).drop(while: { $0.isWhitespace } ))) }
    else { return nil }
  }

  func generateBody() async -> String {

    var output = ""

    while !lines.isEmpty {
      var line = String(lines.first!)
      if isCommentLine(line) {
        output.append(commentBlock())
        if lines.isEmpty { return output }
        line = String(lines.first!)
      }
      line = stripComment(line)
      lines.removeFirst()
      await output.append(handleLine(line, enders: []))
    }
    return output
  }

  func toHTML() async -> String {

    let tt = Bundle.main.url(forResource: "Mandoc", withExtension: "css")!
    let kk = try! String(contentsOf: tt, encoding: .utf8)
    let header = "<!DOCTYPE html>\n<html><head><meta charset=\"UTF-8\"><title>Mandoc</title><style>\(kk)</style></head><body>"

    let output = await generateBody()

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


  func handleLine( _ line : String, enders: [String]) async -> String {
    if line.isEmpty {
      // FIXME: perhaps this should just be return "" ?
      return "<p/>\n"
    } else if isCommentLine(line) {
      return "<!-- \(line.dropFirst(3)) -->\n"
    } else if line.first != "." && line.first != "'" {
      return await span("body", String(Tokenizer.shared.escaped(line)), lineNo)+"\n"
    } else {
      await setz(String(line.dropFirst()))
      if let j = await parseLine(enders: enders) {
        return j.value + j.closingDelimiter
      } else {
        return ""
      }
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

  static func getTheHTML(_ man : URL, _ manpath : Manpath) async -> (String, String) {
    var error = ""
    let m = man.pathComponents
    var mm = ""
    if m.count == 2 {
      mm = m[1]
    } else if m.count > 2 {
      mm = "\(m[2]) \(m[1])"
    }
    do {
      let p = ShellProcess.init("/bin/sh", "-c", "mandoc -T html `man -w \(mm)`", env: ["MANPATH": (manpath.manpath.map { $0.path }).joined(separator: ":") ])
      let (_ , o, e) = try await p.run()

      error = e!
      return (e!, o!)

    } catch(let e) {
      error = e.localizedDescription
    }
    return (error, "")
  }

  static func newParse(_ ap : AppState) async -> String {
    // Now, in theory, for handling a .so, I can throw an error from toHTML(), catch the error, load a new source text, parse it, and return it.
    //    var mx = ap.manSource
      await Tokenizer.shared.setMandoc(ap)
    if ap.manSource.manSource.isEmpty {
      return ""
    } else {
      return await Tokenizer.shared.toHTML()
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

  /*
  static func readManFile(_ manu : URL, _ state : AppState) async -> (String, String) {
    //    let ad = (NSApp.delegate) as? AppDelegate
    //    let manu = canonicalize(man)
    let manpath = state.manpath
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
       */
    } else if pp.count >= 1 {
         error = ""
      // FIXME: maybe retry other pp[n] hits if pp[0] fai
         do {
           let d = try Data(contentsOf: pp[0])
           state.fileURL = pp[0]
           // FIXME: this is a kludge for old man files that use LATIN1 without saying so
           let dd = d.replacing([0xB1], with: [0xC2, 0xB1])
           return (error, String(decoding: dd, as: UTF8.self))
         } catch(let e) {
           return (e.localizedDescription, "")
         }
       }
    return ("not found: \(manx)", "")
  }
*/

  /*
  static func readTextSafely(at url: URL) throws -> String {
      let handle = try FileHandle(forReadingFrom: url)
      defer { try? handle.close() }
      let data = try handle.readToEnd() ?? Data()
    return String(decoding: data, as: UTF8.self)
  }
*/
  

}


extension Mandoc {


  /// parse the remainder of a line contained by the Tokenizer.  This assumes the line needs to be parsed for macro evaluation.
  /// Returns the HTML output as a result of the parsing.
  /// The blockstate is primarily used for lists (to determine if I'm starting a new list item or not -- for example)
  func parseLine(_ bs : BlockState? = nil, enders: [String], flag: Bool = false) async -> Token? {
    var output = Substring("")
    var thisDelim = ""
    while let thisCommand = await macro(bs, enders: enders, flag: flag) {
      output.append(contentsOf: thisDelim)
      output.append(contentsOf: thisCommand.value)
      thisDelim = thisCommand.closingDelimiter
    }
    thisDelim.append(" ") // maybe "\n"
    // FIXME: should thisDelim have \n appended?
    if output.isEmpty {
      return nil
    } else {
      return Token(value: output, unsafeValue: output, closingDelimiter: thisDelim, isMacro: true)
    }
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

  var peekLine : String {
    return lines.first!
  }

  func getLines() -> ArraySlice<String> {
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
