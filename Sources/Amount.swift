import Foundation

public struct Amount: Equatable {
    
    @NonNegative public var value: Double
    public var unit: Unit
    
    public init(value: Double, unit: Amount.Unit) {
        self.value = value
        self.unit = unit
    }
    
    public func converted(to targetUnit: Unit) -> Amount {
        
        guard unit != targetUnit else { return self }
        
        switch targetUnit {
        case .AR:
            return Amount(value: value / 1e12, unit: .AR)
        case .winston:
            return Amount(value: value * 1e12, unit: .winston)
        }
    }
}

public extension Amount {
    enum Unit: Equatable {
        case AR
        case winston
    }
}

extension Amount: CustomStringConvertible {
    public var description: String {
        return String(format: "%.f", converted(to: .winston).value)
    }
}
