// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import WebKit

final class SchemeHandler : URLSchemeHandler, Sendable {

  @MainActor var state : AppState

  @MainActor init(_ s : AppState) {
    state = s
  }

  @MainActor static var fileData : [String : String] = [:]

  @MainActor func cache(_ f : String, _ d : String) {
    Self.fileData[f] = d
  }

  func reply(for request: URLRequest) -> some AsyncSequence<URLSchemeTaskResult, any Error> {
    let k = request.url!
    return AsyncThrowingStream { c in
      Task {
        let d = await htmlForMan(k)
        c.yield(.response(URLResponse(url: k, mimeType: "text/html", expectedContentLength: d.count, textEncodingName: "utf-8")))
        c.yield(.data(d))
        c.finish()
      }
    }
  }


    // FIXME: done this way, the forward/backward stuff doesn't work.
  // To make it work, I have to construct a global dictionary mapping filename to manual source
  // Then the url is  manMLx://?filename  -- which can look up the data
  @MainActor func htmlForMan(_ u : URL) async -> Data {
    if state.legacy {
      let (error, html) = Mandoc.getTheHTML(u, state.manpath)
        state.error = error
        return html.data(using: .utf8 ) ?? Data()
    } else {
      if u.path.isEmpty {
        state.manSource = SchemeHandler.fileData[u.query() ?? ""] ?? ""
        // FIXME: when I read the data, I can store the error as well as the contents
        state.error = ""
      } else {
        (state.error, state.manSource) = await Mandoc.readManFile(u, state.manpath)
      }
        var html : String = ""
        (state.error, html, state.manSource) = await Mandoc.newParse(state.manSource, state.manpath)
        return html.data(using: .utf8 ) ?? Data()
      }
  }


  func webView(_ : WKWebView, stop: any WKURLSchemeTask) {
  }

}
