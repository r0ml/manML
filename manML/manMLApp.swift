// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import SwiftUI
import Observation
import UniformTypeIdentifiers

let scheme = "manmlx"

@main
struct manMLApp: App {
  @State var showFind = false
  @State var currentURL: URL?
  @State var appState = AppState()

  @State var textDoc : HTMLExportDocument?
  @State var showExporter = false

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
        .fileExporter(
            isPresented: $showExporter,
            document: textDoc,
            contentType: .html,
            defaultFilename: "Export"
        ) { result in
            // handle success/failure if you want
            if case .failure(let error) = result {
                print("Export Text failed:", error.localizedDescription)
            }
        }

    }.commands {
      CommandGroup(after: .newItem) {
        Divider()
        Button("Export HTML…") {
          // Prepare whatever you want to write
          Task {
            textDoc = await HTMLExportDocument(text: getHTMLToExport())
            showExporter = true
          }
        }
        .keyboardShortcut("e", modifiers: [.command])
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

  /// Put your export content logic here.
  private func getHTMLToExport() async -> String {
    if let t = appState.page.backForwardList.currentItem?.initialURL {
      return await String(data: appState.handler.htmlForMan(t), encoding: .utf8)!
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

