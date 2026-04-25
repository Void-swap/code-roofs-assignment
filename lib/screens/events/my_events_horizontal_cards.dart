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

class MyEventsHorizontal extends StatefulWidget {
  @override
  _MyEventsHorizontalState createState() => _MyEventsHorizontalState();
}

class _MyEventsHorizontalState extends State<MyEventsHorizontal> {
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

  // Fetch all events and filter by user interests
  Future<void> _fetchVolunteerEvents() async {
    try {
      final eventsSnapshot =
          await FirebaseFirestore.instance.collection('Events').get();

      final userInterests = userData?.interests ?? [];

      for (var event in eventsSnapshot.docs) {
        final eventData = event.data() as Map<String, dynamic>;
        final eventTags = List<String>.from(eventData['tags'] ?? []);

        if (eventTags.any((tag) => userInterests.contains(tag))) {
          volunteerEvents.add(eventData);
        }
      }
      setState(() {});
    } catch (e) {
      print('Error fetching volunteer events: $e');
    }
  }

  String formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMMM, yy').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: volunteerEvents.isEmpty
          ? const Center(child: Text('No events found.'))
          : Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(volunteerEvents.length, (index) {
                    final event = volunteerEvents[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EventDetailScreen(event: event)));
                      },
                      child: Container(
                        width: 350,
                        height: 500,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: Card(
                          color: getRandomColor(),
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
                                                    : Colors.orange.shade400,
                                              ),
                                            ),
                                            child: Text(
                                              event['status'] ?? 'No Status',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    fontSize: 12,
                                                    color: event['status'] ==
                                                            'Present'
                                                        ? Colors.green.shade400
                                                        : Colors
                                                            .orange.shade400,
                                                  ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  String shareText =
                                                      "Sharing link";
                                                  Share.share(shareText);
                                                },
                                                child: const Icon(
                                                  IconlyBroken.send,
                                                  size: 20,
                                                  color: primaryWhite,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
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
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                      "In person" &&
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
                                                      "In person" &&
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
                  }),
                ),
              ),
            ),
    );
  }
}
