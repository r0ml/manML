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
   
   // Lines:
   "(ba": "|", //  bar
   "(br": "│", //  box rule
   "(ul": "_", //  underscore
   "(ru": "_", //  underscore (width 0.5m)
   "(rn": "‾", //  overline
   "(bb": "¦", //  broken bar
   "(sl": "/", //  forward slash
   "(rs": "\\", //  backward slash

   // Text markers:
   "(ci": "○", //  circle
   "(bu": "•", //  bullet
   "(dd": "‡", //  double dagger
   "(dg": "†", //  dagger
   "(lz": "◊", //  lozenge
   "(sq": "□", //  white square
   "(ps": "¶", //  paragraph
   "(sc": "§", //  section
   "(lh": "☜", //  left hand
   "(rh": "☞", //  right hand
   "(at": "@", //  at
   "(sh": "#", //  hash (pound)
   "(CR": "↵", //  carriage return
   "(OK": "✓", //  check mark
   "(CL": "♣", //  club suit
   "(SP": "♠", //  spade suit
   "(HE": "♥", //  heart suit
   "(DI": "♦", //  diamond suit

   // Legal symbols
   "(co" : "©", // copyright
   "(rg" : "®", // registered
   "(tm" : "™", // trademarked

   // Punctuation
   "(em": "—", //  em-dash
   "(en": "–", //  en-dash
   "(hy": "‐", //   hyphen
   "e": "\\", //  back-slash
   ".": ".", //  period
   "(r!": "¡", //  upside-down exclamation
   "(r?": "¿", //  upside-down question

    // Quotes
   "(Bq": "„", //  right low double-quote
   "(bq": "‚", //  right low single-quote
   "(lq": "“", //  left double-quote
   "(rq": "”", //  right double-quote
   "(oq": "‘", //  left single-quote
   "(cq": "’", //  right single-quote
   "(aq": "'", //  apostrophe quote (ASCII character)
   "(dq": "\"", // double quote (ASCII character)
   "(Fo": "«", //  left guillemet
   "(Fc": "»", //  right guillemet
   "(fo": "‹", //  left single guillemet
   "(fc": "›", //  right single guillemet

   // brackets
   "(lB": "[", //  left bracket
   "(rB": "]", //  right bracket
   "(lC": "{", //  left brace
   "(rC": "}", //  right brace
   "(la": "⟨", //  left angle
   "(ra": "⟩", //  right angle
   "(bv": "⎪", //  brace extension (special font)
   "[braceex]": "⎪", //  brace extension
   "[bracketlefttp]": "⎡", //  top-left hooked bracket
   "[bracketleftbt]": "⎣", //  bottom-left hooked bracket
   "[bracketleftex]": "⎢", //  left hooked bracket extension
   "[bracketrighttp]": "⎤", //  top-right hooked bracket
   "[bracketrightbt]": "⎦", //  bottom-right hooked bracket
   "[bracketrightex]": "⎥", //  right hooked bracket extension
   "(lt": "⎧", //  top-left hooked brace
   "[bracelefttp]": "⎧", //  top-left hooked brace
   "(lk":  "⎨", //  mid-left hooked brace
   "[braceleftmid]": "⎨", //  mid-left hooked brace
   "(lb": "⎩", //  bottom-left hooked brace
   "[braceleftbt]": "⎩", //  bottom-left hooked brace
   "[braceleftex]": "⎪", //  left hooked brace extension
   "(rt":  "⎫", //  top-left hooked brace
   "[bracerighttp]": "⎫", //  top-right hooked brace
   "(rk": "⎬", // mid-right hooked brace
   "[bracerightmid]": "⎬", //  mid-right hooked brace
   "(rb": "⎭", //  bottom-right hooked brace
   "[bracerightbt]": "⎭", //  bottom-right hooked brace
   "[bracerightex]": "⎪", //  right hooked brace extension
   "[parenlefttp]": "⎛", //  top-left hooked parenthesis
   "[parenleftbt]": "⎝", //  bottom-left hooked parenthesis
   "[parenleftex]": "⎜", //  left hooked parenthesis extension
   "[parenrighttp]": "⎞", //  top-right hooked parenthesis
   "[parenrightbt]": "⎠", //  bottom-right hooked parenthesis
   "[parenrightex]": "⎟", //  right hooked parenthesis extension

   // Arrows
   "(<-": "←", //  left arrow
   "(->": "→", //  right arrow
   "(<>": "↔", //  left-right arrow
   "(da": "↓", //  down arrow
   "(ua": "↑", //  up arrow
   "(va": "↕", //  up-down arrow
   "(lA": "⇐", //  left double-arrow
   "(rA": "⇒", //  right double-arrow
   "(hA": "⇔", //  left-right double-arrow
   "(uA": "⇑", //  up double-arrow
   "(dA": "⇓", //  down double-arrow
   "(vA": "⇕", //  up-down double-arrow
   "(an": "⎯", //  horizontal arrow extension

   // Logical
   "(AN": "∧", //  logical and
   "(OR": "∨", //  logical or
   "[tno]": "¬", //  logical not (text font)
   "(no": "¬", //  logical not (special font)
   "(te": "∃", //  existential quantifier
   "(fa": "∀", //  universal quantifier
   "(st": "∋", //  such that
   "(tf": "∴", //  therefore
   "(3d": "∴", //  therefore
   "(or": "|", //  bitwise or

   // Mathematical
   "-": "-", //  minus (text font)
   "(mi": "−", //  minus (special font)
   "(pl": "+", //  plus (special font)
   "(-+": "∓", //  minus-plus
   "[t+-]": "±", // plus-minus (text font)
   "(+-": "±", //  plus-minus (special font)
   "(pc": "·", //  center-dot
   "[tmu]": "×", //  multiply (text font)
   "(mu": "×", //  multiply (special font)
   "(c*": "⊗", //  circle-multiply
   "(c+": "⊕", //  circle-plus
   "[tdi]": "÷", //  divide (text font)
   "(di": "÷", //  divide (special font)
   "(f/": "⁄", //  fraction
   "(**": "∗", //  asterisk
   "(<=": "≤", //  less-than-equal
   "(>=": "≥", //  greater-than-equal
   "(<<": "≪", //  much less
   "(>>": "≫", //  much greater
   "(eq": "=", //  equal
   "(!=": "≠", //  not equal
   "(==": "≡", //  equivalent
   "(ne": "≢", //  not equivalent
   "(ap": "∼", //  tilde operator
   "(|=": "≃", //  asymptotically equal
   "(=~": "≅", //  approximately equal
   "(~~": "≈", //  almost equal
   "(~=": "≈", //  almost equal
   "(pt": "∝", //  proportionate
   "(es": "∅", //  empty set
   "(mo": "∈", //  element
   "(nm": "∉", //  not element
   "(sb": "⊂", //  proper subset
   "(nb": "⊄", //  not subset
   "(sp": "⊃", //  proper superset
   "(nc": "⊅", //  not superset
   "(ib": "⊆", //  reflexive subset
   "(ip": "⊇", //  reflexive superset
   "(ca": "∩", //  intersection
   "(cu": "∪", //  union
   "(/_": "∠", //  angle
   "(pp": "⊥", //  perpendicular
   "(is": "∫", //  integral
   "[integral]": "∫", //  integral
   "[sum]": "∑", //  summation
   "[product]": "∏", //  product
   "[coproduct]": "∐", //  coproduct
   "(gr": "∇", //  gradient
   "(sr":  "√", //  square root
   "[sqrt]": "√", //  square root
   "(lc": "⌈", //  left-ceiling
   "(rc": "⌉", //  right-ceiling
   "(lf": "⌊", //  left-floor
   "(rf": "⌋", //  right-floor
   "(if": "∞", //  infinity
   "(Ah": "ℵ", //  aleph
   "(Im": "ℑ", //  imaginary
   "(Re": "ℜ", //  real
   "(wp": "℘", //  Weierstrass p
   "(pd": "∂", //  partial differential
   "(-h": "ℏ", //  Planck constant over 2π
   "[hbar]": "ℏ", //  Planck constant over 2π
   "(12": "½", //  one-half
   "(14": "¼", //  one-fourth
   "(34": "¾", //  three-fourths
   "(18": "⅛", //  one-eighth
   "(38": "⅜", //  three-eighths
   "(58": "⅝", //  five-eighths
   "(78": "⅞", //  seven-eighths
   "(S1": "¹", //  superscript 1
   "(S2": "²", //  superscript 2
   "(S3": "³", //  superscript 3

   // Ligatures
   "(ff": "ﬀ", //  ff ligature
   "(fi": "ﬁ", //  fi ligature
   "(fl": "ﬂ", //  fl ligature
   "(Fi": "ﬃ", //  ffi ligature
   "(Fl": "ﬄ", //  ffl ligature
   "(AE": "Æ", //  AE
   "(ae": "æ", //  ae
   "(OE": "Œ", //  OE
   "(oe": "œ", //  oe
   "(ss": "ß", //  German eszett
   "(IJ": "Ĳ", //  IJ ligature
   "(ij": "ĳ", //  ij ligature

   // Accents
   "(a\"": "˝", //  Hungarian umlaut
   "(a-": "¯", //  macron
   "(a.": "˙", //  dotted
   "(a^": "^", //  circumflex
   "(aa": "´", //  acute
   "\'": "´", //  acute
