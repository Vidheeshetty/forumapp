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

  Future<ForumPost?> createPost({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
  }) async {
    try {
      final postData = {
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
      };

      final request = RESTRequest(
        method: RESTMethod.post,
        path: '/posts',
        body: HttpPayload.json(postData),
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
      return null;
    }
  }

  Future<List<Comment>> getComments(String postId) async {
    try {
      final request = RESTRequest(
        method: RESTMethod.get,
        path: '/comments',
        queryParameters: {'postId': postId},
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

  Future<Comment?> createComment({
    required String postId,
    required String content,
    required String authorId,
    required String authorName,
  }) async {
    try {
      final commentData = {
        'postId': postId,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
      };

      final request = RESTRequest(
        method: RESTMethod.post,
        path: '/comments',
        body: HttpPayload.json(commentData),
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
      return null;
    }
  }
}