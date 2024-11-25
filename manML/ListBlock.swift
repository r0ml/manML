// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation

extension Mandoc {
  enum blState {
    case none
    case tag
    case _enum
    case item
    case hang
  }
  
  // State for tagged paragraphs
  enum tpState {
    case between
    case started
    case justTagged
    case describing
    case ready
  }

  class BlockState {
    var bl : blState = .none
    var functionDef = false
  }
  
  func blockBlock(_ tknz : Tokenizer) -> String {
    let j = tknz.next()?.value
    var k = tknz.next()?.value
    var width = "3em"
    var thisCommand = ""
    
    if k == "-offset" {
      let w = tknz.next()?.value
      k = tknz.next()?.value
      
      switch w {
        case "indent":
          width = "3em"
          break;
        case "indent-two":
          break;
        case "left":
          break;
        case "right":
          break;
        case "center":
          break;
        default:
          thisCommand.append( span("unimplemented", "-offset \(w ?? "")") )
      }
      
    }
    
    let isCompact = k == "-compact"
    
    switch j {
      case "-centered":
        thisCommand = "<blockquote>"
      case "-filled":
        thisCommand = "<blockquote>"
      case "-literal":
        thisCommand = "<blockquote style=\"margin-left: \(width)\">"
      case "-ragged":
        thisCommand = "<blockquote>"
      case "-unfilled":
        thisCommand = "<blockquote>"
      default:
        thisCommand = span("unimplemented", "Bd \(j ?? "")")
    }

    let bs = BlockState()
    let block = macroBlock(["Ed"], bs)
    thisCommand.append(block)
    return thisCommand
  }
  
  
  func listBlock(_ tknz : Tokenizer) -> String {
    let j = tknz.next()
    var k = tknz.next()
    var width = "6em"
    if k?.value == "-width" { // indentation of item bodies
      let m = tknz.next()?.value ?? "3em"
      
      let mm = m.prefix(while: { $0.isNumber} )
      if mm.count > 0 {
        var mn = Double(mm) ?? 3
        let un = m.dropFirst(mm.count).first
        var u = "em";
        switch un {
          case "c": // centimeter
            u = "cm"
          case "i": // inch
            u = "in"
          case "P": // pica (1/6 inch)
            u = "pc"
          case "p": // point (1/72 inch)
             u = "pt"
          case "f": // scale `u' by 65536
            // FIXME: unimplemented
            break // unimplemented
          case "v": // default vertical span
            u = "vh"
            mn *= 100
          case "m": // width of rendered `m' (em)  character
            u = "em"
          case "n": // width of rendered `n' (en)  character
            u = "em"
            mn *= 0.5
          case "u": // default horizontal  span for the terminal
            u = "vx"
            mn *= 100
          case "M": // mini-em (1/100 em)
            u = "em"
            mn *= 100
          default:
            // FIXME: unimplemented
            break
        }
        width = "\(mn)\(u)"
      } else {
        switch m {
          case "indent": width = "3em"
          case "indent-two":
            width = "6em"
          case "left":
            width = "0"
            
            // FIXME: what to do here?
          case "right":
            width = "12em"
          default:
            width = "3em"
        }
      }
      k = tknz.next()
    }
    var bs = BlockState()
    bs.bl = .none
    var offset = "0em" // indentation of the list
    if k?.value == "-offset" {
      let m = tknz.next()?.value ?? "4em"
      switch m {
        case "indent": offset = "2em"
        default: offset = "???"
      }
      k = tknz.next()
    }
    
    var compact = k?.value == "-compact"
    var thisCommand = ""
    
    let jj = String(j?.value ?? "")
    switch jj {
      case "-bullet":
        thisCommand = span("unimplemented", "Bl " + jj )
      case "-column":
        thisCommand = span("unimplemented", "Bl " + jj )
      case "-dash":
        thisCommand = span("unimplemented", "Bl " + jj )
      case "-diag":
        thisCommand = span("unimplemented", "Bl " + jj )
      case "-enum":
        thisCommand = "<ol style=\"margin-left: \(width); margin-top: 0.5em; \">"
        bs.bl = ._enum
      case "-hang":
        thisCommand = "<div class=\"hang\" style=\"text-indent: -\(width); padding-left: \(width); margin-top: 0.5em; \">"
        bs.bl = .hang
      case "-hyphen":
        thisCommand = span("unimplemented", "Bl " + jj )
      case "-inset":
        thisCommand = span("unimplemented", "Bl " + jj )
      case "-item":
        thisCommand = "<ul style=\"margin-left: \(width); margin-top: 0.5em;list-style-type: none; \">"
        bs.bl = .item
      case "-ohang":
        thisCommand = span("unimplemented", "Bl " + jj )
      case "-tag":
        thisCommand = "<div class=\"tag-list\" style=\"margin-top: 0.5em; --tag-width: \(width); --compact: \(compact ? 0 : 0.5)em \">"
        bs.bl = .tag

      default:
        thisCommand = span("unimplemented", "Bl " + jj )
    }
    
    let blk = macroBlock( ["El"] , bs)
    thisCommand.append(blk)
    
    if !linesSlice.isEmpty { linesSlice.removeFirst() }
    switch bs.bl {
      case .tag:
        thisCommand.append( #"</div><div style="clear: both;"></div>"# )
      case ._enum:
        thisCommand.append("</ol>")
      case .item:
        thisCommand.append("</ul>")
      case .hang:
        thisCommand.append("</div>")
      default:
        thisCommand.append(span("unimplemented", "BLError"))
    }

    return thisCommand
  }
  
  func macroBlock(_ enders : [String], _ bs : BlockState? = nil) -> String {
    var output = ""
    while !linesSlice.isEmpty {
      var line = linesSlice.first!
      
      if line.hasPrefix(".") {
        var tknz = Tokenizer(line.dropFirst(), lineNo, parseState: parseState)
        if let pt = tknz.peekToken(),
           enders.contains( String(pt.value) ) {
          break
        }
        linesSlice.removeFirst()
        var cc : String? = nil
        if let k = line.firstMatch(of: /\\\"/) {
          cc = String(line.suffix(from: k.endIndex))
          line = line.prefix(upTo: k.startIndex)
          tknz = Tokenizer(line.dropFirst(), lineNo, parseState: parseState)
        }
        
        let pl = parseLine(tknz, bs)
        output.append( pl )
        if let cc { output.append(contentsOf: "<!-- \(cc) -->") }
        output.append("\n")
      } else {
        linesSlice.removeFirst()
        output.append(contentsOf: span("body", Tokenizer(line, lineNo, parseState: parseState).escaped(line)))
        output.append(contentsOf: "\n")
      }
    }
    return output
  }
    
  func definitionBlock() {
    while !linesSlice.isEmpty {
      let line = linesSlice.removeFirst()
      if line == ".." { break }
    }
  }
  
  
  func commentBlock() -> String {
    var output = ""
    
    while !linesSlice.isEmpty {
      let line = linesSlice.first!
      if line.hasPrefix(".\\\"") {
        linesSlice.removeFirst()
        output.append( contentsOf: line.dropFirst(3) )
        output.append("\n")
      } else {
        output = "<!--" + output + "-->"
        return output
      }
    }
    return output
  }
}
