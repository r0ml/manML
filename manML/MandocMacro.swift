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
  func macro( _ bs : BlockState? = nil,
              enders: [String]? = nil, flag: Bool = false) -> Token? {
    
    
    guard let thisToken = next() else { return nil }
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
    
    if let m = definedMacro[String(thisToken.value)] {
      // FIXME: because of this catenation, the line numbering must be adjusted.
      // either need to maintain a list of line numbers with the source macro line repeated --
      // or a list of line numbers with the target macro text associated
      // or a first pass of the source substituting the defined macros.
      let pp = getLines()
      let mm = ArraySlice(m+pp)
      // FIXME: this modifies the lines being parsed, breaks the line numbering -- and should ideally be done in a way
      // to maintain the hierarchy of substitutions
      lines = mm
      return nil
      //      let output = macroBlock(&mm, [], BlockState() )
      //      return Token(value: Substring(output), closingDelimiter: "\n", isMacro: false)
    }
    
    
    switch thisToken.value {
      case "%A": rsState?.author.append( String(rest.value) )
      case "%B": rsState?.book = String(rest.value)
      case "%C": rsState?.location = String(rest.value)
      case "%D": rsState?.date = String(rest.value)
      case "%I": rsState?.issuer = String(rest.value)
      case "%J": rsState?.journal = String(rest.value)
      case "%N": rsState?.issue = String(rest.value)
      case "%O": rsState?.optional = String(rest.value)
      case "%P": rsState?.page = String(rest.value)
      case "%Q": rsState?.institution.append(String(rest.value) )
      case "%R": rsState?.report = String(rest.value)
      case "%T": rsState?.article = String(rest.value)
      case "%U": rsState?.uri = String(rest.value)
      case "%V": rsState?.volume = String(rest.value)
        
      case "Ac": // end Ao
        thisCommand = ">"
        thisDelim = "&thinsp;"
      case "Ad": // memory address
        thisCommand = span("unimplemented", "Ad", lineNo)
        
      case "An": // Author name
        let z = peekToken()
        if z?.value == "-split" { authorSplit = true; let _ = rest; break }
        else if z?.value == "-nosplit" { authorSplit = false; let _ = rest; break }
        let k = parseLine()
        thisCommand = span("author", k , lineNo)
        
      case "Ao": // enclose in angle bracketrs
        thisCommand = "<"
        thisDelim = "&thinsp;"
        
      case "Ap": // apostrophe
        thisCommand = "'"
        
      case "Aq": // enclose rest of line in angle brackets
        let j = rest
        thisCommand.append(span(nil, "&lt;\(j.value)&gt;", lineNo))
        thisDelim = j.closingDelimiter
        
      case "Ar": // command arguments
        if let jj = nextArg() {
          thisCommand.append(span("argument", jj.value, lineNo))
          thisDelim = jj.closingDelimiter
          while peekToken()?.value != "|",
                let kk = nextArg() {
            thisCommand.append(thisDelim)
            thisCommand.append(span("argument", kk.value, lineNo))
            thisDelim = kk.closingDelimiter
          }
        } else {
          thisCommand.append(span("argument", "file", lineNo) + " " + span("argument", "…", lineNo))
        }
        
      case "At": // at&t unix version
        if let jt = next() {
          thisCommand = "<nobr>"+span("os", att[String(jt.value)] ?? "AT&T Unix", lineNo)+"</nobr>"
          thisDelim = jt.closingDelimiter
        }
        
      case "Bc": // cloase a Bo block
        let _ = rest
        
      case "Bd": // begin a display block
                 // FIXME: doesn't handle all types of display blocks
        thisCommand = blockBlock()
        
      case "Bf": // begin a font block
        if let j = next() {
          let k = macroBlock(["Ef"])
          switch j.value {
            case "Em", "-emphasis":
              thisCommand = span("", "<em>" + k + "</em>", lineNo)
            case "Li", "-literal":
              thisCommand = span("", "<code>" + k + "</code>", lineNo)
            case "Sy", "-symbolic":
              thisCommand = span("", "<i>" + k + "</i>", lineNo)
            default:
              thisCommand = k
          }
        }
      case "Bk": // keep block on single line
        let _ = rest // it should be `-words`
        let j = macroBlock(["Ek"])
        thisCommand = j
        
      case "Bl": // begin list.
                 // FIXME: not all list types are supported yet
        thisCommand = listBlock()
        
      case "Bo": // begin square bracket block.
        thisCommand = span(nil, "[" + macroBlock(["Bc"])+"]", lineNo)
        
      case "Bq": // enclose in square brackets.
        if let j = macro() {
          thisCommand = span(nil, "["+j.value+"]", lineNo)
          thisDelim = j.closingDelimiter
        }
        
      case "Brc": // end Bro
        let _ = rest
        
      case "Bro": // curly brace block
        thisCommand = macroBlock(["Brc"])
        
      case "Brq": // curly brace
        if let j = macro() {
          thisCommand = span(nil, "{"+j.value+"}", lineNo)
          thisDelim = j.closingDelimiter
        }
        
      case "Bsx": // BSD version
        if let j = nextArg() {
          thisCommand = span("os", "BSD/OSv\(j.value)", lineNo)
          thisDelim = j.closingDelimiter
        } else {
          thisCommand = span("os", "BSD/OS", lineNo)
          thisDelim = "\n"
        }
        
      case "Bt": // deprecated
        thisCommand = span(nil, "is currently in beta test.", lineNo)
        
      case "Bx":
        if let j = next() {
          thisCommand = span("os","\(j.value)BSD", lineNo) // + parseState.closingDelimiter
          thisDelim = j.closingDelimiter
        } else {
          thisCommand = span("os", "BSD", lineNo)
          thisDelim = "\n"
        }
        
        // ==============================================
        
      case "Cd": // kernel configuration
        let j = rest
        thisCommand = span("kernel", j.value, lineNo)
        thisDelim = j.closingDelimiter
        
      case "Cm": // command modifiers
        while let j = macro(flag: true) {
          thisCommand.append(thisDelim + span("command", j.value, lineNo) )
          thisDelim = j.closingDelimiter
        }
        
      case "Db": // obsolete and ignored
        let _ = rest
        
      case "Dc": // close a "Do" block
        let _ = rest
        
      case "Dd": // document date
        var d = String(rest.value)
        // This weirdness is for ssh(1)
        let k = "$Mdocdate:"
        if d.hasPrefix(k) {
          d = String(d.dropFirst(k.count))
          if d.last == "$" {
            d = String(d.dropLast())
          }
          d = d.trimmingCharacters(in: .whitespaces)
        }
        date = d
        
      case "D1", "Dl": // single indented line
                       //        if let j = macro(&linesSlice, tknz) {
        let j = rest
        thisCommand = "<blockquote>"+span("", j.value, lineNo )+"</blockquote>"
        thisDelim = j.closingDelimiter
        //        }
        
      case "Do": // enclose block in quotes
        let j = macroBlock(["Dc"])
        thisCommand = span(nil, "<q>"+j+"</q>", lineNo)
        
      case "Dq": // enclosed in quotes
        let q = peekToken()
        if let j = macro() {
          // This is an ugly Kludge for find(1) and others that double quote literals.
          if q?.value == "Li" {
            thisCommand = String(j.value)
          } else {
            thisCommand = "<q>\(j.value)</q>"
          }
          thisDelim = j.closingDelimiter
        }
        
      case "Dt": // document title
        title = String(rest.value)
        let tt = title!.split(separator: " ")
        
        let (name, section) = (tt[0], tt[1])
        
        thisCommand = pageHeader(name, section, sections[String(section)] ?? "Unknown")
        
        
      case "Dv": // defined variable
        if let j = nextArg() {
          thisCommand = span("defined-variable", j.value, lineNo)
          thisDelim = j.closingDelimiter
        }
        
      case "Dx": // dragonfly version
        thisCommand = span("unimplemented", "Dx", lineNo)
        
        // =======================================================
        
      case "Ed":
        thisCommand = "</blockquote>"
        
      case "Ef":
        let _ = rest
        
      case "Ek":
        let _ = rest
        
      case "El":
        thisCommand = span("unimplemented", ".El encountered without .Bl", lineNo)
        
      case "Em":
        if let j = macro() {
          thisCommand = "<em>\(j.value)</em>"
          thisDelim = j.closingDelimiter
        }
      case "Er":
        if let j = macro() {
          thisCommand = span("error", j.value, lineNo)
          thisDelim = j.closingDelimiter
        }
      case "Ev":
        while let j = nextArg() {
          thisCommand.append(span("environment", j.value, lineNo) )
          thisCommand.append(j.closingDelimiter.replacing(" ", with: "&ensp;"))
          //          thisDelim = j.closingDelimiter
        }
      case "Ex":
        let _ = next() // should equal "-std"
        let j = next()?.value ?? Substring(name ?? "??")
        thisCommand = "The \(span("utility",j, lineNo)) utility exits 0 on success, and >0 if an error occurs."
        
        // Function argument
      case "Fa":
        //        let sep = parseState.wasFa ? ", " : ""
        thisCommand.append(thisDelim)
        if let j = nextArg() {
          thisCommand.append(span("function-arg", j.value, lineNo))
          thisDelim = bs?.functionDef == true ? faDelim : j.closingDelimiter
        }
      case "Fc":
        thisCommand = "<br/>"
        if inSynopsis {
          thisDelim = "<br>"
        }
      case "Fd":
        let j = rest
        thisCommand = span("directive", j.value, lineNo) + "<br/>"
        thisDelim = j.closingDelimiter
        
      case "Fl":
        // This was upended by "ctags" and "ssh"
        repeat {
          if let j = macro(flag: true) {
            thisCommand.append(thisDelim)
            thisCommand.append(contentsOf: "<nobr>" + span("flag", "-" + j.value, lineNo) + "</nobr>")
            thisDelim = j.closingDelimiter
          } else if let j = next() {
            thisCommand.append("<nobr>" + span("flag", "-"+j.value, lineNo) + "</nobr>")
            thisDelim = j.closingDelimiter
          }
        } while thisDelim == "|"
        
        // if there is no argument, the result is a single dash
        if thisCommand.isEmpty {
          thisCommand = span("flag", "-", lineNo)
        }
        
      case "Fn":
        // for compat(5)
        if let j = next()?.value {
          thisCommand = span("function-name", j, lineNo)
          thisCommand.append("(")
          var sep = ""
          while let j = next()?.value {
            thisCommand.append(sep)
            thisCommand.append(contentsOf: span("argument", j, lineNo) )
            sep = ", "
          }
          thisCommand.append(")")
        }
      case "Fo":
        let j = rest
        thisCommand = span("function-name", j.value, lineNo) + "&thinsp;("
        let bs = BlockState()
        bs.functionDef = true
        let k = macroBlock(["Fc"], bs)
        thisCommand.append(contentsOf: k.dropLast(faDelim.count+1) )
        thisCommand.append(");")
        
      case "Ft":
        let j = rest
        thisCommand = "<br/>" + span("function-type", j.value, lineNo)
        if inSynopsis {
          thisDelim = "<br>"
        } else {
          thisDelim = j.closingDelimiter
        }
      case "Fx":
        if let j = next() {
          thisCommand = span("os", "FreeBSD \(j.value)", lineNo)
          thisDelim = j.closingDelimiter
        }
      case "Ic":
        if let j = macro() {
          thisCommand = span("command", j.value, lineNo)
          thisDelim = j.closingDelimiter
        }
      case "In": // include
        let j = rest
        thisCommand = "<div class=\"include\">#include &lt;\(j.value)&gt;</div>"
        thisDelim = j.closingDelimiter
      case "It":
        let currentTag = parseLine(bs)
        let currentDescription = macroBlock(["It", "El"], bs)
        
        switch bs?.bl {
          case .tag:
            thisCommand = taggedParagraph(currentTag, currentDescription, lineNo) // "</div></div>"
          case .item, ._enum, .bullet, .dash:
            thisCommand = "<li>" + currentDescription + "</li>"
          case .hang:
            thisCommand = "<div style=\"margin-top: 0.8em;\">\(currentTag) \(currentDescription)</div>"
          case .table:
            thisCommand = "<tr><td>\(currentTag) \(currentDescription)</td></tr>"
          default:
            thisCommand = span("unimplemented", "BLError", lineNo)
        }
        
      case "Lb": // library
        let j = rest
        if let kl = knownLibraries[String(j.value)] {
          thisCommand.append(span("library", "\(kl) (\(j.value))", lineNo))
        } else {
          thisCommand =  span("library", j.value, lineNo)
        }
        thisDelim = j.closingDelimiter
      case "Li":
        if let j = nextArg() {
          thisCommand.append(span("literal", j.value, lineNo))
          thisDelim = j.closingDelimiter
        }
        
      case "Mt":
        if let j = next() {
          thisCommand = "<a href=\"mailto:\(j.value)\">\(j.value)</a>"
          thisDelim = j.closingDelimiter
        }
        
      case "No": // revert to normal text.  Should not need to do anything?
        break
        
      case "Nd":
        thisCommand = " - \(rest.value)" // removed a <br/> because it mucked up "ctags"
        
      case "Nm":
        // in the case of ".Nm :" , the : winds up as the closing delimiter for the macro name.
        if inSynopsis { thisCommand.append("<br>") }
        if let j = nextArg() {
          if name == nil { name = String(j.value) }
          //          if parseState.inSynopsis { thisCommand.append("<br/>") }
          if j.value.isEmpty {
            thisCommand.append(span("utility", name ?? "", lineNo))
          } else {
            thisCommand.append( span("utility", j.value, lineNo) )
          }
          thisDelim = j.closingDelimiter
        } else {
          if let name { thisCommand.append( span("utility", name, lineNo)) }
        }
        
      case "Ns":
        return macro(bs)
        
      case "Nx":
        if let j = macro() {
          thisCommand = span("os", "NetBSD "+j.value, lineNo)
          thisDelim = j.closingDelimiter
        }
        
      case "Oc":
        let _ = rest
        
      case "Oo":
        // the Oc is often embedded somewhere in the rest of this line.
        // the difference between this and Op is that Op terminates at line end, but Oo does not
        while let j = macro(enders: ["Oc"]) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }
        
        // FIXME: for an "Oo" whih goes across multiple lines, need to do the "macroBlock" type of solution
        // so I need to be able to determine if I saw the closing macro during the above loop
        
        //       let k = macroBlock(&linesSlice, ["Oc"], bs)
        thisCommand = "["+thisCommand+"]"
        // FIXME: should I do this?
        thisDelim = ""
        
      case "Op":
        // in "apply", the .Ns macro is applied here, but "cd" is already " "
        // is the fix to have tknz maintain a previousClosingDelimiter?
        while let j = macro() {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }
        thisCommand = "[" + thisCommand + "]"
        
        // this needs to be parsed
      case "Os":
        let j = rest
        if !j.value.isEmpty { os = String(j.value) }
        else {
          let v = ProcessInfo.processInfo.operatingSystemVersion
          os = "macOS \(v.majorVersion).\(v.minorVersion)"  }
      case "Ox":
        let j = rest
        thisCommand = span("os", "OpenBSD\(j.value)", lineNo)
        
      case "Pa":
        while let j = nextArg() {
          thisCommand.append(thisDelim)
          thisCommand.append( span("path", j.value, lineNo))
          thisDelim = j.closingDelimiter
        }
      case "Pc":
        //        thisCommand = "<br>"
        // for mbrtowc(3), it seems to do nothing
        break
      case "Pf":
        if let j = next() {
          thisCommand.append(contentsOf: j.value)
        }
        
      case "Po":
        //        thisCommand = "<p>"
        // for mbrtowc(3) , it seems to do nothing
        break
      case "Lp", "Pp":
        thisCommand = "<p>"
      case "Pq":
        if let j = macro() {
          thisCommand = "(\(j.value))"
          thisDelim = j.closingDelimiter
        }
        
      case "Ql":
        if let j = macro() {
          thisCommand.append(thisDelim)
          thisCommand.append( span("literal", j.value, lineNo) )
          thisDelim = j.closingDelimiter
        }
        
        // Note: technically this should use normal quotes, not typographic quotes
      case "Qq":
        thisCommand = "<q>\(parseLine())</q>"
        
      case "Re":
        if let re = rsState {
          thisCommand = re.formatted(self, lineNo)
        }
      case "Rs":
        rsState = RsState()
        
      case "Sh", "SH": // can be used to end a tagged paragraph
                       // FIXME: need to handle tagged paragraph
        
        let j = rest
        thisCommand = "<a id=\"\(j.value)\"><h4>" + span(nil, j.value, lineNo) + "</h4></a>"
        inSynopsis = j.value == "SYNOPSIS"
        thisDelim = j.closingDelimiter
        
      case "Sm": // spacing mode
        let j = rest.value
        spacingMode = j.lowercased() != "off"
        
      case "Sq":
        let sq = parseLine()
        thisCommand = "<q class=\"single\">\(sq)</q>"
      case "Ss":
        let j = rest.value
        thisCommand = "<h5 id=\"\(j)\">\(j)</h5>"
      case "St":
        let j = next()?.value ?? "??"
        thisCommand = span("standard", standards[String(j)] ?? "(unknown)", lineNo)
      case "Sx":
        let j = rest.value
        thisCommand = "<a class=\"manref\" href=\"#\(j)\">\(j)</a>"
      case "Sy":
        while let j = macro() {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
          if peekMacro(),
             peekToken()?.value == "No" {
            let _ = next()
            break
          }
        }
        thisCommand = span("serious", thisCommand, lineNo)
        
      case "Ta":
        //        thisCommand = "\t"
        thisCommand = "</td><td>"
        
      case "Tn":
        let j = parseLine()
        thisCommand = span("small-caps", j, lineNo)
      case "Ux":
        thisCommand = span("os", "UNIX", lineNo)
        
      case "Va":
        let j = parseLine() // rest
        thisCommand = span("variable", j, lineNo)
        
      case "Vb":
        let _ = rest
        thisCommand = "<code>"
      case "Ve":
        let _ = rest
        thisCommand = "</code>"
        
      case "Vt": // global variable in the SYNOPSIS section, else variable type
        if let j = next() {
          //        parseLine(tknz)
          if inSynopsis {
            thisCommand = "<br>"+span("variable", j.value, lineNo)
            thisDelim = "\n"
          } else {
            thisCommand = "("+span("variable", j.value, lineNo)+")"
            thisDelim = j.closingDelimiter
          }
        }
        
      case "Xc":
        let _ = rest
        
      case "Xo": // extend item
        thisCommand = macroBlock(["Xc"])
        
      case "Xr":
        if let j = next(),
           let k = next() {
          
          thisCommand = "<a class=\"manref\" href=\"mandocx:/\(j.value)/\(k.value)\">\(j.value)(\(k.value))</a>" // + parseState.closingDelimiter
          thisDelim = k.closingDelimiter
        }
        
        
      default:
        if !flag {
          // =================================================================================
          // roff stuff
          // =================================================================================
          switch(thisToken.value) {
            case "br":
              thisCommand = "<br/>"
              
            case "sp":
              thisCommand = "<br/>"
              
              // "de" defines a macro -- and the macro definition goes until a line consisting of ".."
            case "de":
              // this would be the macro name if I were implementing roff macro definitions
              if let nam = next() {
                // FIXME: need to parse arguments
                //          let a = rest
                let val = definitionBlock() // skip over the definition
                definedMacro[String(nam.value)] = val
              }
              
            case "TP":
              // FIXME: get the indentation from the argument
              //        let ind = next()?.value ?? "10"
              
              if atEnd {
                break
              }
              let line = peekLine
              nextLine()
              let currentTag = handleLine(line)
              
              let k = macroBlock([]) // "TP", "PP", "SH"])
              thisCommand = span("", taggedParagraph(currentTag, k, lineNo), lineNo)
              
            case "P", "PP":
              thisCommand = "<p>"
              
            case "RS":
              let tw = next()?.value ?? "10"
              let _ = rest // eat the rest of the line
              
              let k = macroBlock(["RE"], bs)
              thisCommand = "<div style=\"padding-left: 2em; --tag-width: \(tw)em\">\(k)</div>"
              
            case "RE":
              let _ = rest // already handled in RS
              
            case "B":
              thisCommand = span("bold", rest.value, lineNo)
              
            case "I":
              thisCommand = span("italic", rest.value, lineNo)
              
            case "BI":
              if let j = next()?.value {
                let k = rest
                if k.value.isEmpty {
                  thisCommand = span("italic", span("bold", j, lineNo), lineNo)
                } else {
                  thisCommand = span("italic", span("bold", j, lineNo) + k.value, lineNo)
                }
              }
              
            case "BR":
              /*        if let j = next() {
               let k = rest
               if k.isEmpty {
               thisCommand = span("roman", span("bold", j))
               } else {
               thisCommand = span("roman", span("bold", j) + k)
               }
               }
               */
              var toggle = true
              //        let cd = ""
              while let j = next()?.value {
                if toggle {
                  thisCommand.append( span("bold", j, lineNo) )
                } else {
                  thisCommand.append( span("regular", j, lineNo))
                }
                toggle.toggle()
                //         cd = closingDelimiter
              }
              //        thisCommand.append(cd)
              
            case "IR":
              var toggle = true
              while let j = next()?.value {
                if toggle {
                  thisCommand.append( span("italic", j, lineNo) )
                } else {
                  thisCommand.append( span("regular", j, lineNo))
                }
                toggle.toggle()
              }
              
            case "TH":
              let name = next()?.value ?? "??"
              let section = next()?.value ?? ""
              title = "\(name)(\(section))"
              date = String(next()?.value ?? "")
              os = String(next()?.value ?? "")
              let h = String(next()?.value ?? "")
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
              let _ = rest
              break   // not implemented
              
              // FIXME: put me back -- but in an async way
              /*
               case "so":
               let link = next()?.value ?? "??"
               if let file = manpath.link(String(link) ),
               let k = try? String(contentsOf: file, encoding: .utf8) {
               return Token(value: Substring(generateBody(k)), closingDelimiter: "", isMacro: false)
               }
               */
              
            case "ll":
              let _ = rest
              // FIXME: this changes the line length (roff)
              // for now, I will ignore this macro
              
            case "PD": // Psragraph distance.  Not implemented
              let _ = next()
              
            case "IX": // ignore -- POD uses it to create an index entry
              let _ = rest
              
            case "ds": // define string
              let nam = next()?.value ?? "??"
              let val = String(rest.value)
              definedString[String(nam)] = val
              
            case "rm": // remove macro definition -- ignored for now
              let _ = rest
              
            case "if":
              if let j = next() {
                if j.value == "n" {
                  let tr = rest
                  thisCommand = String(tr.value)
                  thisDelim = tr.closingDelimiter
                } else {
                  let _ = rest
                }
              }
              
            case "ie", "el":
              let j = rest.value
              let k = j.matches(of: /\{/)
              ifNestingDepth += k.count
              
            case "tr": // replace characters -- ignored for now
              let _ = rest
              
            case "nr": // set number register -- ignored for now
              let _ = rest
              
            case "rr": // remove register -- ignored for now because set register is ignored
              let _ = rest
              
            case "IP":
              let k = next()
              var ind = 3
              if let dd = next() {
                if let i = Int(dd.value) { ind = i }
              }
              
              let _ = rest
              
              let kk = macroBlock([])
              
              if ind > 0 {
                thisCommand = "<div style=\"margin-left: \(ind/2)em;text-indent: -0.7em\">" + (k?.value ?? "") + " " + kk + "</div>"
              }
              
              // thisCommand = "<p style=\"margin-left: \(ind)em;\">\(k?.value ?? "")"
              
            case "nf":
              var j = textBlock(["fi"])
              if j.hasSuffix("\n.") { j.removeLast(2) }
              thisCommand = "<pre>\(j)</pre>"
              
            case "fi":
              let _ = rest
              
            case "SS":
              let j = rest.value
              thisCommand = "<h5>" + span(nil, j, lineNo) + "</h5>"
              
            case "SM":
              let _ = rest // eat the line
              if !atEnd {
                let k = peekLine
                nextLine()
                
                let j = handleLine(k)
                let ln = lineNo
                thisCommand = "<span style=\"font-size: 80%;\" x-source=\(ln)>\(j)</span>"
              }
            
            default:
              if macroList.contains(thisToken.value) {
                thisCommand = span("unimplemented", thisToken.value, lineNo)
              } else {
                thisCommand = span(nil, String(escaped(thisToken.value)), lineNo)
                thisDelim = thisToken.closingDelimiter
              }
          }
        } else {
          if macroList.contains(thisToken.value) {
            thisCommand = span("unimplemented", thisToken.value, lineNo)
          } else {
            thisCommand = span(nil, String(escaped(thisToken.value)), lineNo)
            thisDelim = thisToken.closingDelimiter
          }
        }
    }
    return Token(value: Substring(thisCommand), closingDelimiter: thisDelim, isMacro: true)
  }
  
}
