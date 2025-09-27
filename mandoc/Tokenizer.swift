//
// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024
    

import Foundation

struct Token {
  let value : Substring
  let unsafeValue : Substring
  let closingDelimiter : String
  let isMacro : Bool
}


// Designed to be a singleton reused tokenizer
actor Tokenizer {
  var formatState = FormatState()

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
//    "Aq" : "&lt;...&rt;",  // The value of Aq alternates between < and > -- so I don't know that I can implement this one.
  ]

  var definedString : [String:String]
  var definedMacro = [String: [Substring] ]()

  // build up the next word both as a "safified" word and as a "not-safified" word -- since I could be inserting formatting characters along the way
  var nextWord : (Substring, Substring)?
  var nextToken : Token?
  var openingDelimiter : String?
  var spacingMode = true
  var string : String = ""

  static let closingDelimiters = ".,:;)]?!"
  static let openingDelimiters = "(["
  static let middleDelimiters = "|"

  var mandoc = Mandoc()

  static let shared : Tokenizer = Tokenizer()
  private init() { definedString = initialDefinedString }

  private func reinit() {
    mandoc = Mandoc()
    formatState = FormatState()
    definedString = initialDefinedString
    definedMacro = [:]
    string = ""
    nextWord = nil
    nextToken = nil
    openingDelimiter = nil
    spacingMode = true
  }

  func setMandoc(_ ap : AppState) async {
    reinit()
    await mandoc.setSourceWrapper(ap)
  }

  func toHTML() async -> String {
    return await mandoc.toHTML()
  }

  func setSpacingMode(_ b : Bool) {
    spacingMode = b
  }

  func getDefinedMacro(_ s : String) -> [Substring]? {
    return definedMacro[s]
  }

  func setDefinedMacro(_ s : String, _ v : [Substring]?) {
    definedMacro[s] = v
  }

  func setDefinedString(_ s : String, _ v : String?) {
    definedString[s] = v
  }
  
  func escaped<T : StringProtocol>(_ ss : T ) -> Substring {
    var s = String(ss)
    var res : Substring = Substring("")

    res.append(contentsOf: holdovers())

    whiler:  while let c = s.first {
      if c == "\\" {
        var x : any StringProtocol
        (x, s) = popEscapedChar(s)
        res.append(contentsOf: x)
      } else if c == "<" {
        res.append(contentsOf: "&lt;")
        s.removeFirst()
      } else if c == ">" {
        res.append(contentsOf: "&gt;")
        s.removeFirst()
      } else if c == "\"" && s.dropFirst().first == "\"" {
        res.append(c)
        s.removeFirst(2)
      } else {
        res.append(c)
        s.removeFirst()
      }
    }

    if formatState.fontSizing { res.append(contentsOf: "</span>") }
    // This gets called and wrapped in a <span> -- so if I try to leave the span open for fonting, it gets closed by the invoking handleLine()
    for _ in formatState.fontStyling { res.append(contentsOf: "</span>") }
    for _ in formatState.colorStyling { res.append(contentsOf: "</span>") }
    return res
  }


  private func holdovers() -> String {
    var res = ""
    if formatState.moved {
      res.append("</span>")
    }
    for i in formatState.fontStyling {
      res.append("<span class=\"\(i)\">")
    }
    for i in formatState.colorStyling {
      res.append("span style=\"color: \(i);\">")
    }
    return res
  }

  /// Convert a troff unit into CSS pixels (approximate).
