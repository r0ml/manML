//
// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024
    

import Foundation

let macroList = "%A %B %C %D %I %J %N %O %P %Q %R %T %U %V Ac Ad An Ao Ap Aq Ar At Bc Bd Bf Bk Bl Bo Bq Brc Bro Brq Bsx Bt Cd Cm D1 Db Dc Dd Dl Do Dq Dt Dv Dx Ec Ed Ef Ek El Em En Eo Er Es Ev Ex Fa Fc Fd Fl Fn Fo Fr Ft Fx Hf Ic In It Lb Li Lk Lp Ms Mt Nd Nm No Ns Nx Oc Oo Op Os Ot Ox Pa Pc Pf Po Pp Pq Qc Ql Qo Qq Re Rs Rv Sc Sh Sm So Sq Ss St Sx Sy Ta Tn Ud Ux Va Vt Xc Xo Xr".split(separator: " ")

let standards = [
  "-ansiC": "ANSI X3.159-1989 (“ANSI~C89”)",
  "-ansiC-89": "ANSI X3.159-1989 (“ANSI~C89”)",
  "-isoC": "ISO/IEC 9899:1990 (“ISO~C90”)",
  "-isoC-90": "ISO/IEC 9899:1990 (“ISO~C90”)",
  "-isoC-amd1": "ISO/IEC 9899/AMD1:1995 (“ISO~C90, Amendment 1”)",
  "-isoC-tcor1": "ISO/IEC 9899/TCOR1:1994 (“ISO~C90, Technical Corrigendum 1”)",
  "-isoC-tcor2": "ISO/IEC 9899/TCOR2:1995 (“ISO~C90, Technical Corrigendum 2”)",
  "-isoC-99": "ISO/IEC 9899:1999 (“ISO~C99”)",
  "-isoC-2011": "ISO/IEC 9899:2011 (“ISO~C11”)",
  
  "-p1003.1-88": "IEEE Std 1003.1-1988 (“POSIX.1”)",
  "-p1003.1": "IEEE Std 1003.1 (“POSIX.1”)",
  "-p1003.1-90": "IEEE Std 1003.1-1990 (“POSIX.1”)",
  "-iso9945-1-90": "ISO/IEC 9945-1:1990 (“POSIX.1”)",
  "-p1003.1b-93": "IEEE Std 1003.1b-1993 (“POSIX.1b”)",
  "-p1003.1b": "IEEE Std 1003.1b (“POSIX.1b”)",
  "-p1003.1c-95": "IEEE Std 1003.1c-1995 (“POSIX.1c”)",
  "-p1003.1i-95": "IEEE Std 1003.1i-1995 (“POSIX.1i”)",
  "-p1003.1-96": "ISO/IEC 9945-1:1996 (“POSIX.1”)",
  "-iso9945-1-96": "ISO/IEC 9945-1:1996 (“POSIX.1”)",

  "-xpg3": "X/Open Portability Guide Issue~3 (“XPG3”)",
  "-p1003.2": "IEEE Std 1003.2 (“POSIX.2”)",
  "-p1003.2-92": "IEEE Std 1003.2-1992 (“POSIX.2”)",
  "-iso9945-2-93": "ISO/IEC 9945-2:1993 (“POSIX.2”)",
  "-p1003.2a-92": "IEEE Std 1003.2a-1992 (“POSIX.2”)",
  "-xpg4": "X/Open Portability Guide Issue~4 (“XPG4”)",

  "-susv1": "Version~1 of the Single UNIX Specification (“SUSv1”)",
  "-xpg4.2": "X/Open Portability Guide Issue~4, Version~2 (“XPG4.2”)",
  "-xsh4.2": "X/Open System Interfaces and Headers Issue~4, Version~2 (“XSH4.2”)",
  "-xcurses4.2": "X/Open Curses Issue~4, Version~2 (“XCURSES4.2”)",
  "-p1003.1g-2000": "IEEE Std 1003.1g-2000 (“POSIX.1g”)",
  "-svid4": "System~V Interface Definition, Fourth Edition (“SVID4”)",

  "-susv2": "Version~2 of the Single UNIX Specification (“SUSv2”)",
  "-xbd5": "X/Open Base Definitions Issue~5 (“XBD5”)",
  "-xsh5": "X/Open System Interfaces and Headers Issue~5 (“XSH5”)",
  "-xcu5": "X/Open Commands and Utilities Issue~5 (“XCU5”)",
  "-xns5": "X/Open Networking Services Issue~5 (“XNS5”)",
  "-xns5.2": "X/Open Networking Services Issue~5.2 (“XNS5.2”)",
  
  "-p1003.1-2001": "IEEE Std 1003.1-2001 (“POSIX.1”)",
  "-susv3": "Version~3 of the Single UNIX Specification (“SUSv3”)",
  "-p1003.1-2004": "IEEE Std 1003.1-2004 (“POSIX.1”)",

  "-p1003.1-2008": "IEEE Std 1003.1-2008 (“POSIX.1”)",
  "-susv4": "Version~4 of the Single UNIX Specification (“SUSv4”)",
  "-p1003.1-2013": "IEEE Std 1003.1-2008/Cor 1-2013 (“POSIX.1”)",

  "-ieee754": "IEEE Std 754-1985",
  "-iso8601": "ISO 8601",
  "-iso8802-3": "ISO 8802-3: 1989",
  "-ieee1275-94": "IEEE Std 1275-1994 (“Open Firmware”)"
  
]

