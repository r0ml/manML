// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation

public class MacroProcessor {
  var conditions : [Bool] = []
  /*  When mandoc formats a .TP (tagged paragraph) or .IP (indented paragraph),
   it calculates the indent width and stores/retrieves it from an-margin.
   */
  var definedRegisters : [String : String] = ["an-margin":"0"]
  var definedString : [String:String]
  var definedMacro = [String: [Substring] ]()
  let initialDefinedString = [
    "`": "&lsquo;",
    "``": "&ldquo;",
    "'" : "&rsquo;",
    "''" : "&rdquo;",
    "Gt" : "&gt;",
    "Lt" : "&lt;",
    "Le" : "&le;",
    "Ge" : "&ge;",
    "Eq" : "=",
    "Ne" : "&ne;",
    "Pm" : "&plusmn;",
    "Am" : "&amp;",
    "Ba" : "|",
    "Br" : "[",
    "Ket" : "]",
    "Lq" : "&ldquo;",
    "Rq" : "&rdquo;",
    "Fn-font": "\\c[function-name]",
    "No-font": "\\c[]",

//    "Aq" : "&lt;...&rt;",  // The value of Aq alternates between < and > -- so I don't know that I can implement this one.
  ]

  var bannedMacros : Set<String> = [
//    "BS", "BE", "VS", "VE", "INDENT", "UNINDENT"
  ]
  var source : ArraySlice<Substring>
  var appState : AppState
  var redirects = 0

  public init(_ ap : AppState, _ source : [Substring]) {
    definedString = initialDefinedString
    appState = ap
    self.source = ArraySlice(source)
  }

  public func preprocess() async -> [Substring] {
    var res : [Substring] = []
    while !source.isEmpty {
      var line = source.removeFirst()
      if line.hasPrefix(".\\\"") || line.hasPrefix("'.\\\"") || line.hasPrefix("./\"") {
        continue // skip comment lines
      }
      if let k = line.firstMatch(of: /\\\"/) {
        let _ = String(line.suffix(from: k.endIndex)) // the comment
        line = line.prefix(upTo: k.startIndex) // trailing comment removed
      }

      // This replaces defined string
      // FIXME: change this to look for "\\*" strings and substitute the ones I find, if any.
      for (k,v) in definedString {
        switch k.count {
          case 1: line = Substring(line.replacingOccurrences(of: "\\*\(k)", with: v))
          case 2: line = Substring(line.replacingOccurrences(of: "\\*(\(k)", with: v))
          default: line = Substring(line.replacingOccurrences(of: "\\*[\(k)]", with: v))
        }
      }

      print(line)

      guard line.hasPrefix(".") || line.hasPrefix("'") else {
        res.append(line)  // not a macro line
        continue
      }


      line.removeFirst() // drop the '.'
      line = line.drop { $0.isWhitespace }

      let command = popName(&line, true)
      if command.isEmpty { continue }

      // FIXME: massive kludge to sidestep Tck/Tk man page problems with the malformed prelude they use:
      if bannedMacros.contains(command) {
        continue
      }

      if var m = definedMacro[command] {
        var argn = 0
        while true {
          argn += 1
          let rx = try! Regex("\\\\\\\\\\$\(argn)")
          let k = (m.map { $0.contains(rx) } ).contains(true)
          if k {
            let arg = popName(&line)
            m = m.map { $0.replacing(rx, with: arg) }
          } else {
            break
          }
        }

        m = Array(coalesceLines(m))
        m = m.map { $0.replacing("\\\\", with: "\\") }

        // Feed the macro replacement back into the source stream
        source.replaceSubrange(source.startIndex..<source.startIndex, with: m)
        continue
      }

      replaceRegisters(&line)


      switch command {
        case "ds":
          let nam = popName(&line)
          let val = line
          definedString[String(nam)] = String(val)

          // "de" defines a macro -- and the macro definition goes until a line consisting of ".."
        case "de", "de1":
          // this would be the macro name if I were implementing roff macro definitions
          let nam = popName(&line)
          let val = definitionBlock() // skip over the definition
          definedMacro[nam] = val

        case "ig":
          let _ = popName(&line) // the terminator -- currently not implemented
          let _ = definitionBlock() // and ignore it

        case "wh": // ignored by mandoc -- set page traps
          break

        case "nh": // disable hypenation until .hy
          break // not implemented

        case "hy": // re-enable hyphenation
          break   // not implemented

        case "so":
          let k = line.split(separator: "/").last ?? ""
          let j = (k.split(separator: ".").map { String($0) })+["", ""]
          redirects += 1
          if redirects > 3 {
            appState.error = "too many redirects"
            return []
          }

          if let u = URL(string: "\(scheme):///\(j[0])/\(j[1])") {
            let (e, mm) = await Mandoc.readManFile( u, appState.manpath)
            appState.error = e
            if !e.isEmpty {
              return []
            }
            let m = mm.split(omittingEmptySubsequences: false,  whereSeparator: \.isNewline)

            // FIXME: infinite loops can happen here.
            // if mx == m it is a tight loop.  In theory, it can alternate.  Needs to be fixed.
            // stick a counter in
            if appState.manSource.manSource == m {
              appState.error = "indirection loop detected"
              return []
            }
            appState.manSource.manSource = m
            self.source = ArraySlice(m)
            continue
          } else {
            appState.error = "invalid redirection: \(line)"
            return []
          }

        case "if":
          let j = popName(&line)
          let b = doConditional(j)
          let m = doIf(b, line)
          source.replaceSubrange(source.startIndex..<source.startIndex, with: m)
          continue

        case "ie":
          let j = popName(&line)
          let b = doConditional(j)
          conditions.append(b)
          let m = doIf(b, line)
          source.replaceSubrange(source.startIndex..<source.startIndex, with: m)
          continue

        case "el":
          let b = conditions.isEmpty ? true : conditions.removeLast()
          let m = doIf(!b, line)
          source.replaceSubrange(source.startIndex..<source.startIndex, with: m)
          continue

        case "nr": // set number register -- ignored for now
          let j = popName(&line)
          let k = popName(&line)
          definedRegisters[String(j)] = String(evaluateRegisterValue(String(k)))

        case "rr": // remove register -- ignored for now because set register is ignored
          let j = popName(&line)
          definedRegisters[String(j)] = nil

        default: res.append(".\(command) \(line)")
      }
    }
    return res
  }

