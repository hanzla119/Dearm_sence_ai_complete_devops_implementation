import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();

  // Open comments bottom sheet
  void _openComments(String postId) {
    final TextEditingController commentController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A211D),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _communityService.getCommentsStream(postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF20D284)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No comments yet. Start the conversation!',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        );
                      }
                      final comments = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final commentDoc = comments[index];
                          final comment = commentDoc.data() as Map<String, dynamic>;
                          final String commentId = commentDoc.id;
                          final String author = comment['userName'] ?? comment['userEmail'] ?? 'Anonymous';
                          final String text = comment['text'] ?? '';
                          
                          final Timestamp? commentTime = comment['createdAt'] as Timestamp?;
                          final String commentTimeStr = commentTime != null ? timeago.format(commentTime.toDate()) : 'just now';
                          
                          final bool isCommentAuthor = currentUser != null && comment['userId'] == currentUser.uid;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF20D284).withOpacity(0.1),
                                  radius: 18,
                                  backgroundImage: comment['photoUrl'] != null && comment['photoUrl'].toString().isNotEmpty
                                      ? NetworkImage(comment['photoUrl'])
                                      : null,
                                  child: comment['photoUrl'] == null || comment['photoUrl'].toString().isEmpty
                                      ? Text(
                                          author.isNotEmpty ? author[0].toUpperCase() : 'G',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF20D284),
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              author,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF1A211D),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            commentTimeStr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          if (isCommentAuthor) ...[
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () async {
                                                await _communityService.deleteComment(postId, commentId);
                                              },
                                              child: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 16,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: const Color(0xFF1A211D).withOpacity(0.8),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            final text = commentController.text.trim();
                            if (text.isNotEmpty) {
                              commentController.clear();
                              await _communityService.addComment(postId, text);
                            }
                          },
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF20D284)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Edit a post with dialog input
  void _showEditPostDialog(String postId, String initialContent) {
    final TextEditingController editController = TextEditingController(text: initialContent);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Post'),
          content: TextField(
            controller: editController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Edit your post...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20D284)),
              onPressed: () async {
                final newText = editController.text.trim();
                if (newText.isNotEmpty) {
                  // Safety check even on edit
                  final lowerContent = newText.toLowerCase();
                  final forbiddenWords = ['toothpaste', 'lemon', 'baking soda', 'bleach'];
                  final containsForbidden = forbiddenWords.any((word) => lowerContent.contains(word));

                  if (containsForbidden) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post rejected because it contains unsafe skincare advice.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await _communityService.editPost(postId, newText);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Delete a post with confirmation
  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _communityService.deletePost(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
          );
        }
      }
    }
  }

  // Share post content natively
  void _sharePost(String content) {
    Share.share(content, subject: 'Shared from DermaSense AI');
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF20D284);
    const bgColor = Color(0xFFF9FCFA);
    const textColor = Color(0xFF1A211D);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('GlowGang Community', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _communityService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_rounded, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    "No posts yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text("Be the first one to post!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final posts = snapshot.data!.docs;

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postDoc = posts[index];
                final post = postDoc.data() as Map<String, dynamic>;
                final String postId = postDoc.id;
                final String authorName = post['userName'] ?? post['userEmail'] ?? 'GlowGang Member';
                final String content = post['content'] ?? '';
                final List<dynamic> likedBy = post['likedBy'] ?? [];
                final int likesCount = post['likesCount'] ?? likedBy.length;
                final bool isLiked = currentUser != null && likedBy.contains(currentUser.uid);
                final bool isAuthor = currentUser != null && post['userId'] == currentUser.uid;

                final Timestamp? postTime = post['createdAt'] as Timestamp?;
                final String postTimeStr = postTime != null ? timeago.format(postTime.toDate()) : 'just now';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.black.withOpacity(0.04)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primaryColor.withOpacity(0.1),
                              backgroundImage: post['photoUrl'] != null && post['photoUrl'].toString().isNotEmpty
                                  ? NetworkImage(post['photoUrl'])
                                  : null,
                              child: post['photoUrl'] == null || post['photoUrl'].toString().isEmpty
                                  ? Text(
                                      authorName.isNotEmpty ? authorName[0].toUpperCase() : 'G',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authorName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    postTimeStr,
                                    style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.4)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          content,
                          style: TextStyle(fontSize: 15, color: textColor.withOpacity(0.8), height: 1.4),
                        ),
                        const Divider(height: 24),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              // Likes
                              InkWell(
                                onTap: () => _communityService.toggleLike(postId, likedBy),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: isLiked ? Colors.red : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$likesCount',
                                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Comments
                              TextButton.icon(
                                onPressed: () => _openComments(postId),
                                icon: const Icon(Icons.comment_outlined, size: 20, color: Colors.grey),
                                label: const Text('Comment', style: TextStyle(color: Colors.grey)),
                              ),
                              // Share
                              TextButton.icon(
                                onPressed: () => _sharePost(content),
                                icon: const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
                                label: const Text('Share', style: TextStyle(color: Colors.grey)),
                              ),
                              const SizedBox(width: 16),
                              // Conditional Edit/Delete Post
                              if (isAuthor) ...[
                                IconButton(
                                  onPressed: () => _showEditPostDialog(postId, content),
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: () => _deletePost(postId),
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: currentUser == null ? null : () async {
          final posted = await Navigator.pushNamed(context, '/create-post');
          if (posted == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post added to community'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
