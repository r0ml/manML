//
// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation

let knownLibraries = ["libc" : "Standard C Library",
                      "libm" : "Math Library"
]
let faDelim = ",&ensp;"

extension Mandoc {
  /** Evaluation of a single Mandoc ( or roff ) macro returning the HTML string  which is the output.
   The tokenizer is advanced by consuming the arguments.  It does not necessarily consume the entire line.
   */
  func macro( _ linesSlice : inout ArraySlice<Substring>, _ tknz : Tokenizer, _ bs : BlockState? = nil) -> Token? {

    
    guard let thisToken = tknz.next() else { return nil }
    var thisCommand = ""
    var thisDelim = ""
    
    // FIXME: use these categories?
 /*
    if blockFullExplicit.keys.contains(String(thisToken.value) ) {
      
    } else if blockFullImplicit.keys.contains(String(thisToken.value) ) {
      
    } else if blockPartialExplicit.keys.contains(String(thisToken.value) ) {
      
    } else if blockPartialImplicit.contains(String(thisToken.value) ) {
      
    } else if inLine.contains(String(thisToken.value)) {
      
    } else {
      
    }
   */
    
    //    parseState.isFa = false
    //    parseState.previousClosingDelimiter = ""

    if var m = parseState.definedMacro[String(thisToken.value)] {
      // FIXME: because of this catenation, the line numbering must be adjusted.
      // either need to maintain a list of line numbers with the source macro line repeated --
      // or a list of line numbers with the target macro text associated
      // or a first pass of the source substituting the defined macros.
      var mm = ArraySlice(m+linesSlice)
      linesSlice = mm
      return nil
//      let output = macroBlock(&mm, [], BlockState() )
//      return Token(value: Substring(output), closingDelimiter: "\n", isMacro: false)
    }


    switch thisToken.value {
      case "%A": parseState.rsState?.author.append( String(tknz.rest.value) )
      case "%B": parseState.rsState?.book = String(tknz.rest.value)
      case "%C": parseState.rsState?.location = String(tknz.rest.value)
      case "%D": parseState.rsState?.date = String(tknz.rest.value)
      case "%I": parseState.rsState?.issuer = String(tknz.rest.value)
      case "%J": parseState.rsState?.journal = String(tknz.rest.value)
      case "%N": parseState.rsState?.issue = String(tknz.rest.value)
      case "%O": parseState.rsState?.optional = String(tknz.rest.value)
      case "%P": parseState.rsState?.page = String(tknz.rest.value)
      case "%Q": parseState.rsState?.institution.append(String(tknz.rest.value) )
      case "%R": parseState.rsState?.report = String(tknz.rest.value)
      case "%T": parseState.rsState?.article = String(tknz.rest.value)
      case "%U": parseState.rsState?.uri = String(tknz.rest.value)
      case "%V": parseState.rsState?.volume = String(tknz.rest.value)

      case "Ac": // end Ao
        thisCommand = ">"
        thisDelim = "&thinsp;"
      case "Ad": // memory address
        thisCommand = span("unimplemented", "Ad", lineNo(linesSlice))

      case "An": // Author name
        let z = tknz.peekToken()
        if z?.value == "-split" { parseState.authorSplit = true; let _ = tknz.rest; break }
        else if z?.value == "-nosplit" { parseState.authorSplit = false; let _ = tknz.rest; break }
        let k = parseLine(&linesSlice, tknz)
        thisCommand = span("author", k , lineNo(linesSlice))

      case "Ao": // enclose in angle bracketrs
        thisCommand = "<"
        thisDelim = "&thinsp;"

      case "Ap": // apostrophe
        thisCommand = "'"

      case "Aq": // enclose rest of line in angle brackets
        let j = tknz.rest
        thisCommand.append(span(nil, "&lt;\(j.value)&gt;", lineNo(linesSlice)))
        thisDelim = j.closingDelimiter

      case "Ar": // command arguments
        if let jj = nextArg(tknz) {
          thisCommand.append(span("argument", jj.value, lineNo(linesSlice)))
          thisDelim = jj.closingDelimiter
          while tknz.peekToken()?.value != "|",
                let kk = nextArg(tknz) {
            thisCommand.append(thisDelim)
            thisCommand.append(span("argument", kk.value, lineNo(linesSlice)))
            thisDelim = kk.closingDelimiter
          }
        } else {
          thisCommand.append(span("argument", "file", lineNo(linesSlice)) + " " + span("argument", "…", lineNo(linesSlice)))
        }

      case "At": // at&t unix version
        if let jt = tknz.next() {
          thisCommand = "<nobr>"+span("os", att[String(jt.value)] ?? "AT&T Unix", lineNo(linesSlice))+"</nobr>"
          thisDelim = jt.closingDelimiter
        }

      case "Bc": // cloase a Bo block
        let _ = tknz.rest

      case "Bd": // begin a display block
                 // FIXME: doesn't handle all types of display blocks
        thisCommand = blockBlock(&linesSlice, tknz)

      case "Bf": // begin a font block
        if let j = tknz.next() {
          let k = macroBlock(&linesSlice, ["Ef"])
          switch j.value {
            case "Em", "-emphasis":
              thisCommand = span("", "<em>" + k + "</em>", lineNo(linesSlice))
            case "Li", "-literal":
              thisCommand = span("", "<code>" + k + "</code>", lineNo(linesSlice))
            case "Sy", "-symbolic":
              thisCommand = span("", "<i>" + k + "</i>", lineNo(linesSlice))
            default:
              thisCommand = k
          }
        }
      case "Bk": // keep block on single line
        let _ = tknz.rest // it should be `-words`
        let j = macroBlock(&linesSlice, ["Ek"])
        thisCommand = j

      case "Bl": // begin list.
                 // FIXME: not all list types are supported yet
        thisCommand = listBlock(&linesSlice, tknz)

      case "Bo": // begin square bracket block.
        thisCommand = span(nil, "["+macroBlock(&linesSlice, ["Bc"])+"]", lineNo(linesSlice))

      case "Bq": // enclose in square brackets.
        if let j = macro(&linesSlice, tknz) {
          thisCommand = span(nil, "["+j.value+"]", lineNo(linesSlice))
          thisDelim = j.closingDelimiter
        }

      case "Brc": // end Bro
        let _ = tknz.rest

      case "Bro": // curly brace block
        thisCommand = macroBlock(&linesSlice, ["Brc"])

      case "Brq": // curly brace
        if let j = macro(&linesSlice, tknz) {
          thisCommand = span(nil, "{"+j.value+"}", lineNo(linesSlice))
          thisDelim = j.closingDelimiter
        }

      case "Bsx": // BSD version
        if let j = nextArg(tknz) {
          thisCommand = span("os", "BSD/OSv\(j.value)", lineNo(linesSlice))
          thisDelim = j.closingDelimiter
        } else {
          thisCommand = span("os", "BSD/OS", lineNo(linesSlice))
          thisDelim = "\n"
        }

      case "Bt": // deprecated
        thisCommand = span(nil, "is currently in beta test.", lineNo(linesSlice))

      case "Bx":
        if let j = tknz.next() {
          thisCommand = span("os","\(j.value)BSD", lineNo(linesSlice)) // + parseState.closingDelimiter
          thisDelim = j.closingDelimiter
        } else {
          thisCommand = span("os", "BSD", lineNo(linesSlice))
          thisDelim = "\n"
        }

        // ==============================================

      case "Cd": // kernel configuration
        let j = tknz.rest
        thisCommand = span("kernel", j.value, lineNo(linesSlice))
        thisDelim = j.closingDelimiter

      case "Cm": // command modifiers
        while let j = macro(&linesSlice, tknz) {
          thisCommand.append(thisDelim + span("command", j.value, lineNo(linesSlice)) )
          thisDelim = j.closingDelimiter
        }

      case "Db": // obsolete and ignored
        let _ = tknz.rest

      case "Dc": // close a "Do" block
        let _ = tknz.rest

      case "Dd": // document date
        date = String(tknz.rest.value)

      case "D1", "Dl": // single indented line
        if let j = macro(&linesSlice, tknz) {
          thisCommand = "<blockquote>"+span("", j.value, lineNo(linesSlice) )+"</blockquote>"
          thisDelim = j.closingDelimiter
        }

      case "Do": // enclose block in quotes
        let j = macroBlock(&linesSlice, ["Dc"])
        thisCommand = span(nil, "<q>"+j+"</q>", lineNo(linesSlice))

      case "Dq": // enclosed in quotes
        let q = tknz.peekToken()
        if let j = macro(&linesSlice, tknz) {
          // This is an ugly Kludge for find(1) and others that double quote literals.
          if q?.value == "Li" {
            thisCommand = String(j.value)
          } else {
            thisCommand = "<q>\(j.value)</q>"
          }
          thisDelim = j.closingDelimiter
        }

      case "Dt": // document title
        title = String(tknz.rest.value)
        let tt = title!.split(separator: " ")

        let (name, section) = (tt[0], tt[1])

        thisCommand = pageHeader(name, section, sections[String(section)] ?? "Unknown")


      case "Dv": // defined variable
        if let j = nextArg(tknz) {
          thisCommand = span("defined-variable", j.value, lineNo(linesSlice))
          thisDelim = j.closingDelimiter
        }

      case "Dx": // dragonfly version
        thisCommand = span("unimplemented", "Dx", lineNo(linesSlice))

        // =======================================================

      case "Ed":
        thisCommand = "</blockquote>"

      case "Ef":
        let _ = tknz.rest
        
      case "Ek":
        let _ = tknz.rest

      case "El":
        thisCommand = span("unimplemented", ".El encountered without .Bl", lineNo(linesSlice))

      case "Em":
        if let j = macro(&linesSlice, tknz) {
          thisCommand = "<em>\(j.value)</em>"
          thisDelim = j.closingDelimiter
        }
      case "Er":
        if let j = macro(&linesSlice, tknz) {
          thisCommand = span("error", j.value, lineNo(linesSlice))
          thisDelim = j.closingDelimiter
        }
      case "Ev":
        while let j = nextArg(tknz) {
          thisCommand.append(span("environment", j.value, lineNo(linesSlice)) )
          thisCommand.append(j.closingDelimiter.replacing(" ", with: "&ensp;"))
          //          thisDelim = j.closingDelimiter
        }
      case "Ex":
        let _ = tknz.next() // should equal "-std"
        let j = tknz.next()?.value ?? Substring(name ?? "??")
        thisCommand = "The \(span("utility",j, lineNo(linesSlice))) utility exits 0 on success, and >0 if an error occurs."

        // Function argument
      case "Fa":
        //        let sep = parseState.wasFa ? ", " : ""
        thisCommand.append(thisDelim)
        if let j = nextArg(tknz) {
          thisCommand.append(span("function-arg", j.value, lineNo(linesSlice)))
          thisDelim = bs?.functionDef == true ? faDelim : j.closingDelimiter
        }
      case "Fc":
        thisCommand = "<br/>"
        if parseState.inSynopsis {
          thisDelim = "<br>"
        }
      case "Fd":
        let j = tknz.rest
        thisCommand = span("directive", j.value, lineNo(linesSlice)) + "<br/>"
        thisDelim = j.closingDelimiter

      case "Fl":
        // This was upended by "ctags" and "ssh"

        if let j = tknz.next() {
          thisCommand.append("<nobr>" + span("flag", "-"+j.value, lineNo(linesSlice)) + "</nobr>")
          thisDelim = j.closingDelimiter
        }

        if let j = macro(&linesSlice, tknz) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }

/*
        while let jj = tknz.peekToken()?.value,
              !(jj == "Ar" || jj == "Xo" || jj == "Ns") ,
              let j = nextArg(tknz) {
          if j.value == "\\" {
            thisCommand.append(" ")
            thisDelim = ""
          } else {
            thisCommand.append("<nobr>" + span("flag", "-"+j.value, lineNo(linesSlice))+"</nobr>")
          }
          if tknz.peekToken()?.value == "|"  {
            let _ = tknz.popToken()
            thisCommand.append("&ensp;| " /* &ensp;" */)
          }
          thisDelim = j.closingDelimiter
          if tknz.peekMacro() || tknz.peekToken() == nil { break }
          thisCommand.append(thisDelim)
        }
