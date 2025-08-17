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
  @State var mandoc : String = ""
  var manpath : Manpath

  var ss : Sourcerer = Sourcerer()
  
    var body: some View {
        VStack {
//          HStack {
//            Text(error).foregroundStyle(.red)
/*            Spacer()
            Toggle("manML", isOn: $modern).padding().help(
              "Use manML formatting instead of legacy mandoc"
            )
 */
//          }
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
        .onChange(of: mandoc) {
            ss.manSource = mandoc
            let md = Mandoc(mandoc)
            let h = md.toHTML()
            html = h
        }
 
        .onChange(of: legacy) {
          if !legacy {
            mandoc = ""
          }
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
                  mandoc = f
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
        html = getTheHTML(ss.which)
      } else {
        mandoc = await readManFile(ss.which)
      }
    }
  }
  
  func getTheHTML(_ man : String) -> String {
    error = ""
    do {
      let (_, o, e) = try captureStdoutLaunch("mandoc -T html `man -w \(man)`", "", ["MANPATH": manpath.defaultManpath.joined(separator: ":") ])

      error = e!
      return o!
      
    } catch(let e) {
      error = e.localizedDescription
    }
    return ""
  }

  func canonicalize(_ man : String) -> String {
    let manx = man.split(separator: " ", omittingEmptySubsequences: true)
    var manu : String
    if manx.count == 1 {
      manu = String(manx[0])
    } else if man.count >= 2 {
      if let i = Int(manx[0]) {
        manu = "\(manx[1])/\(manx[0])"
      } else if let i = Int(manx[1]) {
        manu = "\(manx[0])/\(manx[1])"
      } else {
        manu = ""
      }
    } else {
      manu = ""
    }
    return manu
  }

  func readManFile(_ man : String) async -> String {
//    let ad = (NSApp.delegate) as? AppDelegate
    let manu = canonicalize(man)
    let pp = mandocFind( URL(string: "mandoc:///\(manu)")!)
    if pp.count == 0 {
      error = "not found: \(man)"
/*    } else if pp.count > 1 {
      error = "multiple found"
      let a = makeMenu(pp)
      a.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
*/    } else if pp.count >= 1 {
      error = ""
      do {
        return try String(contentsOf: pp[0], encoding: .utf8)
      } catch(let e) {
        error = e.localizedDescription
      }
    }
    error = "not found: \(man)"
    return ""
  }
  
  func makeMenu(_ s : [URL] ) -> NSMenu {
    let a = NSMenu(title: "Manual")
    openers = []
    let i = s.map { p in
      let mi = NSMenuItem()
      mi.title = p.path
      let o = Opener(p, {
        mandoc = $0
      })
      openers.append(o)
      mi.target = o
      mi.action = #selector(Opener.doRead(_:))
      return mi
    }
    a.items = i
    return a
  }
  
  
  func mandocFind( _ k : URL) -> [URL] {
    if k.scheme == "mandoc" {
      let j = k.pathComponents
      if j.count < 2 { return [] }
      let j1 = j[1]
      var j2 = j.count > 2 ? j[2] : nil
      if j2?.isEmpty == true { j2 = nil }
      let pp = manpath.find(j1, j2)
      return pp
    } else {
      return [k]
    }
  }

}

