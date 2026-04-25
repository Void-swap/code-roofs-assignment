import 'package:bloom/model/user.dart';
import 'package:bloom/register_login.dart';
import 'package:bloom/screens/admin/admin.dart';
import 'package:bloom/screens/profile/edit_profie.dart';
import 'package:bloom/utils/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_verify_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _box = GetStorage();

  Future<void> _refreshProfile() async {
    try {
      final userDataMap = _box.read('userData') as Map<String, dynamic>?;
      if (userDataMap == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user data found in local storage')),
        );
        return;
      }

      final userData = UserModel.fromMap(userDataMap);
      final uid = userData.uid;

      // Fetch user data from Firestore using userId
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final updatedUserData = UserModel.fromMap(userDoc.data()!);

        // Update local storage
        _box.write('userData', updatedUserData.toMap());

        // Update the UI
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found in Firestore')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDataMap = _box.read('userData') as Map<String, dynamic>?;
    final userData =
        userDataMap != null ? UserModel.fromMap(userDataMap) : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          if (userData!.role == "Admin")
            IconButton(
              icon: const Icon(
                IconlyBroken.notification,
              ),
              onPressed: () {
                if (userData != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminVerificationScreen(),
                    ),
                  );
                }
              },
            ),
          // if (userData!.role == "Admin")
          IconButton(
            icon: const Icon(
              IconlyBroken.chart,
            ),
            onPressed: () {
              if (userData != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminDashboard()),
                );
              }
            },
          ),
          // IconButton(
          //   icon: const Icon(
          //     IconlyBroken.swap,
          //   ),
          //   onPressed: () {
          //     _refreshProfile();
          //   },
          // ),
          IconButton(
            icon: const Icon(
              IconlyBroken.edit,
            ),
            onPressed: () {
              if (userData != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      userData: userData,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: userData == null
                ? const Text('No user data available')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // padding: const EdgeInsets.all(12),
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (userData != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      userData: userData,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Hero(
                              tag: "ProfilePic",
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  userData.profilePic.isEmpty
                                      ? SizedBox(
                                          // color: Colors.grey[500]!,
                                          child: CircleAvatar(
                                            child: const Icon(
                                              IconlyBold.profile,
                                              color: primaryBlack,
                                              size: 50,
                                            ),
                                            radius: 50,
                                            backgroundColor: primaryGrey,
                                          ),
                                        )
                                      : Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x40000000),
                                                blurRadius: 10,
                                                spreadRadius: 1.5,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                            shape: BoxShape.circle,
                                            border:
                                                Border.all(color: Colors.grey),
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: userData.profilePic,
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                    CircleAvatar(
                                              backgroundImage: imageProvider,
                                            ),
                                            placeholder: (context, url) =>
                                                Shimmer.fromColors(
                                              baseColor: Colors.grey[500]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: const CircleAvatar(
                                                backgroundColor: Colors.grey,
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Shimmer.fromColors(
                                              baseColor: Colors.grey[500]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: const CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                child: Icon(Icons.error,
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ),
                                        ),
                                  Positioned.fill(
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
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hey,',
                                style: TextStyle(
                                    color: primaryBlack,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "I'm ${userData.name} ",
                                    style: const TextStyle(
                                        color: primaryBlack,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: GestureDetector(
                                        onTap: () {
                                          if (userData.isVerified ==
                                              "Not Applied") {
                                            Navigator.pushNamed(
                                                context, '/verifyMe');
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('Already Applied')),
                                            );
                                          }
                                        },
                                        child: userData.isVerified == "Verified"
                                            ? Image.asset(
                                                "assets/images/verified.png",
                                                height: 28,
                                              )
                                            : Image.asset(
                                                "assets/images/notVerified.png",
                                                height: 28,
                                              )),
                                  )
                                ],
                              ),
                              Text(
                                userData.role,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w100,
                                        color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "A Peek Into Who I Am!",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        userData.description.isNotEmpty
                            ? userData.description
                            : 'How would you like to describe yourself',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontSize: 12),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "I'm passionate about",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        userData.interests.isNotEmpty
                            ? 'You have ${userData.interests.length} interests!'
                            : 'Explore new interests to connect with others.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Events that shaped me",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        userData.attendedEvents.isNotEmpty
                            ? 'You’ve attended ${userData.attendedEvents.length} skill-building events! 🎉'
                            : 'Join our upcoming skill-building events to learn and grow!',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontSize: 12),
                      ),
                      // Expanded(child: MyEventsHorizontal()),
                      const SizedBox(height: 15),
                      Text(
                        "My Badges",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        userData.badges.isNotEmpty
                            ? 'You’ve earned ${userData.badges.length} badges for your achievements! 🌟'
                            : 'Participate in events to earn badges and showcase your skills!',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 15),

                      const SizedBox(height: 15),
                      Text(
                        "Find me on socials",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      GestureDetector(
                        onTap: () {
                          if (userData.socialMediaLinks.isNotEmpty) {
                            final url = userData.socialMediaLinks[0];
                            _launchURL(url);
                          }
                        },
                        child: Image.asset(
                          "assets/image.png",
                          height: 35,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Text(
                      //   'Lets connect at: ${userData.socialMediaLinks.length}',
                      //   style: const TextStyle(fontSize: 18),
                      // ),
                      // Text(
                      //   'Email: ${userData.email}',
                      //   style: const TextStyle(fontSize: 18),
                      // ),
                      // Text(
                      //   'Role: ${userData.role}',
                      //   style: const TextStyle(fontSize: 18),
                      // ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
