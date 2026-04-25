import 'package:bloom/model/user.dart';
import 'package:bloom/screens/events/event_detail_screen.dart';
import 'package:bloom/utils/colors.dart';
import 'package:bloom/utils/random_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class MyEventScreen extends StatefulWidget {
  @override
  _MyEventScreenState createState() => _MyEventScreenState();
}

class _MyEventScreenState extends State<MyEventScreen> {
  final _box = GetStorage();
  UserModel? userData;
  List<Map<String, dynamic>> volunteerEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() {
    final userDataMap = _box.read('userData') as Map<String, dynamic>?;
    if (userDataMap != null) {
      setState(() {
        userData = UserModel.fromMap(userDataMap);
        _fetchVolunteerEvents();
      });
    }
  }

  Future<void> _fetchVolunteerEvents() async {
    try {
      final eventsSnapshot =
          await FirebaseFirestore.instance.collection('Events').get();

      if (userData!.role == "Learner") {
        for (var event in eventsSnapshot.docs) {
          final attendees = List.from(event['attendees'] ?? []);

          final userAttendee = attendees.firstWhere(
            (attendee) => attendee['userId'] == userData?.uid,
            orElse: () => null,
          );

          if (userAttendee != null) {
            volunteerEvents.add({
              ...event.data(),
              'status': userAttendee['status'],
            });
          }
        }
      } else {
        for (var event in eventsSnapshot.docs) {
          final attendees = List.from(event['volunteers'] ?? []);

          final userAttendee = attendees.firstWhere(
            (attendee) => attendee['userId'] == userData?.uid,
            orElse: () => null,
          );

          if (userAttendee != null) {
            volunteerEvents.add({
              ...event.data(),
              'status': userAttendee['status'],
            });
          }
        }
      }
      setState(() {});
    } catch (e) {
      print('Error fetching volunteer events: $e');
    }
  }

//changes 2024-10-2 into 2 october, 24
  String formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMMM, yy').format(dateTime);
    } catch (e) {
      //return the original string
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Events'),
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            dividerHeight: 0,
            indicatorColor: orange,
            unselectedLabelStyle:
                Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 15,
                      color: primaryBlack,
                    ),
            labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: primaryBlack,
                ),
            tabs: [
              const Tab(text: 'Upcoming'),
              const Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            //1st Tab
            volunteerEvents.isEmpty
                ? const Center(child: Text('No events found.'))
                : ListView.builder(
                    itemCount: volunteerEvents
                        .where((event) => event['status'] == 'Applied')
                        .length,
                    itemBuilder: (context, index) {
                      final event = volunteerEvents
                          .where((event) => event['status'] == 'Applied')
                          .toList()[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EventDetailScreen(event: event)));
                        },
                        child: Container(
                          height: 200,
                          child: Card(
                            color: getRandomColor(),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                if (event['images'] != null &&
                                    event['images'].isNotEmpty)
                                  Positioned.fill(
                                    child: PageView.builder(
                                      itemCount: event['images'].length,
                                      itemBuilder: (context, imgIndex) {
                                        return Image.network(
                                          event['images'][imgIndex],
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                Container(
                                  width: double.maxFinite,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                  ),
                                  padding: const EdgeInsets.all(16.0),
                                  // filter: ImageFilter.blur(
                                  //     sigmaX: 0.1,
                                  //     sigmaY: 0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(5)),
                                                  border: Border.all(
                                                    width: 1,
                                                    color: event['status'] ==
                                                            'Present'
                                                        ? Colors.green.shade400
                                                        : Colors
                                                            .orange.shade400,
                                                  )),
                                              child: Text(
                                                event['status'] ?? 'No Status',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                      fontSize: 12,
                                                      color: event['status'] ==
                                                              'Present'
                                                          ? Colors
                                                              .green.shade400
                                                          : Colors
                                                              .orange.shade400,
                                                    ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                GestureDetector(
                                                    onTap: () {
                                                      String shareText =
                                                          "Sharing link";
                                                      Share.share(shareText);
                                                      //   Navigator.of(context).pop();
                                                    },
                                                    child: const Icon(
                                                      IconlyBroken.send,
                                                      size: 20,
                                                      color: primaryWhite,
                                                    )),
                                                const SizedBox(
                                                  width: 8,
                                                ),
                                                GestureDetector(
                                                    onTap: () {
                                                      String shareText =
                                                          "Sharing link";
                                                      Share.share(shareText);
                                                    },
                                                    child: const Icon(
                                                      IconlyBroken.bookmark,
                                                      size: 20,
                                                      color: primaryWhite,
                                                    )),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            // Event name
                                            Text(
                                              event['name'] ?? 'No name',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: primaryWhite,
                                                  ),
                                            ),
                                            Row(
                                              children: [
                                                if (event['type'] != null)
                                                  Text(
                                                    "${event['type']}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: primaryWhite,
                                                        ),
                                                  ),
                                                if (event['type'] ==
                                                        "offline" &&
                                                    event['venue'] != null)
                                                  Text(
                                                    " • ${event['venue']}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: primaryWhite,
                                                        ),
                                                  ),
                                                if (event['type'] ==
                                                        "offline" &&
                                                    event['city'] != null)
                                                  Text(
                                                    ' • ${event['city']} ',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: primaryWhite,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                if (event['date'] != null)
                                                  Text(
                                                    formatDate(event['date']),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: primaryWhite,
                                                        ),
                                                  ),
                                                if (event['time'] != null)
                                                  Text(
                                                    ' • ${event['time']} ',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: primaryWhite,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

            //2nd Tab
            volunteerEvents.isEmpty
                ? const Center(child: Text('No events found.'))
                : ListView.builder(
                    itemCount: volunteerEvents
                        .where((event) => event['status'] == 'Present')
                        .length,
                    itemBuilder: (context, index) {
                      final event = volunteerEvents
                          .where((event) => event['status'] == 'Present')
                          .toList()[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EventDetailScreen(event: event)));
                        },
                        child: Container(
                          height: 200,
                          child: Card(
                            color: getRandomColor(),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                if (event['images'] != null &&
                                    event['images'].isNotEmpty)
                                  Positioned.fill(
                                    child: PageView.builder(
                                      itemCount: event['images'].length,
                                      itemBuilder: (context, imgIndex) {
                                        return Image.network(
                                          event['images'][imgIndex],
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                Container(
                                  width: double.maxFinite,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                  ),
                                  padding: const EdgeInsets.all(16.0),
                                  // filter: ImageFilter.blur(
                                  //     sigmaX: 0.1,
                                  //     sigmaY: 0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(5)),
                                                  border: Border.all(
                                                    width: 1,
                                                    color: event['status'] ==
                                                            'Present'
                                                        ? Colors.green.shade400
                                                        : Colors
                                                            .orange.shade400,
                                                  )),
                                              child: Text(
                                                event['status'] ?? 'No Status',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                      fontSize: 12,
                                                      color: event['status'] ==
                                                              'Present'
                                                          ? Colors
                                                              .green.shade400
                                                          : Colors
                                                              .orange.shade400,
                                                    ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                GestureDetector(
                                                    onTap: () {
                                                      String shareText =
                                                          "Sharing link";
                                                      Share.share(shareText);
                                                      //   Navigator.of(context).pop();
                                                    },
                                                    child: const Icon(
                                                      IconlyBroken.send,
                                                      size: 20,
                                                      color: primaryWhite,
                                                    )),
                                                const SizedBox(
                                                  width: 8,
                                                ),
                                                GestureDetector(
                                                    onTap: () {
                                                      String shareText =
                                                          "Sharing link";
                                                      Share.share(shareText);
                                                    },
                                                    child: const Icon(
                                                      IconlyBroken.bookmark,
                                                      size: 20,
                                                      color: primaryWhite,
                                                    )),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              event['name'] ?? 'No name',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: primaryWhite,
                                                  ),
                                            ),
                                            Row(
                                              children: [
                                                if (event['type'] != null)
                                                  Text(
                                                    "${event['type']}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: primaryWhite,
                                                        ),
                                                  ),
                                                if (event['type'] ==
                                                        "offline" &&
                                                    event['venue'] != null)
                                                  Text(
                                                    " • ${event['venue']}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: primaryWhite,
                                                        ),
                                                  ),
                                                if (event['type'] ==
                                                        "offline" &&
                                                    event['city'] != null)
                                                  Text(
                                                    ' • ${event['city']} ',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: primaryWhite,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                if (event['date'] != null)
                                                  Text(
                                                    formatDate(event['date']),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: primaryWhite,
                                                        ),
                                                  ),
                                                if (event['time'] != null)
                                                  Text(
                                                    ' • ${event['time']} ',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: primaryWhite,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
