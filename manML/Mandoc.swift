// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import AppKit

class Mandoc {
  private var origInput : [Substring]
  private var input : String
  var date : String?
  var title : String?
  var os : String = ""
  var name : String?
  var argument : String?

  var lnSlice : ArraySlice<Substring>

  var parseState = ParseState()

  init(_ s : String) {
    input = s
    origInput = input.split(omittingEmptySubsequences: false,  whereSeparator: \.isNewline)
    lnSlice = ArraySlice(origInput)
  }
  
  func macroPrefix(_ lin : Substring) -> (String, String)? {
    if lin.first != "." { return nil }
    let k = lin.dropFirst().drop(while: { $0.isWhitespace })
    let j = k.prefix(2)
    let h = k.dropFirst(2).first?.isWhitespace ?? (j.count == 2)
    if h { return (String(j), String(k.dropFirst(2).drop(while: { $0.isWhitespace } ))) }
    else { return nil }
  }
  
  func generateBody(_ input : String) -> String {
    var output = ""

    while !lnSlice.isEmpty {
      var line = lnSlice.first!
      
      if line.hasPrefix(".\\\"") {
        output.append(commentBlock(&lnSlice))
        if lnSlice.isEmpty { return output }
        line = lnSlice.first!
      }
      
      var cc : String? = nil
      if let k = line.firstMatch(of: /\\\"/) {
        cc = String(line.suffix(from: k.endIndex))
        line = line.prefix(upTo: k.startIndex)
      }
      
      lnSlice.removeFirst()

      output.append(handleLine(&lnSlice, line))

      if let cc {
        output.append( "<!-- \(cc) -->\n")
      } else {
        output.append("\n")
      }
      
    }
//      let separator : Character = "\n"
/*      var thisLine = ""
      
      if parseState.ifNestingDepth > 0 {
        let j = line.matches(of: /\\\}/ )
        let k = line.matches(of: /\\\{/ )
        parseState.ifNestingDepth += k.count - j.count
        if parseState.ifNestingDepth < 0 { parseState.ifNestingDepth = 0 }
        continue
      }
    
      switch parseState.inItem {
        case .started:
          output.append(contentsOf: thisLine)
          output.append(separator)
          parseState.inItem = .justTagged
        case .justTagged:
          // KLUDGE for zshmodules(1)
          if thisLine.trimmingCharacters(in: .whitespaces).isEmpty {
            break
          }
          parseState.currentTag = thisLine
          parseState.currentDescription = ""
          parseState.inItem = .describing
        case .describing:
          parseState.currentDescription.append(contentsOf: thisLine)
          parseState.currentDescription.append("\n")
        case .between:

          output.append(contentsOf: thisLine )
          output.append(separator)
        case .ready:
          output.append(contentsOf: thisLine)
          output.append(separator)
          parseState.inItem = .describing
      }
    }
 */
    return output
  }
  
  func toHTML() -> String {
    
    let tt = Bundle.main.url(forResource: "Mandoc", withExtension: "css")!
    let kk = try! String(contentsOf: tt, encoding: .utf8)
    let header = "<html><head><title>Mandoc</title><style>\(kk)</style></head><body>"
    let output = generateBody(input)
    
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

  func parseLine(_ linesSlice : inout ArraySlice<Substring>, _ tknz : Tokenizer, _ bs : BlockState? = nil) -> String {
    var output = Substring("")
    while let thisCommand = macro(&linesSlice, tknz, bs) {
      output.append(contentsOf: thisCommand.value)
      output.append(contentsOf: thisCommand.closingDelimiter)
    }
    return String(output)
  }
  
  func nextArg(_ tknz: Tokenizer) -> Token? {
    guard let k = tknz.peekToken() else { return nil }
    
    if k.isMacro {
      // FIXME: when I'm here, I don't need to read subsequence lines?
      var aa = ArraySlice<Substring>()
      return macro(&aa, tknz)
    }
    
    let _ = tknz.next()
    return k
  }
  
  func handleLine(_ linesSlice : inout ArraySlice<Substring>, _ line : any StringProtocol) -> String {
    if line.isEmpty {
      return "<p>\n"
    } else if line.first != "." {
      return span("body", String(Tokenizer("", lineNo(linesSlice), parseState: parseState).escaped(line)), lineNo(linesSlice))
    } else {
      let tknz = Tokenizer(line.dropFirst(), lineNo(linesSlice), parseState: parseState )
      return parseLine(&linesSlice, tknz)
      //        thisLine.append( parseState.previousClosingDelimiter )
    }
  }

  func lineNo(_ n : ArraySlice<Substring>) -> Int {
    n.startIndex - 1
  }
}
