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

  func nextArg(enders: [String]) async -> Token? {
    return await Tokenizer.shared.nextArg(enders: enders)
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
              enders: [String], flag: Bool = false) async -> Token? {

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
        let k = await parseLine(enders: enders, flag: true)
        thisCommand = span("author", k , lineNo)

      case "Ao": // enclose in angle bracketrs
        thisCommand = "<"
        thisDelim = "&thinsp;"

      case "Ap": // apostrophe
        thisCommand = "'"

      case "Aq": // enclose rest of line in angle brackets
        if let j = await macro(bs, enders: enders) {
          thisCommand.append(span(nil, "&lt;\(j.value)&gt;", lineNo))
          thisDelim = j.closingDelimiter
        }

      case "Ar": // command arguments
        if let jj = await nextArg(enders: enders) {
          thisCommand.append(span("argument", jj.value, lineNo))
          thisDelim = jj.closingDelimiter
          while await peekToken()?.value != "|",
                let kk = await nextArg(enders: enders) {
            thisCommand.append(thisDelim)
            //             thisCommand.append(span("argument", kk.value, lineNo))
            if !kk.value.isEmpty { thisCommand.append(span("argument", kk.value, lineNo)) }
            thisDelim = kk.closingDelimiter
          }
          //  thisDelim = ""
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
        let (tc, palm) = await blockBlock()
        if palm == "Ed" {
          nextLine()
        }
        thisCommand = tc
        thisCommand.append("</blockquote>")

      case "Bf": // begin a font block
        if let j = await next() {
          let (k, _) = await macroBlock( enders + ["Ef"])
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
        let (j, _) = await macroBlock( enders + ["Ek"])
        thisCommand = j

      case "Bl": // begin list.
                 // FIXME: not all list types are supported yet
        let (tc, palm) = await listBlock()
        if palm == "El" {
          nextLine()
        }
        thisCommand = tc

      case "Bo": // begin square bracket block.
        let (j, _) = await macroBlock( enders + ["Bc"])
        thisCommand = span(nil, "[" + j + "]", lineNo)

      case "Bq": // enclose in square brackets.
        if let j = await macro(enders: enders) {
          thisCommand = span(nil, "["+j.value+"]", lineNo)
          thisDelim = j.closingDelimiter
        }

      case "Brc": // end Bro
        thisCommand = ""
        thisDelim = "}"

      case "Bro": // curly brace block
        while let j = await macro(enders: ["Brc"]) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }

        thisCommand = "{"+thisCommand

      case "Brq": // curly brace
        if let j = await macro(enders: enders) {
          thisCommand = span(nil, "{"+j.value+"}", lineNo)
          thisDelim = j.closingDelimiter
        }

      case "Bsx": // BSD version
        if let j = await nextArg(enders: enders) {
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
        while let j = await macro(enders: enders, flag: true) {
          if !j.value.isEmpty {
            thisCommand.append(thisDelim + span("command", j.value, lineNo) )
          }
          thisDelim = j.closingDelimiter
          if thisDelim == " " {
            break
          }
        }

      case "Db": // obsolete and ignored
        let _ = await rest()

      case "Dc": // close a "Do" block
        thisCommand = span(nil, "&rdquo;", lineNo)
        thisDelim = thisToken.closingDelimiter

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
        let j = await parseLine(enders: enders, flag: true)
        thisCommand = "<blockquote>"+span("", j, lineNo )+"</blockquote>"
        thisDelim = "\n"
        //        }

      case "Do": // enclose block in quotes
        thisCommand = span(nil, "&ldquo;", lineNo)
        thisDelim = thisToken.closingDelimiter
        //        let (j, _) = await macroBlock( enders + ["Dc"])
        //        thisCommand = span(nil, "<q>"+j+"</q>", lineNo)

      case "Dq": // enclosed in quotes
        if let q = await peekToken() {
          var j : Token?
          if q.isMacro {
            j = await macro(enders: enders)
          } else {
            j = await next()
          }
          if let j {
            thisCommand = "<q>\(j.value)</q>"
            thisDelim = j.closingDelimiter
          }
        }

      case "Dt": // document title
        title = String(await rest().value)
        let tt = title!.split(separator: " ")
        let ttt = tt + ["", ""]
        let (name, section) = (ttt[0], ttt.count > 1 ? ttt[1] : "")

        thisCommand = pageHeader(name, section, sections[String(section)] ?? "Unknown")


      case "Dv": // defined variable
        if let j = await nextArg(enders: enders) {
          thisCommand = span("defined-variable", j.value, lineNo)
          thisDelim = j.closingDelimiter
        }

      case "Dx": // dragonfly version
        thisCommand = span("unimplemented", "Dx", lineNo)

        // =======================================================

      case "Ed":
        // I should never get here -- because it gets handled in Bd
        thisCommand = "</blockquote>"

      case "Ef":
        let _ = await rest()

      case "Ek":
        let _ = await rest()

      case "El":
        thisCommand = ""
        thisDelim = ""

      case "Em":
        thisCommand = await restMacro(enders: enders) { self.span("bold italic", $0, self.lineNo) }

        /*
         if let j = await macro(flag: true) {
         //       let j = await rest()
         thisCommand = "<em>\(j.value)</em>"
         thisDelim = j.closingDelimiter
         },
         */

      case "Eo":
        let j = await macroBlock(["Ec"])
        thisCommand = span("enc", j.0, lineNo)

      case "Ec":
        break


      case "Er":
        if let j = await macro(enders: enders) {
          thisCommand = span("error", j.value, lineNo)
          thisDelim = j.closingDelimiter
        }
      case "Ev":
        while let j = await nextArg(enders: enders) {
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
        if let j = await nextArg(enders: enders + [ "Fa", "Fc" ]) {
          await thisCommand.append(span("function-arg", Tokenizer.shared.escaped(j.value), lineNo))
          thisDelim = bs?.functionDef == true ? faDelim : j.closingDelimiter
        }
      case "Fc":
        let j = await next()
//        thisCommand = "<br/>"
        if inSynopsis {
          thisDelim = (j?.closingDelimiter ?? "") + "<br/>"
        }
      case "Fd":
        let j = await rest()
        thisCommand = await span("directive", Tokenizer.shared.escaped(j.value), lineNo) + "<br/>"
        thisDelim = j.closingDelimiter

      case "Fl":
        // This was upended by "ctags" and "ssh"
        repeat {
          if let j = await macro(enders: enders, flag: true) {
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
          if inSynopsis {
            thisCommand.append("<br/>")
          } else {
            thisCommand.append(jj?.closingDelimiter ?? "")
          }
        }
      case "Fo":
        let j = await rest()
        thisCommand = span("function-name", j.value, lineNo) + "&thinsp;("
        let bs = BlockState()
        bs.functionDef = true
        let (k, _) = await macroBlock( enders + ["Fc"], bs)
        thisCommand.append(contentsOf: k.dropLast(faDelim.count) )
        thisCommand.append(");")

      case "Ft":
        let j = await rest()
        thisCommand = // "<br/>" +
        span("function-type", j.value, lineNo)
        if inSynopsis {
          thisDelim = "<br/>"
        } else {
          thisDelim = j.closingDelimiter
        }

      case "Fx":
        if let j = await next() {
          thisCommand = span("os", "FreeBSD \(j.value)", lineNo)
          thisDelim = j.closingDelimiter
        }
      case "Ic":
        if let j = await macro(enders: enders) {
          thisCommand = span("command", j.value, lineNo)
          thisDelim = j.closingDelimiter
        }
      case "In": // include
        let j = await rest()
        if inSynopsis {
          thisCommand = "<div>"+span("include", "#include &lt;\(j.value)&gt;", lineNo) + "</div>"
        } else {
          thisCommand = span("include", "&lt;\(j.value)&gt;", lineNo)
        }
        thisDelim = j.closingDelimiter

      case "It":
        let currentTag = await parseLine(bs, enders: enders, flag: true)
        let (currentDescription, _) = await macroBlock( enders + ["It", "El", "Ed"], bs)

        switch bs?.bl {
          case .diag:
            thisCommand = #"<div class="list-item">"# + span("diag", currentTag + "&nbsp;", lineNo)
            thisCommand.append(#"<div class="tag-description">"# + currentDescription + "</div>")
            thisCommand.append(#"</div><div style="clear: both;"></div>"#)

          case .tag:
            thisCommand = taggedParagraph(currentTag, currentDescription, lineNo) // "</div></div>"
          case .item, ._enum, .bullet, .dash:
            thisCommand = "<li>" + currentDescription + "</li>"
          case .hang:
            thisCommand = "<div style=\"margin-top: var(--compact);\">\(currentTag) \(currentDescription)</div>"
          case .table:
            thisCommand = "<tr><td>\(currentTag) \(currentDescription)</td></tr>"
          case .inset:
            thisCommand = "<div style=\"margin-top: 0.8em;\">\(currentTag) \(currentDescription)</div>"

          case .filled:    fallthrough
          case .unfilled:  fallthrough
          case .centered:  fallthrough
          case .ragged:    fallthrough
          case .literal:
            thisCommand = taggedBlock(currentTag, currentDescription, lineNo) // "</div></div>"
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
        if let j = await nextArg(enders: enders) {
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

        if inSynopsis && bs?.bl == nil {
          thisCommand.append("<br>")
        }

        // FIXME: I would like (in SYNOPSIS) to take each macroBlock of .Nm and put it in a hanging indent
        // but figuring out where the hanging lines are is tricky
        var arg : String
        if let k = await peekToken(), !k.isMacro {
          if name == nil { name = String(k.value) }
          arg = String(k.value)
          thisDelim = k.closingDelimiter
          let _ = await next()
        } else {
          arg = name ?? "??"
          thisDelim = " "
        }
        thisCommand.append(span("utility", arg, lineNo))

      case "Ns":
        return await macro(bs, enders: enders)

      case "Nx":
        if let j = await macro(enders: enders) {
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
        while let j = await macro(enders: ["Oc"]) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }

        thisCommand = "[" + thisCommand

      case "Op":
        // in "apply", the .Ns macro is applied here, but "cd" is already " "
        // is the fix to have tknz maintain a previousClosingDelimiter?
        while let j = await macro(enders: enders) {
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
        while let j = await nextArg(enders: enders) {
          thisCommand.append(thisDelim)
          thisCommand.append( span("path", j.value, lineNo))
          thisDelim = j.closingDelimiter
        }
      case "Pc":
        thisCommand = ")"
        thisDelim = thisToken.closingDelimiter

      case "Pf":
        if let j = await next() {
          thisCommand.append(contentsOf: j.value)
        }

      case "Po":
        thisCommand = "("
        thisDelim = thisToken.closingDelimiter

      case "Lp", "Pp":
        thisCommand = "<p/>"
      case "Pq":
        thisCommand = await restMacro(enders: enders) { self.span("pq", $0, self.lineNo) } // wrap in parens
        /*
         //        if let j = await macro() {
         let j = await rest()
         thisCommand = "(\(j.value))"
         thisDelim = j.closingDelimiter
         //        }
         */

      case "Ql":
        if let j = await macro(enders: enders) {
          thisCommand.append(thisDelim)
          thisCommand.append( span("literal", j.value, lineNo) )
          thisDelim = j.closingDelimiter
        }

        // Note: technically this should use normal quotes, not typographic quotes
      case "Qq":
        thisCommand = await "<q>\(parseLine(enders: enders, flag: true))</q>"

      case "Qc":
        let _ = await rest()

      case "Qo":
        thisCommand = await restMacro(enders: ["Qc"]) { j in
          "<q>\(j)</q>"
        }

      case "Re":
        if let re = rsState {
          thisCommand = re.formatted(self, lineNo)
        }
      case "Rs":
        rsState = RsState()

      case "Rv":
        let j = await next()
        let k = await next()
        let _ = await rest()
        if j?.value == "-std" {
          let fn = k == nil ? "" : span("function-name", k!.value + "()", lineNo)
          thisCommand = span(nil, "The \(fn) function returns the value 0 if successful; otherwise the value -1 is returned and the global variable " + span("defined-variable", "errno", lineNo) + " is set to indicate the error.", lineNo)
        } else {
          thisCommand = span(nil, span("unimplemented","-->Rv<--", lineNo) + (j?.value ?? ""), lineNo)
        }
        thisDelim = j?.closingDelimiter ?? ""

      case "Sh", "SH": // can be used to end a tagged paragraph
                       // FIXME: need to handle tagged paragraph

        let j = await rest()
        thisCommand = "<a id=\"\(j.value)\"><h4>" + span(nil, j.value, lineNo) + "</h4></a>"
        inSynopsis = j.value == "SYNOPSIS"
        /*        if inSynopsis {
         let (j, _) = await macroBlock( enders + ["Sh", "SH"])
         thisCommand.append("<div class=synopsis>\(j)</div>")
         }
         */

      case "Sm": // spacing mode
        let j = await rest().value
        await Tokenizer.shared.setSpacingMode ( j.lowercased() != "off" )

      case "Sc":
        if enders.last != "Sc" {
          await Tokenizer.shared.pushToken( thisToken )
        }
        return nil

      case "So":
        while let j = await macro(enders: ["Sc"]) {
          thisCommand.append(thisDelim)
          thisCommand.append(contentsOf: j.value)
          thisDelim = j.closingDelimiter
        }
        thisCommand = "<q class=\"single\">\(thisCommand)</q>"

      case "Sq":
        while let sq = await macro(enders: enders) {
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
        while let j = await macro(enders: enders) {
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
        let j = await parseLine(enders: enders, flag: true)
        thisCommand = span("small-caps", j, lineNo)
      case "Ux":
        thisCommand = span("os", "UNIX", lineNo)

      case "Va":
        let j = await parseLine(enders: enders, flag: true) // rest()
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
        let j = await macro(bs, enders: [])
        thisCommand = String(j?.value ?? "")
        let (k, _) = await macroBlock( enders + ["Xc"])
        thisCommand.append(k)
        thisDelim = "\n"

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
            case "UC": // Obsolete -- equivalent to .Os -- kept for compatibility
              let j = await rest()
              os = "BSD " + j.value

            case "br":
              thisCommand = "<br/>"
              let _ = await rest()

            case "sp":
              let _ = await rest()
              thisCommand = "<p/>"


            case "tm":
              let m = await Tokenizer.shared.rawRest()
              var se = FileHandle.standardError
              print(m, to: &se)

            case "TP":
              // FIXME: get the indentation from the argument
              //        let ind = next()?.value ?? "10"

              if atEnd {
                break
              }

              var currentTag = ""
              while currentTag.isEmpty {
                let line = peekLine
                nextLine()
                currentTag = await handleLine(line, enders: enders)
              }

              let (k, nn) = await macroBlock( enders + ["TP", "PP", "SH", "SS", "HP", "LP"] ) // "TP", "PP", "SH"])
                                                                                              //              print(nn)
              thisCommand = span("", taggedBlock(currentTag, k, lineNo), lineNo)
              if nn != "TP" {
                thisCommand.append("<div style=\"clear: both;\"></div>")
              }
            case "P", "PP", "LP":
              thisCommand = "<p/>"

            case "RS":
              let tw = await next()?.value ?? "10"
              let _ = await rest() // eat the rest of the line

              let tx = Int(tw) ?? 10

              relativeStart.append(tx)
//              thisCommand = "<div style=\"padding-left: 2em; margin-top: 0.3em; --tag-width: \(tw)em\">"

            case "RE":
              let _ = await rest() // already handled in RS

              if !relativeStart.isEmpty { relativeStart.removeLast() }
//              thisCommand = "</div>"

            case "B":
              thisCommand = span("bold", await rest().value, lineNo)

            case "I":
              thisCommand = span("italic", await rest().value, lineNo)


            case "ft": // set font
              let f = await next()?.value ?? "R"
              let _ = await rest()
              let (j, _) = await macroBlock( enders + ["ft", "nf"])
              switch f {
                case "R", "1":
                  thisCommand = span("", j, lineNo) // no font
                case "I", "2":
                  thisCommand = span("italic", j, lineNo)
                case "B", "3":
                  thisCommand = span("bold", j, lineNo)
                case "4":
                  thisCommand = span("bold italic", j, lineNo)
                case "C", "CW":
                  thisCommand = span("pre", j, lineNo)
                case "P":
                  thisCommand = span("", j, lineNo)
                default:
                  thisCommand = span("", j, lineNo)
              }

            case "fam": // set font family -- but I'm gong to ignore for now
              let _ = await rest()

            case "BI":
              await fontAlternate(&thisCommand, "bold", "italic")

            case "DT":   // reset tab stops -- just a noop
              let _ = await rest()

            case "IB":
              await fontAlternate(&thisCommand, "italic", "bold")

            case "BR":
              await fontAlternate(&thisCommand, "bold", "regular")

            case "IR":
              await fontAlternate(&thisCommand, "italic", "regular")

            case "RI": // alternating roman / italic -- seems to handle white spaces and ignore delimiters
              await fontAlternate(&thisCommand, "regular", "italic")

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

              let (kk, _) = await macroBlock( enders + ["PP", "IP", "TP", "SS", "HP", "LP"])

              let width = "3em"
              thisCommand = "<div class=hang style=\"text-indent: -\(width); padding-left: \(width);>"+span("", kk, lineNo)+"</div>"

            case "na": // no alignment -- disables justification until .ad
              let (j, _) = await macroBlock( enders + ["ad", "SH"]) // in postfix, there is no trailing .fi  in SEE ALSO
                                                                    // FIXME: did I need this?
              //              if j.hasSuffix("\n.") { j.removeLast(2) }

              if !j.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                thisCommand = "<div class=na>\(j)</div>"
              }
              break // not implemented

            case "ad": // left/right justify
              let _ = await rest()
              break // not implemented

             case "ll":
              let _ = await rest()
              // FIXME: this changes the line length (roff)
              // for now, I will ignore this macro

            case "PD": // Psragraph distance.  Not implemented
              let _ = await next()

            case "IX": // ignore -- POD uses it to create an index entry
              let _ = await rest()

            case "rm": // remove macro definition -- ignored for now
              let _ = await rest()

            case "ne": // need this much space left on the page.  For an HTML page, just ignore it.
              let _ = await rest()

            case "in":
              let inx = await rest()
              //              print(inx)
              break

              // FIXME: this mucks up dyld_usage;   Should I have a state variable holding the current desired indent level and apply it to divs?
              let (j, _) = await macroBlock(enders+["in"])
              var iny = "0"
              if inx.value.first == "+" {
                iny = (inx.value.dropFirst()+"en")
                thisCommand = "<div style=\"margin-left: \(iny)\">\(j)</div>"
              } else {
                thisCommand = j
              }
            case "mk": // groff mark position -- but mandoc ignores
              let _ = await rest()

            case "ev": // set an "environment" for font/indentation/formatting
              let _ = await rest() // ignored by mandoc

            case "ta":  // sets tab stops.  For now, just ignore it.
              let _ = await rest()

            case "ti":
              // This wants to indent for a single line -- but there is not a good way to detect when "a single line" ends.
              let inx = await rest()
              var iny = "0"
              if inx.value.first == "+" { iny = (inx.value + "ch") }
              else if inx.value.first == "-" { iny = inx.value + "ch" }

              // FIXME: may be many more "enders" here
              let (z, m) = await macroBlock(enders + ["ti", "in", "ad", "br"])
              if m == "br" {
                nextLine()
              }
              thisCommand = "<div style=\"margin-left: \(iny)\">\(z)</div>"

              // FIXME: this was the old way -- didn't handle use case in tcpdump
              /*              let jx = lines.removeFirst()
               let j = await handleLine(jx, enders: enders)
               thisCommand = "<div style=\"margin-left: \(iny)\">\(j)</div>"
               */

            case "tr": // replace characters -- ignored for now
              let _ = await rest()

            case "IP":
              let kkk = await next()
              let kj = kkk?.value ?? ""
              let k = kj.isEmpty ? "" : span("tag", kj, lineNo)
              var ind : Double = 3
              if let dd = await next() {
                // FIXME: somehow I'm seeing a \n here
                let dx = dd.value.trimmingCharacters(in: .whitespacesAndNewlines)
                if let i = Int(dx) { ind = Double(i)/16.0 }
              }

              let _ = await rest()

              let (kk, _) = await macroBlock(enders + ["IP", "LP", "PP", "HP", "TP", "SH", "Sh", "SS", "ie", "el", "if"])

              if ind > 0 && !k.isEmpty {
/*
                thisCommand = "<div class=hanging style=\"margin-left: \(ind)em; --hang: \(ind)em\">" +
                k + " " +
                span("hanging", kk, lineNo) +
                "</div>"
 */

                thisCommand = "<div style=\"margin-top: 0.4em; margin-bottom: 0.4em;\">" + taggedParagraph(k, kk, lineNo) + "</div>"
              } else {
                thisCommand = "<div style=\"margin-left: \(ind)ch; margin-top: 0.5em;\">" + kk + "</div>"
              }


              // thisCommand = "<p style=\"margin-left: \(ind)em;\">\(k?.value ?? "")"

            case "EE":
              let _ = await rest()
            case "EX":
              let _ = await rest()
              let j = await macroBlock(enders + ["EE"])

              thisCommand = "div class=nf style = \"margin-top: 0.5em\">\(j.0)</div>"

            case "ns": // suppress vertical space -- ignored for now
              let _ = await rest()

            case "nf":

              // FIXME: macroBlocks must be nested.  A macroBlock terminates when any of its enders hit -- or any of its parent macroBlocks enders hit
              let (j, _) = await macroBlock( enders +  ["fi", "Sh", "SH"]) // in postfix, there is no trailing .fi  in SEE ALSO
                                                                           // FIXME: did I need this?
              //              if j.hasSuffix("\n.") { j.removeLast(2) }

              let jj = j.replacing(/\n?<br\/?>\n?/, with: "<p style=\"margin-block-start: 0.2em; margin-block-end: 0.2  em;\"/>")

              if !j.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                thisCommand = "<div class=nf style=\"margin-top: 0.6em; margin-bottom: 0.6em;\">\(jj)</div>"
              }

            case "fi":
              let _ = await rest()

            case "BS", "BE": // Ignore -- wrap the SYNOPSIS section?
              let _ = await rest()

            case "SS":
              let j = await rest().value
              thisCommand = "<h5>" + span(nil, j, lineNo) + "</h5>"

            case "SM":
              let _ = await rest() // eat the line
              if !atEnd {
                let k = peekLine
                nextLine()

                let j = await handleLine(k, enders: enders)
                let ln = lineNo
                thisCommand = "<span style=\"font-size: 80%;\" x-source=\(ln)>\(j)</span>"
              }

            case "TE":
              let _ = await rest()

            case "TS": // define table start
              let _ = await rest()

              thisCommand = await tblBlock()

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

    // FIXME: At this point I can't back out the unsafe string -- this kind of token is a higher level than the Tokenizer token
    // should I have two kinds of tokens?
    return Token(value: Substring(thisCommand), unsafeValue: Substring(thisCommand), closingDelimiter: thisDelim, isMacro: false)
  }

  func fontAlternate(_ thisCommand : inout String, _ f1 : String, _ f2: String) async {
    var toggle = true
    // FIXME: alternating fonts don't respect "closing delimiters"
    while let j = await next() {
      thisCommand.append( span(toggle ? f1 : f2, j.value, lineNo) )
      toggle.toggle()
      if (j.closingDelimiter.contains { !$0.isWhitespace }) {
        thisCommand.append( span( toggle ? f1 : f2, j.closingDelimiter, lineNo))
        toggle.toggle()
      }
    }
  }

  // in fact, I should never throw the redirect
  func restMacro(enders: [String], _ f : @escaping (String) -> String) async -> String {
    var ended = true
    var thisCommand = ""
    var thisDelim = ""
    while let j = await macro(enders: enders, flag: true) {
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
