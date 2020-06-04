import Foundation

public struct Wallet {
    func foo() {
        let balance = Amount(value: 12, unit: .AR)
    }
}

typealias Amount = Measurement<ARUnit>

class ARUnit: Dimension {

    static let AR = ARUnit(symbol: "AR", converter: UnitConverterLinear(coefficient: 1.0))
    static let winston = ARUnit(symbol: "winston", converter: UnitConverterLinear(coefficient: 1e-12))

    static let baseUnit = AR
}
