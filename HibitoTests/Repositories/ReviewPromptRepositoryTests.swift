import Foundation
import Testing

@testable import DailyDo

@MainActor
struct ReviewPromptRepositoryTests {

  private func createRepository(suiteName: String) -> ReviewPromptRepository {
    let userDefaults = UserDefaults(suiteName: suiteName)!
    userDefaults.removePersistentDomain(forName: suiteName)
    return ReviewPromptRepository(userDefaults: userDefaults)
  }

  private func date(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
    Calendar.current.date(
      from: DateComponents(year: year, month: month, day: day, hour: hour)
    )!
  }

  // MARK: - recordAppForeground

  @Test("初回フォアグラウンドではレビューリクエストされない")
  func recordFirstForeground() {
    let repository = createRepository(suiteName: "test.reviewPrompt.first")

    repository.recordAppForeground(now: date(year: 2026, month: 3, day: 1))

    #expect(repository.shouldRequestReview() == false)
  }

  @Test("同じ日に複数回フォアグラウンドにしてもカウントは増えない")
  func recordSameDayMultipleTimes() {
    let repository = createRepository(suiteName: "test.reviewPrompt.sameDay")

    for day in 1...6 {
      repository.recordAppForeground(now: date(year: 2026, month: 3, day: day))
    }
    #expect(repository.shouldRequestReview() == false)

    repository.recordAppForeground(now: date(year: 2026, month: 3, day: 6, hour: 12))
    repository.recordAppForeground(now: date(year: 2026, month: 3, day: 6, hour: 18))

    #expect(repository.shouldRequestReview() == false)
  }

  @Test("異なる日にフォアグラウンドにするとカウントが増える")
  func recordDifferentDays() {
    let repository = createRepository(suiteName: "test.reviewPrompt.diffDays")

    for day in 1...6 {
      repository.recordAppForeground(now: date(year: 2026, month: 3, day: day))
    }
    #expect(repository.shouldRequestReview() == false)

    repository.recordAppForeground(now: date(year: 2026, month: 3, day: 7))
    #expect(repository.shouldRequestReview() == true)
  }

  // MARK: - shouldRequestReview

  @Test("7日目の起動でshouldRequestReviewがtrueを返す")
  func shouldRequestReviewAfter7Days() {
    let repository = createRepository(suiteName: "test.reviewPrompt.7days")

    for day in 1...7 {
      repository.recordAppForeground(now: date(year: 2026, month: 3, day: day))
    }

    #expect(repository.shouldRequestReview() == true)
  }

  @Test("6日目の起動ではshouldRequestReviewがfalseを返す")
  func shouldNotRequestReviewBefore7Days() {
    let repository = createRepository(suiteName: "test.reviewPrompt.6days")

    for day in 1...6 {
      repository.recordAppForeground(now: date(year: 2026, month: 3, day: day))
    }

    #expect(repository.shouldRequestReview() == false)
  }

  @Test("markReviewRequested後はshouldRequestReviewがfalseを返す")
  func shouldNotRequestAfterMarked() {
    let repository = createRepository(suiteName: "test.reviewPrompt.marked")

    for day in 1...7 {
      repository.recordAppForeground(now: date(year: 2026, month: 3, day: day))
    }

    repository.markReviewRequested()

    #expect(repository.shouldRequestReview() == false)
  }

  @Test("リクエスト済みなら日数を満たしていてもfalseを返す")
  func shouldNotRequestWhenAlreadyRequested() {
    let repository = createRepository(suiteName: "test.reviewPrompt.alreadyRequested")

    for day in 1...7 {
      repository.recordAppForeground(now: date(year: 2026, month: 3, day: day))
    }
    repository.markReviewRequested()

    // さらに日数を重ねても
    for day in 8...14 {
      repository.recordAppForeground(now: date(year: 2026, month: 3, day: day))
    }

    #expect(repository.shouldRequestReview() == false)
  }

}
