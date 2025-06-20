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
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      TodoItem.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(sharedModelContainer)
  }
}
