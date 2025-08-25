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
    } else {
      return "\(upc[1])"
    }
  }
}


struct ContentView: View {
  @AppStorage("lastMan") var mantext : String = ""

  @Environment(AppState.self) var state
  @State var goback = false
  @State var goforward = false
  @State var isTargeted = false

  var body: some View {
    VStack {
      HStack {
        TextField("Man", text: $mantext, prompt: Text("manual page") )
          .onSubmit {
            if mantext.first != "/" { // because I might have a file path here from file drop
              state.doTheLoad( Mandoc.canonicalize(mantext) )
            }
          }

         Button("<") {
           if let previous = state.page.backForwardList.backList.last {
             state.doTheLoad(previous.initialURL)
             self.mantext = urlToMantext(previous.initialURL)
           }
         }.disabled( !state.canBack )

         Button(">") {
           if let next = state.page.backForwardList.forwardList.first {
             state.doTheLoad(next.initialURL)
             self.mantext = urlToMantext(next.initialURL)
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
              let k = try? String(contentsOf: url, encoding: .utf8)

              // FIXME: load the SchemeHandler with the source and use a weird URL: e.g. "manmlx:///"
              state.handler.cache(url.path, k ?? "")

              let fu = URL(string: scheme+"://?"+url.path)!
              state.doTheLoad(fu)
              self.mantext = urlToMantext(fu)
              return true
            }
            return false
          } isTargeted: {
            isTargeted = $0
          }
      }

      SourceView( )
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
      state.page.reload()
    }

    .padding()
    .onDrop(of: [UTType.content], isTargeted: nil) { providers in

      // FIXME: put me back
      /*
       if let p = providers.first {
       p.loadDataRepresentation(forTypeIdentifier: UTType.text.identifier) { (data, err) in
       // log.error("\(err.localizedDescription)")
       if let d = data,
       let f = String.init(data: d, encoding: .utf8) {
       Task { @MainActor in
       (state.error, html, state.manSource) = await Mandoc.newParse(f, state.manpath)
       mantext = ""
       }
       }

       }
       return true
       }
       */
      return false
    }
  }
}
