import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forum_provider.dart';
import '../models/models.dart';

class OnlineUsersWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ForumProvider>(
      builder: (context, forumProvider, child) {
        final onlineUsers = forumProvider.onlineUsers;

        if (onlineUsers.isEmpty) {
          return SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: Colors.green,
                    size: 12,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${onlineUsers.length} users online',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: onlineUsers.length,
                  itemBuilder: (context, index) {
                    final user = onlineUsers[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: _UserAvatar(user: user),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final ForumUser user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: user.username,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.deepPurple,
            child: Text(
              user.username.isNotEmpty
                  ? user.username[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (user.isModerator)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Icon(
                  Icons.star,
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}