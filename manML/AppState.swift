// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import WebKit

final class ExternalLinkDecider: WebPage.NavigationDeciding {
    func decidePolicy(
        for action: WebPage.NavigationAction,
        preferences: inout WebPage.NavigationPreferences
    ) async -> WKNavigationActionPolicy {
        guard let url = action.request.url,
              let scheme = url.scheme?.lowercased()
        else { return .allow }

        if ["mailto", "tel", "sms"].contains(scheme) {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #else
            UIApplication.shared.open(url)
            #endif
            return .cancel        // stop WebView from trying to load it
        }
        return .allow
    }
}

final class SourceWrapper {
  var manSource : [Substring]

  init(_ x : [Substring] = []) {
    manSource = x
  }
}

@Observable public final class AppState : @unchecked Sendable {
  var error : String = " "
  var legacy : Bool = false
  var manpath : Manpath = Manpath()
  var sourceLine : Int? = nil
  var lineSource : String = ""
  var fileURL : URL? = nil

  @ObservationIgnored var manSource = SourceWrapper()

  var mantext : String = ""

  var handler : SchemeHandler?

  var page : WebPage?

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

    page = WebPage(configuration: config, navigationDecider: ExternalLinkDecider() )
    page?.isInspectable = true

    //    print("====> \(scheme) registered")
  }


  @MainActor func doTheLoad(_ item : WebPage.BackForwardList.Item) {
      page?.load(item)
      if let p = page {
        self.mantext = urlToMantext(item.initialURL)

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

  func loadManPage(_ p : URL) {

    if p.scheme == scheme {

      let manpath = self.manpath
      let j = p.pathComponents + ["",""]
      let manx = "\(j[2]) \(j[1])"
      let (pp, defered) = Mandoc.mandocFind( p, manpath)
      defer {
        for i in defered { i.stopAccessingSecurityScopedResource() }
      }
      self.error = ""
      if pp.count == 0 {
        self.error = "not found: \(manx)"
        self.manSource.manSource = []

        /*    } else if pp.count > 1 {
         error = "multiple found"
         let a = makeMenu(pp)
         a.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
         */
      } else if pp.count >= 1 {
        // FIXME: maybe retry other pp[n] hits if pp[0] fai
        loadManPageFromFile(pp[0])
      }
    } else if p.scheme == "file" {
      loadManPageFromFile(p)
    }
  }

  func loadManPageFromFile(_ p : URL) {
    do {
      let d = try Data(contentsOf: p)
      self.fileURL = p
      // FIXME: this is a kludge for old man files that use LATIN1 without saying so
      let dd = d.replacing([0xB1], with: [0xC2, 0xB1])
      let m = String(decoding: dd, as: UTF8.self)
      self.manSource.manSource = m.split(omittingEmptySubsequences: false,  whereSeparator: \.isNewline)
    } catch(let e) {
      self.error = e.localizedDescription
      self.manSource.manSource = []
      self.fileURL = nil
    }
  }
}
