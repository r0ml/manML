// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  @AppStorage("lastMan") var mantext : String = ""

  //  @State var html : String = ""
  // if this is initialized to "", the toolbar doesn't appear !!!

//  @Binding var currentURL : URL?
//  @State var manSource = ""

  @Environment(AppState.self) var state

//  var ss : Sourcerer = Sourcerer()

  var body: some View {
    VStack {
      HStack {
        TextField("Man", text: $mantext, prompt: Text("manual page") )
          .onSubmit {
            state.doTheLoad( Mandoc.canonicalize(mantext) )
          }

        // FIXME: put me back
        /*
         Button("<") {
         ss.back()
         }.disabled(!ss.canBack)

         Button(">") {
         ss.next()
         }.disabled(!ss.canNext)
         */
      }
      HTMLView( )
        .task {
          state.doTheLoad( Mandoc.canonicalize(mantext) )
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
//    .task {
//        state.doTheLoad(u)
//    }
    /*        .onChange(of: currentURL) {
     if ss.which.isEmpty { return }
     if mantext != ss.which {
     mantext = ss.which
     self.runFormat()
     }
    // FIXME: put me back
    // ss.updateHistory()
  }
     */

    // FIXME: put me back
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


  /*
  func runFormat() {
    guard let currentURL else {
      state.error = " "
      html = ""
      state.manSource = ""
      return
    }

    Task {
      if state.legacy {
        (state.error, html) = Mandoc.getTheHTML(currentURL, state.manpath)
      } else {
//        (state.error, state.manSource) = await Mandoc.readManFile(currentURL, state.manpath)
//        (state.error, html, state.manSource) = await Mandoc.newParse(manSource, state.manpath)
        page.load(currentURL)
      }
    }
  }
*/

}


/*
extension Observable {
  @MainActor func binding<Value>(
        _ keyPath: ReferenceWritableKeyPath<Self, Value>
    ) -> Binding<Value> {
      return Binding(
            get: { self[keyPath: keyPath] },
            set: { v in self[keyPath: keyPath] = v }
        )
    }
}
*/
