import Foundation

/// A published marketplace post (`posts`). Public-read, owner-write.
struct Post: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    var nickname: String
    var city: String
    var country: String
    var latitude: Double?
    var longitude: Double?
    var meetingPoint: String
    var meetingTime: String
    var priceNote: String
    var contactMethod: String
    let createdAt: Date
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case nickname
        case city
        case country
        case latitude
        case longitude
        case meetingPoint = "meeting_point"
        case meetingTime = "meeting_time"
        case priceNote = "price_note"
        case contactMethod = "contact_method"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }

    var isExpired: Bool { expiresAt < Date() }
}

/// Payload to insert a new post (id/created_at/expires_at are server defaults).
struct PostInsert: Encodable {
    let userId: UUID
    let nickname: String
    let city: String
    let country: String
    let latitude: Double?
    let longitude: Double?
    let meetingPoint: String
    let meetingTime: String
    let priceNote: String
    let contactMethod: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname
        case city
        case country
        case latitude
        case longitude
        case meetingPoint = "meeting_point"
        case meetingTime = "meeting_time"
        case priceNote = "price_note"
        case contactMethod = "contact_method"
    }
}

/// Payload to update editable fields of an existing post.
struct PostUpdate: Encodable {
    let nickname: String
    let city: String
    let country: String
    let latitude: Double?
    let longitude: Double?
    let meetingPoint: String
    let meetingTime: String
    let priceNote: String
    let contactMethod: String

    enum CodingKeys: String, CodingKey {
        case nickname
        case city
        case country
        case latitude
        case longitude
        case meetingPoint = "meeting_point"
        case meetingTime = "meeting_time"
        case priceNote = "price_note"
        case contactMethod = "contact_method"
    }
}
