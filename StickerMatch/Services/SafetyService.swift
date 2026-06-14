import Foundation
import Supabase

/// Blocking and reporting. Blocking hides posts/conversations both ways (enforced
/// in RLS); reporting records content for moderation.
final class SafetyService {
    private var client: SupabaseClient { SupabaseService.shared.client }

    // MARK: - Blocking

    func block(blockerId: UUID, blockedId: UUID, nickname: String) async throws {
        let payload = BlockInsert(blockerId: blockerId, blockedId: blockedId, blockedNickname: nickname)
        try await client
            .from("blocks")
            .upsert(payload, onConflict: "blocker_id,blocked_id")
            .execute()
    }

    func unblock(blockerId: UUID, blockedId: UUID) async throws {
        try await client
            .from("blocks")
            .delete()
            .eq("blocker_id", value: blockerId.uuidString)
            .eq("blocked_id", value: blockedId.uuidString)
            .execute()
    }

    func fetchBlocked(blockerId: UUID) async throws -> [Block] {
        try await client
            .from("blocks")
            .select()
            .eq("blocker_id", value: blockerId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Reporting

    func report(
        reporterId: UUID,
        reportedUserId: UUID,
        postId: UUID?,
        reason: ReportReason,
        note: String
    ) async throws {
        let payload = ReportInsert(
            reporterId: reporterId,
            reportedUserId: reportedUserId,
            postId: postId,
            reason: reason,
            note: note
        )
        try await client
            .from("reports")
            .insert(payload)
            .execute()
    }
}
