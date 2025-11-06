// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import AppKit
import SwiftUI

struct SettingsView : View {
  @State var whichMan : String?
  @State var error : String = ""
  @State var whichDir : String?
  @State var rowHeight : CGFloat? = nil

  var openPanel : NSOpenPanel = NSOpenPanel()


  @Environment(\.openWindow) var openWindow
  @Environment(AppState.self) var appState

  init() {
    makeDirectoryPanel()
  }


  var body : some View {
    let unopened = appState.manpath.defaultManpath.filter {
      jj in
      let j = URL(fileURLWithPath: jj)
      return !appState.manpath.addedManpath.contains { sameDirectory($0, j ) }
    }

    GeometryReader { geo in
      let halfHeight = geo.size.height / 2
      let rowHeight = self.rowHeight ?? 28 // fallback if not measured
      let contentHeight = CGFloat(unopened.count) * rowHeight

      VStack {
        Text(error).foregroundStyle(Color.red)

        GroupBox {
          VStack {
            List(appState.manpath.addedManpath, id: \.relativePath, selection: $whichMan) { k in
              Text(k.relativePath)
            }

            HStack {
              Button(action: {
                openDirectoryPanel()
              }) {
                Text("+")
              }
              Button(action: {
                appState.manpath.remove(path: whichMan)
                whichMan = nil
              }) {
                Text("-")
              }
              .disabled(whichMan == nil)
            }
          }//.padding([.leading, .trailing], 10)
        } label: {
          Text("Accessible manual directories")
        }
        if !unopened.isEmpty {
          GroupBox {
//            ScrollView.init([.vertical]) {
//              VStack(alignment: .leading) {
//                ForEach(unopened, id: \.self) { k in

                  List(unopened, id: \.self, selection: $whichDir) {k in
                  Text(k)
                    .onTapGesture { _ in
                      Task { self.whichDir = k }
                      openDirectoryPanel(k)
                    }
  //              }
//              }
            }
              .frame(maxHeight: min(contentHeight+20, halfHeight))
            //   .padding(EdgeInsets(top: 1, leading: 10, bottom: 1, trailing: 10))
          } label: {
            Text("Tap to add to accessible manpath (security requires opening the directory)")
          }
        }
      }

    }
    .padding([.top, .bottom], 20)
  }

  func hilit( _ k : String?) -> some View {
    return self.whichDir == k ? Color.blue : Color.clear
  }

  /// compares two URLs to see if they are the same.  Should work if one or the other is a symbolic link
  ///  and they wind up at the same place
  func sameDirectory(_ url1: URL, _ url2: URL) -> Bool {
      let fm = FileManager.default
    do {
      let attrs1 = try fm.attributesOfItem(atPath: url1.path)
      let attrs2 = try fm.attributesOfItem(atPath: url2.path)

      if let id1 = attrs1[.systemFileNumber] as? NSNumber,
         let id2 = attrs2[.systemFileNumber] as? NSNumber,
         let dev1 = attrs1[.systemNumber] as? NSNumber,
         let dev2 = attrs2[.systemNumber] as? NSNumber {
        return id1 == id2 && dev1 == dev2
      }
      return false
    } catch {
      return false
    }
  }

  /// opens a directory with the Open Panel in order to get a security scoped bookmark
  func makeDirectoryPanel() {
    openPanel.canChooseFiles = false
    openPanel.canChooseDirectories = true
    openPanel.allowsMultipleSelection = false
    openPanel.showsHiddenFiles = true
    openPanel.prompt = "Select to add to manpath"
  }

  func openDirectoryPanel(_ arg : String? = nil) {
    if let arg {
      openPanel.directoryURL = URL(fileURLWithPath: arg)
    }

    openPanel.begin(completionHandler: { a in
      Task { @MainActor in
        error = ""
        if a == .OK, let url = openPanel.url {
          storeSecurityScopedBookmark(for: url, key: "manpath")
        }
        whichDir = nil
        (NSApp.windows.first { $0.title.contains(/Settings/) })?.makeKeyAndOrderFront(nil)
      }
    })
  }
                    
  /// store a security scoped bookmark
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
        
        if (appState.manpath.addedManpath.contains { sameDirectory($0, url)  }) {
          error = "already in manpath: \(url.relativePath)"
          return
        }
          // Add or update the bookmark for the given URL
          bookmarks[url.absoluteString] = bookmarkData
          
        appState.manpath.addedManpath.append(url)

          // Save updated bookmarks to UserDefaults
          UserDefaults.standard.set(bookmarks, forKey: key)
      } catch {
          print("Failed to create bookmark: \(error.localizedDescription)")
      }
  }
}
