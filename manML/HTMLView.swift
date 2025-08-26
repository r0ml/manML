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