  func evaluateRegisterValue(_ sx : String) -> Double {
    var s = Substring(sx)
    replaceRegisters(&s)
    if let k = Tokenizer.troffCalcUnits(String(s)) {
      return k
    }
    print(s)
    return 10
  }

  func definitionBlock() -> [Substring] {
    var k = [Substring]()
    while !source.isEmpty {
      let line = source.removeFirst()
      if line == ".." { break }
      k.append(line)
    }
    return k
  }

  func popName(_ line : inout Substring, _ b : Bool = false) -> String {
    if line.starts(with: "\"") {
      line.removeFirst()
      let nam = String(line.prefix { $0 != "\"" } )
      line = line.dropFirst(nam.count + 1)
      line = line.drop { $0.isWhitespace }
      return nam
    } else {
      let nam = String(line.prefix { !($0.isWhitespace || (b && $0 == "\\") ) } )
      line = line.dropFirst(nam.count)
      line = line.drop { $0.isWhitespace }
      return nam
    }
  }

  func doConditional(_ s : String) -> Bool {
    if s.hasPrefix("!") {
      // FIXME: I presume v is empty after this -- since it was already popped
      let k = doConditional(String(s.dropFirst()))
      return !k
    }
    if s == "\"\"\"" { return true }
    if s.hasPrefix("\"") && s.hasSuffix("\"\"") { return false }


    switch s.first {
      case "n": // terminal output
        return true
      case "t": // typeset output
        return false
      case "o": // current page is odd -- not going to implement this
        return false
      case "g": // groff mode -- not going to implement this
        return false
      case "e": // current page is even -- not going to implement this
        return false
      default: // some other test case -- not yet implemented
        let z = evalCondition(s)
        return  z
    }
  }

