// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation

func safify(_ s : any StringProtocol) -> String {
  return CFXMLCreateStringByEscapingEntities(nil, String(s) as CFString, nil) as String
}

func popEscape<S: RangeReplaceableCollection & StringProtocol>( _ s : inout S) -> String? {
  // if this is a predefined character sequence, look it up and return it
  guard s.first == "\\" else { return nil }

//  var ns = Set<Int>()
  let ns = escapeSequences.keys.reduce(into: Set<Int>() ) { $0.insert($1.count) }

  for i in ns {
    guard i < s.count else { continue }
    let k = s.prefix(i+1).dropFirst()
    if let j = escapeSequences[String(k)] {
      s.removeFirst(i+1)
      return j
    }
  }
  return nil
}

func popDefinedString<S: RangeReplaceableCollection & StringProtocol>(_ sx : inout S, _ definedString : [ String : String] ) -> String? {
  guard sx.hasPrefix("\\*") else { return nil }
  var s = sx.dropFirst(2)
  guard !s.isEmpty else { return nil }

  var lookup = String(s.removeFirst())

//  \*x  single char name
//  \*(xx  double char name
//  \*[xyz]  multichar name

  if lookup == "(" {
    lookup = String(s.prefix(2))
    sx = S(s.dropFirst(2))
  } else if lookup == "[" {
    lookup = String(s.prefix { $0 != "]" } )
    sx = S(s.dropFirst(lookup.count + 1))
  }
  if let mx = definedString[lookup] {
    return mx
  } else {
    return "undefined:[\(lookup)]"
  }
}

func popQuoted<S: RangeReplaceableCollection & StringProtocol>(_ sx : inout S) -> String? {
  guard sx.hasPrefix("'") else { return nil }
  let nam = String(sx.dropFirst().prefix { $0 != "'" } )
  sx.removeFirst(nam.count + 2)
  return nam
}
struct FormatState {
  var colorStyling : [String] = []
  var fontStyling : [String] = []
  var subscripting : Bool = false
  var fontSizing : Bool = false
  var moved : Bool = false
}

