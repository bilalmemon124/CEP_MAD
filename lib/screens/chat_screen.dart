import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_x/models/chat.dart';

// ignore: must_be_immutable
class ChatScreen extends StatefulWidget {
  Chat chat;
  Map<String, dynamic> otherUser;

  ChatScreen({Key? key, required this.chat, required this.otherUser})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? userId;
  TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  _initChat() async {
    userId = FirebaseAuth.instance.currentUser!.uid;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.otherUser["name"],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chat.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chatData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final messages = chatData['messages'] as List<dynamic>;

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageText = messages[index]['text'] as String;
                      final messageSender = messages[index]['sender'] as String;

                      // // Scroll to the bottom when new messages are added
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      });

                      return Align(
                        alignment: messageSender == userId
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: messageSender == userId
                                ? Colors.pink[200]
                                : Colors.purple[200],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            messageText,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.deepPurple.shade400,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.deepPurple.shade400,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                hintText: 'Type Message',
                suffixIcon: IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void sendMessage() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Get the reference to the chat document
    final DocumentReference chatDocRef =
        firestore.collection('chats').doc(widget.chat.id);

    // Get the current user's ID
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    // Create a new message map
    final Map<String, dynamic> newMessage = {
      'text': messageController.text,
      'sender': userId,
    };

    messageController.clear();

    // Update the chat document's messages array with the new message
    await chatDocRef.update({
      'messages': FieldValue.arrayUnion([newMessage]),
    });
  }
}
