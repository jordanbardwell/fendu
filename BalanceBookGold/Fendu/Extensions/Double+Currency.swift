import Foundation

extension Double {
    func asCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "$\(formatter.string(from: NSNumber(value: self)) ?? "0.00")"
    }

    func asCurrencyWhole() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return "$\(formatter.string(from: NSNumber(value: self)) ?? "0")"
    }
}