/*  func troffToPx(_ value: Double, unit: String) -> Double {
      switch unit {
      case "i": return value * 96.0        // inches → px
      case "p": return value * (96.0 / 72) // points → px
      case "n": return value * 8.0         // en, rough
      case "m": return value * 16.0        // em, rough
      case "u": return value * 0.22        // basic unit
      default:  return value               // assume px if no unit
      }
  }
*/


  /// Convert troff motion/line escapes into an SVG path string.
  func troffToSvgPath(_ troff: inout String) -> String {
      var path = ""


    // Do I need to do "path = "M0 0" "?
    
      // Regex: matches \h'20p' etc.
      let pattern = /\\([hvHlL])'([^']*)'/

    while let match = troff.prefixMatch(of: pattern) {

      let cmd = match.output.1
      
      if let val = troffCalcNumericUnits(String(match.output.2)) {

        switch cmd {
          case "h": path += " h\(val)"     // horizontal motion
          case "v": path += " v\(val)"     // vertical motion
          case "l": path += " h\(val)"     // horizontal line
          case "L": path += " v\(val)"     // vertical line
          case "H": path += " h\(val)"
          default: break
        }
      }
      troff = String(troff.dropFirst(match.output.0.count))
    }
    if path.isEmpty { return "" }
      return "<svg style=\"position: absolute;\"><path d=\"M0 0 \(path)\" stroke=black fill=none/></svg>"
  }

