import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_x/screens/home_screen.dart';

import '../utils/info_box.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  File? _image;
  String? _imageUrl;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sign Up",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Form(
                  key: _formkey,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _uploadProfilePicture,
                        child: _image != null
                            ? CircleAvatar(
                                backgroundImage: FileImage(_image!),
                                radius: 50,
                              )
                            : const CircleAvatar(
                                radius: 50,
                                child: Icon(Icons.add_a_photo),
                              ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                            hintText: 'Enter Username',
                            prefixIcon: Icon(Icons.person)),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Username required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                        decoration: const InputDecoration(
                            hintText: 'Enter Email',
                            prefixIcon: Icon(Icons.alternate_email)),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Email required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        obscureText: true,
                        controller: passwordController,
                        decoration: const InputDecoration(
                            hintText: 'Enter Password',
                            prefixIcon: Icon(Icons.lock)),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Password required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () {
                    if (_formkey.currentState!.validate()) {
                      _signUp();
                    }
                  },
                  child: const Text('Sign Up'),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initUser(User user) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final CollectionReference usersCollection = firestore.collection('users');

      final Map<String, dynamic> userData = {
        'name': usernameController.text,
        'email': emailController.text,
        'profileImage': _imageUrl,
      };

      await usersCollection.doc(user.uid).set(userData);

      // Show a success message
      InfoBox('User data initialized successfully',
          context: context, infoCategory: InfoCategory.success);

      // Navigate to the HomeScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } catch (error) {
      // Show an error message
      InfoBox('Error initializing user data: $error',
          context: context, infoCategory: InfoCategory.error);
    }
  }

  Future<void> _signUp() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final UserCredential userCredential =
          await auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // Update user's display name
        await user.updateDisplayName(usernameController.text);

        // Upload user's profile picture if an image was selected
        if (_image != null) {
          await _uploadProfilePictureToStorage(user.uid);
        }

        // Initialize user data in Firestore
        await _initUser(user);
      } else {
        print('Failed to create user account.');
      }
    } catch (error) {
      // Show an error message
      InfoBox('Error signing up: $error',
          context: context, infoCategory: InfoCategory.error);
    }
  }

  Future<void> _uploadProfilePictureToStorage(String userId) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final Reference storageRef =
          storage.ref().child('profile_pictures/$userId.png');

      final UploadTask uploadTask = storageRef.putFile(_image!);

      final TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() {});
      final String imageUrl = await storageSnapshot.ref.getDownloadURL();

      setState(() {
        _imageUrl = imageUrl;
      });

      print('Profile picture uploaded successfully');
    } catch (error) {
      // Show an error message
      print('Error uploading profile picture: $error');
    }
  }

  Future<void> _uploadProfilePicture() async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? image =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }
}
