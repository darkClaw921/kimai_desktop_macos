import Foundation

nonisolated struct KimaiRate: Decodable, Sendable {
    let id: Int
    let user: RateUser?
    let rate: Double
    let internalRate: Double?
    let isFixed: Bool

    struct RateUser: Decodable, Sendable {
        let id: Int
    }
}
