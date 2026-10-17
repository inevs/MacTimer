import Foundation
import Testing
@testable import MacTimer

@MainActor
private final class FakeClock {
    var now = Date(timeIntervalSinceReferenceDate: 0)
    func advance(_ seconds: TimeInterval) { now.addTimeInterval(seconds) }
}

@MainActor
struct TimerModelTests {
    private let clock = FakeClock()
    private let model: TimerModel

    init() {
        let clock = clock
        model = TimerModel(now: { clock.now }, autoTick: false)
    }

    @Test(arguments: [
        (0.0, "00:00"),
        (59.2, "01:00"),
        (600.0, "10:00"),
        (3599.0, "59:59"),
        (3600.0, "1:00:00"),
        (3725.0, "1:02:05"),
    ])
    func format(interval: TimeInterval, expected: String) {
        #expect(TimerModel.format(interval) == expected)
    }

    @Test(arguments: [
        ("10", 600.0),
        ("7,5", 450.0),
        ("7.5", 450.0),
        ("7:30", 450.0),
        (" 0:45 ", 45.0),
    ])
    func parseValid(input: String, expected: TimeInterval) {
        #expect(TimerModel.parseDuration(input) == expected)
    }

    @Test(arguments: ["", "0", "-3", "abc", "5:60", "1:2:3", "inf", "2000"])
    func parseInvalid(input: String) {
        #expect(TimerModel.parseDuration(input) == nil)
    }

    @Test func countsDownAndFinishesOnce() {
        var finishCount = 0
        model.onFinish = { finishCount += 1 }

        model.start(duration: 120)
        #expect(model.state == .running)
        #expect(model.displayText == "02:00")

        clock.advance(61)
        model.tick()
        #expect(model.displayText == "00:59")
        #expect(model.isLastMinute)

        clock.advance(60)
        model.tick()
        model.tick()
        #expect(model.state == .finished)
        #expect(model.remaining == 0)
        #expect(finishCount == 1)
    }

    @Test func adjustExtendsAndShortensButNeverBelowZero() {
        model.start(duration: 120)
        model.adjust(by: 60)
        #expect(model.remaining == 180)

        model.adjust(by: -60)
        #expect(model.remaining == 120)

        clock.advance(90)
        model.adjust(by: -60)
        #expect(model.remaining == 0)
        #expect(model.state == .finished)
    }

    @Test func plusAfterFinishRestarts() {
        model.start(duration: 10)
        clock.advance(10)
        model.tick()
        #expect(model.state == .finished)

        model.adjust(by: -60)
        #expect(model.state == .finished)

        model.adjust(by: 60)
        #expect(model.state == .running)
        #expect(model.remaining == 60)
    }

    @Test func stopResets() {
        model.start(duration: 60)
        model.stop()
        #expect(model.state == .idle)
        #expect(model.remaining == 0)
        model.adjust(by: 60)
        #expect(model.state == .idle)
    }
}