//   "(ga": "`", //  grave
   "`" : "`", //  grave
   "(ab": "˘", //  breve
   "(ac": "¸", //  cedilla
   "(ad": "¨", //  dieresis
   "(ah": "ˇ", //  caron
   "(ao": "˚", //  ring
   "(a~": "~", //  tilde
   "(ho": "˛", //  ogonek
   "(ha": "^", //  hat (ASCII character)
   "(ti": "~", //  tilde (ASCII character)

   // Accented letters
   "('A": "Á", //  acute A
   "('E": "É", //  acute E
   "('I": "Í", //  acute I
   "('O": "Ó", //  acute O
   "('U": "Ú", //  acute U
   "('Y": "Ý", //  acute Y
   "('a": "á", //  acute a
   "('e": "é", //  acute e
   "('i": "í", //  acute i
   "('o": "ó", //  acute o
   "('u": "ú", //  acute u
   "('y": "ý", //  acute y
   "(`A": "À", //  grave A
   "(`E": "È", //  grave E
   "(`I": "Ì", //  grave I
   "(`O": "Ò", //  grave O
   "(`U": "Ù", //  grave U
   "(`a": "à", //  grave a
   "(`e": "è", //  grave e
   "(`i": "ì", //  grave i
   "(`o": "ì", //  grave o
   "(`u": "ù", //  grave u
   "(~A": "Ã", //  tilde A
   "(~N": "Ñ", //  tilde N
   "(~O": "Õ", //  tilde O
   "(~a": "ã", //  tilde a
   "(~n": "ñ", //  tilde n
   "(~o": "õ", //  tilde o
   "(:A": "Ä", //  dieresis A
   "(:E": "Ë", //  dieresis E
   "(:I": "Ï", //  dieresis I
   "(:O": "Ö", //  dieresis O
   "(:U": "Ü", //  dieresis U
   "(:a": "ä", //  dieresis a
   "(:e": "ë", //  dieresis e
   "(:i": "ï", //  dieresis i
   "(:o": "ö", //  dieresis o
   "(:u": "ü", //  dieresis u
   "(:y": "ÿ", //  dieresis y
   "(^A": "Â", //  circumflex A
   "(^E": "Ê", //  circumflex E
   "(^I": "Î", //  circumflex I
   "(^O": "Ô", //  circumflex O
   "(^U": "Û", //  circumflex U
   "(^a": "â", //  circumflex a
   "(^e": "ê", //  circumflex e
   "(^i": "î", //  circumflex i
   "(^o": "ô", //  circumflex o
   "(^u": "û", //  circumflex u
   "(,C": "Ç", //  cedilla C
   "(,c": "ç", //  cedilla c
   "(/L": "Ł", //  stroke L
   "(/l": "ł", //  stroke l
   "(/O": "Ø", //  stroke O
   "(/o": "ø", //  stroke o
   "(oA": "Å", //  ring A
   "(oa": "å", //  ring a

   // Special letters
   "(-D": "Ð", //  Eth
   "(Sd": "ð", //  eth
   "(TP": "Þ", //  Thorn
   "(Tp": "þ", //  thorn
   "(.i": "ı", //  dotless i
   "(.j": "ȷ", //  dotless j

   // Currency:
   "(Do": "$", //  dollar
   "(ct": "¢", //  cent
   "(Eu": "€", //  Euro symbol
   "(eu": "€", //  Euro symbol
   "(Ye": "¥", //  yen
   "(Po": "£", //  pound
   "(Cs": "¤", //  Scandinavian
   "(Fn": "ƒ", //  florin
  
   // Units
   "(de": "°", //  degree
   "(%0": "‰", //  per-thousand
   "(fm": "′", //  minute
   "(sd": "″", //  second
   "(mc": "µ", //  micro
   "(Of": "ª", //  Spanish female ordinal
   "(Om": "º", //  Spanish masculine ordinal

  // Greek letters
   "(*A": "Α", //  Alpha
   "(*B": "Β", //  Beta
   "(*G": "Γ", //  Gamma
   "(*D": "Δ", //  Delta
   "(*E": "Ε", //  Epsilon
   "(*Z": "Ζ", //  Zeta
   "(*Y": "Η", //  Eta
   "(*H": "Θ", //  Theta
   "(*I": "Ι", //  Iota
   "(*K": "Κ", //  Kappa
   "(*L": "Λ", //  Lambda
   "(*M": "Μ", //  Mu
   "(*N": "Ν", //  Nu
   "(*C": "Ξ", //  Xi
   "(*O": "Ο", //  Omicron
   "(*P": "Π", //  Pi
   "(*R": "Ρ", //  Rho
   "(*S": "Σ", //  Sigma
   "(*T": "Τ", //  Tau
   "(*U": "Υ", //  Upsilon
   "(*F": "Φ", //  Phi
   "(*X": "Χ", //  Chi
   "(*Q": "Ψ", //  Psi
   "(*W": "Ω", //  Omega
   "(*a": "α", //  alpha
   "(*b": "β", //  beta
   "(*g": "γ", //  gamma
   "(*d": "δ", //  delta
   "(*e": "ε", //  epsilon
   "(*z": "ζ", //  zeta
   "(*y": "η", //  eta
   "(*h": "θ", //  theta
   "(*i": "ι", //  iota
   "(*k": "κ", //  kappa
   "(*l": "λ", //  lambda
   "(*m": "μ", //  mu
   "(*n": "ν", //  nu
   "(*c": "ξ", //  xi
   "(*o": "ο", //  omicron
   "(*p": "π", //  pi
   "(*r": "ρ", //  rho
   "(*s": "σ", //  sigma
   "(*t": "τ", //  tau
   "(*u": "υ", //  upsilon
   "(*f": "ϕ", //  phi
   "(*x": "χ", //  chi
   "(*q": "ψ", //  psi
   "(*w": "ω", //  omega
   "(+h": "ϑ", //  theta variant
   "(+f": "φ", //  phi variant
   "(+p": "ϖ", //  pi variant
   "(+e": "ϵ", //  epsilon variant
   "(ts": "ς", //  sigma terminal

  // Predefined
   "*(Ba": "|", //  vertical bar
   "*(Ne": "≠", //  not equal
   "*(Ge": "≥", //  greater-than-equal
   "*(Le": "≤", //  less-than-equal
   "*(Gt": ">", //  greater-than
   "*(Lt": "<", //  less-than
   "*(Pm": "±", //  plus-minus
   "*(If": "infinity", // infinity
   "*(Pi": "pi", //  pi
   "*(Na": "NaN", //  NaN
   "*(Am": "&", //  ampersand
   "*R": "®", //  restricted mark
   "*(Tm":  "(Tm)", //  trade mark
   "*q": "\"", //  double-quote
   "*(Rq": "”", //  right-double-quote
   "*(Lq":  "“", //  left-double-quote
   "*(lp":  "(", //  right-parenthesis
   "*(rp":  ")", //  left-parenthesis
   "*(lq":  "“", //  left double-quote
   "*(rq":  "”", //  right double-quote
   "*(ua":  "↑", //  up arrow
   "*(va":  "↕", //  up-down arrow
   "*(<=":  "≤", //  less-than-equal
   "*(>=":  "≥", //  greater-than-equal
   "*(aa":  "´", //  acute
   "*(ga":  "`", //  grave
   "*(Px":  "POSIX", //  POSIX standard name
   "*(Ai":  "ANSI", //  ANSI standard name

   "(/"  : "÷",
   
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
   
   // ====================
   
   "&" : "&#x200B;", // "&#x200B;", // zero width space
   " " : "&nbsp;",
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
//  var stringPos : Int

  let closingDelimiters = ".,:;)]?!"
  let openingDelimiters = "(["
  let middleDelimiters = "|"
  
  var parseState : ParseState
  
  var fontStyling = false
  var fontSizing = false
  
  init(_ s : any StringProtocol, /* _ pos : Int, */ parseState : ParseState) { //   definitions: [String : String]) {
    string = Substring(s)
    self.parseState = parseState
//    stringPos = pos
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
    nextWord = nil
    
    if let k, closingDelimiters.contains(k) {
      return Token(value: "", closingDelimiter: String(k), isMacro: false)
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
    
    if nextWord == "Ns" || nextWord == "Ap" || !parseState.spacingMode { cd = String(cd.dropLast()) }
    
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
    } else {
      // for that weird construction: "el\\{\\"
      var k : Substring
//      if string.first == "\\" {
//        k = string.prefix(while: { $0 != " " && $0 != "\t" } )
//      } else {
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
//      string = string.dropFirst(k.count)
//      return escaped(k)
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
      let mx = parseState.definedString.keys.max(by: { $0.count < $1.count } )?.count ?? 1
      for n in 1...mx {
        let pp = s.prefix(n)
        if parseState.definedString.keys.contains(String(pp)) {
          let res = parseState.definedString[String(pp)]!
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
