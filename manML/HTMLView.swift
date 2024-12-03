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
            source = String(lines[ssx])
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
  var which : String = ""  {
    willSet {
      if historyIndex == history.count - 1 {
        history.append(newValue)
        historyIndex = history.count - 1
      } else {
        history[historyIndex] = newValue
      }
    }
  }
  
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


}

class SchemeHandler : NSObject, WKURLSchemeHandler {

  var ss : Sourcerer
  
  init(_ s : Sourcerer) {
    ss = s
  }
  
  func webView(_ : WKWebView, start: any WKURLSchemeTask) {
    let k = start.request.url!.pathComponents
    
    ss.which = "\(k[2]) \(k[1])"
    /*
    Task { @MainActor in
      let url = URL(string: "mandoc:///\(k[2])/\(k[1])")!
      NSWorkspace.shared.open( url )
    }
    */
    
    start.didReceive(URLResponse())
    start.didFinish()
  }

  func webView(_ : WKWebView, stop: any WKURLSchemeTask) {
  }

}


final class Handler : NSObject, WKScriptMessageHandler, WKNavigationDelegate {
  var wv : HTMLView!
  var ss : Sourcerer
  
  init(_ s : Sourcerer) { // _ wv : HTMLView) {
    ss = s
    super.init()
//    self.wv = wv
  }


/*  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
     decisionHandler(.allow)
  }
*/

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    webView.evaluateJavaScript("""
document.addEventListener('click', function(event) {
  // Example of sending a message to Swift with click details
  console.log(event);
//  window.webkit.messageHandlers.mouseClickMessage.postMessage('Mouse clicked at X: ' + event.clientX + ' Y: ' + event.clientY);

//  let htmlx = document.documentElement.innerHTML;
  let efp = document.elementFromPoint(event.clientX, event.clientY);
  let jj = efp.attributes["x-source"].value
//  let index = htmlx.indexOf(efp.innerHTML);
  window.webkit.messageHandlers.mouseClickMessage.postMessage('Source line: '+Number(jj) );

  let range;
  let textNode;
  let offset;

  let sel = window.getSelection();
  offset = sel.focusOffset;
  let xx = htmlx.indexOf(sel.focusNode.parentElement.innerHTML);
  window.webkit.messageHandlers.mouseClickMessage.postMessage('Selection Offset: '+offset+' '+sel.baseOffset+' '+sel.anchorOffset+' '+sel.extentOffset+' '+xx); 

}, {'passive':true, 'capture':true} );
""")

  }

  func userContentController(_ c : WKUserContentController, didReceive message: WKScriptMessage) {
    if message.name == "mouseClickMessage" {
      if let messageBody = message.body as? String {
        if messageBody.hasPrefix("Source line: ") {
          let mm = messageBody.dropFirst("Source line: ".count)
          let kk = Int(mm)!
          ss.sourceLine = kk
        }
//        print("Mouse clicked with message: \(messageBody)")
//        wv.getPos()
      }
    }
  }

}

struct HTMLView: NSViewRepresentable {
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
