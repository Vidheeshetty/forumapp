class ForumPost {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final bool isPinned;
  final bool isLocked;
  final bool isApproved;
  final List<String> upvotedBy;
  final List<String> downvotedBy;

  ForumPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    this.upvotes = 0,
    this.downvotes = 0,
    this.commentCount = 0,
    this.isPinned = false,
    this.isLocked = false,
    this.isApproved = true,
    this.upvotedBy = const [],
    this.downvotedBy = const [],
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      isLocked: json['isLocked'] ?? false,
      isApproved: json['isApproved'] ?? true,
      upvotedBy: List<String>.from(json['upvotedBy'] ?? []),
      downvotedBy: List<String>.from(json['downvotedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'commentCount': commentCount,
      'isPinned': isPinned,
      'isLocked': isLocked,
      'isApproved': isApproved,
      'upvotedBy': upvotedBy,
      'downvotedBy': downvotedBy,
    };
  }
}

class Comment {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String? parentId;
  final int upvotes;
  final int downvotes;
  final bool isApproved;
  final List<String> upvotedBy;
  final List<String> downvotedBy;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.parentId,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isApproved = true,
    this.upvotedBy = const [],
    this.downvotedBy = const [],
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      parentId: json['parentId'],
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      isApproved: json['isApproved'] ?? true,
      upvotedBy: List<String>.from(json['upvotedBy'] ?? []),
      downvotedBy: List<String>.from(json['downvotedBy'] ?? []),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((e) => Comment.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'isApproved': isApproved,
      'upvotedBy': upvotedBy,
      'downvotedBy': downvotedBy,
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }
}

class ForumUser {
  final String id;
  final String username;
  final String email;
  final bool isOnline;
  final DateTime lastSeen;
  final bool isModerator;
  final DateTime createdAt;

  ForumUser({
    required this.id,
    required this.username,
    required this.email,
    this.isOnline = false,
    required this.lastSeen,
    this.isModerator = false,
    required this.createdAt,
  });

  factory ForumUser.fromJson(Map<String, dynamic> json) {
    return ForumUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastSeen: DateTime.parse(json['lastSeen']),
      isModerator: json['isModerator'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'isModerator': isModerator,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}