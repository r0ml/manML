// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import SwiftUI
import Observation
import UniformTypeIdentifiers

let scheme = "manml"

@main
struct manMLApp: App {

  @State var showFind = false
  @State var currentURL: URL?
  @State var appState = AppState()

  @State var textDoc : HTMLExportDocument?
  @State var showExporter = false
  @State var xnam : String = "export"

  var body: some Scene {
    Window("ManML", id: "main") {
      ContentView()
        .environment  (appState)
        .onOpenURL { u in
          appState.doTheLoad(u)
        }
        .fileExporter(
          isPresented: $showExporter,
          document: textDoc,
          contentType: .html,
          defaultFilename: xnam
        ) { result in
          // handle success/failure if you want
          if case .failure(let error) = result {
            appState.error = "Export failed: \(error.localizedDescription)"
          }
        }

    }.commands {
      CommandGroup(after: .newItem) {
        Divider()
        Button("Export HTML…") {
          // Prepare whatever you want to write
          Task {
            textDoc = await HTMLExportDocument(text: getHTMLToExport())
            if let jj = appState.page?.backForwardList.currentItem?.initialURL {
              let j = urlToMantext(jj)
              var k : String
              if j.first == "/" {
                k = String(j[j.lastIndex(of: "/")!..<j.endIndex])
              } else {
                k = j.components(separatedBy: " ").reversed().joined(separator: ".")
              }
              xnam = k
              showExporter = true
            } else {
              appState.error = "No URL to export"
            }
          }
        }
        .keyboardShortcut("e", modifiers: [.command])
      }
    }

    Settings {
      SettingsView(manpath: appState.manpath)
    }.windowToolbarStyle(.unified(showsTitle: true))
  }

  /// Put your export content logic here.
  private func getHTMLToExport() async -> String {
    if let t = appState.page?.backForwardList.currentItem?.initialURL,
       let d = await appState.handler?.htmlForMan(t) {
      return String(data: d, encoding: .utf8) ?? ""
    } else {
      return ""
    }
  }

}


/// Simple text document you generate on the fly.
struct HTMLExportDocument: FileDocument {

  static let readableContentTypes: [UTType] = [.html]

  var text: String

  init(text: String) { self.text = text }

  init(configuration: ReadConfiguration) throws {
    if let data = configuration.file.regularFileContents,
       let s = String(data: data, encoding: .utf8) {
      text = s
    } else {
      text = ""
    }
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    .init(regularFileWithContents: Data(text.utf8))
  }
}

