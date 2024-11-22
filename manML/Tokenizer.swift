//
// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024
    

import Foundation

let escapeSequences = [
  // accented characters
   "'a": "á",
   "a`": "à",
   "^a": "â",
   "\"a": "ä",
   "oA": "å",
   "'e": "é",
   "e`": "è",
   "^e": "ê",
   "\"e": "ë",
   "'i": "í",
   "i`": "ì",
   "^i": "î",
   "\"i": "ï",
   "'o": "ó",
   "o`": "ò",
   "^o": "ô",
   "\"o": "ö",
   "/o": "ø",
   "'u": "ú",
   "u`": "ù",
   "^u": "û",
   "\"u": "ü",
   "~n": "ñ",
   ",c": "ç",
   
   // special characters
   "(co" : "©",
   "(rg" : "®",
   "(:o" : "°",
   "(+-" : "±",
   "(/"  : "÷",
   "(mu" : "×",
   "(sc" : "§",
   "(ps" : "¶",
   "(tm" : "™",
   
   // greek letters
   "(ga" : "α",
   "(gb" : "β",
   "(gc" : "γ",
   "(gd" : "δ",
   "(ge" : "ε",
   "(gh" : "θ",
   "(gl" : "λ",
   "(gm" : "μ",
   "(gp" : "π",
   "(gs" : "σ",
   "(gf" : "φ",
   "(go" : "ω",
   
   // mathematical symbols
   "(su" : "∑",
   "(sp" : "∏",
   "(if" : "∞",
   "(sr" : "√",
   "(<=" : "≤",
   "(>=" : "≥",
   "(ne" : "≠",
   
   // ====================
   
   "&" : "", // "&#x200B;", // zero width space
   "e" : "\\",
   " " : "&nbsp;",
   "-" : "-",
   "|" : "&#8239;", // narrow non-breaking space
   "," : "&#8202;", // hair space
   "/" : "&thinsp;", // italic correction
   "~" : "&nbsp;",
   "^" : "&thinsp;", // another thin space
   "%" : "&#8209;", // non-breaking hyphen

]

struct Token {
  let value : Substring
  let closingDelimiter : String
  let isMacro : Bool
}

class Tokenizer : IteratorProtocol {
  var string : Substring
  var nextWord : Substring?
  var nextToken : Token?
  var stringPos : Int
  
  let closingDelimiters = ".,:;)]?!"
  let openingDelimiters = "(["
  let middleDelimiters = "|"
  
//  var previousClosingDelimiter = ""
  var definitions : [String : String]
  
  var fontStyling = false
  var fontSizing = false
  
  init(_ s : any StringProtocol, _ pos : Int, definitions: [String : String]) {
    string = Substring(s)
    self.definitions = definitions
    stringPos = pos
  }
  
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
    
    nextWord = popWord()
    var cd : String = ""
    
    // If this token is a macro token, do NOT consume a closing delimiter
    if let k, macroList.contains(k) {
    } else {
      // here is where I set the closing delimiter
      if nextWord != nil,
         nextWord!.count == 1,
         let cdx = nextWord!.first,
         closingDelimiters.contains(cdx) {
        cd = String(cdx) + " "
        nextWord = popWord()
      } else {
        cd = nextWord == nil ? "\n" : " "
      }
    }
    
    if nextWord == "Ns" || nextWord == "Ap" { cd = String(cd.dropLast()) }
    
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
      while let s = string.first, s != "\"" {
        res.append(s)
        string.removeFirst()
      }
      if string.first == "\"" { string.removeFirst() }
      // FIXME: need to deal with escaped closing quote
      return escaped(res)
    }
    // for that weird construction: "el\\{\\"
    var k : Substring
    if string.first == "\\" {
      k = string.prefix(while: { $0 != " " && $0 != "\t" } )
    } else {
      k = string.prefix(while: { $0 != " " && $0 != "\t" && $0 != "\\"} )
    }
    string = string.dropFirst(k.count)
    return escaped(k)
  }

  /*
  func peekToken() -> Substring? {
    if nextWord != nil { return nextWord }
    nextWord = popWord()
    return nextWord
  }
*/
  
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
      output.append(cd)
      output.append(contentsOf: t.value)
      cd = t.closingDelimiter
    }
    return Token(value: Substring(output), closingDelimiter: cd, isMacro: true)
  }
}





extension Tokenizer {
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
      let mx = definitions.keys.max(by: { $0.count < $1.count } )?.count ?? 0
      for n in 1...mx {
        let pp = s.prefix(n)
        if definitions.keys.contains(String(pp)) {
          let res = definitions[String(pp)]!
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
      default: // res.append("\\")
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

}
