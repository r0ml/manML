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
  var fontStyling : [String] = []
  var fontSizing = false
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
    fontStyling = []
    fontSizing = false
    definedString = initialDefinedString
    definedMacro = [:]
    string = ""
    nextWord = nil
    nextToken = nil
    openingDelimiter = nil
    spacingMode = true
  }

  func setMandoc(_ s : SourceWrapper) async {
    reinit()
    await mandoc.setSourceWrapper(s)
  }

  func toHTML() async throws(ThrowRedirect) -> String {
    return try await mandoc.toHTML()
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
        var x : Substring
        (x, s) = popEscapedChar(s)
        res.append(contentsOf: x)
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
    // This gets called and wrapped in a <span> -- so if I try to leave the span open for fonting, it gets closed by the invoking handleLine()
    for _ in fontStyling { res.append(contentsOf: "</span>") }
    return res
  }

  private func popDefinedString(_ sx : String) -> (String, String) {
    var s = sx.dropFirst(2)
    guard !s.isEmpty else { return ("", String(s) ) }

    var lookup = String(s.removeFirst())

//  \*x  single char name
//  \*(xx  double char name
//  \*[xyz]  multichar name

    if lookup == "(" {
      lookup = String(s.prefix(2))
      s = s.dropFirst(2)
    } else if lookup == "[" {
      // at this point, I'm looking for a defined string -- but there is no marker for where the string ends.
      // So we keep trying adding one character at a time until we give up
      lookup = String(s.prefix { $0 != "]" } )
      s = s.dropFirst(lookup.count + 1)
    }
    if let mx = definedString[lookup] {
      return (mx, String(s) )
    } else {
      return ( "undefined:\(lookup)", String(s) )
    }
  }

  private func holdovers() -> String {
    var res = ""
    for i in fontStyling {
      switch i {
        case "B": res.append("<span class=bold>")
        case "I": res.append("<span class=italic")
        case "C": res.append("<span class=pre")
        default: break
      }
    }
    return res
  }

  private func parseFontControl(_ sx : String ) -> (String, String) {
    var s = sx
    var res = ""
    let k = s.removeFirst()
    switch k {
      case "f":   // font style
        let m = s.isEmpty ? nil : s.removeFirst()
        switch m {
          case "B":
            res.append( #"<span class="bold">"# )
            fontStyling.append("B")
          case "I":
            res = #"<span class="italic">"#
            fontStyling.append("I")
          case "R": // regular font
            while fontStyling.count > 0 {
              res.append("</span>")
              fontStyling.removeLast()
            }
          case "P":
            if fontStyling.count > 0 {
              res.append("</span>")
              fontStyling.removeLast()
            }

          case "[":
            let j = s.prefix { $0 != "]" }
            s.removeFirst(j.count + 1)
            switch j.dropFirst() {
              case "B":
                fontStyling.append("B")
                res.append( #"<span class="bold">"# )
              case "R":
                while fontStyling.count > 0 {
                  fontStyling.removeLast()
                  res.append("</span>")
                }
              case "I":
                res.append( #"<span class="italic">"# )
                fontStyling.append("I")
              case "P", "":
                if fontStyling.count > 0 {
                  fontStyling.removeLast()
                  res.append("</span>")
                }
              default:
                res = "<span class=\"unimplemented\">unknown font: \(j.dropFirst())</span>"
            }

          case "(": // changes to courier if followed by CW
            if s.hasPrefix("CW") { s.removeFirst(2) }
            fontStyling.append("C")
            res.append("<span class=pre>" )

          default:
            break
        }
      case "s": // font size
        if fontSizing { res.append(contentsOf: "</span>"); fontSizing = false }
        if let k = s.prefixMatch(of: /[-+]?\d+/),
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
      default:
        res = String(k)
    }
    return (res, s)
  }

  private func popEscapedChar(_ sx : String) -> (Substring, String) {
    var s = sx
    let ss = s.dropFirst()

    // if this is a predefined character sequence, look it up and return it
    for (i,j) in escapeSequences {
      if ss.hasPrefix(i) {
        s = String(ss.dropFirst(i.count))
        return (Substring(j), s)
      }
    }

    // if it is a defined string, look it up and return it
    if let k = s.dropFirst().first, k == "*" {
      let (res, s) = popDefinedString(s)
      return (Substring(res), s)
    }

    // if it is a font control sequence, parse that
    s.removeFirst()
    if !s.isEmpty {
      let (res, s) = parseFontControl(s)
      return (Substring(res), s)
    } else {
      // keep the trailing backslash?
      return ("\\", s)
    }
  }

  func reset() {
    fontStyling = []
    fontSizing = false
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
      var k : Substring
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
          if string.first == "\\" {
            (k, string) = popEscapedChar(string)
            res.0.append(contentsOf: k)
// FIXME: need to have popEscapedChar return both kinds
          } else {
            k = string.prefix(1)
            if k == " " || k == "\t" { break }
            string.removeFirst()
            res.0.append(contentsOf: safify(k) )
            res.1.append(contentsOf: k)
          }
        }
        return res
      }
  }

  func safify(_ s : any StringProtocol) -> String {
    return CFXMLCreateStringByEscapingEntities(nil, String(s) as CFString, nil) as String
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


  func nextArg(enders: [String]) async throws(ThrowRedirect) -> Token? {
    guard let k = peekToken() else { return nil }

    if k.isMacro {
      if enders.contains(String(k.value)) {
        return nil
      } else {
        // FIXME: when I'm here, I don't need to read subsequence lines?
        //      var aa = ArraySlice<Substring>()
        return try await mandoc.macro(enders: enders)
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

