import Foundation

/// A helper class to debounce function calls.
///
/// This is useful for delaying an action until a certain amount of time has passed without it being called again,
/// such as for autosaving or search query execution.
public final class Debouncer {
    private let delay: TimeInterval
    private var timer: Timer?

    public init(delay: TimeInterval) {
        self.delay = delay
    }

    /// Schedules a block of code to be executed after the specified delay.
    /// If called again before the delay has passed, the previous timer is invalidated and a new one is started.
    public func debounce(action: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
        }
    }
    
    /// Invalidates the current timer, if any, preventing the action from firing.
    public func cancel() {
        timer?.invalidate()
    }
}
