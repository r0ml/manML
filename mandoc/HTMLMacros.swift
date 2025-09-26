//
// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024
    

import Foundation

extension Mandoc {
  func taggedParagraph(_ tag : String, _ description : any StringProtocol, _ lno : Int) -> String {
    var m = #"<div class="list-item">"# + span("tag", tag + "&nbsp;", lno)
    m.append(#"<div class="tag-description">"# + description + "</div>")
    m.append(#"</div><div style="clear: both;"></div>"#)
    return m
  }

  func taggedBlock(_ tag : String, _ description : any StringProtocol, _ lno : Int, _ indx : (any StringProtocol)?) -> String {
    var ind : String
    if let indx {
      ind = String(indx)
    } else {
      ind = tagOffset
    }
    var m = "<div style=\"--tag-width:\(ind);\" class=\"list-item\">"

    m += span("tag", tag + "&nbsp;", lno)
    m.append(#"<div class="tag-description">"# + description + "</div>")
    m.append(#"</div>"#)
    return m
  }

  func pageHeader(_ name : any StringProtocol , _ section : any StringProtocol, _ title : any StringProtocol) -> String {
    let mm = "\(String(name))(\(section))"
    var tit : String
    if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      tit = "Unknown"
    } else {
      tit = String(title)
    }
    /*
    return """
<div style="margin-left: -40px">
<div style="float: left">\(mm)</div>
<div style="float: right">\(mm)</div>
<div style="margin: 0 auto; width: 100%; text-align: center;">\(tit)</div>
</div>
"""
*/

    return """
<table style="width: calc(100% + 40px); margin-left: -40px; margin-right: 0;">
<tr>
<td>\(mm)</td>
<td style="text-align: center;">\(tit)</td>
<td style="text-align: right">\(mm)</td>
</tr>
</table>
"""
  }
  
  func span(_ c : String?, _ s : any StringProtocol, _ lno : Int) -> String {
    if s.isEmpty {
      return ""
    }
    if let c {
      return "<span class=\"\(c)\" x-source=\(lno)>\(s)</span>"
    } else {
      return "<span x-source=\(lno)>\(s)</span>"
    }
  }
}