  func evalCondition(_ s : any StringProtocol) -> Bool {
    // FIXME: need to actually parse this, for now: punt
//    print("condition: \(s)")
    if s.hasPrefix("\\n") {
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

  func doIf(_ b : Bool, _ line : Substring) -> [Substring] {
    var ifNest = 0
    var output : [Substring] = []
    if !b {
      var k = line
      // FIXME: doesnt handle { embedded in strings
      ifNest += k.count { $0 == "{" }
      ifNest -= k.count { $0 == "}" }
//      print("skip: \(k)")
          // FIXME: instead of using lines.first and nextLine -- need a parser function to read/advance through source
      while ifNest > 0 || k.last == "\\",
                let j = source.first {
        k = j
            ifNest += j.count { $0 == "{" }
            ifNest -= j.count { $0 == "}" }
//            print("skip: \(lines.first!)")
            source.removeFirst()
          }
    } else {
      // FIXME: I need to evaluate command lines until end.
      let k = line
      var j = k
      var sk = false
      if k.hasPrefix("\\{") {
        j = j.dropFirst(2)
        sk = true
      } else if k.hasPrefix("{") {
        j = j.dropFirst(1)
        sk = true
      }
      if j.hasSuffix("\\") { j.removeLast() }
      if sk {
        ifNest = 1
        if j.hasSuffix("\\}") { j.removeLast(2); ifNest -= 1}
        if j.hasSuffix("}") { j.removeLast(); ifNest -= 1 }

        j = Substring(j.trimmingCharacters(in: .whitespaces))
//        print("eval: \(j)")
        if !j.isEmpty { output.append(j) }
        while ifNest > 0, !source.isEmpty {
          var k = source.removeFirst()
          ifNest += k.count { $0 == "{" }
          ifNest -= k.count { $0 == "}" }
//          print("eval: \(k)")
          if ifNest == 0 && k.hasSuffix("\\}") { k.removeLast(2) }
          else if ifNest == 0 && k.hasSuffix("}") { k.removeLast() }
          output.append(k)
        }
      } else {
        output.append(k)
      }
    }
    return output
  }

  func replaceRegisters(_ line : inout Substring) {
      // This replaces defined registers
      let drm = /\\n(?:\[(?<multi>[^\]]+)\]|\((?<double>..)|(?<single>[^\(\[]))/
      while true {
        let mx = line.matches(of: drm)

        if let m = mx.last {
          if let mm = m.output.multi ?? m.output.double ?? m.output.single {
            let v = definedRegisters[String(mm)] ?? "0"
            if let _ = m.output.multi {
              line.replace(/\\n\[(?<multi>[^\]]+)\]/ , with: v )
            } else if let _ = m.output.double {
              line.replace(/\\n\((?<double>..)/, with: v)
            } else if let _ = m.output.single {
              line.replace(/\\n(?<single>[^\(\[])/, with: v)
            }
          }
        } else {
          break
        }
      }

    }
}


/*
 Prefdefined registers:

 Line & Page Geometry
   •  \n(.l → line length (current maximum line width).
   •  \n(.i → indent (left margin / how much text is shifted in).
   •  \n(.o → output line offset (distance from physical left margin of device).
   •  \n(.p → page length (how tall the page is, in vertical units).
   •  \n(.v → vertical spacing (current line spacing, usually 1v = baseline skip).
   •  \n(.d → current vertical place (distance down the page; like “cursor y”).

 ⸻

 Fonts & Size
   •  \n(.f → current font number.
   •  \n(.s → current point size (scaled point).
   •  \n(.u → 1 if spacing is “unitwidth” (constant character width, e.g. CW font).

 ⸻

 Environment state
   •  \n(.h → current horizontal position (relative to left margin).
   •  \n(.c → number of characters on current output line so far.
   •  \n(.k → current output line length in units.
   •  \n(.n → length of the text stored in register .s (point size).

 ⸻

 Page control
   •  \n(.t → current page number.
   •  \n(.b → current vertical base line (used with diversions).
   •  \n(.z → current font family.
   •  \n(.y → last vertical line spacing value used.

 ⸻

 Special / less common
   •  \n(.C → count of lines since last centered line request.
   •  \n(.P → current page length in machine units.
   •  \n(.L → line spacing in machine units.
   •  \n(.H → current horizontal resolution.
   •  \n(.V → current vertical resolution.

 */
