import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:bloom/form.dart';
import 'package:bloom/model/user.dart';
import 'package:bloom/utils/colors.dart';
import 'package:bloom/utils/custom_headers.dart';
import 'package:bloom/utils/reusable_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vibration/vibration.dart';

class GetVerifiedScreen extends StatefulWidget {
  const GetVerifiedScreen({super.key});

  @override
  _GetVerifiedScreenState createState() => _GetVerifiedScreenState();
}

class _GetVerifiedScreenState extends State<GetVerifiedScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _motivation;
  String? _pastExperience;
  PlatformFile? _cvFile;
  late String _uid;
  final _box = GetStorage();
  UserModel? userData;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    final box = GetStorage();

    final userDataMap = box.read('userData') as Map<String, dynamic>?;

    userData = userDataMap != null ? UserModel.fromMap(userDataMap) : null;

    _uid = userData?.uid ?? 'user@example.com';
  }

  Future<void> _pickCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: false,
    );

    if (result != null) {
      setState(() {
        _cvFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadCV(File file) async {
    try {
      final storage = FirebaseStorage.instance;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          file.path.split('/').last;
      final ref = storage.ref().child('cv_files/$fileName');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload CV: $e')),
      );
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _audioPlayer.setSource(AssetSource('success.mp3'));
      _audioPlayer.resume(); // Play the sound
      if (await Vibration.hasVibrator() != null) {
        Vibration.vibrate(duration: 500);
      }
      try {
        String? cvUrl;
        if (_cvFile != null) {
          final file = File(_cvFile!.path!);
          cvUrl = await _uploadCV(file);
        }

        final firestore = FirebaseFirestore.instance;
        final verificationCollection = firestore.collection('verification');
        final box = GetStorage();
        final uid = _uid;

        await verificationCollection.add({
          'uid': uid,
          'motivation': _motivation,
          'pastExperience': _pastExperience,
          'cvUrl': cvUrl,
          'cvFileName': _cvFile?.name,
          'status': 'pending'
        });

        final usersCollection = firestore.collection('users');
        final userDoc = usersCollection.doc(uid);

        await userDoc.update({
          'isVerified': 'Pending',
        });

        box.write('isVerified', 'Pending');
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return CustomSplash(
            image: "assets/images/phone.svg",
            title: "Verification Request Submitted!",
            subTitle: "Next Steps: Stay Tuned for Updates",
            buttonName: "Next",
            nextPath: "/home",
          );
        }));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification request submitted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Verified'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userData!.role == "Mentor")
                      CustomHeaders(
                          context: context,
                          Header:
                              "What inspires you to volunteer or become a mentor?*")
                    else if (userData!.role == "Learner")
                      CustomHeaders(
                          context: context,
                          Header: "What motivates you to seek mentorship?*")
                    else
                      CustomHeaders(
                          context: context,
                          Header:
                              "How does this venue sponsoring aligns with your organization’s mission and values?*"),
                    const SizedBox(height: 5),
                    TextFormField(
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Start typing here...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your response';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _motivation = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (userData!.role == "Mentor")
                      CustomHeaders(
                          context: context,
                          Header:
                              "Can you share a meaningful experience from your past mentoring?*")
                    else if (userData!.role == "Learner")
                      CustomHeaders(
                          context: context,
                          Header:
                              "What specific outcomes do you hope to achieve by attending the events?*")
                    else
                      CustomHeaders(
                          context: context,
                          Header:
                              "Share past sponsorship experiences that made a meaningful impact*"),
                    const SizedBox(height: 5),
                    TextFormField(
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Start typing here..."',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your response';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _pastExperience = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomHeaders(
                        context: context, Header: "CV (PDF/Word document)"),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickCV,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _cvFile == null
                            ? Text(
                                'Tap to select your CV',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: Colors.black,
                                    ),
                              )
                            : Text(
                                'Selected CV: ${_cvFile!.name}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: Colors.black,
                                    ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 47),
              child: GestureDetector(
                  onTap: _submitForm,
                  child: CustomButton(name: "Submit", color: orange)),
            ),
          )
        ],
      ),
    );
  }
}
