// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import WebKit

final class SchemeHandler : URLSchemeHandler, Sendable {

  @MainActor var state : AppState

  @MainActor init(_ s : AppState) {
    state = s
  }





  func reply(for request: URLRequest) -> some AsyncSequence<URLSchemeTaskResult, any Error> {

    let k = request.url!

    //    ss.which = "\(k[2]) \(k[1])"

    return AsyncThrowingStream { c in
      // FIXME:  can I reload the data without counting on the Sourcerer?
      Task {
        let d = await htmlForMan(k)
        print( String(data: d, encoding: .utf8)! )
        c.yield(.response(URLResponse(url: k, mimeType: "text/html", expectedContentLength: d.count, textEncodingName: "utf-8")))
        c.yield(.data(d))
        c.finish()
      }
    }
  }


  @MainActor func htmlForMan(_ u : URL) async -> Data {
    if state.legacy {
      let (error, html) = Mandoc.getTheHTML(u, state.manpath)
        state.error = error
        return html.data(using: .utf8 ) ?? Data()
      } else {
        (state.error, state.manSource) = await Mandoc.readManFile(u, state.manpath)
        var html : String = ""
        (state.error, html, state.manSource) = await Mandoc.newParse(state.manSource, state.manpath)
        return html.data(using: .utf8 ) ?? Data()
      }
  }


  func webView(_ : WKWebView, stop: any WKURLSchemeTask) {
  }

}
