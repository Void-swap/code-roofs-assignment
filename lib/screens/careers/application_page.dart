import 'package:audioplayers/audioplayers.dart';
import 'package:bloom/form.dart';
import 'package:bloom/model/user.dart';
import 'package:bloom/screens/events/create_event.dart';
import 'package:bloom/utils/colors.dart';
import 'package:bloom/utils/reusable_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vibration/vibration.dart';

class ApplicationPage extends StatefulWidget {
  final String jobId;

  ApplicationPage({required this.jobId});

  @override
  _ApplicationPageState createState() => _ApplicationPageState();
}

class _ApplicationPageState extends State<ApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  String? message;
  String? filePath;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Use AudioCache for assets

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        filePath = result.files.single.path; // Store the file path
      });
    }
  }

  Future<void> applyForJob(
      String jobId, String userId, String message, String? filePath) async {
    if (jobId.isEmpty) {
      throw Exception("Job ID must not be empty");
    }

    final application = {
      'userId': userId,
      'message': message,
      'filePath': filePath,
      'appliedOn': Timestamp.now(),
      'status': "pending"
    };

    await FirebaseFirestore.instance.collection('careers').doc(jobId).update({
      'applications': FieldValue.arrayUnion([application]),
    });
  }

  Future<void> _applyForJob() async {
    final GetStorage _box = GetStorage();
    final userDataMap = _box.read('userData') as Map<String, dynamic>?;
    final userData =
        userDataMap != null ? UserModel.fromMap(userDataMap) : null;
    if (_formKey.currentState!.validate()) {
      if (message == null || message!.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Please enter a message")));
        return;
      }
      try {
        print("Applying for job with ID: ${widget.jobId}");
        await applyForJob(widget.jobId, userData!.uid, message!, filePath);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Application submitted!")));
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return CustomSplash(
            image: "assets/images/499.svg",
            title: "Hooray! Your Application is in the Queue",
            subTitle:
                "Thank you for your patience as we evaluate your submission",
            buttonName: "Apply for more listing",
            nextPath: "/home",
          );
        }));
        await _audioPlayer.setSource(AssetSource('success.mp3'));
        _audioPlayer.resume(); // Play the sound
        if (await Vibration.hasVibrator() != null) {
          Vibration.vibrate(duration: 500);
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Apply for Job")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomHeaders(context: context, Header: "Additinal Info*"),
                TextFormField(
                  maxLines: 9,
                  decoration: InputDecoration(
                    hintText:
                        "What additional information would you like to provide?\n\nWe recommend adding relevant projects links & giving a small write-up about why you are the right fit for this role",
                    hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          color: primaryBlack,
                        ),
                  ),
                  onChanged: (value) => message = value,
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a message" : null,
                ),
                SizedBox(height: 20),
                CustomHeaders(
                    context: context, Header: "Resume (PDF/Word document)"),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: filePath == null
                        ? Text(
                            'Tap to select your resume',
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: Colors.black,
                                    ),
                          )
                        : Text(
                            'Selected resume: ${filePath}',
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: Colors.black,
                                    ),
                          ),
                  ),
                ),
                SizedBox(height: 30),
                Center(
                  child: GestureDetector(
                    onTap: _applyForJob,
                    child: CustomButton(
                      name: "Submit application",
                      color: orange,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
