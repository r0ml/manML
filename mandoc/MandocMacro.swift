//
// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation

let knownLibraries = ["libc" : "Standard C Library",
                      "libm" : "Math Library"
]
let faDelim = ",&ensp;"

extension Mandoc {

  func next() async -> Token? {
    return await Tokenizer.shared.next()
  }

  func peekToken() async -> Token? {
    return await Tokenizer.shared.peekToken()
  }

  func nextArg(enders: [String]) async throws(ThrowRedirect) -> Token? {
    return try await Tokenizer.shared.nextArg(enders: enders)
  }

  func rest() async -> Token {
    return await Tokenizer.shared.rest()
  }

  func shouldIContinue(_ thisDelim : String) async -> Bool {
    let res = thisDelim == " | " || thisDelim == ", "
    if !res { return false }
    if let b = await peekToken() {
      if b.isMacro { return false }
    } else {
      return false
    }
    return true
  }
  /** Evaluation of a single Mandoc ( or roff ) macro returning the HTML string  which is the output.
   The tokenizer is advanced by consuming the arguments.  It does not necessarily consume the entire line.
   */
  func macro( _ bs : BlockState? = nil,
              enders: [String], flag: Bool = false) async throws(ThrowRedirect) -> Token? {

    guard let thisToken = await next() else { return nil }
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
    
    if let m = await Tokenizer.shared.getDefinedMacro(String(thisToken.value)) {
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
      case "%A": 
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.author.append( rv )
      case "%B":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.book = rv
      case "%C":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.location = rv
      case "%D":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.date = rv
      case "%I":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.issuer = rv
      case "%J":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.journal = rv
      case "%N":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.issue = rv
      case "%O":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.optional = rv
      case "%P":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.page = rv
      case "%Q":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.institution.append(rv)
      case "%R":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.report = rv
      case "%T":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.article = rv
      case "%U":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.uri = rv
      case "%V":
        let rv = String(await Tokenizer.shared.rest().value)
        rsState?.volume = rv
        
      case "Ac": // end Ao
        thisCommand = ">"
        thisDelim = "&thinsp;"
      case "Ad": // memory address
        thisCommand = span("unimplemented", "Ad", lineNo)
        
      case "An": // Author name
        let z = await peekToken()
        if z?.value == "-split" { authorSplit = true; let _ = await rest(); break }
        else if z?.value == "-nosplit" { authorSplit = false; let _ = await rest(); break }
        let k = try await parseLine(enders: enders)
        thisCommand = span("author", k , lineNo)
        
      case "Ao": // enclose in angle bracketrs
        thisCommand = "<"
        thisDelim = "&thinsp;"
        
      case "Ap": // apostrophe
        thisCommand = "'"
        
      case "Aq": // enclose rest of line in angle brackets
        let j = await rest()
        thisCommand.append(span(nil, "&lt;\(j.value)&gt;", lineNo))
        thisDelim = j.closingDelimiter
        
      case "Ar": // command arguments
        if let jj = try await nextArg(enders: enders) {
          thisCommand.append(span("argument", jj.value, lineNo))
          thisDelim = jj.closingDelimiter
          while await peekToken()?.value != "|",
                let kk = try await nextArg(enders: enders) {
            thisCommand.append(thisDelim)
            //             thisCommand.append(span("argument", kk.value, lineNo))
            thisCommand.append(span("argument", kk.value, lineNo))
            thisDelim = kk.closingDelimiter
          }
        } else {
          thisCommand.append(span("argument", "file", lineNo) + " " + span("argument", "…", lineNo))
        }
        
      case "At": // at&t unix version
        if let jt = await next() {
          thisCommand = "<nobr>"+span("os", att[String(jt.value)] ?? "AT&T Unix", lineNo)+"</nobr>"
          thisDelim = jt.closingDelimiter
        }
        
      case "Bc": // cloase a Bo block
        let _ = await rest()

      case "Bd": // begin a display block
                 // FIXME: doesn't handle all types of display blocks
        thisCommand = await blockBlock()

      case "Bf": // begin a font block
        if let j = await next() {
          let k = await macroBlock( (enders ?? []) + ["Ef"])
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
        let _ = await rest() // it should be `-words`
        let j = await macroBlock( enders + ["Ek"])
        thisCommand = j
        
      case "Bl": // begin list.
                 // FIXME: not all list types are supported yet
        thisCommand = await listBlock()

      case "Bo": // begin square bracket block.
        thisCommand = await span(nil, "[" + macroBlock( enders + ["Bc"])+"]", lineNo)

      case "Bq": // enclose in square brackets.
        if let j = try await macro(enders: enders) {
          thisCommand = span(nil, "["+j.value+"]", lineNo)
          thisDelim = j.closingDelimiter
        }
        
      case "Brc": // end Bro
        thisCommand = ""
        thisDelim = "}"

      case "Bro": // curly brace block
        while let j = try await macro(enders: ["Brc"]) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }

        thisCommand = "{"+thisCommand

      case "Brq": // curly brace
        if let j = try await macro(enders: enders) {
          thisCommand = span(nil, "{"+j.value+"}", lineNo)
          thisDelim = j.closingDelimiter
        }
        
      case "Bsx": // BSD version
        if let j = try await nextArg(enders: enders) {
          thisCommand = span("os", "BSD/OSv\(j.value)", lineNo)
          thisDelim = j.closingDelimiter
        } else {
          thisCommand = span("os", "BSD/OS", lineNo)
          thisDelim = "\n"
        }
        
      case "Bt": // deprecated
        thisCommand = span(nil, "is currently in beta test.", lineNo)
        
      case "Bx":
        if let j = await next() {
          thisCommand = span("os","\(j.value)BSD", lineNo) // + parseState.closingDelimiter
          thisDelim = j.closingDelimiter
        } else {
          thisCommand = span("os", "BSD", lineNo)
          thisDelim = "\n"
        }
        
        // ==============================================
        
      case "Cd": // kernel configuration
        let j = await rest()
        thisCommand = span("kernel", j.value, lineNo)
        thisDelim = j.closingDelimiter
        
      case "Cm": // command modifiers
        while let j = try await macro(enders: enders, flag: true) {
          if !j.value.isEmpty {
            thisCommand.append(thisDelim + span("command", j.value, lineNo) )
          }
          thisDelim = j.closingDelimiter
        }
        
      case "Db": // obsolete and ignored
        let _ = await rest()

      case "Dc": // close a "Do" block
        let _ = await rest()

      case "Dd": // document date
        var d = String(await rest().value)
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
        let j = try await parseLine(enders: enders)
        thisCommand = "<blockquote>"+span("", j, lineNo )+"</blockquote>"
        thisDelim = "\n"
        //        }
        
      case "Do": // enclose block in quotes
        let j = await macroBlock( (enders ?? [] ) + ["Dc"])
        thisCommand = span(nil, "<q>"+j+"</q>", lineNo)
        
      case "Dq": // enclosed in quotes
        let q = await peekToken()
        if let j = try await macro(enders: enders) {
          // This is an ugly Kludge for find(1) and others that double quote literals.
          if q?.value == "Li" {
            thisCommand = String(j.value)
          } else {
            thisCommand = "<q>\(j.value)</q>"
          }
          thisDelim = j.closingDelimiter
        }
        
      case "Dt": // document title
        title = String(await rest().value)
        let tt = title!.split(separator: " ")
        let ttt = tt + ["", ""]
        let (name, section) = (ttt[0], ttt.count > 1 ? ttt[1] : "")

        thisCommand = pageHeader(name, section, sections[String(section)] ?? "Unknown")

        
      case "Dv": // defined variable
        if let j = try await nextArg(enders: enders) {
          thisCommand = span("defined-variable", j.value, lineNo)
          thisDelim = j.closingDelimiter
        }
        
      case "Dx": // dragonfly version
        thisCommand = span("unimplemented", "Dx", lineNo)
        
        // =======================================================
        
      case "Ed":
        thisCommand = "</blockquote>"
        
      case "Ef":
        let _ = await rest()

      case "Ek":
        let _ = await rest()

      case "El":
        thisCommand = ""
        thisDelim = ""

      case "Em":
        thisCommand = try await restMacro(enders: enders) { self.span("bold italic", $0, self.lineNo) }

          /*
        if let j = try await macro(flag: true) {
 //       let j = await rest()
          thisCommand = "<em>\(j.value)</em>"
          thisDelim = j.closingDelimiter
       }
        */
      case "Er":
        if let j = try await macro(enders: enders) {
          thisCommand = span("error", j.value, lineNo)
          thisDelim = j.closingDelimiter
        }
      case "Ev":
        while let j = try await nextArg(enders: enders) {
          thisCommand.append(span("environment", j.value, lineNo) )
          thisCommand.append(j.closingDelimiter.replacing(" ", with: "&ensp;"))
          //          thisDelim = j.closingDelimiter
        }
      case "Ex":
        let _ = await next() // should equal "-std"
        let j = await next()?.value ?? Substring(name ?? "??")
        thisCommand = "The \(span("utility",j, lineNo)) utility exits 0 on success, and >0 if an error occurs."
        
        // Function argument
      case "Fa":
        //        let sep = parseState.wasFa ? ", " : ""
        thisCommand.append(thisDelim)
        if let j = try await nextArg(enders: enders) {
          await thisCommand.append(span("function-arg", Tokenizer.shared.escaped(j.value), lineNo))
          thisDelim = bs?.functionDef == true ? faDelim : j.closingDelimiter
        }
      case "Fc":
        thisCommand = "<br/>"
        if inSynopsis {
          thisDelim = "<br>"
        }
      case "Fd":
        let j = await rest()
        thisCommand = await span("directive", Tokenizer.shared.escaped(j.value), lineNo) + "<br/>"
        thisDelim = j.closingDelimiter
        
      case "Fl":
        // This was upended by "ctags" and "ssh"
        repeat {
          if let j = try await macro(enders: enders, flag: true) {
            thisCommand.append(thisDelim)
            thisCommand.append(contentsOf: "<nobr>" + span("flag", "-" + j.value, lineNo) + "</nobr>")
            thisDelim = j.closingDelimiter
          } else if let j = await next() {
            thisCommand.append("<nobr>" + span("flag", "-"+j.value, lineNo) + "</nobr>")
            thisDelim = j.closingDelimiter
          } else {
            thisDelim = "\n"
          }
          // applesingle has Fl h | Fl V -- and doesn't want to double dash the V
          // chmod has Fl H | L | P  -- and wants to dash the L and P
        } while await shouldIContinue(thisDelim)

        // if there is no argument, the result is a single dash
        if thisCommand.isEmpty {
          thisCommand = span("flag", "-", lineNo)
        }
        
      case "Fn":
        // for compat(5)
        let jj = await next()
        if let j = jj?.value {
          thisCommand = span("function-name", j, lineNo)
          thisCommand.append("(")
          var sep = ""
          while let j = await next()?.value {
            thisCommand.append(sep)
            thisCommand.append(contentsOf: span("argument", j, lineNo) )
            sep = ", "
          }
          thisCommand.append(")")
          thisCommand.append(jj!.closingDelimiter)
        }
      case "Fo":
        let j = await rest()
        thisCommand = span("function-name", j.value, lineNo) + "&thinsp;("
        let bs = BlockState()
        bs.functionDef = true
        let k = await macroBlock( (enders ?? []) + ["Fc"], bs)
        thisCommand.append(contentsOf: k.dropLast(faDelim.count+1) )
        thisCommand.append(");")
        
      case "Ft":
        let j = await rest()
          thisCommand = "<br/>" + span("function-type", j.value, lineNo)
          if inSynopsis {
            thisDelim = "<br>"
          } else {
            thisDelim = j.closingDelimiter
          }

      case "Fx":
        if let j = await next() {
          thisCommand = span("os", "FreeBSD \(j.value)", lineNo)
          thisDelim = j.closingDelimiter
        }
      case "Ic":
        if let j = try await macro(enders: enders) {
          thisCommand = span("command", j.value, lineNo)
          thisDelim = j.closingDelimiter
        }
      case "In": // include
        let j = await rest()
        thisCommand = "<br>"+span("include", "#include &lt;\(j.value)&gt;", lineNo)
        thisDelim = j.closingDelimiter

      case "It":
        let currentTag = try await parseLine(bs, enders: enders)
        let currentDescription = await macroBlock( (enders ?? []) + ["It", "El"], bs)

        switch bs?.bl {
          case .diag:
            thisCommand = #"<div class="list-item">"# + span("diag", currentTag + "&nbsp;", lineNo)
//            m.append(#"<div class="tag-description">"# + description + "</div>")
            thisCommand.append(#"</div><div style="clear: both;"></div>"#)

          case .tag:
            thisCommand = taggedParagraph(currentTag, currentDescription, lineNo) // "</div></div>"
          case .item, ._enum, .bullet, .dash:
            thisCommand = "<li>" + currentDescription + "</li>"
          case .hang:
            thisCommand = "<div style=\"margin-top: 0.8em;\">\(currentTag) \(currentDescription)</div>"
          case .table:
            thisCommand = "<tr><td>\(currentTag) \(currentDescription)</td></tr>"
          case .inset:
            thisCommand = "<div style=\"margin-top: 0.8em;\">\(currentTag) \(currentDescription)</div>"
          default:
            thisCommand = span("unimplemented", "BLError", lineNo)
        }
        
      case "Lb": // library
        let j = await rest()
        if let kl = knownLibraries[String(j.value)] {
          thisCommand.append(span("library", "\(kl) (\(j.value))", lineNo))
        } else {
          thisCommand =  span("library", j.value, lineNo)
        }
        thisDelim = j.closingDelimiter
      case "Li":
        if let j = try await nextArg(enders: enders) {
          thisCommand.append(span("literal", j.value, lineNo))
          thisDelim = j.closingDelimiter
        }

      case "Lk":
        if let jj = await next() {
          let j = jj.value
          var k = await rest().value
          if k.isEmpty { k = j }
          let t = span("link", k, lineNo)
          thisCommand.append("<a href=\"\(j)\">\(t)</a>")
          thisDelim = jj.closingDelimiter
        }

      case "Mt":
        if let j = await next() {
          thisCommand = "<a href=\"mailto:\(j.value)\">\(j.value)</a>"
          thisDelim = j.closingDelimiter
        }
        
      case "No": // revert to normal text.  Should not need to do anything?
        break
        
      case "Nd":
        thisCommand = " - \(await rest().value)" // removed a <br/> because it mucked up "ctags"

      case "Nm":
        // in the case of ".Nm :" , the : winds up as the closing delimiter for the macro name.
        if inSynopsis {
          thisCommand.append("<br>")
        }

        var named = false
        while let j = try await nextArg(enders: enders) {
          named = true
          if j.isMacro || j.value.isEmpty {
            if let name {
              thisCommand.append( span("utility", name, lineNo))
              thisCommand.append(" ")
            }
            thisCommand.append(thisToken.closingDelimiter)
            thisCommand.append(contentsOf: j.value)
            thisDelim = j.closingDelimiter
            break
          } else {
            //        if let j = nextArg() {
            if name == nil { name = String(j.value) }

            //          if parseState.inSynopsis { thisCommand.append("<br/>") }

            thisCommand.append(thisDelim)
            thisCommand.append( span("utility", j.value, lineNo) )
            thisDelim = j.closingDelimiter
          }
        }
        if !named {
          if let name { thisCommand.append( span("utility", name, lineNo)) }
          thisDelim = thisToken.closingDelimiter
        }

      case "Ns":
        return try await macro(bs, enders: enders)

      case "Nx":
        if let j = try await macro(enders: enders) {
          thisCommand = span("os", "NetBSD "+j.value, lineNo)
          thisDelim = j.closingDelimiter
        }
        
      case "Oc":
        // let _ = rest()
        thisCommand = ""
        thisDelim = "]"
        break
      case "Oo":
        // the Oc is often embedded somewhere in the rest of this line.
        // the difference between this and Op is that Op terminates at line end, but Oo does not
        while let j = try await macro(enders: ["Oc"]) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }
        
        thisCommand = "[" + thisCommand

      case "Op":
        // in "apply", the .Ns macro is applied here, but "cd" is already " "
        // is the fix to have tknz maintain a previousClosingDelimiter?
        while let j = try await macro(enders: enders) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }
        thisCommand = "[" + thisCommand + "]"
        
        // this needs to be parsed
      case "Os":
        let j = await rest()
        if !j.value.isEmpty { os = String(j.value) }
        else {
          let v = ProcessInfo.processInfo.operatingSystemVersion
          os = "macOS \(v.majorVersion).\(v.minorVersion)"  }
      case "Ox":
        let j = await rest()
        thisCommand = span("os", "OpenBSD\(j.value)", lineNo)
        
      case "Pa":
        while let j = try await nextArg(enders: enders) {
          thisCommand.append(thisDelim)
          thisCommand.append( span("path", j.value, lineNo))
          thisDelim = j.closingDelimiter
        }
      case "Pc":
        //        thisCommand = "<br>"
        // for mbrtowc(3), it seems to do nothing
        break
      case "Pf":
        if let j = await next() {
          thisCommand.append(contentsOf: j.value)
        }
        
      case "Po":
        //        thisCommand = "<p>"
        // for mbrtowc(3) , it seems to do nothing
        break
      case "Lp", "Pp":
        thisCommand = "<p>"
      case "Pq":
        thisCommand = try await restMacro(enders: enders) { self.span("pq", $0, self.lineNo) } // wrap in parens
/*
 //        if let j = try await macro() {
        let j = await rest()
          thisCommand = "(\(j.value))"
          thisDelim = j.closingDelimiter
//        }
*/
      case "Ql":
        if let j = try await macro(enders: enders) {
          thisCommand.append(thisDelim)
          thisCommand.append( span("literal", j.value, lineNo) )
          thisDelim = j.closingDelimiter
        }
        
        // Note: technically this should use normal quotes, not typographic quotes
      case "Qq":
        thisCommand = try await "<q>\(parseLine(enders: enders))</q>"

      case "Re":
        if let re = rsState {
          thisCommand = re.formatted(self, lineNo)
        }
      case "Rs":
        rsState = RsState()

      case "Rv":
        let j = await rest()
        if j.value == "-std" {
          thisCommand = span(nil, "The function returns the value 0 if successful; otherwise the value -1 is returned and errno is set to indicate the error.", lineNo)
        } else {
          thisCommand = span(nil, "-->Rv<--\(j.value)", lineNo)
        }
        thisDelim = j.closingDelimiter

      case "Sh", "SH": // can be used to end a tagged paragraph
                       // FIXME: need to handle tagged paragraph
        
        let j = await rest()
        thisCommand = "<a id=\"\(j.value)\"><h4>" + span(nil, j.value, lineNo) + "</h4></a>"
        inSynopsis = j.value == "SYNOPSIS"
        thisDelim = j.closingDelimiter
        
      case "Sm": // spacing mode
        let j = await rest().value
        await Tokenizer.shared.setSpacingMode ( j.lowercased() != "off" )

      case "Sc":
        if enders.last != "Sc" {
          await Tokenizer.shared.pushToken( thisToken )
        }
        return nil

      case "So":
        while let j = try await macro(enders: ["Sc"]) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }
        thisCommand = "<q class=\"single\">\(thisCommand)</q>"

