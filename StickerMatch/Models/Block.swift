import Foundation

/// A user the current user has blocked (`blocks`). Nickname is snapshotted so
/// the blocked-users list needs no profile read.
struct Block: Codable, Identifiable, Hashable {
    let id: UUID
    let blockerId: UUID
    let blockedId: UUID
    let blockedNickname: String

    enum CodingKeys: String, CodingKey {
        case id
        case blockerId = "blocker_id"
        case blockedId = "blocked_id"
        case blockedNickname = "blocked_nickname"
    }

    var displayName: String { blockedNickname.isEmpty ? "Trader" : blockedNickname }
}

struct BlockInsert: Encodable {
    let blockerId: UUID
    let blockedId: UUID
    let blockedNickname: String

    enum CodingKeys: String, CodingKey {
        case blockerId = "blocker_id"
        case blockedId = "blocked_id"
        case blockedNickname = "blocked_nickname"
    }
}

/// Reasons a user can report another user / post.
enum ReportReason: String, Codable, CaseIterable, Identifiable {
    case spam
    case harassment
    case scam
    case other

    var id: String { rawValue }
    var label: String {
        switch self {
        case .spam:       return "Spam"
        case .harassment: return "Harassment or inappropriate"
        case .scam:       return "Scam or fraud"
        case .other:      return "Other"
        }
    }
}

struct ReportInsert: Encodable {
    let reporterId: UUID
    let reportedUserId: UUID
    let postId: UUID?
    let reason: ReportReason
    let note: String

    enum CodingKeys: String, CodingKey {
        case reporterId = "reporter_id"
        case reportedUserId = "reported_user_id"
        case postId = "post_id"
        case reason
        case note
    }
}
