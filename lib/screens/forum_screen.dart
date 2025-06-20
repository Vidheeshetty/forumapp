import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forum_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/online_users_widget.dart';
import '../widgets/search_filter_widget.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'auth_screen.dart';

class ForumScreen extends StatefulWidget {
  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumProvider>().loadPosts();
      context.read<ForumProvider>().loadOnlineUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          return AuthScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Community Forum'),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  context.read<ForumProvider>().loadPosts();
                  context.read<ForumProvider>().loadOnlineUsers();
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    authProvider.signOut();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: Icon(Icons.trending_up), text: 'Trending'),
                Tab(icon: Icon(Icons.access_time), text: 'Recent'),
                Tab(icon: Icon(Icons.people), text: 'Following'),
              ],
            ),
          ),
          body: Column(
            children: [
              SearchFilterWidget(),
              OnlineUsersWidget(),
              Expanded(
                child: Consumer<ForumProvider>(
                  builder: (context, forumProvider, child) {
                    if (forumProvider.isLoading) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final posts = forumProvider.filteredPosts;

                    if (posts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No posts found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to start a discussion!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => forumProvider.loadPosts(),
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return PostCard(
                            post: post,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(post: post),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePostScreen(),
                ),
              ).then((_) {
                context.read<ForumProvider>().loadPosts();
              });
            },
            child: Icon(Icons.add),
            backgroundColor: Colors.deepPurple,
          ),
        );
      },
    );
  }
}