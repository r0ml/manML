// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation

enum LayoutPosition {
  case center
  case right
  case left
  case numeric
  case leftPad
  case horizSpan
  case vertSpan
  case line
  case doubleLine
}

extension Measurement {
  var myDescription : String { get { String(value) + unit.symbol } }
}
struct Layout {
  var justification : LayoutPosition = .left
  var width : Measurement<Unit>?
}

extension Mandoc {
  func tblBlock() async -> String {

    var output = ""
    var line = peekLine
    if line.hasSuffix(";") { // process Options line
      nextLine()
    }

    var layout : [[Layout]] = []
    // Layout line(s)
    repeat {
      line = peekLine
      nextLine()
      let lines = line.split(separator: ",")
      for lo in lines {
        let lox = lo.lowercased()
        let wrds = lox.split(separator: /\s/, omittingEmptySubsequences: true)
        var llo = [Layout]()
        for w in wrds {
          llo.append(parseLayout(w))
        }
        layout.append(llo)
      }

    } while !line.hasSuffix(".")

    output = "<table>\n"

    let tblsep = "\t"
    var thisLayout = layout.first!
    while true {
      if layout.count > 1 {
        thisLayout = layout.removeFirst()
      } else {
        thisLayout = layout.first!
      }
      line = peekLine
      nextLine()
      if line.hasPrefix(".TE") { break }
      output.append("<tr>")
      let cs = line.split(separator: tblsep, omittingEmptySubsequences: false)
      var lay = thisLayout.map { $0 }
      for d in cs {
        let l = lay.removeFirst()
        let dd = await span("", Tokenizer.shared.escaped(d), lineNo)
        if let lw = l.width?.myDescription {
            output.append("<td style=\"width:\(lw)\">\(dd)</td>")
        } else {
          output.append("<td>\(dd)</td>")
        }
      }

      output.append("</tr>")
    }

    output.append("</table>\n")
    return output
  }

  func parseLayout(_ ss : any StringProtocol) -> Layout {
    var s = ss.lowercased()
    var lay = Layout()
    if !s.isEmpty {
      let j = s.removeFirst()
      switch j {
        case "l": lay.justification = .left
        case "r": lay.justification = .right
        case "c": lay.justification = .center
        default:
          break
      }
    }
    if !s.isEmpty {
      let j = s.removeFirst()
      switch j {
        case "w":
          if s.hasPrefix("(") {
            var k = (s.prefix { $0 != ")" }).dropFirst()
            s.removeFirst(k.count + 2)
            let n = k.prefix { $0.isNumber || $0 == "." }
            k.removeFirst(n.count)
            if k == "i" { k = "in" }
            if let nn = Double(n) {
              lay.width = Measurement(value: nn, unit: Unit(symbol: String(k)))
            }
          } else {
            var k = s.prefix { $0.isNumber }
            s.removeFirst(k.count)
            if let nn = Double(k) {
              lay.width = Measurement(value: nn, unit: Unit(symbol: "ch"))
            }
          }
        default:
          break
      }
    }
    return lay
  }
}
