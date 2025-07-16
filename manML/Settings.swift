// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import AppKit
import SwiftUI

struct SettingsView : View {
  var manpath : Manpath
  @State var selectedDirectory : URL?
  @State var whichMan : String?
  @State var error : String = ""

  @Environment(\.openWindow) var openWindow

  var body : some View {
    VStack {
      Text("Settings")

      Text(error).foregroundStyle(Color.red)
      
      HStack {Button(action: {
        openDirectoryPanel()
      }) {
        Text("+")
/*        Text("Select Directory")
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
 */
      }
        Button(action: {
          manpath.remove(path: whichMan)
        }) {
          Text("-")
        }
      }
      List(manpath.addedManpath, id: \.relativePath, selection: $whichMan) { k in
          Text(k.relativePath)
      }
//    }.onChange(of: manpath.addedManpath) {
//      print("manpath changed")
    }
    
  }
  
  func openDirectoryPanel() {
    let openPanel = NSOpenPanel()
    openPanel.canChooseFiles = false
    openPanel.canChooseDirectories = true
    openPanel.allowsMultipleSelection = false
    openPanel.showsHiddenFiles = true
    openPanel.prompt = "Select Directory"
    //    openPanel.directoryURL = URL(fileURLWithPath: "/usr/share/man")

    openPanel.begin(completionHandler: { a in
      Task { @MainActor in
        error = ""
        if a == .OK, let url = openPanel.url {
          selectedDirectory = url
          storeSecurityScopedBookmark(for: url, key: "manpath")
        }
        
        //     NSApplication.shared.activate(ignoringOtherApps: true)
        (NSApp.windows.first { $0.title.contains(/Settings/) })?.makeKeyAndOrderFront(nil)
        
        //      openWindow(id: "settings-window")
      }
    })
  }
                    
  
  func storeSecurityScopedBookmark(for url: URL, key: String) {
      do {
          // Create a security-scoped bookmark
          let bookmarkData = try url.bookmarkData(
              options: .withSecurityScope,
              includingResourceValuesForKeys: nil,
              relativeTo: nil
          )
          
          // Retrieve existing bookmarks from UserDefaults
          var bookmarks = UserDefaults.standard.dictionary(forKey: key) as? [String: Data] ?? [:]
          
        if bookmarks.contains(where: { $0.key == url.absoluteString }) {
          error = "already in manpath: \(url.relativePath)"
          return
        }
        
        if manpath.defaultManpath.contains(url.relativePath) {
          error = "in default manpath: \(url.relativePath)"
          return
        }
          // Add or update the bookmark for the given URL
          bookmarks[url.absoluteString] = bookmarkData
          
        manpath.addedManpath.append(url)
        
          // Save updated bookmarks to UserDefaults
          UserDefaults.standard.set(bookmarks, forKey: key)
      } catch {
          print("Failed to create bookmark: \(error.localizedDescription)")
      }
  }
}
