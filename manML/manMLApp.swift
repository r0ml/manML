// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import SwiftUI

// var globalManpath: [URL] = []

@main
struct manMLApp: App {
  var manpath = Manpath()
  

  var body: some Scene {
    WindowGroup {
      ContentView(manpath: manpath)
//        .task {
//            self.manpath = await Manpath().retrieveSecurityScopedBookmarks(key: "manpath")

          //          globalManpath = self.manpath
          //          print("manpath = \(globalManpath)")
//        }
    }
    Settings {
      SettingsView(manpath: manpath)
    }
  }

  /*
  func retrieveSecurityScopedBookmarks(key: String) -> [URL] {
      var retrievedURLs: [URL] = []
      
      // Retrieve the saved bookmarks dictionary from UserDefaults
      guard let bookmarks = UserDefaults.standard.dictionary(forKey: key) as? [String: Data] else {
          return []
      }
      
      for (urlString, bookmarkData) in bookmarks {
          do {
              var isStale = false
              
              // Resolve the bookmark to a URL
              let resolvedURL = try URL(
                  resolvingBookmarkData: bookmarkData,
                  options: .withSecurityScope,
                  relativeTo: nil,
                  bookmarkDataIsStale: &isStale
              )
              
              if isStale {
                  print("Bookmark for URL \(urlString) is stale.")
              }
              
              retrievedURLs.append(resolvedURL)
          } catch {
              print("Failed to resolve bookmark for \(urlString): \(error.localizedDescription)")
          }
      }
      
      return retrievedURLs
  }
  
*/
  

}

