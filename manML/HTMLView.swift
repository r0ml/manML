// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import SwiftUI
import WebKit
import Observation

final class ClickBridge : NSObject, WKScriptMessageHandler {
  var fn : ((Int) -> Void)
  init(_ f : @escaping ((Int) -> Void)) {
    self.fn = f
  }
  func userContentController(_ c : WKUserContentController, didReceive message: WKScriptMessage) {
      if let messageBody = message.body as? String {
        if messageBody.hasPrefix("Source line: ") {
          let mm = messageBody.dropFirst("Source line: ".count)
          let kk = Int(mm) ?? 0
          fn(kk)
        }
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

struct HTMLView : View {
  @Environment(AppState.self) var state
  @Environment(\.findContext) private var findContext   // gives findNext/Previous

  @State var finding : Bool = false

  var body : some View {
    if let page = state.page {
      WebView(page)
        .findNavigator(isPresented: $finding)
        .toolbar {
          ToolbarItem {
            Button("Find", systemImage: "magnifyingglass") {
              finding.toggle()
            }
            .keyboardShortcut(KeyEquivalent("f"), modifiers: [.command])
          }

          ToolbarItem {
            Button("Find Next") {
              let item = NSMenuItem()
              item.tag = NSTextFinder.Action.nextMatch.rawValue
              NSApp.sendAction(#selector(NSResponder.performTextFinderAction(_:)),
                               to: nil, from: item)
            }.keyboardShortcut(KeyEquivalent("g"), modifiers: [.command])
              .toolbarItemHidden()
          }.hidden()
        }
    } else {
      EmptyView()
    }
  }
}
