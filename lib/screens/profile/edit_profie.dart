import 'dart:convert';
import 'dart:io';

import 'package:bloom/model/user.dart';
import 'package:bloom/register_login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userData;

  const EditProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _description = TextEditingController();
  final _addressController = TextEditingController();
  final _contactsController = TextEditingController();
  final _emailController = TextEditingController();
  final _socialMediaLinksController = TextEditingController();
  final _interestsController = TextEditingController();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  String? _profilePicUrl;
  final List<String> availableInterests = [
    "Technology",
    "Finance",
    "Healthcare",
    "Engineering",
    "Entertainment",
    "Education",
    "Environment",
    "Social",
    "Lifestyle",
    "Law",
    "Agriculture",
    "Marketing",
    "Arts",
    "Design",
    "Hospitality",
    "Soft Skills"
  ];

  List<String> selectedInterests = [];

  String searchQuery = '';
  void _showInterestsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Interests'), // Search field
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Interests',
                      prefixIcon: Icon(IconlyBroken.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListBody(
                      children: availableInterests
                          .where((interest) =>
                              interest.toLowerCase().contains(searchQuery))
                          .map((interest) {
                        return CheckboxListTile(
                          title: Text(interest),
                          value: selectedInterests.contains(interest),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedInterests.add(interest);
                              } else {
                                selectedInterests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _interestsController.text = selectedInterests.join(', ');
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateDescription() async {
    String inputText = _description.text.trim();

    if (inputText.isNotEmpty) {
      try {
        String generatedText = await generateFeedbackWithAI(inputText);
        setState(() {
          _description.text = generatedText;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Hold on! It looks like your description field is empty'),
        ),
      );
    }
  }

  Future<String> generateFeedbackWithAI(String inputText) async {
    const String apiKey = 'AIzaSyDT_p6t2MjZhrfNocqQri2ovGPeqrV_n08';
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

    String modifiedInput =
        "Elaborate on the following statement with enthusiasm, using an active voice and an assertive tone: '$inputText'. Avoid adding any extra text or questions.";

    final response = await http.post(
      Uri.parse('$apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': modifiedInput}
            ]
          }
        ]
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print('Decoded response: $responseBody');

      if (responseBody.containsKey('candidates') &&
          responseBody['candidates'].isNotEmpty &&
          responseBody['candidates'][0].containsKey('content') &&
          responseBody['candidates'][0]['content']['parts'].isNotEmpty) {
        return responseBody['candidates'][0]['content']['parts'][0]['text'] ??
            'No content returned';
      } else {
        throw Exception('Expected content structure not found in response');
      }
    } else {
      throw Exception('Failed to generate feedback: ${response.body}');
    }
  }

  // Future<String> generateFeedbackWithAI(String inputText) async {

  //   String modifiedInput =
  //       "Elaborate on the following statement with enthusiasm, using an active voice and an assertive tone: '$inputText'. Avoid adding any extra text or questions.";

  //   final String groqApiUrl =
  //       'https://api.groq.com/openai/v1/chat/completions'; // Assume this is the correct endpoint

  //   final response = await http.post(
  //     Uri.parse(groqApiUrl),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization':
  //           'Bearer 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', // Add your actual API key here
  //     },
  //     body: jsonEncode({
  //       'model': 'llama-3.1-70b-versatile',
  //       'messages': [
  //         {
  //           'role': 'user',
  //           'content': modifiedInput,
  //         }
  //       ],
  //       'temperature': 1,
  //       'max_tokens': 1024,
  //       'top_p': 1,
  //       'stream': false, // Keeping it simple without streaming
  //     }),
  //   );

  //   print('Response status: ${response.statusCode}');
  //   print('Response body: ${response.body}');

  //   if (response.statusCode == 200) {
  //     final responseBody = jsonDecode(response.body);
  //     print('Decoded response: $responseBody');

  //     if (responseBody.containsKey('choices') &&
  //         responseBody['choices'].isNotEmpty &&
  //         responseBody['choices'][0].containsKey('message') &&
  //         responseBody['choices'][0]['message'].containsKey('content')) {
  //       return responseBody['choices'][0]['message']['content'] ??
  //           'No content returned';
  //     } else {
  //       throw Exception('Expected content structure not found in response');
  //     }
  //   } else {
  //     throw Exception('Failed to generate feedback: ${response.body}');
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData.name;
    _description.text = widget.userData.description;
    _addressController.text = widget.userData.address;
    _contactsController.text = widget.userData.contacts;
    _emailController.text = widget.userData.email;
    _socialMediaLinksController.text = widget.userData.socialMediaLinks;
    _interestsController.text = widget.userData.interests.join(', ');
    _profilePicUrl = widget.userData.profilePic;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });

      final file = File(_image!.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profilePic/${DateTime.now().millisecondsSinceEpoch}');
      // Create metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=3600',
      );

      final uploadTask = await storageRef.putFile(File(file.path), metadata);

      try {
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          _profilePicUrl = downloadUrl;
        });
      } catch (e) {
        print('Failed to upload image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Future<void> _uploadImages() async {
  //   try {
  //     List<String> urls = [];
  //     for (var image in _images) {
  //       final fileName = DateTime.now().millisecondsSinceEpoch.toString();
  //       final storageRef =
  //           FirebaseStorage.instance.ref().child('eventImages').child(fileName);

  //       final imageUrl = await storageRef.getDownloadURL();
  //       urls.add(imageUrl);
  //     }

  //     setState(() {
  //       _imageUrls.clear();
  //       _imageUrls.addAll(urls);
  //     });
  //   } catch (e) {
  //     _showError('Error uploading images: $e');
  //   }
  // }

  Future<void> _saveProfile() async {
    final updatedUserData = UserModel(
      uid: widget.userData.uid,
      description: _description.text,
      profilePic: _profilePicUrl ?? widget.userData.profilePic,
      name: _nameController.text,
      address: _addressController.text,
      contacts: _contactsController.text,
      email: _emailController.text,
      isVerified: widget.userData.isVerified,
      socialMediaLinks: _socialMediaLinksController.text,
      interests: _interestsController.text.split(', ').toList(),
      role: widget.userData.role,
      attendedEvents: widget.userData.attendedEvents,
      badges: widget.userData.badges,
      foundedOn: widget.userData.foundedOn,
    );

    try {
      final box = GetStorage();
      box.write('userData', updatedUserData.toMap());

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(updatedUserData.uid);
      await userDoc.update(updatedUserData.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Failed to update profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(
              IconlyBroken.logout,
            ),
            onPressed: () {
              final GetStorage box = GetStorage();
              box.erase();
              FirebaseAuth.instance.signOut();

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterLogin()),
              );
            },
          ),
          IconButton(
            tooltip: "Save",
            icon: Icon(IconlyBroken.tick_square),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Hero(
                  tag: "ProfilePic",
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_profilePicUrl == null || _profilePicUrl!.isEmpty)
                        Shimmer.fromColors(
                          baseColor: Colors.grey[500]!,
                          highlightColor: Colors.grey[100]!,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey,
                          ),
                        )
                      else
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(0, 4),
                              ),
                            ],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                            image: DecorationImage(
                              image: NetworkImage(_profilePicUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_profilePicUrl == null || _profilePicUrl!.isEmpty)
                        Positioned.fill(
                          child: Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey,
                              child:
                                  Icon(IconlyBold.camera, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: 'Name', prefixIcon: Icon(IconlyBold.profile)),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _description,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'description',
                  prefixIcon: Icon(IconlyBold.star),
                  suffixIcon: GestureDetector(
                    onTap: _generateDescription,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        "assets/images/ai.png",
                        fit: BoxFit.contain,
                        height: 16,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(IconlyBold.location)),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _contactsController,
                decoration: InputDecoration(
                    labelText: 'Contacts', prefixIcon: Icon(IconlyBold.call)),
              ),
              SizedBox(height: 20),
              TextField(
                readOnly: true,
                controller: _emailController,
                decoration: InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(IconlyBold.message)),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _socialMediaLinksController,
                decoration: InputDecoration(
                    labelText: 'Social Media Link',
                    prefixIcon: Icon(IconlyBold.chat)),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _showInterestsDialog,
                child: AbsorbPointer(
                  child: TextField(
                    controller: _interestsController,
                    decoration: InputDecoration(
                      labelText: 'Interests',
                      prefixIcon: Icon(IconlyBold.star),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
