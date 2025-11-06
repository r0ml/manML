// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation
import AppKit
import SwiftUI

struct SettingsView : View {
  var manpath : Manpath
  @State var whichMan : String?
  @State var error : String = ""
  @State var whichDir : String?
  @State var rowHeight : CGFloat? = nil

  @Environment(\.openWindow) var openWindow

  var body : some View {
    let unopened = manpath.defaultManpath.filter {
      jj in
      let j = URL(fileURLWithPath: jj)
      return !manpath.addedManpath.contains { sameDirectory($0, j ) }
    }

    GeometryReader { geo in
      let halfHeight = geo.size.height / 2
      let rowHeight = self.rowHeight ?? 28 // fallback if not measured
      let contentHeight = CGFloat(unopened.count) * rowHeight

      VStack {
        Text(error).foregroundStyle(Color.red)

        GroupBox {
          VStack {
            List(manpath.addedManpath, id: \.relativePath, selection: $whichMan) { k in
              Text(k.relativePath)
            }

            HStack {
              Button(action: {
                openDirectoryPanel()
              }) {
                Text("+")
              }
              Button(action: {
                manpath.remove(path: whichMan)
                whichMan = nil
              }) {
                Text("-")
              }
              .disabled(whichMan == nil)
            }
          }
        } label: {
          Text("Accessible manual directories")
        }
        if !unopened.isEmpty {
          GroupBox {
            ScrollView {
              VStack(alignment: .leading) {
                ForEach(unopened, id: \.self) { k in
                  Text(k)
                    .onTapGesture { _ in
                      Task { self.whichDir = k }
                      openDirectoryPanel(k)
                    }
                    .background(
                      GeometryReader { geo in
                          hilit(k).onAppear {
                            if self.rowHeight == nil || self.rowHeight! < geo.size.height {
                              self.rowHeight = geo.size.height
                            }
                          }
                      }
                    )
                }
              }
            }
            .frame(maxHeight: min(contentHeight, halfHeight))
          } label: {
            Text("Tap to add to accessible manpath (security requires opening the directory)")
          }
        }
      }
    }

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
  func openDirectoryPanel(_ arg : String? = nil) {
    let openPanel = NSOpenPanel()
    openPanel.canChooseFiles = false
    openPanel.canChooseDirectories = true
    openPanel.allowsMultipleSelection = false
    openPanel.showsHiddenFiles = true
    openPanel.prompt = "Select Directory"
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
        
        if (manpath.addedManpath.contains { sameDirectory($0, url)  }) {
          error = "already in manpath: \(url.relativePath)"
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
