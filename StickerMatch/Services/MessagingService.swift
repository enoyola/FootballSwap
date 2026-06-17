import Foundation
import Supabase

/// Conversations + messages, including a realtime stream of incoming messages.
final class MessagingService {
    private var client: SupabaseClient { SupabaseService.shared.client }

    // MARK: - Reads

    /// The current user's conversations, most-recent first.
    func fetchConversations(userId: UUID) async throws -> [Conversation] {
        try await client
            .from("conversations")
            .select()
            .or("user_a.eq.\(userId.uuidString),user_b.eq.\(userId.uuidString)")
            .order("last_message_at", ascending: false)
            .execute()
            .value
    }

    func fetchMessages(conversationId: UUID) async throws -> [Message] {
        try await client
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    /// A single conversation by id (RLS restricts this to its participants).
    /// Used to deep-link from a tapped push notification to the right chat.
    func fetchConversation(id: UUID) async throws -> Conversation {
        try await client
            .from("conversations")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    // MARK: - Writes

    /// Returns the existing conversation with `otherUserId`, creating it if needed.
    func getOrCreateConversation(otherUserId: UUID) async throws -> UUID {
        try await client
            .rpc("get_or_create_conversation", params: ["other_user": otherUserId.uuidString])
            .execute()
            .value
    }

    @discardableResult
    func sendMessage(conversationId: UUID, senderId: UUID, body: String) async throws -> Message {
        let payload = MessageInsert(conversationId: conversationId, senderId: senderId, body: body)
        return try await client
            .from("messages")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Realtime

    /// Streams new messages inserted into `conversationId`. The channel is torn
    /// down when the stream's consumer cancels.
    func messageStream(conversationId: UUID) -> AsyncStream<Message> {
        let realtime = client.realtimeV2
        let channel = realtime.channel("messages:\(conversationId.uuidString)")
        let inserts = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: .eq("conversation_id", value: conversationId.uuidString)
        )

        return AsyncStream { continuation in
            let task = Task {
                await channel.subscribe()
                for await change in inserts {
                    if let message = try? change.decodeRecord(as: Message.self, decoder: Self.realtimeDecoder) {
                        continuation.yield(message)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
                Task { await realtime.removeChannel(channel) }
            }
        }
    }

    /// Streams every new message across the current user's conversations
    /// (RLS scopes it to rows the user can see). Drives the unread badge — no
    /// per-conversation filter, unlike `messageStream(conversationId:)`.
    func incomingMessageStream() -> AsyncStream<Message> {
        let realtime = client.realtimeV2
        let channel = realtime.channel("messages:inbox")
        let inserts = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages"
        )

        return AsyncStream { continuation in
            let task = Task {
                await channel.subscribe()
                for await change in inserts {
                    if let message = try? change.decodeRecord(as: Message.self, decoder: Self.realtimeDecoder) {
                        continuation.yield(message)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
                Task { await realtime.removeChannel(channel) }
            }
        }
    }

    // Realtime delivers column values as strings; tolerate Postgres timestamp
    // shapes (with/without fractional seconds and timezone).
    private static let realtimeDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = parseTimestamp(raw) { return date }
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Unrecognized date: \(raw)")
        }
        return decoder
    }()

    private static func parseTimestamp(_ s: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: s) { return d }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "UTC")
        for format in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss"
        ] {
            df.dateFormat = format
            if let d = df.date(from: s) { return d }
        }
        return nil
    }
}
