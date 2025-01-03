import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:bloom/utils/colors.dart';
import 'package:bloom/utils/reusable_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String email;

  const RoleSelectionScreen({super.key, required this.email});

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Select Role'),
      // ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "I am a ...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryBlack,
                        letterSpacing: 5),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () {
                      _onRoleSelected('Individual');
                    },
                    child: Container(
                      height: 50,
                      width: 370,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        color: _selectedRole == 'Individual'
                            ? orange
                            : const Color(0xFFf2f2f2),
                      ),
                      child: Center(
                        child: Text(
                          "Individual",
                          style: TextStyle(
                            // fontFamily: "Poppins",
                            fontSize: 20,
                            fontWeight: _selectedRole == 'Individual'
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: _selectedRole == 'Individual'
                                ? primaryWhite
                                : primaryBlack,
                            height: 30 / 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      _onRoleSelected('Organization');
                    },
                    child: Container(
                      height: 50,
                      width: 370,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        color: _selectedRole == 'Organization'
                            ? orange
                            : const Color(0xFFf2f2f2),
                      ),
                      child: Center(
                        child: Text(
                          "Organization",
                          style: TextStyle(
                            // fontFamily: "Poppins",
                            fontSize: 20,
                            fontWeight: _selectedRole == 'Organization'
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedRole == 'Organization'
                                ? Colors.white
                                : const Color(0xff000000),
                            height: 30 / 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedRole != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 17,
                          ),
                          SizedBox(
                            width: 6,
                          ),
                          Text(
                            "You will not be able to change this later",
                            style: TextStyle(
                              // fontFamily: "Poppins",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0x9912121d),
                              height: 16 / 12,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FormScreen(
                                email: widget.email,
                                role: _selectedRole ?? "")),
                      ),
                      child: const CustomButton(
                        color: orange,
                        name: "Next",
                      ),
                    ),
                    const SizedBox(height: 47),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String name;
  final Color color;
  const CustomButton({
    super.key,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      // width: 109,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Make width as wide as text
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color == orange ? primaryWhite : primaryBlack,
                height: (24 / 16),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FormScreen extends StatefulWidget {
  final String email;
  final String role;

  FormScreen({super.key, required this.email, required this.role});

  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();
  late String name;
  late String selectedRole;
  late String contacts;

  String get storedEmail => box.read('userEmail') ?? "no mail";

  @override
  void initState() {
    super.initState();
    selectedRole = getRoleOptions().first;
  }

  List<String> getRoleOptions() {
    if (widget.role == 'Organization') {
      return ['Educational Institute', 'Corporation'];
    } else {
      return ['Mentor', 'Learner'];
    }
  }

  Future<File> getImageFileFromAssets(String imagePath) async {
    final byteData = await rootBundle.load(imagePath);

    final file = File(
        '${(await getTemporaryDirectory()).path}/${path.basename(imagePath)}');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  Future<bool> sendEmail() async {
    String username = 'swapnil.gdsc9@gmail.com';
    String password = 'jgcc huyb fomc tbay';

    final smtpServer = gmail(username, password);
    print("Started to send email");

    File imageFile = await getImageFileFromAssets('assets/images/433.png');
    File Ai = await getImageFileFromAssets('assets/images/ai.png');
    // File imageFile = await getImageFileFromAssets('assets/images/433.png');
    // File imageFile = await getImageFileFromAssets('assets/images/433.png');
    // File imageFile = await getImageFileFromAssets('assets/images/433.png');
    // Uncomment and initialize other images if needed
    // File theDevilWorks = await getImageFileFromAssets('assets/TheDevilWorks.png');
    // File circle = await getImageFileFromAssets('assets/welcomeMail/circle.png');
    // File section2 = await getImageFileFromAssets('assets/welcomeMail/section2.png');
    // File jumpRightIn = await getImageFileFromAssets('assets/welcomeMail/jumpRightIn.png');
    // File appStore = await getImageFileFromAssets('assets/welcomeMail/appStore.png');
    // File playStore = await getImageFileFromAssets('assets/welcomeMail/playStore.png');

    final message = Message()
      ..from = Address(username, 'BLOOM')
      ..recipients.add('dishaj644@gmail.com')
      ..subject = 'Welcome to BLOOM'
      ..html = '''
    <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 0;
            color: #333333;
        }

        .container {
            width: 100%;
            max-width: 600px;
            margin: 20px auto;
            background-color: #ffffff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }

        .header {
            background-color: #222;
            padding: 20px;
            text-align: center;
            color: #ffffff;
        }

        .header h1 {
            font-size: 28px;
            letter-spacing: 1px;
            margin: 0;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .header img.banner-image {
            width: auto;
            height: 100px;
            margin-left: 5px;
            vertical-align: middle;
        }

        .content {
            padding: 20px;
            line-height: 1.6;
        }

        .content h2 {
            color: #333;
            font-size: 24px;
            display: inline-block;
            vertical-align: middle;
            margin: 0;
        }

        .content img.logo {
            max-width: 60px;
            vertical-align: middle;
            margin-left: 10px;
        }

        .content p {
            color: #555;
            line-height: 1.8;
            font-size: 16px;
            margin-bottom: 16px;
        }

        .cta {
            margin-top: 20px;
            text-align: center;
        }

        .cta a {
            background-color: #fe7e05;
            color: #ffffff;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 6px;
            font-weight: bold;
            font-size: 16px;
            transition: background-color 0.3s ease;
        }

        .cta a:hover {
            background-color: #e67300;
        }

        .footer {
            background-color: #222;
            color: #ffffff;
            text-align: center;
            padding: 15px;
            font-size: 14px;
        }

        .footer p {
            margin: 0;
        }

        /* Responsive styles */
        @media (max-width: 600px) {
            .header h1 {
                font-size: 22px;
            }

            .content h2 {
                font-size: 20px;
            }

            .content img.logo {
                max-width: 30px;
            }

            .cta a {
                padding: 10px 20px;
                font-size: 14px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to <img src="https://i.ibb.co/bWDXxFx/IMG-2016.png" alt="BLOOM" class="banner-image"></h1>
        </div>

        <div class="content">
            <h2>Hi there!</h2>
            <img src="https://i.ibb.co/GxQYTtS/IMG-2003.png" alt="BLOOM Logo" class="logo">
            
            <p>Welcome to <b>Bloom</b>—we’re so excited to have you on board!</p>
            <p>Bloom is more than just an app. It’s a community where youth mentors, corporate partners, and eager learners come together to create skill-building events that make a real impact. Here’s how we do it, together with YOU</p>
           <p> <b>For Learners:</b> Bloom opens doors to practical skills and hands-on experiences. It’s learning beyond the classroom, where each child’s unique way of learning matters.</p>
            
           <p> <b>For Mentors:</b> You get to teach and share what you know while building your own skills and career path. Guiding others is one of the best ways to grow yourself!</P>
            
            <p> <b>For Venue Partners:</b> You’ll make your space a hub of positive change, helping the community while creating real social impact.</p>
            <br>
             <p>   Every event we create together is a chance to learn, connect, and bloom. 🌸 If you ever need help or just want to chat about ideas, we’re right here.</p>

             <p>Thanks for being part of something amazing!</p>
            <br>
             <p>With excitement,</p>
             <p>The Bloom Team</p>
            
            <div class="cta">
                <a href="#">Get Started with BLOOM</a>
            </div>
        </div>

        <div class="footer">
            <p>&copy; 2024 BLOOM. All rights reserved.</p>
        </div>
    </div>
</body>
</html>


    '''
      ..attachments = [
        FileAttachment(imageFile)
        //..location = Location.inline
        //..cid = 'image1@your-emails.com',FileAttachment(imageFile)
        //..location = Location.inline
        //..cid = 'image2@your-emails.com',FileAttachment(Ai)
        //..location = Location.inline
        //..cid = 'image3@your-emails.com',FileAttachment(imageFile)
        //..location = Location.inline
        //..cid = 'image41@your-emails.com',
        // Add other attachments here if needed
        // FileAttachment(theDevilWorks)
        //   ..location = Location.inline
        //   ..cid = 'image2@your-emails.com',
        // FileAttachment(circle)
        //   ..location = Location.inline
        //   ..cid = 'image3@your-emails.com',
        // FileAttachment(section2)
        //   ..location = Location.inline
        //   ..cid = 'image4@your-emails.com',
        // FileAttachment(jumpRightIn)
        //   ..location = Location.inline
        //   ..cid = 'image5@your-emails.com',
        // FileAttachment(appStore)
        //   ..location = Location.inline
        //   ..cid = 'image6@your-emails.com',
        // FileAttachment(playStore)
        //   ..location = Location.inline
        //   ..cid = 'image7@your-emails.com',
      ];

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      await send(message, smtpServer);
      print("Email Sent successfully");
      return true;
    } catch (e) {
      print('Message not sent. Error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('User Details Form'),
      // ),
      body: Material(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // SizedBox(),
                  Column(
                    children: [
                      const SizedBox(
                        height: 50,
                      ),
                      SvgPicture.asset(
                        'assets/svg/doodle.svg',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const Text(
                        "Let’s Get to Know You",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryBlack,
                        ),
                      ),
                      const Text(
                        "Every story is unique, let’s begin with yours.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          // fontWeight: FontWeight.bold,
                          color: primaryBlack,
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      TextFormField(
                        initialValue: storedEmail,
                        readOnly: true,
                        // ignore: unrelated_type_equality_checks
                        style: const TextStyle(color: primaryBlack),
                        cursorColor: Colors.amber,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: primaryBlack, width: 0.9),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: orange, width: 1.5),
                          ),
                          label: const Text(
                            "Email",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: primaryBlack,
                            ),
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Icon(
                              IconlyBold.message,
                              color: primaryBlack,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomTextFormField(
                        hintText: "Name",
                        icon: IconlyBold.profile,
                        onSaved: (value) => name = value ?? '',
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        items: getRoleOptions().map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(
                              role,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: primaryBlack,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value!;
                          });
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select a role'
                            : null,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: primaryBlack, width: 0.9),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: orange, width: 1.5),
                          ),
                          label: const Text(
                            "Role",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: primaryBlack,
                            ),
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Icon(
                              IconlyBold.star,
                              color: primaryBlack,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // CustomTextFormField(
                      //   hintText: "Contacts",
                      //   icon: IconlyBold.call,
                      //   onSaved: (value) => contacts = value ?? '',
                      //   validator: (value) =>
                      //       value!.isEmpty ? 'Please enter your contacts' : null,
                      // ),
                      Container(
                        padding: const EdgeInsets.only(
                          left: 10,
                        ),
                        child: InternationalPhoneNumberInput(
                          onInputChanged: (PhoneNumber number) {
                            String _phoneNumber = number.phoneNumber ?? '';
                            print("number is : ${_phoneNumber}");
                          },
                          selectorConfig: const SelectorConfig(
                              trailingSpace: false,
                              showFlags: true,
                              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                              leadingPadding: 0,
                              setSelectorButtonAsPrefixIcon: false),
                          ignoreBlank: false,
                          selectorTextStyle: const TextStyle(),
                          maxLength: 13,
                          onSaved: (value) {
                            contacts = value.toString();
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please Enter your Phone number";
                            } else if (value.length < 10) {
                              return "Phone number must be at least 10 digits";
                            }
                            return null;
                          },
                          inputDecoration: InputDecoration(
                            // contentPadding: const EdgeInsets.symmetric(
                            //     // horizontal: 0,
                            //     vertical: 8.0), // Reduced vertical padding

                            // enabledBorder: OutlineInputBorder(
                            //   borderRadius: BorderRadius.circular(8),
                            //   borderSide: const BorderSide(
                            //       color: primaryBlack, width: 0.9),
                            // ),
                            // focusedBorder: OutlineInputBorder(
                            //   borderRadius: BorderRadius.circular(8),
                            //   borderSide:
                            //       const BorderSide(color: orange, width: 1.5),
                            // ),
                            label: Text(
                              "Phone Number",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: primaryBlack,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();

                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('User not authenticated')),
                          );
                          return;
                        }
                        final uid = user.uid; // Use the user's UID
                        final userDoc = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid);

                        final userData = {
                          'uid': uid,
                          'profilePic': '',
                          'description': '',
                          'name': name,
                          'address': '',
                          'contacts': contacts,
                          'email': storedEmail,
                          'isVerified': "Not Applied",
                          'socialMediaLinks': '',
                          'interests': [],
                          'role': selectedRole,
                          'attendedEvents': [],
                          'badges': [],
                        };
                        if (selectedRole == 'Educational Institute' ||
                            selectedRole == 'Corporation') {
                          userData.addAll({
                            'listingCreated': [],
                            'venuesCreated': [],
                            'foundedOn': '',
                          });
                        }
                        sendEmail();
                        await userDoc.set(userData);
                        box.write('userData', userData);
                        await _audioPlayer
                            .setSource(AssetSource('success.mp3'));
                        _audioPlayer.resume(); 
                        if (await Vibration.hasVibrator() != null) {
                          Vibration.vibrate(duration: 500);
                        }
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) {
                          return CustomSplash(
                            image: "assets/images/connect.svg",
                            title: "Welcome aboard, $name",
                            subTitle: "You're all set to ",
                            subTitle2: "Bridge the gap",
                            buttonName: "Get Started",
                            nextPath: "/home",
                          );
                        }));
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 47),
                      height: 50,
                      width: 109,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(5.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            // fontFamily: "Poppins",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: (24 / 16),
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.onSaved,
    required this.validator,
  });

  final String hintText;
  final IconData icon;
  final Function(String?) onSaved;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: primaryBlack),
      cursorColor: Colors.amber,
      onSaved: onSaved,
      validator: validator,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlack, width: 0.9),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        label: Text(
          hintText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: primaryBlack,
          ),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Icon(
            icon,
            color: primaryBlack,
            size: 25,
          ),
        ),
      ),
    );
  }
}
