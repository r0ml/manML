// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import SwiftUI
import UniformTypeIdentifiers

func urlToMantext(_ url: URL) -> String {
  if url.path.isEmpty {
    return url.query() ?? ""
  } else {
    let upc = url.pathComponents
    if upc.count > 2 {
      return "\(upc[2]) \(upc[1])"
    } else if upc.count > 1 {
      return "\(upc[1])"
    } else {
      return ""
    }
  }
}


struct ContentView: View {
  @AppStorage("lastMan") var mantext : String = ""
  @Environment(\.openWindow) var openWindow
  @Environment(AppState.self) var state
  @State var goback = false
  @State var goforward = false
  @State var isTargeted = false

  var body: some View {
    if state.manpath.addedManpath.isEmpty {
      VStack {
        Button { openWindow(id: "app-settings") } label: { Text("Go to Settings").font(.largeTitle) }
        Text("and add directories to your MANPATH.").font(.largeTitle)
        Spacer().frame(maxHeight: 30)
        Text("The macOS security model requires that").font(.largeTitle)
        Text("you manually open these directories.").font(.largeTitle)
      }
    } else {
      VStack {
        HStack {
          TextField("Man", text: $mantext, prompt: Text("manual page") )
            .onSubmit {
              if mantext.first != "/" { // because I might have a file path here from file drop
                state.doTheLoad( Mandoc.canonicalize(mantext) )
              }
            }

          Button("<") {
            if let previous = state.page?.backForwardList.backList.last {
              state.doTheLoad(previous.initialURL)
            }
          }.disabled( !state.canBack )

          Button(">") {
            if let next = state.page?.backForwardList.forwardList.first {
              state.doTheLoad(next.initialURL)
            }
          }.disabled( !state.canNext )

        }

        ZStack {
          HTMLView( )
            .task {
              state.doTheLoad( Mandoc.canonicalize(mantext) )
            }
          Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle()) // ensure it's hit-testable
            .allowsHitTesting(isTargeted)
            .dropDestination(for: URL.self) { urls, _ in // second argument is drop coordinates


              if let url = urls.first {

                let ok = url.startAccessingSecurityScopedResource()
                defer { if ok { url.stopAccessingSecurityScopedResource() } }
                if let dd = try? Data(contentsOf: url) {
                  // FIXME: this is a kludge for old man files which use LATIN1 without saying so.
                  let ddd = dd.replacing([0xB1], with: [0xC2, 0xB1])
                  let k = String(decoding: ddd, as: UTF8.self)
                  state.handler?.cache(url.path, k)
                  let fu = URL(string: scheme+"://?"+url.path)!
                  state.doTheLoad(fu)
                  return true
                }
              }
              return false
            } isTargeted: {
              isTargeted = $0
            }
        }

        SourceView( )
      }.onChange(of: state.mantext) {
        self.mantext = state.mantext
      }
      .toolbar {
        ToolbarItem(id: "error", placement: .status) {
          HStack {
            Text(state.error).foregroundStyle(.red)
          }
        }
        ToolbarItem(id: "toggle") {
          HStack {
            @Bindable var state = state
            Text("Legacy")
            Toggle("Legacy", isOn: $state.legacy).toggleStyle(.switch).help(
              "Use legacy mandoc formatting")
          }
        }

      }

      .onChange(of: state.legacy) {
        state.page?.reload()
      }

      .padding()
    }
  }
}
