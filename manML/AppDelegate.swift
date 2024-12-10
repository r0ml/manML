// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import AppKit
import SwiftUI



class AppDelegate : NSObject, NSApplicationDelegate {
  var manpath : Manpath

  init(manpath: Manpath) {
    self.manpath = manpath
  }

  /*
  func application(_ app : NSApplication, open: [URL]) {
    //    print(open)
    Task {
      for k in open {
        if k.scheme == "mandoc" {
          let pp = mandocFind(k)
          if pp.count == 0 {
            print("not found")
/*          } else if pp.count > 1 {
            print("multiple found")
            let a = makeMenu(pp)
            a.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
 */
          } else if pp.count >= 1 {
            Opener(pp[0]).doOpen(nil)
          }
        } else {
          Opener(k).doOpen(nil)
        }
      }
    }
  }
 */

  @MainActor func makeMenu(_ s : [URL] ) -> NSMenu {
    let a = NSMenu(title: "Manual")
    openers = []
    let i = s.map { p in
      let mi = NSMenuItem()
      mi.title = p.path
      let o = Opener(p)
      openers.append(o)
      mi.target = o
      mi.action = #selector(Opener.doOpen(_:))
      return mi
    }
    a.items = i
    return a
  }
}

@MainActor var openers : [Opener] = []

class Opener : NSObject {
  var url : URL
  var fn : ((String) -> Void)?
  init(_ u : URL, _ fn : ((String)->Void)? = nil) {
    url = u
    self.fn = fn
    super.init()
  }

  @objc func doOpen(_ dk : Any?) {
    print(url.path)
    if FileManager.default.isSymbolicLink(atPath: url.path) {
      do {
        let qp = try FileManager.default.destinationOfSymbolicLink(atPath: url.path)
        print(qp)
        let base = url
        let bx = base.deletingLastPathComponent()
        url = URL(filePath: qp, relativeTo: bx)
      } catch(let e) {
        print("resolving symbolic link \(url.path): \(e.localizedDescription)")
      }
    }
    let lurl = url
    Task {
      do {
        try await NSDocumentController.shared.openDocument(withContentsOf: lurl, display: true )
      } catch(let e) {
        print("attempting to open document \(lurl.path): \(e.localizedDescription)")
      }
    }
  }
  
  @objc func doRead( _ dk : Any?) {
    do {
      let res = try String(contentsOf: url, encoding: .utf8)
      if let fn {
        fn(res)
      }
    } catch(let e) {
      print(e.localizedDescription)
    }
  }

}