let sections = [ "1" : "General Commands Maual",
                 "2" : "System Calls Manual",
                 "3" : "Library Functions Manual",
                 "4" : "Special Files Manual",
                 "5" : "File Formats Manual",
                 "6" : "Games Manual",
                 "7" : "Miscellaneous Manual",
                 "8" : "Systems Administration Manual",
                 "9" : "Kernel Routines Manual",
                 "n" : "Non-Standard Extensions Manual",
                 ]

let blockFullExplicit = ["Bd" : "Ed", "Bf" : "Ef",
                         "Bk" : "Ek", "Bl" : "El",
                         ]

let blockFullImplicit = ["It": ["It", "El"],
                         "Nd": ["Sh"],
                         "Nm": ["Nm", "Sh", "Ss"],
                         "Sh": ["Sh"],
                         "Ss": ["Sh", "Ss"],
                         ]
let blockPartialExplicit = ["Ao": "Ac",
                            "Bo": "Bc",
                            "Bro": "Brc",
                            "Do": "Dc",
                            "Eo": "Ec",
                            "Fo": "Fc",
                            "Oo": "Oc",
                            "Po": "Pc",
                            "Qo": "Qc",
                            "Rs": "Re",
                            "So": "Sc",
                            "Xo": "Xc",
                            ]

let blockPartialImplicit = ["Aq", "Bq", "Brq", "Dl", "D1", "Dq",
                            "En", "Op", "Pq", "Ql", "Qq", "Sq", "Vt",
                            ]

let inLine = ["%A", "%B", "%C", "%D", "%I", "%J", "%N", "%O", "%P",
              "%Q", "%R", "%T", "%U", "%V", "Ad", "An", "Ap", "Ar",
              "At", "Bsx", "Bt", "Bx", "Cd", "Cm", "Db", "Dd", "Dt",
              "Dv", "Dx", "Em", "Er", "Es", "Ev", "Ex", "Fa",
              "Fd", "Fl", "Fn", "Fr", "Ft", "Fx", "Hf", "Ic",
              "In", "Lb", "Li", "Lk", "Lp", "Ms", "Mt", "Nm",
              "No", "Ns", "Nx", "Os", "Ot", "Ox", "Pa", "Pf",
              "Pp", "Rv", "Sm", "St", "Sx", "Sy", "Tg", "Tn",
              "Ud", "Ux", "Va", "Vt", "Xr",
            ]


