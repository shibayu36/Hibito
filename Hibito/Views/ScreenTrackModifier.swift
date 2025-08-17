import FirebaseAnalytics
import SwiftUI

struct ScreenTrackModifier: ViewModifier {
  let name: String
  let klass: String
  @State private var loggedOnce = false

  func body(content: Content) -> some View {
    content.onAppear {
      guard !loggedOnce else { return }
      Analytics.logEvent(
        AnalyticsEventScreenView,
        parameters: [
          AnalyticsParameterScreenName: name,
          AnalyticsParameterScreenClass: klass,
        ])
      loggedOnce = true
    }
  }
}

extension View {
  func trackScreen(_ name: String, klass: String? = nil) -> some View {
    modifier(ScreenTrackModifier(name: name, klass: klass ?? "\(type(of: self))"))
  }
}
