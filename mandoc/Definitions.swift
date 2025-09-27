//
// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024
    

import Foundation

let macroList = "%A %B %C %D %I %J %N %O %P %Q %R %T %U %V Ac Ad An Ao Ap Aq Ar At Bc Bd Bf Bk Bl Bo Bq Brc Bro Brq Bsx Bt Cd Cm D1 Db Dc Dd Dl Do Dq Dt Dv Dx Ec Ed Ef Ek El Em En Eo Er Es Ev Ex Fa Fc Fd Fl Fn Fo Fr Ft Fx Hf Ic In It Lb Li Lk Lp Ms Mt Nd Nm No Ns Nx Oc Oo Op Os Ot Ox Pa Pc Pf Po Pp Pq Qc Ql Qo Qq Re Rs Rv Sc Sh Sm So Sq Ss St Sx Sy Ta Tn Ud Ux Va Vt Xc Xo Xr".split(separator: " ")
let additionalMacroList = "TP PP LP SH IP RE".split(separator: " ")

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
                 "4" : "Special Files and Device Drivers Manual",
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
