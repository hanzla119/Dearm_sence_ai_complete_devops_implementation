import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createPost(String content) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection('posts').add({
      'content': content,
      'userId': user.uid,
      'userEmail': user.email ?? 'Anonymous Glower',
      'userName': user.displayName ?? user.email ?? 'Anonymous',
      'likedBy': [],
      'likesCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  Future<void> toggleLike(String postId, List likedBy) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore.collection('posts').doc(postId);

    if (likedBy.contains(user.uid)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([user.uid]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([user.uid]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> addComment(String postId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'text': text,
      'userId': user.uid,
      'userEmail': user.email ?? 'Anonymous Glower',
      'userName': user.displayName ?? user.email ?? 'Anonymous',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<void> editPost(String postId, String content) async {
    await _firestore.collection('posts').doc(postId).update({
      'content': content,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }
}
