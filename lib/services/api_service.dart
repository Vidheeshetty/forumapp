import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../models/models.dart';

class ApiService {
  static const String _apiName = 'forumapi';

  Future<List<ForumPost>> getPosts() async {
    try {
      final request = RESTRequest(
        method: RESTMethod.get,
        path: '/posts',
        apiName: _apiName,
      );

      final response = await Amplify.API.get(request).response;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.decodeBody());
        return data.map((json) => ForumPost.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error getting posts: $e');
      return [];
    }
  }

  Future<ForumPost> createPost(String title, String content, List<String> tags) async {
    try {
      final postData = {
        'title': title,
        'content': content,
        'tags': tags,
      };

      final request = RESTRequest(
        method: RESTMethod.post,
        path: '/posts',
        body: HttpPayload.json(postData),
        apiName: _apiName,
      );

      final response = await Amplify.API.post(request).response;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.decodeBody());
        return ForumPost.fromJson(data);
      } else {
        throw Exception('Failed to create post: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error creating post: $e');
      rethrow;
    }
  }

  Future<void> votePost(String postId, bool isUpvote) async {
    try {
      final voteData = {
        'isUpvote': isUpvote,
      };

      final request = RESTRequest(
        method: RESTMethod.post,
        path: '/posts/$postId/vote',
        body: HttpPayload.json(voteData),
        apiName: _apiName,
      );

      final response = await Amplify.API.post(request).response;

      if (response.statusCode != 200) {
        throw Exception('Failed to vote on post: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error voting on post: $e');
      rethrow;
    }
  }

  Future<List<Comment>> getComments(String postId) async {
    try {
      final request = RESTRequest(
        method: RESTMethod.get,
        path: '/posts/$postId/comments',
        apiName: _apiName,
      );

      final response = await Amplify.API.get(request).response;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.decodeBody());
        return data.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error getting comments: $e');
      return [];
    }
  }

  Future<Comment> addComment(String postId, String content, String? parentId) async {
    try {
      final commentData = {
        'content': content,
        if (parentId != null) 'parentId': parentId,
      };

      final request = RESTRequest(
        method: RESTMethod.post,
        path: '/posts/$postId/comments',
        body: HttpPayload.json(commentData),
        apiName: _apiName,
      );

      final response = await Amplify.API.post(request).response;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.decodeBody());
        return Comment.fromJson(data);
      } else {
        throw Exception('Failed to create comment: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error creating comment: $e');
      rethrow;
    }
  }

  Future<void> voteComment(String commentId, bool isUpvote) async {
    try {
      final voteData = {
        'isUpvote': isUpvote,
      };

      final request = RESTRequest(
        method: RESTMethod.post,
        path: '/comments/$commentId/vote',
        body: HttpPayload.json(voteData),
        apiName: _apiName,
      );

      final response = await Amplify.API.post(request).response;

      if (response.statusCode != 200) {
        throw Exception('Failed to vote on comment: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error voting on comment: $e');
      rethrow;
    }
  }

  Future<List<ForumUser>> getOnlineUsers() async {
    try {
      final request = RESTRequest(
        method: RESTMethod.get,
        path: '/users/online',
        apiName: _apiName,
      );

      final response = await Amplify.API.get(request).response;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.decodeBody());
        return data.map((json) => ForumUser.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load online users: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error getting online users: $e');
      return [];
    }
  }

  Future<ForumUser?> getUser(String userId) async {
    try {
      final request = RESTRequest(
        method: RESTMethod.get,
        path: '/users/$userId',
        apiName: _apiName,
      );

      final response = await Amplify.API.get(request).response;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.decodeBody());
        return ForumUser.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      final statusData = {
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
      };

      final request = RESTRequest(
        method: RESTMethod.put,
        path: '/users/$userId/status',
        body: HttpPayload.json(statusData),
        apiName: _apiName,
      );

      final response = await Amplify.API.put(request).response;

      if (response.statusCode != 200) {
        throw Exception('Failed to update user status: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error updating user status: $e');
      rethrow;
    }
  }

  // Moderation functions
  Future<void> pinPost(String postId, bool pin) async {
    try {
      final pinData = {
        'isPinned': pin,
      };

      final request = RESTRequest(
        method: RESTMethod.put,
        path: '/posts/$postId/pin',
        body: HttpPayload.json(pinData),
        apiName: _apiName,
      );

      final response = await Amplify.API.put(request).response;

      if (response.statusCode != 200) {
        throw Exception('Failed to pin post: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error pinning post: $e');
      rethrow;
    }
  }

  Future<void> lockPost(String postId, bool lock) async {
    try {
      final lockData = {
        'isLocked': lock,
      };

      final request = RESTRequest(
        method: RESTMethod.put,
        path: '/posts/$postId/lock',
        body: HttpPayload.json(lockData),
        apiName: _apiName,
      );

      final response = await Amplify.API.put(request).response;

      if (response.statusCode != 200) {
        throw Exception('Failed to lock post: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error locking post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final request = RESTRequest(
        method: RESTMethod.delete,
        path: '/posts/$postId',
        apiName: _apiName,
      );

      final response = await Amplify.API.delete(request).response;

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error deleting post: $e');
      rethrow;
    }
  }
}