// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  @AppStorage("lastMan") var mantext : String = ""
  @State var html : String = ""
  // if this is initialized to "", the toolbar doesn't appear !!!
  @State var error : String = " "
  @State var legacy = false
//  @State var mandoc : String = ""
  var manpath : Manpath

  var ss : Sourcerer = Sourcerer()
  
    var body: some View {
        VStack {
          HStack {
            TextField("Man", text: $mantext, prompt: Text("manual page") )
              .onSubmit {
                ss.which = mantext
                self.runFormat()
              }
            Button("<") {
              ss.back()
            }.disabled(!ss.canBack)
            
            Button(">") {
              ss.next()
            }.disabled(!ss.canNext)
          }
          HTMLView( html, source: ss )
          
          SourceView(ss: ss)
        }
        .toolbar {
          ToolbarItem(id: "error", placement: .status) {
            HStack {
              Text(error).foregroundStyle(.red)
            }
          }
          ToolbarItem(id: "toggle") {
            HStack {
              Text("Legacy")
              Toggle("Legacy", isOn: $legacy).toggleStyle(.switch).help(
                "Use legacy mandoc formatting")
            }
          }

        }
        .task {
          ss.which = mantext
          runFormat()
        }
        .onChange(of: ss.which) {
          if ss.which.isEmpty { return }
          if mantext != ss.which {
            mantext = ss.which
            self.runFormat()
          }
          ss.updateHistory()
        }

        .onChange(of: legacy) {
          self.runFormat()
        }
        .padding()
        .onDrop(of: [UTType.content], isTargeted: nil) { providers in
          if let p = providers.first {
            p.loadDataRepresentation(forTypeIdentifier: UTType.text.identifier) { (data, err) in
              // log.error("\(err.localizedDescription)")
              if let d = data,
                 let f = String.init(data: d, encoding: .utf8) {
                Task { @MainActor in
                  (error, html, ss.manSource) = await Mandoc.newParse(f, manpath)
                  mantext = ""
                }
              }
              
            }
            return true
          }
          return false
        }
    }

  func runFormat() {
    Task {
      if legacy {
        (error, html) = Mandoc.getTheHTML(ss.which, manpath)
      } else {
        (error, ss.manSource) = await Mandoc.readManFile(ss.which, manpath)
        (error, html, ss.manSource) = await Mandoc.newParse(ss.manSource, manpath)
      }
    }
  }
  

  
  func makeMenu(_ s : [URL] ) -> NSMenu {
    let a = NSMenu(title: "Manual")
    openers = []
    let i = s.map { p in
      let mi = NSMenuItem()
      mi.title = p.path
      let o = Opener(p, {
        (error, html, ss.manSource) = await Mandoc.newParse($0, manpath)
      })
      openers.append(o)
      mi.target = o
      mi.action = #selector(Opener.doRead(_:))
      return mi
    }
    a.items = i
    return a
  }
  
  

}