func parseFontControl<S: RangeReplaceableCollection & StringProtocol>(_ sx : inout S, _ formatState : inout FormatState  ) -> String? {
  guard sx.hasPrefix("\\") else { return nil }
  var res : String? = nil
  var s = sx.dropFirst()

  guard !s.isEmpty else { return nil }

  let k = s.removeFirst()
  switch k {
    case "m":
      guard s.hasPrefix("[") else { sx = S(s); return "\\m" }
      var cc = s.prefix { $0 != "]" }
      s = s.dropFirst(cc.count + 1)
      cc.removeFirst() // cc is now the color
      if cc.isEmpty {
        formatState.colorStyling.removeLast()
        res = "</span>"
      } else {
        var rr = ""
        // FIXME: should this be append or replace?
        if formatState.colorStyling.isEmpty {
          formatState.colorStyling.append(String(cc))
        } else {
          rr = "</span>"
          formatState.colorStyling.removeLast()
          formatState.colorStyling.append(String(cc))
        }
        res = rr.appending("<span style=\"color: \(cc);\">")
      }
    case "c":
 /*     if s.first == "[" {
        let j = s.prefix { $0 != "]" }
        s.removeFirst(j.count + 1)
        if j.isEmpty {
          res = "</span>"
        } else {
          res = "<span class=\"(j)\">"
        }
      }
*/
      res = ""
    case "f":   // font style
      let m = s.isEmpty ? nil : s.removeFirst()
      switch m {
        case "B":
          res = #"<span class="bold">"#
          formatState.fontStyling.append("bold")
        case "I":
          res = #"<span class="italic">"#
          formatState.fontStyling.append("italic")
        case "C":
          formatState.fontStyling.append("pre")
          res = "<span class=pre>"
        case "R": // regular font
          var rr = ""
          while formatState.fontStyling.count > 0 {
            rr.append("</span>")
            formatState.fontStyling.removeLast()
          }
          res = rr
        case "P":
          if formatState.fontStyling.count > 0 {
            res = "</span>"
            formatState.fontStyling.removeLast()
          }

        case "[":
          let j = s.prefix { $0 != "]" }
          s.removeFirst(j.count + 1)
          switch j.dropFirst() {
            case "B":
              formatState.fontStyling.append("bold")
              res = #"<span class="bold">"#
            case "R":
              var rr = ""
              while formatState.fontStyling.count > 0 {
                formatState.fontStyling.removeLast()
                rr.append("</span>")
              }
              res = rr
            case "I":
              res = #"<span class="italic">"#
              formatState.fontStyling.append("italic")
            case "P", "":
              if formatState.fontStyling.count > 0 {
                formatState.fontStyling.removeLast()
                res = "</span>"
              }
            default:
              res = "<span class=\"unimplemented\">unknown font: \(j.dropFirst())</span>"
          }

        case "(": // changes to courier if followed by CW
          if s.hasPrefix("CW") { s.removeFirst(2)
            formatState.fontStyling.append("pre")
            res = "<span class=pre>"
          } else if s.hasPrefix("BI") {
            s.removeFirst(2)
            formatState.fontStyling.append("bold italic")
            res = "<span class=\"bold italic\">"
          } else if s.hasPrefix("CI") {
            s.removeFirst(2)
            formatState.fontStyling.append("courier italic")
            res = "<span class=\"courier italic\">"
          }
        default:
          break
      }

      // this did successfully typeset the equation in 3 erfc -- but alas, now I use nroff semantics instead of troff
    case "u": // superscript -- until \d
      if formatState.subscripting {
        formatState.subscripting.toggle()
        res = "</sub>"
      } else {
        formatState.subscripting.toggle()
        res = "<sup>"
      }
    case "d":
      if formatState.subscripting {
        formatState.subscripting.toggle()
        res = "</sup>"
      } else {
        formatState.subscripting.toggle()
        res = "<sub>"
      }

    case "z":
      if !s.isEmpty {
        let j = s.removeFirst() // popEscapedChar("\\"+s)
        res = "<span style=\"margin-left: -0.5em;\">\(j)</span>"
      }

      // FIXME: can I do all this stuff with an SVG element?
    case "h": // move horizontally
      var rr = ""
      if formatState.moved { formatState.moved = false ; rr = "</span>"}
      if let arg = popQuoted(&s) {
        formatState.moved = true
        if let aa = Double(arg) {
          res = rr.appending("<span class=backslash-h style=\"margin-left: \(aa * 0.22)px;\">")
        } else {
          res = rr.appending("<span class=backslash-h style=\"margin-left: \(arg);\">")
        }
      } else {
        fatalError("what to do with \\h not followed by '")
      }
    case "L": // draw verticsl line
      if s.first == "'" {
        let arg = popQuoted(&s)
        res = "<span class=backslash-L></span>"
      } else {
        fatalError("what to do with \\L not followed by '")
      }
    case "l":  // draw horizontal line
      if s.first == "'" {
        let arg = popQuoted(&s)
        res = "<span class=backslash-l></span>"
      } else {
        fatalError("what to do with \\l not followed by '")
      }



    case "s": // font size
      var rr = ""
      if formatState.fontSizing { rr = "</span>"; formatState.fontSizing = false }
      // FIXME: technically, should use all digits -- but the typesetting for 3 atan2 is badly formed
      // this kludge makes it work
      if let k = String(s).prefixMatch(of: /[-+]?(1\d|\d)/),
         let kk = Int(String(k.output.0) ) {
        if kk != 0 {
          formatState.fontSizing = true
          var fs = 1.0
          let baseline : Double = 11
          if kk > 0 { fs = (baseline + fs ) / baseline }
          else { fs = (baseline - fs ) / baseline }
          rr.append("<span style=\"font-size: \(fs)em;\">")
        } else {
          formatState.fontSizing = false
          rr.append("</span>")
        }
        s.removeFirst(k.output.0.count)
      }
      res = rr
    default:
      res = nil
  }
  if res != nil { sx = S(s) }
  return res
}

func troffCalcNumericUnits(_ s : String) -> Double? {
  let k = s.last
  var unit : Double = 1
  var val = s.dropLast()

  switch k {
    case "i": unit = 96.0        // inches → px
    case "p": unit = (96.0 / 72) // points → px
    case "n": unit = 8.0         // en, rough
    case "m": unit = 16.0        // em, rough
    case "u": unit = 0.22        // basic unit
    default:                // assume px if no unit
      val = Substring(s)
  }
  if let k = Double(val) { return k * unit }
  // FIXME: what do I do here?
  return nil
}

func troffCalcHTMLUnits(_ s : String) -> String {
  let k = s.last
  var unit = "px"
  // FIXME: this 5.0 is a global default
  var val = Double(s.dropLast()) ?? 5.0

  switch k {
    case "i": unit = "in" // inches
    case "p": unit = "pt" // points
    case "n": unit = "ch" // en
    case "m": unit = "em" // em
    case "u": unit = "px"; val = 0.22 * val       // basic unit
    default:                // assume px if no unit
      break
  }
  return "\(val)\(unit)"
}
