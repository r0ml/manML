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
  func macro(_ tknz : Tokenizer, _ bs : BlockState? = nil) -> Token? {
    
    
 guard let thisToken = tknz.next() else { return nil }
    var thisCommand = ""
    var thisDelim = ""
    
    if blockFullExplicit.keys.contains(String(thisToken.value) ) {
      
    } else if blockFullImplicit.keys.contains(String(thisToken.value) ) {
      
    } else if blockPartialExplicit.keys.contains(String(thisToken.value) ) {
      
    } else if blockPartialImplicit.contains(String(thisToken.value) ) {
      
    } else if inLine.contains(String(thisToken.value)) {
      
    } else {
      
    }

//    parseState.isFa = false
//    parseState.previousClosingDelimiter = ""
    
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
        thisCommand = span("unimplemented", "Ad")
        
      case "An": // Author name
        let z = tknz.peekToken()
        if z?.value == "-split" { parseState.authorSplit = true; let _ = tknz.rest; break }
        else if z?.value == "-nosplit" { parseState.authorSplit = false; let _ = tknz.rest; break }
        let k = parseLine(tknz)
        thisCommand = span("author", k )
        
      case "Ao": // enclose in angle bracketrs
        thisCommand = "<"
        thisDelim = "&thinsp;"
        
      case "Ap": // apostrophe
        thisCommand = "'"
      
      case "Aq": // enclose rest of line in angle brackets
        let j = tknz.rest
          thisCommand.append(span(nil, "&lt;\(j.value)&gt;"))
          thisDelim = j.closingDelimiter

      case "Ar": // command arguments
        if let jj = nextArg(tknz) {
          thisCommand.append(span("argument", jj.value))
          thisDelim = jj.closingDelimiter
          while let kk = nextArg(tknz) {
            thisCommand.append(thisDelim)
            thisCommand.append(span("argument", kk.value))
            thisDelim = kk.closingDelimiter
          }
        } else {
          thisCommand.append(span("argument", "file") + " " + span("argument", "…"))
        }

      case "At": // at&t unix version
        if let jt = tknz.next() {
          thisCommand = "<nobr>"+span("os", att[String(jt.value)] ?? "AT&T Unix")+"</nobr>"
          thisDelim = jt.closingDelimiter
        }
        
      case "Bc": // cloase a Bo block
        let _ = tknz.rest
        
      case "Bd": // begin a display block
        // FIXME: doesn't handle all types of display blocks
          thisCommand = blockBlock(tknz)

      case "Bf": // begin a font block
        thisCommand = span("unimplemented", "Bf")
        
      case "Bk": // keep block on single line
        thisCommand = span("unimplemented", "Bk")
        
      case "Bl": // begin list.
        // FIXME: not all list types are supported yet
        thisCommand = listBlock(tknz)
        
      case "Bo": // begin square bracket block.
        thisCommand = span(nil, "["+macroBlock(["Bc"])+"]")

      case "Bq": // enclose in square brackets.
        if let j = macro(tknz) {
          thisCommand = span(nil, "["+j.value+"]")
          thisDelim = j.closingDelimiter
        }
        
      case "Brc": // end Bro
        let _ = tknz.rest
        
      case "Bro": // curly brace block
        thisCommand = macroBlock(["Brc"])
        
      case "Brq": // curly brace
        if let j = macro(tknz) {
          thisCommand = span(nil, "{"+j.value+"}")
          thisDelim = j.closingDelimiter
        }
        
      case "Bsx": // BSD version
        if let j = nextArg(tknz) {
          thisCommand = span("os", "BSD/OSv\(j.value)")
          thisDelim = j.closingDelimiter
        } else {
          thisCommand = span("os", "BSD/OS")
          thisDelim = "\n"
        }
        
      case "Bt": // deprecated
        thisCommand = span(nil, "is currently in beta test.")
        
      case "Bx":
        if let j = tknz.next() {
          thisCommand = span("os","\(j.value)BSD") // + parseState.closingDelimiter
          thisDelim = j.closingDelimiter
        } else {
          thisCommand = span("os", "BSD")
          thisDelim = "\n"
        }
        
        // ==============================================
        
      case "Cd": // kernel configuration
        let j = tknz.rest
        thisCommand = span("kernel", j.value)
        thisDelim = j.closingDelimiter

      case "Cm": // command modifiers
        if let j = macro(tknz) {
          thisCommand = span("command", j.value)
          thisDelim = j.closingDelimiter
        }

      case "Db": // obsolete and ignored
        let _ = tknz.rest
        
      case "Dc": // close a "Do" block
        let _ = tknz.rest
        
      case "Dd": // document date
        date = String(tknz.rest.value)
        
      case "D1", "Dl": // single indented line
        let j = tknz.rest.value
        thisCommand = "<blockquote>\(j)</blockquote>"
        
      case "Do": // enclose block in quotes
        let j = macroBlock(["Dc"])
        thisCommand = span(nil, "<q>"+j+"</q>")
        
      case "Dq": // enclosed in quotes
        let q = tknz.peekToken()
        if let j = macro(tknz) {
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
          thisCommand = span("defined-variable", j.value)
          thisDelim = j.closingDelimiter
        }
        
      case "Dx": // dragonfly version
        thisCommand = span("unimplemented", "Dx")
        
        // =======================================================
        
      case "Ed":
        thisCommand = "</blockquote>"

      case "El":
        thisCommand = span("unimplemented", ".El encountered without .Bl")

      case "Em":
        if let j = macro(tknz) {
          thisCommand = "<em>\(j.value)</em>"
          thisDelim = j.closingDelimiter
        }
      case "Er":
        if let j = macro(tknz) {
          thisCommand = span("error", j.value)
          thisDelim = j.closingDelimiter
        }
      case "Ev":
        while let j = nextArg(tknz) {
          thisCommand.append(span("environment", j.value) )
          thisCommand.append(j.closingDelimiter.replacing(" ", with: "&ensp;"))
//          thisDelim = j.closingDelimiter
        }
      case "Ex":
        let ign = tknz.next() // should equal "-std"
        let j = tknz.next()?.value ?? Substring(name ?? "??")
        thisCommand = "The \(span("utility",j)) utility exits 0 on success, and >0 if an error occurs."
        
        // Function argument
      case "Fa":
//        let sep = parseState.wasFa ? ", " : ""
        thisCommand.append(thisDelim)
        if let j = nextArg(tknz) {
          thisCommand.append(span("function-arg", j.value))
          thisDelim = bs?.functionDef == true ? faDelim : j.closingDelimiter
        }
      case "Fc":
        thisCommand = "<br/>"
      case "Fd":
        let j = tknz.rest
        thisCommand = span("directive", j.value) + "<br/>"
        thisDelim = j.closingDelimiter
      case "Fl":
        // This was upended by "ctags" and "ssh"
        while let jj = tknz.peekToken()?.value,
              !(jj == "Ar" || jj == "Xo") ,
              let j = nextArg(tknz) {
          thisCommand.append("<nobr>" + span("flag", "-"+j.value)+"</nobr>")
          if tknz.peekToken()?.value == "|"  {
            let _ = tknz.popToken()
            thisCommand.append("&ensp;| " /* &ensp;" */)
          }
          thisDelim = j.closingDelimiter
          if tknz.peekMacro() || tknz.peekToken() == nil { break }
          thisCommand.append(thisDelim)
        }
        
        if thisCommand.isEmpty {
          thisCommand = span("flag", "-")
        }
        
        // if there is no argument, the result is a single dash
      case "Fn":
        // for compat(5)
        if let j = tknz.next()?.value {
          thisCommand = span("function-name", j)
          thisCommand.append("(")
          var sep = ""
          while let j = tknz.next()?.value {
            thisCommand.append(sep)
            thisCommand.append(contentsOf: span("argument", j) )
            sep = ", "
          }
          thisCommand.append(")")
        }
      case "Fo":
        let j = tknz.rest
        thisCommand = span("function-name", j.value) + "&thinsp;("
        let bs = BlockState()
        bs.functionDef = true
        let k = macroBlock(["Fc"], bs)
        thisCommand.append(contentsOf: k.dropLast(faDelim.count+1) )
        thisCommand.append(");")
        
      case "Ft":
        let j = tknz.rest
        thisCommand = "<br/>" + span("function-type", j.value)
        thisDelim = j.closingDelimiter
      case "Fx":
        if let j = tknz.next() {
          thisCommand = span("os", "FreeBSD \(j.value)")
          thisDelim = j.closingDelimiter
        }
      case "Ic":
        if let j = macro(tknz) {
          thisCommand = span("command", j.value)
          thisDelim = j.closingDelimiter
        }
      case "In": // include
        let j = tknz.rest
        thisCommand = "<div class=\"include\">#include &lt;\(j.value)&gt;</div>"
        thisDelim = j.closingDelimiter
      case "It":
        let currentTag = parseLine(tknz)
        let currentDescription = macroBlock(["It", "El"], bs)
        
        switch bs?.bl {
          case .tag:
            thisCommand = taggedParagraph(currentTag, currentDescription) // "</div></div>"
          case .item, ._enum:
            thisCommand = "<li>" + currentDescription + "</li>"
          case .hang:
            thisCommand = "<div style=\"margin-top: 0.8em;\">\(currentTag) \(currentDescription)</div>"
          default:
            thisCommand = span("unimplemented", "BLError")
        }

      case "Lb": // library
        let j = tknz.rest
        if let kl = knownLibraries[String(j.value)] {
          thisCommand.append(span("library", "\(kl) (\(j.value))"))
        } else {
          thisCommand =  span("library", j.value)
        }
        thisDelim = j.closingDelimiter
      case "Li":
        if let j = nextArg(tknz) {
          thisCommand.append(span("literal", j.value))
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
            thisCommand.append(span("utility", name ?? ""))
          } else {
            thisCommand.append( span("utility", j.value) )
          }
          thisDelim = j.closingDelimiter
        } else {
          if let name { thisCommand.append( span("utility", name)) }
        }
        
      case "Ns":
        return macro(tknz)
          
      case "Nx":
        if let j = macro(tknz) {
          thisCommand = span("os", "NetBSD "+j.value)
          thisDelim = j.closingDelimiter
        }
        
      case "Oc":
        let _ = tknz.rest
        
      case "Oo":
        let k = macroBlock(["Oc"])
        thisCommand = "["+k+"]"
        
      case "Op":
        // in "apply", the .Ns macro is applied here, but "cd" is already " "
        // is the fix to have tknz maintain a previousClosingDelimiter?
        while let j = macro(tknz) {
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
        thisCommand = span("os", "OpenBSD\(j.value)")

      case "Pa":
        while let j = nextArg(tknz) {
          thisCommand.append(thisDelim)
          thisCommand.append( span("path", j.value))
          thisDelim = j.closingDelimiter
        }
      case "Pf":
        if let j = tknz.next() {
          thisCommand.append(contentsOf: j.value)
        }
        
      case "Lp", "Pp":
        thisCommand = "<p>"
      case "Pq":
        if let j = macro(tknz) {
          thisCommand = "(\(j.value))"
          thisDelim = j.closingDelimiter
        }
        
      case "Ql":
        let j = tknz.rest
        thisCommand = span("literal", j.value)
        thisDelim = j.closingDelimiter
        
        // Note: technically this should use normal quotes, not typographic quotes
      case "Qq":
        thisCommand = "<q>\(parseLine(tknz))</q>"
        
      case "Re":
        if let re = parseState.rsState {
          thisCommand = re.formatted(self)
        }
      case "Rs":
        parseState.rsState = RsState()
        
      case "Sh", "SH": // can be used to end a tagged paragraph
        // FIXME: need to handle tagged paragraph
        
        let j = tknz.rest
        thisCommand = "<a id=\"\(j.value)\"><h4>" + span(nil, j.value) + "</h4></a>"
        parseState.inSynopsis = j.value == "SYNOPSIS"
        thisDelim = j.closingDelimiter
        
      case "Sm": // spacing mode
        let j = tknz.rest.value
        parseState.spacingMode = j.lowercased() != "off"
        
      case "Sq":
        let sq = parseLine(tknz)
        thisCommand = "<q class=\"single\">\(sq)</q>"
      case "Ss":
        let j = tknz.rest.value
        thisCommand = "<h5 id=\"\(j)\">\(j)</h5>"
      case "St":
        let j = tknz.next()?.value ?? "??"
        thisCommand = span("standard", standards[String(j)] ?? "(unknown)")
      case "Sx":
        let j = tknz.rest.value
        thisCommand = "<a class=\"manref\" href=\"#\(j)\">\(j)</a>"
      case "Sy":
        while let j = macro(tknz) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
          if tknz.peekMacro() && tknz.peekToken()?.value == "No" {
            let _ = tknz.next()
            break
          }
        }
        thisCommand = span("serious", thisCommand)
      
      case "Ta":
        thisCommand = "\t"
      case "Tn":
        let j = parseLine(tknz)
        thisCommand = span("small-caps", j)
      case "Ux":
        thisCommand = span("os", "UNIX")
        
      case "Va":
        let j = parseLine(tknz) // tknz.rest
        thisCommand = span("variable", j)
        
      case "Vb":
        let _ = tknz.rest
        thisCommand = "<code>"
      case "Ve":
        let _ = tknz.rest
        thisCommand = "</code>"
        
      case "Vt": // global variable in the SYNOPSIS section, else variable type
        let j = parseLine(tknz)
        thisCommand = "<br>"+span("variable", j)
        thisDelim = "\n"
        
      case "Xc":
        let _ = tknz.rest
        
      case "Xo": // extend item
        thisCommand = macroBlock(["Xc"])
        
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
        let _ = tknz.rest
        definitionBlock() // wkip over the definition
  
        // FIXME: handle tagged paragraph

      case "TP":
        // FIXME: get the indentation from the argument
        let _ = tknz.next()?.value ?? "10"
        
        if linesSlice.isEmpty {
          break
        }
        let line = linesSlice.removeFirst()
        let currentTag = handleLine(line)

        let k = macroBlock(["TP", "PP", "SH"])
        thisCommand = taggedParagraph(currentTag, k)
        
      case "P", "PP":
        thisCommand = "<p>"
        
      case "RS":
        let _ = tknz.next()?.value ?? "10"
        let _ = tknz.rest // eat the rest of the line
        
        let k = macroBlock(["RE"], bs)
        thisCommand = "<div style=\"padding-left: 4em;\">\(k)</div>"
        
      case "RE":
        let _ = tknz.rest // already handled in RS
        
      case "B":
        thisCommand = span("bold", tknz.rest.value)
        
      case "I":
        thisCommand = span("italic", tknz.rest.value)
        
      case "BI":
        if let j = tknz.next()?.value {
          let k = tknz.rest
          if k.value.isEmpty {
            thisCommand = span("italic", span("bold", j))
          } else {
            thisCommand = span("italic", span("bold", j) + k.value)
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
        var cd = ""
        while let j = tknz.next()?.value {
          if toggle {
            thisCommand.append( cd + span("bold", j) )
          } else {
            thisCommand.append( cd + span("regular", j))
          }
          toggle.toggle()
          //         cd = tknz.closingDelimiter
        }
        thisCommand.append(cd)
        
      case "IR":
        var toggle = true
        while let j = tknz.next()?.value {
          if toggle {
            thisCommand.append( span("italic", j) )
          } else {
            thisCommand.append( span("regular", j))
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

        let kk = macroBlock(["IP"])
        
        if ind > 0 {
          thisCommand = "<div style=\"margin-left: \(ind)em;\">" + (k?.value ?? "") + " " + kk + "</div>"
        }
        
        // thisCommand = "<p style=\"margin-left: \(ind)em;\">\(k?.value ?? "")"
        
      case "nf":
        var j = textBlock(["fi"], parseState: parseState)
        if j.hasSuffix("\n.") { j.removeLast(2) }
        thisCommand = "<pre>\(j)</pre>"

      case "fi":
        let _ = tknz.rest
        
      case "SS":
        if let j = tknz.next()?.value {
          thisCommand = "<h5>" + span(nil, j) + "</h5>"
        }
        
      case "SM":
        let _ = tknz.rest // eat the line
        if !linesSlice.isEmpty {
          let k = linesSlice.removeFirst()
          
          let j = handleLine(k)
          thisCommand = "<span style=\"font-size: 80%;\" x-source=\(lineNo)>\(j)</span>"
        }
        
      default:
        if macroList.contains(thisToken.value) {
          thisCommand = span("unimplemented", thisToken.value)
        } else {
          thisCommand = span(nil, String(tknz.escaped(thisToken.value)))
          thisDelim = thisToken.closingDelimiter
        }
    }
    return Token(value: Substring(thisCommand), closingDelimiter: thisDelim, isMacro: true)
  }
  
}
