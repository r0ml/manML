// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <r0ml@liberally.net> in 2025

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