*/


        // if there is no argument, the result is a single dash
        if thisCommand.isEmpty {
          thisCommand = span("flag", "-", lineNo(linesSlice))
        }

      case "Fn":
        // for compat(5)
        if let j = tknz.next()?.value {
          thisCommand = span("function-name", j, lineNo(linesSlice))
          thisCommand.append("(")
          var sep = ""
          while let j = tknz.next()?.value {
            thisCommand.append(sep)
            thisCommand.append(contentsOf: span("argument", j, lineNo(linesSlice)) )
            sep = ", "
          }
          thisCommand.append(")")
        }
      case "Fo":
        let j = tknz.rest
        thisCommand = span("function-name", j.value, lineNo(linesSlice)) + "&thinsp;("
        let bs = BlockState()
        bs.functionDef = true
        let k = macroBlock(&linesSlice, ["Fc"], bs)
        thisCommand.append(contentsOf: k.dropLast(faDelim.count+1) )
        thisCommand.append(");")

      case "Ft":
        let j = tknz.rest
        thisCommand = "<br/>" + span("function-type", j.value, lineNo(linesSlice))
        if parseState.inSynopsis {
          thisDelim = "<br>"
        } else {
          thisDelim = j.closingDelimiter
        }
      case "Fx":
        if let j = tknz.next() {
          thisCommand = span("os", "FreeBSD \(j.value)", lineNo(linesSlice))
          thisDelim = j.closingDelimiter
        }
      case "Ic":
        if let j = macro(&linesSlice, tknz) {
          thisCommand = span("command", j.value, lineNo(linesSlice))
          thisDelim = j.closingDelimiter
        }
      case "In": // include
        let j = tknz.rest
        thisCommand = "<div class=\"include\">#include &lt;\(j.value)&gt;</div>"
        thisDelim = j.closingDelimiter
      case "It":
        let currentTag = parseLine(&linesSlice, tknz, bs)
        let currentDescription = macroBlock(&linesSlice, ["It", "El"], bs)

        switch bs?.bl {
          case .tag:
            thisCommand = taggedParagraph(currentTag, currentDescription, lineNo(linesSlice)) // "</div></div>"
          case .item, ._enum, .bullet, .dash:
            thisCommand = "<li>" + currentDescription + "</li>"
          case .hang:
            thisCommand = "<div style=\"margin-top: 0.8em;\">\(currentTag) \(currentDescription)</div>"
          case .table:
            thisCommand = "<tr><td>\(currentTag) \(currentDescription)</td></tr>"
          default:
            thisCommand = span("unimplemented", "BLError", lineNo(linesSlice))
        }

      case "Lb": // library
        let j = tknz.rest
        if let kl = knownLibraries[String(j.value)] {
          thisCommand.append(span("library", "\(kl) (\(j.value))", lineNo(linesSlice)))
        } else {
          thisCommand =  span("library", j.value, lineNo(linesSlice))
        }
        thisDelim = j.closingDelimiter
      case "Li":
        if let j = nextArg(tknz) {
          thisCommand.append(span("literal", j.value, lineNo(linesSlice)))
          thisDelim = j.closingDelimiter
        }

      case "Mt":
        if let j = tknz.next() {
          thisCommand = "<a href=\"mailto:\(j.value)\">\(j.value)</a>"
          thisDelim = j.closingDelimiter
        }

      case "No": // revert to normal text.  Should not need to do anything?
        break

      case "Nd":
        thisCommand = " - \(tknz.rest.value)" // removed a <br/> because it mucked up "ctags"

      case "Nm":
        // in the case of ".Nm :" , the : winds up as the closing delimiter for the macro name.
        if parseState.inSynopsis { thisCommand.append("<br>") }
        if let j = nextArg(tknz) {
          if name == nil { name = String(j.value) }
          //          if parseState.inSynopsis { thisCommand.append("<br/>") }
          if j.value.isEmpty {
            thisCommand.append(span("utility", name ?? "", lineNo(linesSlice)))
          } else {
            thisCommand.append( span("utility", j.value, lineNo(linesSlice)) )
          }
          thisDelim = j.closingDelimiter
        } else {
          if let name { thisCommand.append( span("utility", name, lineNo(linesSlice))) }
        }

      case "Ns":
        return macro(&linesSlice, tknz, bs)

      case "Nx":
        if let j = macro(&linesSlice, tknz) {
          thisCommand = span("os", "NetBSD "+j.value, lineNo(linesSlice))
          thisDelim = j.closingDelimiter
        }

      case "Oc":
        let _ = tknz.rest

      case "Oo":
        let k = macroBlock(&linesSlice, ["Oc"], bs)
        thisCommand = "["+k+"]"

      case "Op":
        // in "apply", the .Ns macro is applied here, but "cd" is already " "
        // is the fix to have tknz maintain a previousClosingDelimiter?
        while let j = macro(&linesSlice, tknz) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }
        thisCommand = "[" + thisCommand + "]"

        // this needs to be parsed
      case "Os":
        let j = tknz.rest
        if !j.value.isEmpty { os = String(j.value) }
        else {
          let v = ProcessInfo.processInfo.operatingSystemVersion
          os = "macOS \(v.majorVersion).\(v.minorVersion)"  }
      case "Ox":
        let j = tknz.rest
        thisCommand = span("os", "OpenBSD\(j.value)", lineNo(linesSlice))

      case "Pa":
        while let j = nextArg(tknz) {
          thisCommand.append(thisDelim)
          thisCommand.append( span("path", j.value, lineNo(linesSlice)))
          thisDelim = j.closingDelimiter
        }
      case "Pc":
        //        thisCommand = "<br>"
        // for mbrtowc(3), it seems to do nothing
        break
      case "Pf":
        if let j = tknz.next() {
          thisCommand.append(contentsOf: j.value)
        }

      case "Po":
        //        thisCommand = "<p>"
        // for mbrtowc(3) , it seems to do nothing
        break
      case "Lp", "Pp":
        thisCommand = "<p>"
      case "Pq":
        if let j = macro(&linesSlice, tknz) {
          thisCommand = "(\(j.value))"
          thisDelim = j.closingDelimiter
        }

      case "Ql":
        if let j = macro(&linesSlice, tknz) {
          thisCommand.append(thisDelim)
          thisCommand.append( span("literal", j.value, lineNo(linesSlice)) )
          thisDelim = j.closingDelimiter
        }

        // Note: technically this should use normal quotes, not typographic quotes
      case "Qq":
        thisCommand = "<q>\(parseLine(&linesSlice, tknz))</q>"

      case "Re":
        if let re = parseState.rsState {
          thisCommand = re.formatted(self, lineNo(linesSlice))
        }
      case "Rs":
        parseState.rsState = RsState()
        
      case "Sh", "SH": // can be used to end a tagged paragraph
                       // FIXME: need to handle tagged paragraph
        
        let j = tknz.rest
        thisCommand = "<a id=\"\(j.value)\"><h4>" + span(nil, j.value, lineNo(linesSlice)) + "</h4></a>"
        parseState.inSynopsis = j.value == "SYNOPSIS"
        thisDelim = j.closingDelimiter
        
      case "Sm": // spacing mode
        let j = tknz.rest.value
        parseState.spacingMode = j.lowercased() != "off"
        
      case "Sq":
        let sq = parseLine(&linesSlice, tknz)
        thisCommand = "<q class=\"single\">\(sq)</q>"
      case "Ss":
        let j = tknz.rest.value
        thisCommand = "<h5 id=\"\(j)\">\(j)</h5>"
      case "St":
        let j = tknz.next()?.value ?? "??"
        thisCommand = span("standard", standards[String(j)] ?? "(unknown)", lineNo(linesSlice))
      case "Sx":
        let j = tknz.rest.value
        thisCommand = "<a class=\"manref\" href=\"#\(j)\">\(j)</a>"
      case "Sy":
        while let j = macro(&linesSlice, tknz) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
          if tknz.peekMacro() && tknz.peekToken()?.value == "No" {
            let _ = tknz.next()
            break
          }
        }
        thisCommand = span("serious", thisCommand, lineNo(linesSlice))

      case "Ta":
        //        thisCommand = "\t"
        thisCommand = "</td><td>"
        
      case "Tn":
        let j = parseLine(&linesSlice, tknz)
        thisCommand = span("small-caps", j, lineNo(linesSlice))
      case "Ux":
        thisCommand = span("os", "UNIX", lineNo(linesSlice))

      case "Va":
        let j = parseLine(&linesSlice, tknz) // tknz.rest
        thisCommand = span("variable", j, lineNo(linesSlice))

      case "Vb":
        let _ = tknz.rest
        thisCommand = "<code>"
      case "Ve":
        let _ = tknz.rest
        thisCommand = "</code>"
        
      case "Vt": // global variable in the SYNOPSIS section, else variable type
        if let j = tknz.next() {
          //        parseLine(tknz)
          if parseState.inSynopsis {
            thisCommand = "<br>"+span("variable", j.value, lineNo(linesSlice))
            thisDelim = "\n"
          } else {
            thisCommand = "("+span("variable", j.value, lineNo(linesSlice))+")"
            thisDelim = j.closingDelimiter
          }
        }
        
      case "Xc":
        let _ = tknz.rest
        
      case "Xo": // extend item
        thisCommand = macroBlock(&linesSlice, ["Xc"])

      case "Xr":
        if let j = tknz.next(),
           let k = tknz.next() {
          
          thisCommand = "<a class=\"manref\" href=\"mandocx:/\(j.value)/\(k.value)\">\(j.value)(\(k.value))</a>" // + parseState.closingDelimiter
          thisDelim = k.closingDelimiter
        }
        // =================================================================================
        // roff stuff
        // =================================================================================
      case "br":
        thisCommand = "<br/>"
        
      case "sp":
        thisCommand = "<br/>"
        
        // "de" defines a macro -- and the macro definition goes until a line consisting of ".."
      case "de":
        // this would be the macro name if I were implementing roff macro definitions
        if let nam = tknz.next() {
          // FIXME: need to parse arguments
          let a = tknz.rest
          let val = definitionBlock(&linesSlice) // wkip over the definition
          parseState.definedMacro[String(nam.value)] = val
        }

      case "TP":
        // FIXME: get the indentation from the argument
        let ind = tknz.next()?.value ?? "10"

        if linesSlice.isEmpty {
          break
        }
        let line = linesSlice.removeFirst()
        let currentTag = handleLine(&linesSlice, line)

        let k = macroBlock(&linesSlice, []) // "TP", "PP", "SH"])
        thisCommand = taggedParagraph(currentTag, k, lineNo(linesSlice))

      case "P", "PP":
        thisCommand = "<p>"
        
      case "RS":
        let _ = tknz.next()?.value ?? "10"
        let _ = tknz.rest // eat the rest of the line
        
        let k = macroBlock(&linesSlice, ["RE"], bs)
        thisCommand = "<div style=\"padding-left: 2em;\">\(k)</div>"

      case "RE":
        let _ = tknz.rest // already handled in RS
        
      case "B":
        thisCommand = span("bold", tknz.rest.value, lineNo(linesSlice))

      case "I":
        thisCommand = span("italic", tknz.rest.value, lineNo(linesSlice))

      case "BI":
        if let j = tknz.next()?.value {
          let k = tknz.rest
          if k.value.isEmpty {
            thisCommand = span("italic", span("bold", j, lineNo(linesSlice)), lineNo(linesSlice))
          } else {
            thisCommand = span("italic", span("bold", j, lineNo(linesSlice)) + k.value, lineNo(linesSlice))
          }
        }
        
      case "BR":
        /*        if let j = tknz.next() {
         let k = tknz.rest
         if k.isEmpty {
         thisCommand = span("roman", span("bold", j))
         } else {
         thisCommand = span("roman", span("bold", j) + k)
         }
         }
         */
        var toggle = true
        //        let cd = ""
        while let j = tknz.next()?.value {
          if toggle {
            thisCommand.append( span("bold", j, lineNo(linesSlice)) )
          } else {
            thisCommand.append( span("regular", j, lineNo(linesSlice)))
          }
          toggle.toggle()
          //         cd = tknz.closingDelimiter
        }
        //        thisCommand.append(cd)
        
      case "IR":
        var toggle = true
        while let j = tknz.next()?.value {
          if toggle {
            thisCommand.append( span("italic", j, lineNo(linesSlice)) )
          } else {
            thisCommand.append( span("regular", j, lineNo(linesSlice)))
          }
          toggle.toggle()
        }
        
      case "TH":
        let name = tknz.next()?.value ?? "??"
        let section = tknz.next()?.value ?? ""
        title = "\(name)(\(section))"
        date = String(tknz.next()?.value ?? "")
        os = String(tknz.next()?.value ?? "")
        let h = String(tknz.next()?.value ?? "")
        thisCommand = pageHeader(name, section, h )
        
      case "HP": // Hanging paragraph.  Argument specifies amount of hang
        thisCommand = "<p>" // not implemented properly
        
      case "na": // no alignment -- disables justification until .ad
        break // not implemented
      case "ad": // left/right justify
        break // not implemented
        
      case "nh": // disable hypenation until .hy
        break // not implemented
      case "hy": // re-enable hyphenation
        let _ = tknz.rest
        break   // not implemented
        
        // FIXME: put me back -- but in an async way
        /*
         case "so":
         let link = tknz.next()?.value ?? "??"
         if let file = manpath.link(String(link) ),
         let k = try? String(contentsOf: file, encoding: .utf8) {
         return Token(value: Substring(generateBody(k)), closingDelimiter: "", isMacro: false)
         }
         */
        
      case "ll":
        let _ = tknz.rest
        // FIXME: this changes the line length (roff)
        // for now, I will ignore this macro
        
      case "PD": // Psragraph distance.  Not implemented
        let _ = tknz.next()
        
      case "IX": // ignore -- POD uses it to create an index entry
        let _ = tknz.rest
        
      case "ds": // define string
        let nam = tknz.next()?.value ?? "??"
        let val = String(tknz.rest.value)
        parseState.definedString[String(nam)] = val
        
      case "rm": // remove macro definition -- ignored for now
        let _ = tknz.rest
        
      case "if":
        if let j = tknz.next() {
          if j.value == "n" {
            let tr = tknz.rest
            thisCommand = String(tr.value)
            thisDelim = tr.closingDelimiter
          } else {
            let _ = tknz.rest
          }
        }
        
      case "ie", "el":
        let j = tknz.rest.value
        let k = j.matches(of: /\{/)
        parseState.ifNestingDepth += k.count
        
      case "tr": // replace characters -- ignored for now
        let _ = tknz.rest
        
      case "nr": // set number register -- ignored for now
        let _ = tknz.rest
        
      case "rr": // remove register -- ignored for now because set register is ignored
        let _ = tknz.rest
        
      case "IP":
        let k = tknz.next()
        var ind = 3
        if let dd = tknz.next() {
          if let i = Int(dd.value) { ind = i }
        }

        let _ = tknz.rest
        
        let kk = macroBlock(&linesSlice, [])

        if ind > 0 {
          thisCommand = "<div style=\"margin-left: \(ind/2)em;text-indent: -0.7em\">" + (k?.value ?? "") + " " + kk + "</div>"
        }
        
        // thisCommand = "<p style=\"margin-left: \(ind)em;\">\(k?.value ?? "")"
        
      case "nf":
        var j = textBlock(&linesSlice, ["fi"], parseState: parseState)
        if j.hasSuffix("\n.") { j.removeLast(2) }
        thisCommand = "<pre>\(j)</pre>"
        
      case "fi":
        let _ = tknz.rest
        
      case "SS":
        let j = tknz.rest.value
        thisCommand = "<h5>" + span(nil, j, lineNo(linesSlice)) + "</h5>"

      case "SM":
        let _ = tknz.rest // eat the line
        if !linesSlice.isEmpty {
          let k = linesSlice.removeFirst()
          
          let j = handleLine(&linesSlice, k)
          let ln = lineNo(linesSlice)
          thisCommand = "<span style=\"font-size: 80%;\" x-source=\(ln)>\(j)</span>"
        }
        
      default:
        if macroList.contains(thisToken.value) {
          thisCommand = span("unimplemented", thisToken.value, lineNo(linesSlice))
        } else {
          thisCommand = span(nil, String(tknz.escaped(thisToken.value)), lineNo(linesSlice))
          thisDelim = thisToken.closingDelimiter
        }
    }
    return Token(value: Substring(thisCommand), closingDelimiter: thisDelim, isMacro: true)
  }
  
}
