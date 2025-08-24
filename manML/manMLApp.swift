// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import SwiftUI
import Observation

let scheme = "manmlx"

@main
struct manMLApp: App {
  @State var showFind = false
  @State var currentURL: URL?
  @State var appState = AppState()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment  (appState)
        .onOpenURL { u in
          if u.scheme == scheme {
            let pp = Mandoc.mandocFind(u, appState.manpath)
            if let jj = pp.first {
              doOpen(jj)
            } else {
              print("not found")
  /*          } else if pp.count > 1 {
              print("multiple found")
              let a = makeMenu(pp)
              a.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
   */
            }
          }
        }
    }
    
    Settings {
      SettingsView(manpath: appState.manpath)
    }.windowToolbarStyle(.unified(showsTitle: true))
  }


  func doOpen(_ urlx : URL) {
    var url = urlx
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

  

}

