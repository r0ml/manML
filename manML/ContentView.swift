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
  var manpath : Manpath

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
                    mandoc = await readManFile(ss.which)
                  } else {
                    html = getTheHTML()
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
              mandoc = await readManFile(ss.which)
            } else {
              html = getTheHTML()
            }
          }
        }
        .onChange(of: ss.which) {
          Task {
            if mantext != ss.which {
              mantext = ss.which
              if modern {
                mandoc = await readManFile(ss.which)
              } else {
                html = getTheHTML()
              }
            }
          }
        }
        .onChange(of: mandoc) {
          Task {
            ss.manSource = mandoc
            let md = await Mandoc(mandoc)
            let h = await md.toHTML()
            html = h
          }
        }
        .onChange(of: modern) {
          Task {
            if modern {
              mandoc = ""
              mandoc = await readManFile(ss.which)
              ss.manSource = mandoc
              html = await Mandoc(mandoc).toHTML()
            } else {
              html = getTheHTML()
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

  func getTheHTML() -> String {
    error = ""
    do {
      let (_, o, e) = try captureStdoutLaunch("mandoc -T html `man -w \(ss.which)`")
      
      error = e!
      return o!
      
    } catch(let e) {
      error = e.localizedDescription
    }
    return ""
  }
  
  func readManFile(_ man : String) async -> String {
//    let ad = (NSApp.delegate) as? AppDelegate
    let manx = man.split(separator: " ", omittingEmptySubsequences: true)
    var manu : String
    if manx.count == 1 {
      manu = String(manx[0])
    } else if man.count >= 2 {
      manu = "\(manx[1])/\(manx[0])"
    } else {
      manu = ""
    }
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
      let o = Opener(p, { mandoc = $0 })
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

