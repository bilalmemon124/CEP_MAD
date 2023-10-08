import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final Map<String, dynamic> participants;
  List<Map<String, dynamic>> messages = [];

  Chat({
    required this.id,
    required this.participants,
    required this.messages,
  });

  Map<String, dynamic>? getOtherUser(String currentUid) {
    for (var id in participants.keys) {
      if (id != currentUid) {
        participants[id]["id"] = id;
        return participants[id];
      }
    }
  }
}
