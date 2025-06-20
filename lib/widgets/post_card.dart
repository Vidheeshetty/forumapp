import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/forum_provider.dart';
import '../providers/auth_provider.dart';

class PostCard extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onTap;

  const PostCard({
    Key? key,
    required this.post,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with author and time
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      post.authorName.isNotEmpty
                          ? post.authorName[0].toUpperCase()
                          : 'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatTime(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (post.isPinned) ...[
                    Icon(
                      Icons.push_pin,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                  ],
                  if (post.isLocked)
                    Icon(
                      Icons.lock,
                      color: Colors.orange,
                      size: 20,
                    ),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.isModerator) {
                        return PopupMenuButton<String>(
                          onSelected: (value) => _handleModeratorAction(context, value),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'pin',
                              child: Row(
                                children: [
                                  Icon(post.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                                  SizedBox(width: 8),
                                  Text(post.isPinned ? 'Unpin' : 'Pin'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'lock',
                              child: Row(
                                children: [
                                  Icon(post.isLocked ? Icons.lock_open : Icons.lock),
                                  SizedBox(width: 8),
                                  Text(post.isLocked ? 'Unlock' : 'Lock'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Title
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              // Content preview
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),

              // Tags
              if (post.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: post.tags.map((tag) => Chip(
                    label: Text(
                      tag,
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                    side: BorderSide(color: Colors.deepPurple.withOpacity(0.3)),
                  )).toList(),
                ),

              SizedBox(height: 12),

              // Actions row
              Row(
                children: [
                  _VoteButton(
                    icon: Icons.keyboard_arrow_up,
                    count: post.upvotes,
                    isActive: false, // TODO: Check if user voted
                    onPressed: () {
                      context.read<ForumProvider>().votePost(post.id, true);
                    },
                  ),
                  SizedBox(width: 16),
                  _VoteButton(
                    icon: Icons.keyboard_arrow_down,
                    count: post.downvotes,
                    isActive: false, // TODO: Check if user voted
                    onPressed: () {
                      context.read<ForumProvider>().votePost(post.id, false);
                    },
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${post.commentCount}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleModeratorAction(BuildContext context, String action) {
    final forumProvider = context.read<ForumProvider>();

    switch (action) {
      case 'pin':
        forumProvider.pinPost(post.id, !post.isPinned);
        break;
      case 'lock':
        forumProvider.lockPost(post.id, !post.isLocked);
        break;
      case 'delete':
        _showDeleteDialog(context, forumProvider);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context, ForumProvider forumProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              forumProvider.deletePost(post.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final VoidCallback onPressed;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.deepPurple : Colors.grey[600],
            ),
            SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: isActive ? Colors.deepPurple : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}