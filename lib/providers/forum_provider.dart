import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ForumProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ForumPost> _posts = [];
  List<ForumUser> _onlineUsers = [];
  List<String> _availableTags = [];
  List<String> _selectedTags = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'recent'; // recent, popular, pinned

  List<ForumPost> get posts => _posts;
  List<ForumUser> get onlineUsers => _onlineUsers;
  List<String> get availableTags => _availableTags;
  List<String> get selectedTags => _selectedTags;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  List<ForumPost> get filteredPosts {
    var filtered = _posts.where((post) {
      bool matchesSearch = _searchQuery.isEmpty ||
          post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          post.content.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesTags = _selectedTags.isEmpty ||
          _selectedTags.every((tag) => post.tags.contains(tag));

      return matchesSearch && matchesTags;
    }).toList();

    // Sort posts
    switch (_sortBy) {
      case 'popular':
        filtered.sort((a, b) => (b.upvotes - b.downvotes).compareTo(a.upvotes - a.downvotes));
        break;
      case 'pinned':
        filtered.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      default: // recent
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  Future<void> loadPosts() async {
    try {
      _isLoading = true;
      notifyListeners();

      _posts = await _apiService.getPosts();
      await _loadAvailableTags();
    } catch (e) {
      print('Error loading posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOnlineUsers() async {
    try {
      _onlineUsers = await _apiService.getOnlineUsers();
      notifyListeners();
    } catch (e) {
      print('Error loading online users: $e');
    }
  }

  Future<void> _loadAvailableTags() async {
    Set<String> tags = {};
    for (var post in _posts) {
      tags.addAll(post.tags);
    }
    _availableTags = tags.toList()..sort();
  }

  Future<bool> createPost(String title, String content, List<String> tags) async {
    try {
      final post = await _apiService.createPost(title, content, tags);
      _posts.insert(0, post);
      await _loadAvailableTags();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }

  Future<void> votePost(String postId, bool isUpvote) async {
    try {
      await _apiService.votePost(postId, isUpvote);
      await loadPosts(); // Refresh to get updated votes
    } catch (e) {
      print('Error voting on post: $e');
    }
  }

  Future<List<Comment>> getPostComments(String postId) async {
    try {
      return await _apiService.getComments(postId);
    } catch (e) {
      print('Error loading comments: $e');
      return [];
    }
  }

  Future<bool> addComment(String postId, String content, String? parentId) async {
    try {
      await _apiService.addComment(postId, content, parentId);
      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  Future<void> voteComment(String commentId, bool isUpvote) async {
    try {
      await _apiService.voteComment(commentId, isUpvote);
    } catch (e) {
      print('Error voting on comment: $e');
    }
  }

  // Moderation functions
  Future<void> pinPost(String postId, bool pin) async {
    try {
      await _apiService.pinPost(postId, pin);
      await loadPosts();
    } catch (e) {
      print('Error pinning post: $e');
    }
  }

  Future<void> lockPost(String postId, bool lock) async {
    try {
      await _apiService.lockPost(postId, lock);
      await loadPosts();
    } catch (e) {
      print('Error locking post: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _apiService.deletePost(postId);
      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void toggleTagFilter(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  void clearTagFilters() {
    _selectedTags.clear();
    notifyListeners();
  }
}