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

  var mantext : String = ""

  var handler : SchemeHandler?
  var page : WebPage?

//  var externalURL : URL?
  
  var canBack : Bool = false
  var canNext : Bool = false

  @MainActor init() {
    doInTask()
  }

  @MainActor func doInTask() {

    guard let u = URLScheme(scheme) else {
        assertionFailure("Couldn't create URLScheme for mymanml")
        return
    }

    if let _ = handler { print("already registered"); return }
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
    page?.isInspectable = true

//    print("====> \(scheme) registered")
  }

  @MainActor func doTheLoad(_ url : URL?) {
    if let url {
    page?.load(url)
      if let p = page {
        self.mantext = urlToMantext(url)

        let events = p.navigations
        Task {
          for try await event in events {
            if event == .finished {
              try await p.callJavaScript(myJavascriptString)

              canBack = !p.backForwardList.backList.isEmpty
              canNext = !p.backForwardList.forwardList.isEmpty
            }
          }
        }
      } else {
        print("null URL")
      }
    }
  }

  let myJavascriptString = """
      document.addEventListener('click', function(event) {
        // Example of sending a message to Swift with click details

        console.log(event);

      // possibly use event.srcElement and look for a parent with an x-source attribute

        let efp = document.elementsFromPoint(event.clientX, event.clientY);

        console.log(efp);

        var jj = -1;

        for (var i = 0; i < efp.length; i++) {
      //    console.log(efp[i])
          if (efp[i].hasAttribute("x-source")) {
            jj = efp[i].attributes["x-source"].value
            break;
          }
        }
        if (jj == -1) { return; }
        window.webkit.messageHandlers.mouseClickMessage.postMessage('Source line: '+Number(jj) );
      }, {'passive':true, 'capture':true} );
      """

}
