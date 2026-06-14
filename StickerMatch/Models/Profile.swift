import Foundation

/// A user profile row (`profiles`). Owner-private.
struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var nickname: String?
    var city: String?
    var country: String?       // ISO alpha-2 code (e.g. "MX")
    var meetingPoint: String?
    var contactMethod: String? // legacy; no longer collected (chat replaced it)

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case city
        case country
        case meetingPoint = "meeting_point"
        case contactMethod = "contact_method"
    }
}

/// Payload to update editable profile fields. Contact method is intentionally
/// omitted — users connect via in-app chat now.
struct ProfileUpdate: Encodable {
    let nickname: String?
    let city: String?
    let country: String?
    let meetingPoint: String?

    enum CodingKeys: String, CodingKey {
        case nickname
        case city
        case country
        case meetingPoint = "meeting_point"
    }
}
