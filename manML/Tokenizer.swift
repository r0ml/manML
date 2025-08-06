//
// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024
    

import Foundation

struct Token {
  let value : Substring
  let closingDelimiter : String
  let isMacro : Bool
}

extension Mandoc {

/*  init(_ s : any StringProtocol, parseState : Mandoc) {
    string = Substring(s)
    self.parseState = parseState
  }
  */
  
  func next() -> Token? {
    if nextToken != nil {
      let t = nextToken
      nextToken = nil
      return t
    }
    return popToken()
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
    var k : Substring?
    if nextWord != nil {
      k = nextWord
    } else {
      k = popWord()
    }

/*
    nextWord = nil
    if let k, Self.closingDelimiters.contains(k) {
      return Token(value: "", closingDelimiter: String(k), isMacro: false)
    }
 */
    
    nextWord = popWord()
    var cd : String = ""
    
    // If this token is a macro token, do NOT consume a closing delimiter
    if let k, macroList.contains(k) {
    } else {
      // here is where I set the closing delimiter
      if nextWord != nil,
         nextWord!.count == 1,
         let cdx = nextWord!.first,
         Self.closingDelimiters.contains(cdx) || Self.middleDelimiters.contains(cdx) {
        cd = Self.middleDelimiters.contains(cdx) ? " " + String(cdx) + " " : String(cdx) + " "
        nextWord = popWord()
      } else {
        cd = nextWord == nil ? "\n" : " "
      }
    }
    
    if nextWord == "Ns" || nextWord == "Ap" || !spacingMode { cd = String(cd.dropLast()) }
    
    if var k {
      let isMacro = macroList.contains(k)
      if k.hasPrefix("\\&") {
        k = k.dropFirst(2)
      }
      return Token(value: k, closingDelimiter: cd, isMacro: isMacro)
    } else {
      return nil
    }
  }
    
  func popWord() -> Substring? {
    while string.first == " " || string.first == "\t" { string.removeFirst() }
    guard !string.isEmpty else { return nil }
    var res = Substring("")
    if string.first == "\"" {
      string.removeFirst()
      while let s = string.first {
        if s == "\"" { break }
        else if s == "\\" {
          res.append("\\")
          string.removeFirst()
          if string.isEmpty {
            break
          } else {
            res.append(string.removeFirst())
          }
        } else {
          res.append(s)
          string.removeFirst()
        }
      }
      if string.first == "\"" { string.removeFirst() }
      // FIXME: need to deal with escaped closing quote
      return escaped(res)
    } else {
      // for that weird construction: "el\\{\\"
      var k : Substring
        while !string.isEmpty {
          if string.first == "\\" {
            k = popEscapedChar(&string)
            res.append(contentsOf: k)
          } else {
            k = string.prefix(1)
            if k == " " || k == "\t" { break }
            string.removeFirst()
            res.append(contentsOf: k)
          }
        }
        return res
      }
  }

  func peekMacro() -> Bool {
    if let nextWord {
      return macroList.contains(nextWord)
    } else {
      return false
    }
  }

  var rest : Token {
    var output = ""
    var cd = ""
    while let t = next() {
      if t.value != "Ns" {
        output.append(cd)
        output.append(contentsOf: t.value)
      }
      cd = t.closingDelimiter
    }
    return Token(value: Substring(output), closingDelimiter: cd, isMacro: true)
  }


  func nextArg() -> Token? {
    guard let k = peekToken() else { return nil }

    if k.isMacro {
      // FIXME: when I'm here, I don't need to read subsequence lines?
//      var aa = ArraySlice<Substring>()
      return macro()
    }

    let _ = next()
    return k
  }

  /// parse the remainder of a line contained by the Tokenizer.  This assumes the line needs to be parsed for macro evaluation.
  /// Returns the HTML output as a result of the parsing.
  /// The blockstate is primarily used for lists (to determine if I'm starting a new list item or not -- for example)
  func parseLine(_ bs : BlockState? = nil) -> String {
    var output = Substring("")
    while let thisCommand = macro(bs) {
      output.append(contentsOf: thisCommand.value)
      output.append(contentsOf: thisCommand.closingDelimiter)
    }
    return String(output)
  }



}

