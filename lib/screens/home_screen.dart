import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_x/utils/info_box.dart';

import '../models/chat.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Chat> chatList = [];
  late StreamSubscription<DocumentSnapshot> _userChatsSubscription;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // initChatList();
    listenToUserChats();
  }

  @override
  void dispose() {
    _userChatsSubscription.cancel();
    super.dispose();
  }

  Future<void> initChatList() async {
    CollectionReference chatCollection =
        FirebaseFirestore.instance.collection('chats');
    QuerySnapshot chatSnapshot = await chatCollection.get();

    chatList.clear();

    for (var chatDoc in chatSnapshot.docs) {
      String chatId = chatDoc.id;
      Map<String, dynamic> participants = chatDoc['participants'];
      List<Map<String, dynamic>> messages = chatDoc['messages'];

      Chat chat = Chat(
        id: chatId,
        participants: participants,
        messages: messages,
      );

      chatList.add(chat);
    }

    setState(() {});
  }

  void listenToUserChats() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId);

    _userChatsSubscription = userDoc
        .snapshots()
        .listen((DocumentSnapshot<dynamic> userSnapshot) async {
      if (userSnapshot.exists) {
        List<dynamic> currentChats = userSnapshot.data()?['chats'] ?? [];

        chatList.clear();

        for (var chatId in currentChats) {
          DocumentSnapshot chatDoc = await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .get();

          Map<String, dynamic> participants = chatDoc['participants'];
          // List<String> participants = dynamicParticipants.cast();

          List<dynamic> dynamicMessages = chatDoc['messages'];
          List<Map<String, dynamic>> messages = dynamicMessages.cast();

          Chat chat = Chat(
            id: chatId,
            participants: participants,
            messages: messages,
          );

          setState(
            () {
              chatList.add(chat);
            },
          );
        }
      }
    });
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String email = ''; // Initialize an empty email string

        return AlertDialog(
          title: const Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _emailController,
                onChanged: (value) {
                  email = value; // Update the email when the text field changes
                },
                decoration: const InputDecoration(labelText: 'Enter Email'),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _validateEmail(context); // Validate the entered email
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  void _validateEmail(BuildContext context) async {
    final String email = _emailController.text;
    final bool userExists = await _verifyUserByEmail(email);

    if (userExists) {
      // User with this email exists, you can create a chat here
      _createChat();
      Navigator.pop(context);
    } else {
      // User with this email does not exist, show an error message
      InfoBox('User with email $email does not exist.',
          context: context, infoCategory: InfoCategory.error);
    }
  }

  Future<bool> _verifyUserByEmail(String email) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (error) {
      print('Error verifying user by email: $error');
      return false;
    }
  }

  Future<void> _createChat() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;

    if (currentUser != null) {
      final String currentUserId = currentUser.uid;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Query for the other user's document based on their email
      final QuerySnapshot otherUserQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: _emailController.text)
          .limit(1)
          .get();

      if (otherUserQuery.docs.isNotEmpty) {
        final DocumentSnapshot otherUserDoc = otherUserQuery.docs.first;
        final String otherUserId = otherUserDoc.id;

        // Create a new chat document
        final DocumentReference chatDocRef =
            firestore.collection('chats').doc();

        final currentUserImage =
            (await firestore.collection("users").doc(currentUserId).get())
                .get("profileImage");

        // Set initial chat data
        await chatDocRef.set({
          'participants': {
            currentUserId: {
              "name": currentUser.displayName,
              "profileImage": currentUserImage,
            },
            otherUserId: {
              "name": otherUserDoc["name"],
              "profileImage": otherUserDoc["profileImage"],
            },
          },
          'messages': [],
        });

        // Get the chat document ID
        final String chatId = chatDocRef.id;

        // Update the chats field for the current user
        final DocumentReference userDocRef =
            firestore.collection('users').doc(currentUserId);
        await userDocRef.update({
          'chats': FieldValue.arrayUnion([chatId]),
        });

        // Update the chats field for the other user
        final DocumentReference otherUserDocRef =
            firestore.collection('users').doc(otherUserId);
        await otherUserDocRef.update({
          'chats': FieldValue.arrayUnion([chatId]),
        });

        // Show a success message
        InfoBox('Chat created successfully',
            context: context, infoCategory: InfoCategory.success);
      } else {
        // Show an error message if the other user's email is not found
        InfoBox('User with email ${_emailController.text} not found',
            context: context, infoCategory: InfoCategory.error);
      }
    } else {
      // Show an error message if the current user is not authenticated
      InfoBox('User not authenticated',
          context: context, infoCategory: InfoCategory.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ShareX',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: chatList.isEmpty
          ? const Center(
              child: Text(
                'No chats yet.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: chatList.length,
              itemBuilder: (context, index) {
                final chat = chatList[index];

                Map<String, dynamic> otherUser =
                    chat.getOtherUser(FirebaseAuth.instance.currentUser!.uid)!;

                return ListTile(
                  leading: GestureDetector(
                    onTap: () async {
                      if (otherUser["profileImage"] == null) return;
                      await showDialog(
                        context: context,
                        builder: (ctx) {
                          return Dialog(
                            backgroundColor: Colors.black,
                            child: Container(
                              width: MediaQuery.of(context).size.width - 50,
                              height: MediaQuery.of(context).size.width - 50,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                    image:
                                        NetworkImage(otherUser["profileImage"]),
                                    fit: BoxFit.contain),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(otherUser["profileImage"]),
                    ),
                  ),
                  title: Text(otherUser["name"]),
                  subtitle: chat.messages.isNotEmpty
                      ? Text(chat.messages.last["text"])
                      : const Text(""),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatScreen(chat: chat, otherUser: otherUser),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddUserDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
