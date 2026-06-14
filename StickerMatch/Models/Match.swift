import Foundation

/// A computed possible trade between me and another user's post.
/// `theyHave` = sticker numbers the post offers (repeated) that I'm missing.
/// `iHave`    = sticker numbers I have repeated that the post is missing.
struct Match: Identifiable, Hashable {
    let post: Post
    let theyHave: [String]   // exact sticker numbers they can give me
    let iHave: [String]      // exact sticker numbers I can give them

    var id: UUID { post.id }
    var theyHaveCount: Int { theyHave.count }
    var iHaveCount: Int { iHave.count }
    var score: Int { theyHaveCount + iHaveCount }
}
