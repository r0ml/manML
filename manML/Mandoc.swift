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
  
  func generateBody() -> String {

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

      output.append(handleLine(line))

      if let cc {
        output.append( "<!-- \(cc) -->\n")
      } else {
        output.append("\n")
      }
      
    }
    return output
  }
  
  func toHTML() -> String {

    let tt = Bundle.main.url(forResource: "Mandoc", withExtension: "css")!
    let kk = try! String(contentsOf: tt, encoding: .utf8)
    let header = "<html><head><title>Mandoc</title><style>\(kk)</style></head><body>"
    let output = generateBody()

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

  
  func handleLine( _ line : Substring) -> String {
    if line.isEmpty {
      return "<p>\n"
    } else if line.first != "." {
      return span("body", String(escaped(line)), lineNo)
    } else {
      setz(line.dropFirst())
      return parseLine()
    }
  }

}
