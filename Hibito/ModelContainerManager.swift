//
//  ModelContainerManager.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/22.
//

import Foundation
import SwiftData

class ModelContainerManager {
  static let shared = ModelContainerManager()

  let modelContainer: ModelContainer

  private init() {
    let schema = Schema([TodoItem.self, Settings.self])

    let useCloudSync = UserDefaults.standard.bool(forKey: "useCloudSync")
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false,
      cloudKitDatabase: useCloudSync ? .automatic : .none
    )
    print("🔧 modelConfiguration.cloudKitDatabase: \(modelConfiguration.cloudKitDatabase)")

    do {
      self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  @MainActor
  var mainContext: ModelContext {
    modelContainer.mainContext
  }
}
