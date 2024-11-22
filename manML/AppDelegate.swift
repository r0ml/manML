// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import AppKit
import SwiftUI



class AppDelegate : NSObject, NSApplicationDelegate {

  func mandocFind(_ k : URL) async -> [URL] {
    if k.scheme == "mandoc" {
      let j = k.pathComponents
      if j.count < 2 { return [] }
      let j1 = j[1]
      var j2 = j.count > 2 ? j[2] : nil
      if j2?.isEmpty == true { j2 = nil }
      let pp = await Manpath().find(j1, j2)
      return pp
    } else {
      return [k]
    }
  }

  func application(_ app : NSApplication, open: [URL]) {
    //    print(open)
    Task {
      for k in open {
        if k.scheme == "mandoc" {
          let pp = await mandocFind(k)
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


  func makeMenu(_ s : [URL] ) -> NSMenu {
    var a = NSMenu(title: "Manual")
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

var openers : [Opener] = []

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
    Task {
      do {
        try await NSDocumentController.shared.openDocument(withContentsOf: url, display: true )
      } catch(let e) {
        print("attempting to open document \(url.path): \(e.localizedDescription)")
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

