// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation

/** Class capturing the values required to create a reference to another publication */
class RsState {
  var author : [String] = [] // %A
  var book : String? // %B book title
  var location : String? // %C city
  var date : String? // %D publication date
  var issuer : String? // %I publisher
  var journal : String? // %J
  var issue : String? // %N issue number
  var optional : String? // %O optional info
  var page : String? // %P page number
  var institution : [String] = [] // %Q institutional author
  var report : String? // %R technical report name
  var article : String? // %T article title
  var uri : String? // %U URI of reference document
  var volume : String? // %Volume number

  func formatted(_ m : Mandoc) -> String {
    var output = ""
    let separator = ",&ensp;"
    for j in author {
      output.append(separator)
      output.append(m.span("author", j))
    }
    for j in institution {
      output.append(separator)
      output.append(m.span("author", j))
    }

    if let book {
      output.append(separator)
      output.append(m.span("title", book))
    }
    if let article {
      output.append(separator)
      output.append(m.span("title", article))
    }
    if let journal {
      output.append(separator)
      output.append(m.span("journal", journal))
    }
    if let report {
      output.append(separator)
      output.append(m.span("report", report))
    }
    if let issuer {
              output.append(separator)
      output.append(m.span("issuer", issuer))
    }
    if let location {
              output.append(separator)
      output.append(m.span("location", location))
    }

    if let volume {
              output.append(separator)
      output.append(m.span("volume", volume))
    }
    if let page {
              output.append(separator)
      output.append(m.span("page", page))
    }
    if let uri {
              output.append(separator)
      output.append("<a href=\"\(uri)\">\(uri)</a>")
    }
    if let date {
              output.append(separator)
      output.append(m.span("date", date))
    }

    if let optional {
              output.append(separator)
      output.append(" (\(optional))")
    }

    output = "<div class=\"bibliographic\">".appending(output.dropFirst(separator.count))
    output.append("</div>")
    return output
  }
}

class ParseState {
  // ============================

  var rsState : RsState?
  
  // ============================
  var inSynopsis = false

  var authorSplit = false
  
  var spacingMode = true
  
  // ============================
  var definedString = [String:String]()
  
  // ============================
  var ifNestingDepth = 0
  
}

