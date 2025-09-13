// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

struct SourceView : View {
  @State var source : String = ""
  @Environment(AppState.self) var ss 

  var body : some View {
    HStack {
      Text(source)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.05))
        .onChange(of: ss.sourceLine) {
          if var ssx = ss.sourceLine {
            let lines = ss.manSource.split(omittingEmptySubsequences: false,  whereSeparator: \.isNewline)
            if ssx >= lines.count { ss.sourceLine = lines.count - 1; ssx = lines.count - 1 }
            if ssx >= 0 && ssx < lines.count {
              source = String(lines[ssx])
            }
          } else {
            source = ""
          }
        }
      Spacer()
      Button("⋀") {
        if let s = ss.sourceLine,
           s > 0 {
          ss.sourceLine = s-1
        }
      }
      Button("⋁") {
        if let s = ss.sourceLine {
          ss.sourceLine = s+1
        }
      }
    }
  }
  
}



