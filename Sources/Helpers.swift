import Foundation

@propertyWrapper
struct NonNegative<T: Numeric & Comparable>: Equatable {
    var value: T

    var wrappedValue: T {
        get { value }
        set { value = max(0, newValue) }
    }

    init(wrappedValue: T) {
        self.value = max(0, wrappedValue)
    }
}
