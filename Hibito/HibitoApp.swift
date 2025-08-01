//
//  HibitoApp.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/11.
//

import SwiftData
import SwiftUI

@main
struct AppLauncher {
  static func main() {
    if NSClassFromString("XCTestCase") != nil {
      HibitoTestApp.main()
    } else {
      HibitoApp.main()
    }
  }
}

struct HibitoApp: App {
  var body: some Scene {
    WindowGroup {
      TodoListView()
    }
    .modelContainer(ModelContainerManager.shared.modelContainer)
  }
}

struct HibitoTestApp: App {
  var body: some Scene {
    WindowGroup { Text("Running Unit Tests") }
  }
}
