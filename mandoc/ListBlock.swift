// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation

extension Mandoc {
  func blockBlock() async -> String {
    let j = await next()?.value
    var k = await next()?.value
    var width = "3em"
    var thisCommand = ""
    
    if k == "-offset" {
      let w = await next()?.value
      k = await next()?.value

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
          thisCommand.append( span("unimplemented", "-offset \(w ?? "")", lineNo ) )
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
        thisCommand = span("unimplemented", "Bd \(j ?? "")", lineNo)
    }

    let bs = BlockState()
    let (block, _) = await macroBlock(["Ed"], bs)
    thisCommand.append(block)
    return thisCommand
  }

  func calcWidth() async -> String {
    let m = await next()?.value ?? "3em"

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
          mn = Double(m.count)/2
          break
      }
      return "\(mn)\(u)"
    } else {
      switch m {
        case "indent":
          return "3em"
        case "indent-two":
          return "6em"
        case "left":
          return "0"

          // FIXME: what to do here?
        case "right":
          return "12em"
        default:
          return "3em"
      }
    }
  }

  func listBlock() async -> (String, Substring?) {
    let j = await next()
    var width = "6em"
    var k = await next()
    var offset = "0em" // indentation of the list
    var isCompact = false
    let bs = BlockState()
    bs.bl = .none

    while k != nil { // indentation of item bodies
      loop: switch k?.value {
        case "-width":
          width = await calcWidth()
          k = await next()
/*        case "-inset":
          let m = next()?.value ?? "4em"
          switch m {
 */
        case "-offset":
          offset = await calcWidth()

 /*        case "indent":
          offset = "2em"
  */
          k = await next()
        case "-compact":
          isCompact = true
          k = await next()
        default:
          k = nil
          break loop
      }
    }

    var thisCommand = ""

    let jj = String(j?.value ?? "")
    switch jj {
      case "-bullet":
        thisCommand = "<ul style=\"margin-top: 0.5em; list-style-type: disc;\">"
        bs.bl = .bullet
      case "-column":
        //        thisCommand = span("unimplemented", "Bl " + jj )
        thisCommand = "<table style=\"margin-top: 0.5em; padding-left: \(width)\">"
        bs.bl = .table
      case "-dash":
        thisCommand = "<ul style=\"margin-top: 0.5em; list-style-type: disc;\">"
        bs.bl = .dash
      case "-diag":
        thisCommand = "<div class=\"diag-list\" style=\"--tag-width: \(width); --compact: 0em \">"
        bs.bl = .diag
      case "-enum":
        thisCommand = "<ol style=\"margin-top: 0.5em; \">"
        bs.bl = ._enum
      case "-hang":
        thisCommand = "<div class=\"hang\" style=\"text-indent: -\(width); padding-left: \(width); --compact: \(isCompact ? 0 : 0.5)em; margin-top: 0.5em \">"
        bs.bl = .hang
      case "-hyphen":
        thisCommand = span("unimplemented", "Bl " + jj , lineNo)
      case "-inset":
        thisCommand = "<div class=\"inset\" style=\"margin-left: \(offset); margin-top: 0.5em; \">"
        bs.bl = .inset
      case "-item":
        // FIXME: this was for BUGS in man rs -- is it correct?
        width = "0"
        thisCommand = "<ul style=\"margin-left: \(width); margin-top: 0.5em;list-style-type: circle; \">"
        bs.bl = .item
      case "-ohang":
        thisCommand = span("unimplemented", "Bl " + jj, lineNo )
      case "-tag":
        thisCommand = "<div class=\"tag-list\" style=\"margin-top: 0.5em; --tag-width: \(width); --compact: \(isCompact ? 0 : 0.5)em \">"
        bs.bl = .tag

      default:
        thisCommand = span("unimplemented", "Bl " + jj, lineNo )
    }

    let _ = rest

    // FIXME: seems like I need to stick in the Sh as a list ender for some man pages
    let (blk, term) = await macroBlock(["El", "Sh", "SH"] , bs)
    thisCommand.append(blk)

    // nextLine()
    switch bs.bl {
      case .tag, .diag:
        thisCommand.append( #"</div><div style="clear: both;"></div>"# )
      case ._enum:
        thisCommand.append("</ol>")
      case .item, .bullet, .dash:
        thisCommand.append("</ul>")
      case .hang:
        thisCommand.append("</div>")
      case .table:
        thisCommand.append("</table>")
      case.inset:
        thisCommand.append("</div>")

      default:
        thisCommand.append(span("unimplemented", "BLError", lineNo))
    }

    return (thisCommand, term)
  }
  
  func textBlock(_ enders : [String]) async -> String {
      var output = ""
    while !atEnd {
      let line = peekLine
      if line.hasPrefix(".") || line.hasPrefix("'") {
        await setz(String(line.dropFirst()))
        if let pt = await peekToken(),
           enders.contains( String(pt.value) ) {
          break
        }
      }
      let thes = await span("", "<pre>"+Tokenizer.shared.escaped(line)+"</pre>", lineNo)
      nextLine()
      output.append(contentsOf: thes)
      output.append("\n")
    }
    return String(output.dropLast())
  }
  
  func macroBlock(_ enders : [String], _ bs : BlockState? = nil) async -> (String, Substring?) {
    var output = ""
    while !atEnd {

      var line = peekLine
      if line.isEmpty {
        nextLine();
//        output.append("<br class=br/>")
        output.append("<p/>")
        continue
      }

      if line.hasPrefix(".\\\"") {
        output.append(commentBlock())
        if lines.isEmpty { return (output, nil) }
        line = peekLine
      }

      var cc : String? = nil
      if let k = line.firstMatch(of: /\\\"/) {
        cc = String(line.suffix(from: k.endIndex))
        line = line.prefix(upTo: k.startIndex)
        await setz(String(line.dropFirst()))
      }
      if let cc { output.append(contentsOf: "<!-- \(cc) -->") }

      
      if line.hasPrefix(".") || line.hasPrefix("'") {
        await setz(String(line.dropFirst()))
        if let pt = await peekToken() {
          if (enders.isEmpty && (pt.isMacro || additionalMacroList.contains(pt.value) )) || enders.contains( String(pt.value) ) {
            await setz("")
            return (output, pt.value)
          }
        } else {
          await setz("")
          // FIXME: maybe I need this return when enders are empty?
//          return (output, nil)
        } // if enders.contains("") { break}

        nextLine()
        
        if let pl = try? await parseLine(bs, enders: enders) {
          output.append( pl )
        }
        output.append("\n")
      } else {
        nextLine()
        await output.append(contentsOf: span("body", Tokenizer.shared.escaped(line), lineNo))
        output.append(contentsOf: "\n")
      }
    }
    return (output, nil)
  }
    
  func definitionBlock() -> [Substring] {
    var k = [Substring]()
    while !lines.isEmpty {
      let line = lines.removeFirst()
      if line == ".." { break }
      k.append(line)
    }
    return k
  }
  
  
  func commentBlock() -> String {
    var output = ""
    
    while !lines.isEmpty {
      let line = lines.first!
      if line.hasPrefix(".\\\"") {
        lines.removeFirst()
        output.append( contentsOf: line.dropFirst(3) )
        output.append("\n")
      } else {
        output = "<!--" + output + "-->"
        return output
      }
    }
    return "<!--" + output + "-->"
  }
}
