import 'dart:convert';

import 'package:bloom/model/user.dart';
import 'package:bloom/screens/events/event_detail_screen.dart';
import 'package:bloom/utils/colors.dart';
import 'package:bloom/utils/random_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

String formatDate(String dateStr) {
  try {
    final dateTime = DateTime.parse(dateStr);
    return DateFormat('dd MMMM, yy').format(dateTime);
  } catch (e) {
    return dateStr;
  }
}

class _EventScreenState extends State<EventScreen> {
  final CollectionReference eventsCollection =
      FirebaseFirestore.instance.collection('Events');
  final GetStorage _box = GetStorage();

  ValueNotifier<List<String>> selectedTags = ValueNotifier([]);

  List<String> allTags = [
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
    "Soft Skills"
  ];

  Future<List<String>> getEventRecommendations(List<String> interests) async {
    final apiKey = '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';
    final url = 'https://api.groq.com/openai/v1/chat/completions';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: json.encode({
        'interests': interests,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['events']);
    } else {
      throw Exception('Failed to load recommendations');
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 300,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 1.0,
            maxChildSize: 1.0,
            minChildSize: 1.0,
            builder: (_, controller) {
              return Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(
                  vertical: 25,
                  horizontal: 30,
                ),
                decoration: const BoxDecoration(
                  color: primaryWhite,
                  border: Border.fromBorderSide(
                    BorderSide(width: 1.5, color: orange),
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Customize",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: orange,
                        ),
                      ),
                      const Text(
                        "Get Closer to What You Want",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ValueListenableBuilder<List<String>>(
                        valueListenable: selectedTags,
                        builder: (context, selectedTagsList, _) {
                          return Wrap(
                            spacing: 8.0,
                            runSpacing: 4,
                            children: allTags.map((tag) {
                              return GestureDetector(
                                onTap: () {
                                  // Update the ValueNotifier directly
                                  if (selectedTagsList.contains(tag)) {
                                    selectedTagsList.remove(tag);
                                  } else {
                                    selectedTagsList.add(tag);
                                  }
                                  selectedTags.notifyListeners();
                                },
                                child: Chip(
                                  label: Text(tag),
                                  backgroundColor:
                                      selectedTagsList.contains(tag)
                                          ? Colors.orange
                                          : Colors.grey[300],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          List<String> recommendations =
                              await getEventRecommendations(selectedTags.value);
                          // Handle recommendations (e.g., update UI)
                        },
                        child: const Text('Get Recommendations'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredEvents() {
    var query = eventsCollection.where('status', isEqualTo: 'live');

    // Apply the filter if there are selected tags
    if (selectedTags.value.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: selectedTags.value);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final userDataMap = _box.read('userData') as Map<String, dynamic>?;
    final userData =
        userDataMap != null ? UserModel.fromMap(userDataMap) : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Events'),
        actions: [
          if (userData!.role == "Learner" || userData!.role == "Mentor")
            IconButton(
              tooltip: "My Events",
              icon: const Icon(IconlyBroken.ticket_star),
              onPressed: () {
                Navigator.pushNamed(context, "/myEvents");
              },
            ),
          IconButton(
            tooltip: "Filters",
            icon: const Icon(IconlyBroken.filter),
            onPressed: _showFilterBottomSheet,
          ),
          if (userData.role == "Admin")
            IconButton(
              tooltip: "Event Requests",
              icon: const Icon(IconlyBroken.notification),
              onPressed: () {
                Navigator.pushNamed(context, "/verifyEvent");
              },
            ),
          if (userData!.role != "Learner" && userData.role != "Mentor")
            IconButton(
                tooltip: "Create Venue",
                icon: const Icon(
                  IconlyBroken.location,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/createVenue');
                }),
          if (userData!.role != "Learner")
            IconButton(
              tooltip: "Create Event",
              icon: const Icon(IconlyBroken.plus),
              onPressed: () {
                Navigator.pushNamed(context, "/createEvent");
              },
            ),
        ],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: selectedTags,
        builder: (context, selectedTagsList, _) {
          return StreamBuilder<QuerySnapshot>(
            stream: _getFilteredEvents(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data?.docs ?? [];

              if (events.isEmpty) {
                return const Center(child: Text('No live events found'));
              }

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index].data() as Map<String, dynamic>;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      );
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
                              decoration: BoxDecoration(
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
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Share.share("Sharing link");
                                          },
                                          child: const Icon(
                                            IconlyBroken.send,
                                            size: 20,
                                            color: primaryWhite,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {},
                                          child: const Icon(
                                            IconlyBroken.bookmark,
                                            size: 20,
                                            color: primaryWhite,
                                          ),
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
                                            if (event['type'] == "In person" &&
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
                                            if (event['type'] == "In person" &&
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
              );
            },
          );
        },
      ),
    );
  }
}
