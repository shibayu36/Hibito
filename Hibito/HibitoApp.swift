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
  init() {
    let timestamp = DateFormatter.localizedString(
      from: Date(), dateStyle: .none, timeStyle: .medium)
    print("🚀 [\(timestamp)] HibitoApp launched! [PID:\(ProcessInfo.processInfo.processIdentifier)]")
  }

  var body: some Scene {
    WindowGroup {
      TodoListView()
    }
    .modelContainer(ModelContainerManager.shared.modelContainer)
  }
}