extension Mandoc {
  func escaped<T : StringProtocol>(_ ss : T ) -> Substring {
    var s = Substring(ss)
    var res : Substring = Substring("")
    
    whiler:  while let c = s.first {
      if c == "\\" {
        res.append(contentsOf: popEscapedChar(&s))
      } else if c == "<" {
        res.append(contentsOf: "&lt;")
        s.removeFirst()
      } else if c == ">" {
        res.append(contentsOf: "&gt;")
        s.removeFirst()
      } else {
        res.append(c)
        s.removeFirst()
      }
    }

    if fontSizing { res.append(contentsOf: "</span>") }
    if fontStyling { res.append(contentsOf: "</span>") }
    return res
  }
  
  func popDefinedString(_ s : inout Substring) -> String {
    let m = s.dropFirst(2).first
    if m == "(" {
      s.removeFirst(3)
      // at this point, I'm looking for a defined string -- but there is no marker for where the string ends.
      // So we keep trying adding one character at a time until we give up
      let mx = definedString.keys.max(by: { $0.count < $1.count } )?.count ?? 1
      for n in 1...mx {
        let pp = s.prefix(n)
        if definedString.keys.contains(String(pp)) {
          let res = definedString[String(pp)]!
          s.removeFirst(n)
          return res
        }
      }
      return "<span class=\"unimplemented\">\("defined string: s.prefix(5)")...</span>"
    }
    let res = s.prefix(2)
    s.removeFirst(2)
    return String(res)
  }
  
  func parseFontControl(_ s : inout Substring, _ k : Character ) -> String {
    var res = ""
    switch k {
      case "f":   // font style
        let m = s.dropFirst(2).first
        
        // FIXME: with   a boolean, it does not support nesting font directives
        if fontStyling {
          res.append(contentsOf: "</span>")
          fontStyling = false
        }
        switch m {
          case "B":
            res = #"<span class="bold">"#
            s.removeFirst(1)
            fontStyling = true
          case "I":
            res = #"<span class="italic">"#
            s.removeFirst(1)
            fontStyling = true
          case "R": // regular font
            s.removeFirst(1)
            fontStyling = false
          case "P": // revert to previous font
            // technically, this implies that the font stylings can be nested,
            // but we will pretend they cannot
            s.removeFirst(1) // the \f triggered the </span> -- so nothing else needs to be done
            fontStyling = false
          default:
            break
        }
      case "s": // font size
        if fontSizing { res.append(contentsOf: "</span>") }
        if let k = s.dropFirst(2).prefixMatch(of: /[-+]?\d+/),
           let kk = Int(String(k.output) ) {
          if kk != 0 {
            fontSizing = true
            var fs = 1.0
            let baseline : Double = 11
            if kk > 0 { fs = (baseline + fs ) / baseline }
            else { fs = (baseline - fs ) / baseline }
            res = "<span style=\"font-size: \(fs)em\">"
          } else {
            fontSizing = false
            res = "</span>"
          }
          s.removeFirst(k.output.count)
        }
      case "(": // changes to courier if followed by CW
        break
      default:
        res = String(k)
    }
    s.removeFirst(2)
    return res
  }
  
  func popEscapedChar(_ s : inout Substring) -> Substring {
    let ss = s.dropFirst()
    
    // if this is a predefined character sequence, look it up and return it
    for (i,j) in escapeSequences {
      if ss.hasPrefix(i) {
        s = ss.dropFirst(i.count)
        return Substring(j)
      }
    }
    
    // if it is a defined string, look it up and return it
    if let k = s.dropFirst().first, k == "*" {
      return Substring(popDefinedString(&s))
    }
    
    // if it is a font control sequence, parse that
    if let k = s.dropFirst().first {
      return Substring(parseFontControl(&s, k))
    } else {
      // keep the trailing backslash?
      s.removeFirst()
      return "\\"
    }
  }

  var lineNo : Int {
    lines.startIndex - 1
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

  func setz(_ s : Substring) {
    string = s
    nextToken = nil
    nextWord = nil
    fontStyling = false
    fontSizing = false
  }

  func clearz() {
    string = peekLine
    nextToken = nil
    nextWord = nil
    fontStyling = false
    fontSizing = false
  }
}
