// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import WebKit

@Observable final class AppState {
  var error : String = " "
  var legacy : Bool = false
  var manpath : Manpath = Manpath()
  var sourceLine : Int? = nil
  var lineSource : String = ""
  var manSource : String = ""
  var which : String = ""

  var handler : SchemeHandler!
  var page : WebPage!

  var history : [String] = []
  var historyIndex : Int = -1
  
  var canBack : Bool { historyIndex > 0 }
  var canNext : Bool { historyIndex < history.count - 1 }
  
  func back() {
    if canBack {
      historyIndex -= 1
      which = history[historyIndex]
    }
  }
  
  func next() {
    if canNext {
      historyIndex += 1
      which = history[historyIndex]
    }
  }

  func updateHistory() {
    if historyIndex == history.count - 1 {
      history.append(which)
      historyIndex = history.count - 1
    } else {
      history[historyIndex] = which
    }
  }

  @MainActor init() {
    doInTask()
  }

  @MainActor func doInTask() {
    //    ss = source
    let u = URLScheme(scheme)!
    handler = SchemeHandler(self)
    var config = WebPage.Configuration()
    config.urlSchemeHandlers[u] = handler
    config.defaultNavigationPreferences.allowsContentJavaScript = true

    let ucc = WKUserContentController()
    ucc.add( ClickBridge(
      { (kk: Int) in
        self.sourceLine = kk
      }), name: "mouseClickMessage")
    config.userContentController = ucc

    page = WebPage(configuration: config)
    page.isInspectable = true
  }

  @MainActor func doTheLoad(_ url : URL?) {
    if let url {
    page?.load(url)
      if let p = page {
        let events = p.navigations
        Task {
          for try await event in events {
            if event == .finished {
              try await p.callJavaScript(myJavascriptString)
            }
          }
        }
      } else {
        print("null URL")
      }
    }
  }

}
