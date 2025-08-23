// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import SwiftUI
import WebKit

struct SourceView : View {
  @State var source : String = ""
  var ss : Sourcerer
  
  var body : some View {
    HStack {
      Text(source)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.05))
        .onChange(of: ss.sourceLine) {
          if var ssx = ss.sourceLine {
            let lines = ss.manSource.split(omittingEmptySubsequences: false,  whereSeparator: \.isNewline)
            if ssx >= lines.count { ss.sourceLine = lines.count - 1; ssx = lines.count - 1 }
            if ssx >= 0 && ssx < lines.count {
              source = String(lines[ssx])
            }
          }
        }
      Spacer()
      Button("⋀") {
        if let s = ss.sourceLine,
           s > 0 {
          ss.sourceLine = s-1
        }
      }
      Button("⋁") {
        if let s = ss.sourceLine {
          ss.sourceLine = s+1
        }
      }
    }
  }
  
}

@Observable class Sourcerer {
  var sourceLine : Int? = nil
  var lineSource : String = ""
  var manSource : String = ""
  var which : String = ""
  
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

}

class SchemeHandler : URLSchemeHandler {

  var ss : Sourcerer
  
  init(_ s : Sourcerer) {
    ss = s
  }

  func reply(for request: URLRequest) -> some AsyncSequence<URLSchemeTaskResult, any Error> {

    let k = request.url!.pathComponents

    ss.which = "\(k[2]) \(k[1])"

    return AsyncThrowingStream { c in
      /*
       Task { @MainActor in
       let url = URL(string: "mandoc:///\(k[2])/\(k[1])")!
       NSWorkspace.shared.open( url )
       }
       */
/*
      start.didReceive(URLResponse())
      start.didFinish()
 */

      // FIXME:  can I reload the data without counting on the Sourcerer?
      c.yield(.response(URLResponse(url: request.url!, mimeType: "text/html", expectedContentLength: 0, textEncodingName: "utf8")))
//      c.yield(.data())
      c.finish()

    }
  }

  func webView(_ : WKWebView, stop: any WKURLSchemeTask) {
  }

}



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

//          ss.sourceLine = kk
        }
//        print("Mouse clicked with message: \(messageBody)")
//        wv.getPos()
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
  var string : String
  var ss : Sourcerer
  var page : WebPage
  var handler : SchemeHandler
  @Environment(\.findContext) private var findContext   // gives findNext/Previous

  @State var finding : Bool = false

  init(_ s : String, source : Sourcerer) {
    string = s
    ss = source
    let u = URLScheme("manML")!
    handler = SchemeHandler(source)
    var config = WebPage.Configuration()
    config.urlSchemeHandlers[u] = handler
    config.defaultNavigationPreferences.allowsContentJavaScript = true

    let ucc = WKUserContentController()
    ucc.add( ClickBridge(
      { (kk: Int) in
      source.sourceLine = kk
    }), name: "mouseClickMessage")
    config.userContentController = ucc

    page = WebPage(configuration: config)
    page.isInspectable = true
    page.load(html: s)
    let events = page.navigations
    let p = page
    Task {
      for try await event in events {
        if event == .finished {
          try await p.callJavaScript(myJavascriptString)
        }
      }
    }
  }

  var body : some View {

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
  }
}

/*
struct HTMLViewOld: NSViewRepresentable {
  var string: String
  var schemeHandler : SchemeHandler
  var ss : Sourcerer
  
  let wv : WKWebView
  let controller = WKUserContentController()

  let handler : Handler

  init(_ s: String, source: Sourcerer) {
    string = s
    ss = source
    
    schemeHandler = SchemeHandler(ss)
    handler = Handler(ss)
    controller.add(handler, name: "mouseClickMessage")

    let wkConfiguration = WKWebViewConfiguration()
    wkConfiguration.setURLSchemeHandler(schemeHandler, forURLScheme: "mandocx")
    wkConfiguration.userContentController = controller

    wv = WKWebView(frame: .zero, configuration: wkConfiguration)
    wv.navigationDelegate = handler
    wv.isInspectable = true
    handler.wv = self
  }


  func makeNSView(context: Context) -> WKWebView {
//    wkwebView.loadHTMLString(string, baseURL: nil)
    return wv
  }

  func updateNSView(_ nsView: WKWebView, context: Context) {
    nsView.loadHTMLString(string, baseURL: nil)
  }


  func textWidth(_ s : String) async {
    let k = try! await wv.evaluateJavaScript("""
    document.createElement("canvas").getContext("2d").measureText(\(s)).width
    """)
    print(k)
  }
/*
  func getPos() {
    wv.evaluateJavaScript("""
                          {
                          const htmlx = document.documentElement.outerHTML;
                          document.elementFromPoint(event.clientX, event.clientY);
                          const elementHtml = window.elementUnderCursor.outerHTML;
                          const index = htmlx.indexOf(elementHtml);
                          index;
                          }
                          """) { (result, error) in
        if let index = result as? Int {
            print("Index of element: \(index)")
        }
    }
  }
*/

}
*/
