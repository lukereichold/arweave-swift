import Foundation

@propertyWrapper
public struct NonNegative<T: Numeric & Comparable>: Equatable {
    var value: T

    public var wrappedValue: T {
        get { value }
        set { value = max(0, newValue) }
    }

    public init(wrappedValue: T) {
        self.value = max(0, wrappedValue)
    }
}