//      let path = troffToSvgPath(troff)
//        <svg width="\(width)" height="\(height)" style="border:1px solid #ccc;">
//          <path d="\(path)" stroke="black" fill="none"/>
//        </svg>

  private func popEscapedChar(_ sx : String) -> (any StringProtocol, String) {
    var s = sx

    if let j = popEscape(&s) {
      return (j, s)
    }

    if let j = popDefinedString(&s, definedString) {
      return (j, s)
    }

    if s.hasPrefix("\\\\") {
      return ("\\", String(s.dropFirst(2)))
    }
/*
 var res = troffToSvgPath(&s)
    if !res.isEmpty {
      return (res,s)
    }
*/
    
    // if it is a font control sequence, parse that
    guard !s.isEmpty else { return ("", s) }

    if let res = parseFontControl(&s, &formatState) {
      return (res, s)
    }

    return ( mandoc.span("unimplemented", safify(sx.prefix(2)), mandoc.lineNo), String(sx.dropFirst(2)))
      // keep the trailing backslash?
  //    return ("\\", s)

  }

  func reset() {
    formatState = FormatState()
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


  // return both a safe and unsafe version (unsafe meaning containing HTML special characters in text)
  func popWord() -> (Substring, Substring)? {
    while let c = string.first,
          c == " " || c == "\t" { string.removeFirst() }
    guard !string.isEmpty else { return nil }
    var res = (Substring(""), Substring("") )
    if string.first == "\"" {
      string.removeFirst()
      while let s = string.first {
        if s == "\"" { break }
        else if s == "\\" {
          res.0.append("\\")
          res.1.append("\\")
          string.removeFirst()
          if string.isEmpty {
            break
          } else {
            let n = string.removeFirst()
            res.0.append(n)
            res.1.append(n)
          }
        } else {
          res.0.append(s)
          res.1.append(s)
          string.removeFirst()
        }
      }
      if string.first == "\"" { string.removeFirst() }
      // FIXME: need to deal with escaped closing quote
      return (escaped(res.0), res.1)
    } else {
      // for that weird construction: "el\\{\\"
      var k : any StringProtocol
        while !string.isEmpty {
          if string.hasPrefix("\\{") {
            if res.0.isEmpty {
              string.removeFirst(2)
              // FIXME: maybe unsafe is
              return ("{", "{")
            } else {
              return res
            }
          }
          if string.hasPrefix("\"\"") {
            res.0.append("\"")
            res.1.append("\"")
            string.removeFirst(2)
          }
          if string.first == "\\" {
            (k, string) = popEscapedChar(string)
            res.0.append(contentsOf: k)
// FIXME: need to have popEscapedChar return both kinds
            res.1.append(contentsOf: k)
          } else {
            k = string.prefix(1)

            if String(k) == " " || String(k) == "\t" { break }
            string.removeFirst()
            res.0.append(contentsOf: safify(k) )
            res.1.append(contentsOf: k)
          }
        }
        return res
      }
  }


  func next() -> Token? {
    if nextToken != nil {
      let t = nextToken
      nextToken = nil
      return t
    }

    return popToken()
    /*
    guard var ll = popToken() else { return nil }
    if ss {
      return Token(value: Substring(safify(ll.value)), closingDelimiter: ll.closingDelimiter, isMacro: ll.isMacro)
    } else {
      return ll
    }
     */
  }

  func peekToken() -> Token? {
    if nextToken != nil {
      return nextToken
    }
    nextToken = popToken()
    return nextToken
  }

  func pushToken(_ t : Token) {
    if nextToken == nil {
      nextToken = t
    } else {
      string = t.value + " " + t.closingDelimiter + " " + string
    }
  }

  func popToken() -> Token? {

    if nextToken != nil {
      let t = nextToken
      nextToken = nil
      return t
    }


    var k : (Substring, Substring)?
    if nextWord != nil {
      k = nextWord
    } else {
      k = popWord()
    }

    var cd : String = " "

 /*   if let openingDelimiter {
      var cc = k == nil ? [] : [String(k!)]
      while let nw = popWord() {
        if (openingDelimiter == "(" && nw == ")" ) ||
            (openingDelimiter == "[" && nw == "]") {
          cd = " "
//          nextWord = popWord()
          k = Substring(openingDelimiter + cc.joined(separator: " ") + nw)
          self.openingDelimiter = nil
          break
        } else {
          cc.append(String(nw))
        }
      }
    }
  */
    nextWord = popWord()

    // If this token is a macro token, do NOT consume a closing delimiter
    if let k, macroList.contains(k.0) {
    } else {
      // here is where I set the closing delimiter
      if nextWord != nil,
         // use the unsafe version for closing delimiter
         nextWord!.1.count == 1,
         let cdx = nextWord!.1.first {
/*        if Self.openingDelimiters.contains(cdx) {
          openingDelimiter = String(cdx)
          nextWord = popWord()
        } else
*/   if Self.closingDelimiters.contains(cdx) {
          cd = String(cdx) + " "
          nextWord = popWord()
        } else if Self.middleDelimiters.contains(cdx) {
          cd = " " + String(cdx) + " "
          nextWord = popWord()
        } else {
          cd = nextWord == nil ? "\n" : " "
        }
      }
    }

    if nextWord?.0 == "Ns" || nextWord?.0 == "Ap" || !spacingMode { cd = String(cd.dropLast()) }

    if var k {
      let isMacro = macroList.contains(k.0)
      if k.0.hasPrefix("\\&") {
        k.0 = k.0.dropFirst(2)
      }
      if k.1.hasPrefix("\\&") {
        k.1 = k.1.dropFirst(2)
      }
      return Token(value: k.0, unsafeValue: k.1, closingDelimiter: cd, isMacro: isMacro)
    } else {
      return nil
    }
  }



  func peekMacro() -> Bool {
    if let nextWord {
      return macroList.contains(nextWord.0)
    } else {
      return false
    }
  }


  func rawRest() -> Substring {
    let res = (nextToken?.unsafeValue ?? nextWord?.1 ?? "") + string
    string = ""
    nextWord = nil
    nextToken = nil
    return res
  }

  func rest() -> Token {
    var output = ""
    var unsafeOutput = ""
    var cd = ""
    while let t = next() {
      if t.value != "Ns" {
        output.append(cd)
        output.append(contentsOf: t.value)

        unsafeOutput.append(cd)
        unsafeOutput.append(contentsOf: t.unsafeValue)
      }
      cd = t.closingDelimiter
    }
    return Token(value: Substring(output), unsafeValue: Substring(unsafeOutput), closingDelimiter: cd, isMacro: false)
  }


  func nextArg(enders: [String]) async -> Token? {
    guard let k = peekToken() else { return nil }

    if k.isMacro {
      if enders.contains(String(k.value)) {
        return nil
      } else {
        // FIXME: when I'm here, I don't need to read subsequence lines?
        //      var aa = ArraySlice<Substring>()
        return await mandoc.macro(enders: enders)
      }
    }

    return next()
  }

  func setz(_ s : String) {
    string = s
    nextToken = nil
    nextWord = nil
    reset()
  }

  func clearz(_ s : String) {
    string = s
    nextToken = nil
    nextWord = nil
    reset()
  }
}

