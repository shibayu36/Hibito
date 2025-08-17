//
//  HibitoApp.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/11.
//

import FirebaseCore
import SwiftData
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

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
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

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