let att = [
  "v1": "Version 1 AT&T UNIX",
  "v2": "Version 2 AT&T UNIX",
  "v3": "Version 3 AT&T UNIX",
  "v4": "Version 4 AT&T UNIX",
  "v5": "Version 5 AT&T UNIX",
  "v6": "Version 6 AT&T UNIX",
  "v7": "Version 7 AT&T UNIX",
  "32v": "Version 7 AT&T UNIX/32V",
  "III": "AT&T System III UNIX",
  "V": "AT&T System V UNIX",
  "V.1": "AT&T System V Release 1 UNIX",
  "V.2": "AT&T System V Release 2 UNIX",
  "V.3": "AT&T System V Release 3 UNIX",
  "V.4": "AT&T System V Release 4 UNIX"
]


/*
 Lines:

 Input  Rendered  Description
 \(ba  |  bar
 \(br  │  box rule
 \(ul  _  underscore
 \(ru  _  underscore (width 0.5m)
 \(rn  ‾  overline
 \(bb  ¦  broken bar
 \(sl  /  forward slash
 \(rs  \  backward slash
 Text markers:

 Input  Rendered  Description
 \(ci  ○  circle
 \(bu  •  bullet
 \(dd  ‡  double dagger
 \(dg  †  dagger
 \(lz  ◊  lozenge
 \(sq  □  white square
 \(ps  ¶  paragraph
 \(sc  §  section
 \(lh  ☜  left hand
 \(rh  ☞  right hand
 \(at  @  at
 \(sh  #  hash (pound)
 \(CR  ↵  carriage return
 \(OK  ✓  check mark
 \(CL  ♣  club suit
 \(SP  ♠  spade suit
 \(HE  ♥  heart suit
 \(DI  ♦  diamond suit
 Legal symbols:

 Input  Rendered  Description
 \(co  ©  copyright
 \(rg  ®  registered
 \(tm  ™  trademarked
 Punctuation:

 Input  Rendered  Description
 \(em  —  em-dash
 \(en  –  en-dash
 \(hy  ‐  hyphen
 \e  \  back-slash
 \.  .  period
 \(r!  ¡  upside-down exclamation
 \(r?  ¿  upside-down question
 Quotes:

 Input  Rendered  Description
 \(Bq  „  right low double-quote
 \(bq  ‚  right low single-quote
 \(lq  “  left double-quote
 \(rq  ”  right double-quote
 \(oq  ‘  left single-quote
 \(cq  ’  right single-quote
 \(aq  '  apostrophe quote (ASCII character)
 \(dq  "  double quote (ASCII character)
 \(Fo  «  left guillemet
 \(Fc  »  right guillemet
 \(fo  ‹  left single guillemet
 \(fc  ›  right single guillemet
 Brackets:

 Input  Rendered  Description
 \(lB  [  left bracket
 \(rB  ]  right bracket
 \(lC  {  left brace
 \(rC  }  right brace
 \(la  ⟨  left angle
 \(ra  ⟩  right angle
 \(bv  ⎪  brace extension (special font)
 \[braceex]  ⎪  brace extension
 \[bracketlefttp]  ⎡  top-left hooked bracket
 \[bracketleftbt]  ⎣  bottom-left hooked bracket
 \[bracketleftex]  ⎢  left hooked bracket extension
 \[bracketrighttp]  ⎤  top-right hooked bracket
 \[bracketrightbt]  ⎦  bottom-right hooked bracket
 \[bracketrightex]  ⎥  right hooked bracket extension
 \(lt  ⎧  top-left hooked brace
 \[bracelefttp]  ⎧  top-left hooked brace
 \(lk  ⎨  mid-left hooked brace
 \[braceleftmid]  ⎨  mid-left hooked brace
 \(lb  ⎩  bottom-left hooked brace
 \[braceleftbt]  ⎩  bottom-left hooked brace
 \[braceleftex]  ⎪  left hooked brace extension
 \(rt  ⎫  top-left hooked brace
 \[bracerighttp]  ⎫  top-right hooked brace
 \(rk  ⎬  mid-right hooked brace
 \[bracerightmid]  ⎬  mid-right hooked brace
 \(rb  ⎭  bottom-right hooked brace
 \[bracerightbt]  ⎭  bottom-right hooked brace
 \[bracerightex]  ⎪  right hooked brace extension
 \[parenlefttp]  ⎛  top-left hooked parenthesis
 \[parenleftbt]  ⎝  bottom-left hooked parenthesis
 \[parenleftex]  ⎜  left hooked parenthesis extension
 \[parenrighttp]  ⎞  top-right hooked parenthesis
 \[parenrightbt]  ⎠  bottom-right hooked parenthesis
 \[parenrightex]  ⎟  right hooked parenthesis extension
 Arrows:

 Input  Rendered  Description
 \(<-  ←  left arrow
 \(->  →  right arrow
 \(<>  ↔  left-right arrow
 \(da  ↓  down arrow
 \(ua  ↑  up arrow
 \(va  ↕  up-down arrow
 \(lA  ⇐  left double-arrow
 \(rA  ⇒  right double-arrow
 \(hA  ⇔  left-right double-arrow
 \(uA  ⇑  up double-arrow
 \(dA  ⇓  down double-arrow
 \(vA  ⇕  up-down double-arrow
 \(an  ⎯  horizontal arrow extension
 Logical:

 Input  Rendered  Description
 \(AN  ∧  logical and
 \(OR  ∨  logical or
 \[tno]  ¬  logical not (text font)
 \(no  ¬  logical not (special font)
 \(te  ∃  existential quantifier
 \(fa  ∀  universal quantifier
 \(st  ∋  such that
 \(tf  ∴  therefore
 \(3d  ∴  therefore
 \(or  |  bitwise or
 Mathematical:

 Input  Rendered  Description
 \-  -  minus (text font)
 \(mi  −  minus (special font)
 +  +  plus (text font)
 \(pl  +  plus (special font)
 \(-+  ∓  minus-plus
 \[t+-]  ±  plus-minus (text font)
 \(+-  ±  plus-minus (special font)
 \(pc  ·  center-dot
 \[tmu]  ×  multiply (text font)
 \(mu  ×  multiply (special font)
 \(c*  ⊗  circle-multiply
 \(c+  ⊕  circle-plus
 \[tdi]  ÷  divide (text font)
 \(di  ÷  divide (special font)
 \(f/  ⁄  fraction
 \(**  ∗  asterisk
 \(<=  ≤  less-than-equal
 \(>=  ≥  greater-than-equal
 \(<<  ≪  much less
 \(>>  ≫  much greater
 \(eq  =  equal
 \(!=  ≠  not equal
 \(==  ≡  equivalent
 \(ne  ≢  not equivalent
 \(ap  ∼  tilde operator
 \(|=  ≃  asymptotically equal
 \(=~  ≅  approximately equal
 \(~~  ≈  almost equal
 \(~=  ≈  almost equal
 \(pt  ∝  proportionate
 \(es  ∅  empty set
 \(mo  ∈  element
 \(nm  ∉  not element
 \(sb  ⊂  proper subset
 \(nb  ⊄  not subset
 \(sp  ⊃  proper superset
 \(nc  ⊅  not superset
 \(ib  ⊆  reflexive subset
 \(ip  ⊇  reflexive superset
 \(ca  ∩  intersection
 \(cu  ∪  union
 \(/_  ∠  angle
 \(pp  ⊥  perpendicular
 \(is  ∫  integral
 \[integral]  ∫  integral
 \[sum]  ∑  summation
 \[product]  ∏  product
 \[coproduct]  ∐  coproduct
 \(gr  ∇  gradient
 \(sr  √  square root
 \[sqrt]  √  square root
 \(lc  ⌈  left-ceiling
 \(rc  ⌉  right-ceiling
 \(lf  ⌊  left-floor
 \(rf  ⌋  right-floor
 \(if  ∞  infinity
 \(Ah  ℵ  aleph
 \(Im  ℑ  imaginary
 \(Re  ℜ  real
 \(wp  ℘  Weierstrass p
 \(pd  ∂  partial differential
 \(-h  ℏ  Planck constant over 2π
 \[hbar]  ℏ  Planck constant over 2π
 \(12  ½  one-half
 \(14  ¼  one-fourth
 \(34  ¾  three-fourths
 \(18  ⅛  one-eighth
 \(38  ⅜  three-eighths
 \(58  ⅝  five-eighths
 \(78  ⅞  seven-eighths
 \(S1  ¹  superscript 1
 \(S2  ²  superscript 2
 \(S3  ³  superscript 3
 Ligatures:

 Input  Rendered  Description
 \(ff  ﬀ  ff ligature
 \(fi  ﬁ  fi ligature
 \(fl  ﬂ  fl ligature
 \(Fi  ﬃ  ffi ligature
 \(Fl  ﬄ  ffl ligature
 \(AE  Æ  AE
 \(ae  æ  ae
 \(OE  Œ  OE
 \(oe  œ  oe
 \(ss  ß  German eszett
 \(IJ  Ĳ  IJ ligature
 \(ij  ĳ  ij ligature
 Accents:

 Input  Rendered  Description
 \(a"  ˝  Hungarian umlaut
 \(a-  ¯  macron
 \(a.  ˙  dotted
 \(a^  ^  circumflex
 \(aa  ´  acute
 \'  ´  acute
 \(ga  `  grave
 \`  `  grave
 \(ab  ˘  breve
 \(ac  ¸  cedilla
 \(ad  ¨  dieresis
 \(ah  ˇ  caron
 \(ao  ˚  ring
 \(a~  ~  tilde
 \(ho  ˛  ogonek
 \(ha  ^  hat (ASCII character)
 \(ti  ~  tilde (ASCII character)
 Accented letters:

 Input  Rendered  Description
 \('A  Á  acute A
 \('E  É  acute E
 \('I  Í  acute I
 \('O  Ó  acute O
 \('U  Ú  acute U
 \('Y  Ý  acute Y
 \('a  á  acute a
 \('e  é  acute e
 \('i  í  acute i
 \('o  ó  acute o
 \('u  ú  acute u
 \('y  ý  acute y
 \(`A  À  grave A
 \(`E  È  grave E
 \(`I  Ì  grave I
 \(`O  Ò  grave O
 \(`U  Ù  grave U
 \(`a  à  grave a
 \(`e  è  grave e
 \(`i  ì  grave i
 \(`o  ì  grave o
 \(`u  ù  grave u
 \(~A  Ã  tilde A
 \(~N  Ñ  tilde N
 \(~O  Õ  tilde O
 \(~a  ã  tilde a
 \(~n  ñ  tilde n
 \(~o  õ  tilde o
 \(:A  Ä  dieresis A
 \(:E  Ë  dieresis E
 \(:I  Ï  dieresis I
 \(:O  Ö  dieresis O
 \(:U  Ü  dieresis U
 \(:a  ä  dieresis a
 \(:e  ë  dieresis e
 \(:i  ï  dieresis i
 \(:o  ö  dieresis o
 \(:u  ü  dieresis u
 \(:y  ÿ  dieresis y
 \(^A  Â  circumflex A
 \(^E  Ê  circumflex E
 \(^I  Î  circumflex I
 \(^O  Ô  circumflex O
 \(^U  Û  circumflex U
 \(^a  â  circumflex a
 \(^e  ê  circumflex e
 \(^i  î  circumflex i
 \(^o  ô  circumflex o
 \(^u  û  circumflex u
 \(,C  Ç  cedilla C
 \(,c  ç  cedilla c
 \(/L  Ł  stroke L
 \(/l  ł  stroke l
 \(/O  Ø  stroke O
 \(/o  ø  stroke o
 \(oA  Å  ring A
 \(oa  å  ring a
 Special letters:

 Input  Rendered  Description
 \(-D  Ð  Eth
 \(Sd  ð  eth
 \(TP  Þ  Thorn
 \(Tp  þ  thorn
 \(.i  ı  dotless i
 \(.j  ȷ  dotless j
 Currency:

 Input  Rendered  Description
 \(Do  $  dollar
 \(ct  ¢  cent
 \(Eu  €  Euro symbol
 \(eu  €  Euro symbol
 \(Ye  ¥  yen
 \(Po  £  pound
 \(Cs  ¤  Scandinavian
 \(Fn  ƒ  florin
 Units:

 Input  Rendered  Description
 \(de  °  degree
 \(%0  ‰  per-thousand
 \(fm  ′  minute
 \(sd  ″  second
 \(mc  µ  micro
 \(Of  ª  Spanish female ordinal
 \(Om  º  Spanish masculine ordinal
 Greek letters:

 Input  Rendered  Description
 \(*A  Α  Alpha
 \(*B  Β  Beta
 \(*G  Γ  Gamma
 \(*D  Δ  Delta
 \(*E  Ε  Epsilon
 \(*Z  Ζ  Zeta
 \(*Y  Η  Eta
 \(*H  Θ  Theta
 \(*I  Ι  Iota
 \(*K  Κ  Kappa
 \(*L  Λ  Lambda
 \(*M  Μ  Mu
 \(*N  Ν  Nu
 \(*C  Ξ  Xi
 \(*O  Ο  Omicron
 \(*P  Π  Pi
 \(*R  Ρ  Rho
 \(*S  Σ  Sigma
 \(*T  Τ  Tau
 \(*U  Υ  Upsilon
 \(*F  Φ  Phi
 \(*X  Χ  Chi
 \(*Q  Ψ  Psi
 \(*W  Ω  Omega
 \(*a  α  alpha
 \(*b  β  beta
 \(*g  γ  gamma
 \(*d  δ  delta
 \(*e  ε  epsilon
 \(*z  ζ  zeta
 \(*y  η  eta
 \(*h  θ  theta
 \(*i  ι  iota
 \(*k  κ  kappa
 \(*l  λ  lambda
 \(*m  μ  mu
 \(*n  ν  nu
 \(*c  ξ  xi
 \(*o  ο  omicron
 \(*p  π  pi
 \(*r  ρ  rho
 \(*s  σ  sigma
 \(*t  τ  tau
 \(*u  υ  upsilon
 \(*f  ϕ  phi
 \(*x  χ  chi
 \(*q  ψ  psi
 \(*w  ω  omega
 \(+h  ϑ  theta variant
 \(+f  φ  phi variant
 \(+p  ϖ  pi variant
 \(+e  ϵ  epsilon variant
 \(ts  ς  sigma terminal
 PREDEFINED STRINGS

 Predefined strings are inherited from the macro packages of historical troff implementations. They are not recommended for use, as they differ across implementations. Manuals using these predefined strings are almost certainly not portable.

 Their syntax is similar to special characters, using ‘\*X’ (for a one-character escape), ‘\*(XX’ (two-character), and ‘\*[N]’ (N-character).

 Input  Rendered  Description
 \*(Ba  |  vertical bar
 \*(Ne  ≠  not equal
 \*(Ge  ≥  greater-than-equal
 \*(Le  ≤  less-than-equal
 \*(Gt  >  greater-than
 \*(Lt  <  less-than
 \*(Pm  ±  plus-minus
 \*(If  infinity  infinity
 \*(Pi  pi  pi
 \*(Na  NaN  NaN
 \*(Am  &  ampersand
 \*R  ®  restricted mark
 \*(Tm  (Tm)  trade mark
 \*q  "  double-quote
 \*(Rq  ”  right-double-quote
 \*(Lq  “  left-double-quote
 \*(lp  (  right-parenthesis
 \*(rp  )  left-parenthesis
 \*(lq  “  left double-quote
 \*(rq  ”  right double-quote
 \*(ua  ↑  up arrow
 \*(va  ↕  up-down arrow
 \*(<=  ≤  less-than-equal
 \*(>=  ≥  greater-than-equal
 \*(aa  ´  acute
 \*(ga  `  grave
 \*(Px  POSIX  POSIX standard name
 \*(Ai  ANSI  ANSI standard name
 */
