// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  @AppStorage("lastMan") var mantext : String = ""
  @State var html : String = ""
  @State var error : String = ""
  @State var modern = true
  @State var mandoc : String = ""
  
  var ss : Sourcerer = Sourcerer()
  
    var body: some View {
        VStack {
          HStack {
            Text(error).foregroundStyle(.red)
            Spacer()
            Toggle("manML", isOn: $modern).padding()
          }
          HStack {
            TextField("Man", text: $mantext, prompt: Text("manual page") )
              .onSubmit {
                Task {
                  ss.which = mantext
                  if modern {
                    await readManFile(ss.which)
                  } else {
                    getTheHTML()
                  }
                }
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
        .onAppear {
          Task {
            ss.which = mantext
            if modern {
              await readManFile(ss.which)
            } else {
              getTheHTML()
            }
          }
        }
        .onChange(of: ss.which) {
          Task {
            if mantext != ss.which {
              mantext = ss.which
              if modern {
                await readManFile(ss.which)
              } else {
                getTheHTML()
              }
            }
          }
        }
        .onChange(of: mandoc) {
          Task {
            ss.manSource = mandoc
            html = await Mandoc(mandoc).toHTML()
          }
        }
        .onChange(of: modern) {
          Task {
            if modern {
              mandoc = ""
              await readManFile(ss.which)
              ss.manSource = mandoc
              html = await Mandoc(mandoc).toHTML()
            } else {
              getTheHTML()
            }
          }
        }
        .padding()
        .onDrop(of: [UTType.content], isTargeted: nil) { providers in
          if let p = providers.first {
            p.loadDataRepresentation(forTypeIdentifier: UTType.text.identifier) { (data, err) in
              // log.error("\(err.localizedDescription)")
              if let d = data,
                 let f = String.init(data: d, encoding: .utf8) {
                mandoc = f
                mantext = ""
              }
              
            }
            return true
          }
          return false
        }
    }

  func getTheHTML() {
    error = ""
    do {
      let (c, o, e) = try captureStdoutLaunch("mandoc -T html `man -w \(ss.which)`")
      html = o!
      error = e!
    } catch(let e) {
      error = e.localizedDescription
    }
  }
  
  func readManFile(_ man : String) async {
    let ad = AppDelegate()
    let manx = man.split(separator: " ", omittingEmptySubsequences: true)
    var manu : String
    if manx.count == 1 {
      manu = String(manx[0])
    } else if man.count >= 2 {
      manu = "\(manx[1])/\(manx[0])"
    } else {
      manu = ""
    }
    let pp = await ad.mandocFind(URL(string: "mandoc:///\(manu)")!)
    if pp.count == 0 {
      error = "not found: \(man)"
/*    } else if pp.count > 1 {
      error = "multiple found"
      let a = makeMenu(pp)
      a.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
*/    } else if pp.count >= 1 {
      do {
        mandoc = try String(contentsOf: pp[0], encoding: .utf8)
      } catch(let e) {
        error = e.localizedDescription
      }
    }
  }
  
  func makeMenu(_ s : [URL] ) -> NSMenu {
    var a = NSMenu(title: "Manual")
    openers = []
    let i = s.map { p in
      let mi = NSMenuItem()
      mi.title = p.path
      let o = Opener(p, { mandoc = $0 })
      openers.append(o)
      mi.target = o
      mi.action = #selector(Opener.doRead(_:))
      return mi
    }
    a.items = i
    return a
  }
}

#Preview {
    ContentView()
}
