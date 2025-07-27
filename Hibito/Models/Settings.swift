import Foundation
import SwiftData

@Model
class Settings {
  var resetTime: Int = 0

  init(resetTime: Int = 0) {
    self.resetTime = resetTime
  }
}
