//
//  HibitoApp.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/11.
//

import SwiftData
import SwiftUI

@main
struct HibitoApp: App {
  var body: some Scene {
    WindowGroup {
      TodoListView()
    }
    .modelContainer(ModelContainerManager.shared.modelContainer)
  }
}