      case "Sq":
        while let sq = try await macro(enders: enders) {
          thisCommand.append(contentsOf: thisDelim)
          thisCommand.append(contentsOf: sq.value)
          thisDelim = sq.closingDelimiter
        }
        thisCommand = "<q class=\"single\">\(thisCommand)</q>"
      case "Ss":
        let j = await rest().value
        thisCommand = "<h5 id=\"\(j)\">\(j)</h5>"
      case "St":
        let j = await next()?.value ?? "??"
        thisCommand = span("standard", standards[String(j)] ?? "(unknown)", lineNo)
      case "Sx":
        let j = await rest().value
        thisCommand = "<a class=\"manref\" href=\"#\(j)\">\(j)</a>"
      case "Sy":
        while let j = try await macro(enders: enders) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
          if await Tokenizer.shared.peekMacro(),
             await Tokenizer.shared.peekToken()?.value == "No" {
            let _ = await next()
            break
          }
        }
        thisCommand = span("serious", thisCommand, lineNo)
        
      case "Ta":
        //        thisCommand = "\t"
        thisCommand = "</td><td>"
        
      case "Tn":
        let j = try await parseLine(enders: enders)
        thisCommand = span("small-caps", j, lineNo)
      case "Ux":
        thisCommand = span("os", "UNIX", lineNo)
        
      case "Va":
        let j = try await parseLine(enders: enders) // rest()
        thisCommand = span("variable", j, lineNo)
        
      case "Vb":
        let _ = await rest()
        thisCommand = "<code>"
      case "Ve":
        let _ = await rest()
        thisCommand = "</code>"
        
      case "Vt": // global variable in the SYNOPSIS section, else variable type
        if let j = await next() {
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
        let _ = await rest()

      case "Xo": // extend item
        thisCommand = await macroBlock( (enders ?? []) + ["Xc"])

      case "Xr":
        if let j = await next() {
          var sch = "\(scheme):/\(j.value)"
          var dsp = "\(j.value)"
          thisDelim = j.closingDelimiter
          if let k = await next() {
            sch.append("/\(k.value)")
            dsp.append("(\(k.value))")
            thisDelim = k.closingDelimiter
          }
          
          thisCommand = "<a class=\"manref\" href=\"\(sch)\">\(dsp)</a>" // + parseState.closingDelimiter
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
              if let nam = await next() {
                // FIXME: need to parse arguments
                //          let a = rest()
                let val = definitionBlock() // skip over the definition
                await Tokenizer.shared.setDefinedMacro(String(nam.value), val)
              }
              
            case "TP":
              // FIXME: get the indentation from the argument
              //        let ind = next()?.value ?? "10"
              
              if atEnd {
                break
              }
              let line = peekLine
              nextLine()
              let currentTag = try await handleLine(line, enders: enders)

              let k = await macroBlock( [] ) // "TP", "PP", "SH"])
              thisCommand = span("", taggedParagraph(currentTag, k, lineNo), lineNo)
              
            case "P", "PP", "LP":
              thisCommand = "<p>"
              
            case "RS":
              let tw = await next()?.value ?? "10"
              let _ = await rest() // eat the rest of the line

              let k = await macroBlock( (enders ?? []) + ["RE"], bs)
              thisCommand = "<div style=\"padding-left: 2em; margin-top: 0.3em; --tag-width: \(tw)em\">\(k)</div>"

            case "RE":
              let _ = await rest() // already handled in RS

            case "RI": // alternating roman / italic -- seems to handle white spaces and ignore delimiters
              while let j = await Tokenizer.shared.xNextWord() {
                thisCommand.append(span("", j, lineNo))
                if let k = await Tokenizer.shared.popWord() {
                  thisCommand.append(span("italic", k, lineNo))
                }
              }

            case "B":
              thisCommand = span("bold", await rest().value, lineNo)

            case "I":
              thisCommand = span("italic", await rest().value, lineNo)


            case "ft": // set font
              let f = await next()?.value ?? "R"
              let _ = await rest()
              let j = await macroBlock( (enders ?? []) + ["ft"])
              switch f {
                case "R":
                  thisCommand = span("", j, lineNo) // no font
                case "I":
                  thisCommand = span("italic", j, lineNo)
                case "B":
                  thisCommand = span("bold", j, lineNo)
                case "C":
                  thisCommand = span("pre", j, lineNo)
                case "P":
                  thisCommand = span("", j, lineNo)
                default:
                  thisCommand = span("", j, lineNo)
              }



            case "BI":
              if let j = await next()?.value {
                let k = await rest()
                if k.value.isEmpty {
                  thisCommand = span("italic", span("bold", j, lineNo), lineNo)
                } else {
                  thisCommand = span("italic", span("bold", j, lineNo) + k.value, lineNo)
                }
              }
              
            case "BR":
              /*        if let j = next() {
               let k = rest()
               if k.isEmpty {
               thisCommand = span("roman", span("bold", j))
               } else {
               thisCommand = span("roman", span("bold", j) + k)
               }
               }
               */
              var toggle = true
              //        let cd = ""
              while let j = await next()?.value {
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
              while let j = await next()?.value {
                if toggle {
                  thisCommand.append( span("italic", j, lineNo) )
                } else {
                  thisCommand.append( span("regular", j, lineNo))
                }
                toggle.toggle()
              }
              
            case "TH":
              let name = await next()?.value ?? "??"
              let section = await next()?.value ?? " "
              title = "\(name)(\(section))"
              date = String(await next()?.value ?? " ")
              os = String(await next()?.value ?? " ")
              let h = String(await next()?.value ?? "Unknown" )
              thisCommand = pageHeader(name, section, h ) // + "<br>"

            case "HP": // Hanging paragraph.  Argument specifies amount of hang
              // FIXME: I see things like \w'abcdef'u -- which computes the length of 'abcdef' for the size of the hanging indent
              let _ = await rest()  // just not implemented

              let kk = await macroBlock( (enders ?? []) + ["PP", "IP", "TP", "HP", "LP"])

              let width = "3em"
              thisCommand = "<div class=hang style=\"text-indent: -\(width); padding-left: \(width);>"+span("", kk, lineNo)+"</div>"

            case "na": // no alignment -- disables justification until .ad
              var j = await macroBlock( (enders ?? []) + ["ad", "SH"]) // in postfix, there is no trailing .fi  in SEE ALSO
              // FIXME: did I need this?
//              if j.hasSuffix("\n.") { j.removeLast(2) }

              if !j.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                thisCommand = "<div class=na>\(j)</div>"
              }
              break // not implemented

            case "ad": // left/right justify
              let _ = await rest()
              break // not implemented

            case "nh": // disable hypenation until .hy
              let _ = await rest()
              break // not implemented
              
            case "hy": // re-enable hyphenation
              let _ = await rest()
              break   // not implemented
              
             case "so":
              /*
               let link = next()?.value ?? "??"
               if let file = manpath.link(String(link) ),
               let k = try? String(contentsOf: file, encoding: .utf8) {
               return Token(value: Substring(generateBody(k)), closingDelimiter: "", isMacro: false)
               }
               */
              throw ThrowRedirect.to( String(await next()?.value ?? "??") )
            case "ll":
              let _ = await rest()
              // FIXME: this changes the line length (roff)
              // for now, I will ignore this macro
              
            case "PD": // Psragraph distance.  Not implemented
              let _ = await next()
              
            case "IX": // ignore -- POD uses it to create an index entry
              let _ = await rest()

            case "ds": // define string
              let nam = await next()?.value ?? "??"
              let val = String(await rest().value)
              await Tokenizer.shared.setDefinedString(String(nam), val)

            case "rm": // remove macro definition -- ignored for now
              let _ = await rest()

            case "if":
              if let j = await next() {
                if j.value == "n" {
                  let tr = await rest()
                  thisCommand = String(tr.value)
                  thisDelim = tr.closingDelimiter
                } else {
                  let _ = await rest()
                }
              }
              
            case "ie", "el":
              let j = await rest().value
              let k = j.matches(of: /\{/)
              ifNestingDepth += k.count

            case "in":
              let inx = await rest()
//              print(inx)
              let j = await macroBlock(enders+["in"])
              var iny = "0"
              if inx.value.first == "+" {
                iny = (inx.value.dropFirst()+"en")
                thisCommand = "<div style=\"margin-left: \(iny)\">\(j)</div>"
              } else {
                thisCommand = j
              }

            case "ti":
              let inx = await rest()
              let jx = lines.removeFirst()
              let j = try await handleLine(jx, enders: enders)
              var iny = "0"
              if inx.value.first == "+" { iny = (inx.value + "ch") }
              else if inx.value.first == "-" { iny = inx.value + "ch" }
              thisCommand = "<div style=\"margin-left: \(iny)\">\(j)</div>"

            case "tr": // replace characters -- ignored for now
              let _ = await rest()

            case "nr": // set number register -- ignored for now
              let _ = await rest()

            case "rr": // remove register -- ignored for now because set register is ignored
              let _ = await rest()

            case "IP":
              let kkk = await next()
              let k = span("tag", kkk?.value ?? "", lineNo)
              var ind = 3
              if let dd = await next() {
                if let i = Int(dd.value) { ind = i }
              }
              
              let _ = await rest()

              let kk = await macroBlock([])

              if ind > 0 {
//                thisCommand = "<div class=hanging style=\"margin-left: \(ind/2)em; text-indent: -1.7em; margin-top: 0.5em; margin-bottom: 0.5em;\">" +
                thisCommand = "<div class=hanging  style=\"--hang: \(Double(ind)/2.0)em\">" + 
                k + " " +
                span("hanging", kk, lineNo) +
                "</div>"
              }
              
              // thisCommand = "<p style=\"margin-left: \(ind)em;\">\(k?.value ?? "")"
              
            case "nf":

              // FIXME: macroBlocks must be nested.  A macroBlock terminates when any of its enders hit -- or any of its parent macroBlocks enders hit
              var j = await macroBlock( (enders ?? []) +  ["fi", "SH"]) // in postfix, there is no trailing .fi  in SEE ALSO
              // FIXME: did I need this?
//              if j.hasSuffix("\n.") { j.removeLast(2) }

              if !j.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                thisCommand = "<div class=nf style=\"margin-top: 0.5em\";>\(j)</div>"
              }

            case "fi":
              let _ = await rest()

            case "SS":
              let j = await rest().value
              thisCommand = "<h5>" + span(nil, j, lineNo) + "</h5>"
              
            case "SM":
              let _ = await rest() // eat the line
              if !atEnd {
                let k = peekLine
                nextLine()
                
                let j = try await handleLine(k, enders: enders)
                let ln = lineNo
                thisCommand = "<span style=\"font-size: 80%;\" x-source=\(ln)>\(j)</span>"
              }
            
            case "TE":
              let _ = await rest()

            case "TS": // define table start
              let _ = await rest()
              thisCommand = await macroBlock( (enders ?? []) + ["TE"])
//              print(thisCommand)
            default:
              // FIXME: if the token is not recognized as a macro, then it must be regular text
             if macroList.contains(thisToken.value) {
                thisCommand = span("unimplemented", thisToken.value, lineNo)
              } else {
                thisCommand = span(nil, String(thisToken.value), lineNo)
                thisDelim = thisToken.closingDelimiter
              }
          }
        } else {
          if macroList.contains(thisToken.value) {
            thisCommand = span("unimplemented", thisToken.value, lineNo)
          } else {
                        thisCommand = span(nil, String(thisToken.value), lineNo)
//            thisCommand = span(nil, String(escaped(thisToken.value)), lineNo)
            thisDelim = thisToken.closingDelimiter
          }
        }
    }
    return Token(value: Substring(thisCommand), closingDelimiter: thisDelim, isMacro: false)
  }


// in fact, I should never throw the redirect
  func restMacro(enders: [String], _ f : @escaping (String) -> String) async throws(ThrowRedirect) -> String {
    var ended = true
    var thisCommand = ""
    var thisDelim = ""
    while let j = try await macro(enders: enders, flag: true) {
      if !j.isMacro {
        thisCommand.append(thisDelim)
        thisCommand.append(contentsOf: j.value)
        thisDelim = j.closingDelimiter
        continue
      } else {
        thisCommand = f(thisCommand)
        thisCommand.append(thisDelim)
        thisCommand.append(contentsOf: j.value)
        thisCommand.append(j.closingDelimiter)
        ended = false
        break
      }
    }

    if ended {
      thisCommand = f(thisCommand)
      thisCommand.append(thisDelim)
    }
    return thisCommand
  }

 }
