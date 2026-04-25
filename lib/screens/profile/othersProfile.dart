import 'package:bloom/model/user.dart';
import 'package:bloom/services/services.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class OthersProfileView extends StatelessWidget {
  final UserService _userService = UserService();
  final String userId;

  OthersProfileView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userService.getUserInfo(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error fetching user info'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('User not found'));
        }

        final userData = snapshot.data!;
        UserModel userModel = UserModel.fromMap(userData);

        return Scaffold(
          appBar: AppBar(
            title: Text('User Profile'),
            actions: [
              IconButton(
                icon: const Icon(IconlyBroken.notification),
                onPressed: () {},
              ),
            ],
          ),
          body: Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hey, ${userModel.name}',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800)),
                            Text(userModel.role,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text("A Peek Into Who I Am!",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(userModel.description.isNotEmpty
                        ? userModel.description
                        : 'How would you like to describe yourself'),
                    const SizedBox(height: 20),
                    Text("I'm passionate about",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(userModel.interests.isNotEmpty
                        ? 'You have ${userModel.interests.length} interests!'
                        : 'Explore new interests to connect with others.'),
                    const SizedBox(height: 20),
                    Text("Events that shaped me",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600)),
                    Expanded(child: SizedBox()),
                    const SizedBox(height: 20),
                    Text("My Badges",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(userModel.badges.isNotEmpty
                        ? 'You’ve earned ${userModel.badges.length} badges for your achievements!'
                        : 'Participate in events to earn badges and showcase your skills!'),
                    const SizedBox(height: 20),
                    Text("I’m Just a Message Away!",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text("Email: ${userModel.email}"),
                    const SizedBox(height: 20),
                    Text("Find me on socials",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(
                        'Lets connect at: ${userModel.socialMediaLinks.length}'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
