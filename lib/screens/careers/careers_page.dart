import 'package:bloom/model/careers.dart';
import 'package:bloom/model/user.dart';
import 'package:bloom/screens/careers/career_in_detail_page.dart';
import 'package:bloom/screens/events/create_event.dart';
import 'package:bloom/utils/colors.dart';
import 'package:bloom/utils/custom_headers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

void _showFilterBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
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
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomHeaders(
                                    context: context, Header: "• Interests"),
                                CustomHeaders(
                                    context: context, Header: "• City")
                              ],
                            ),

                            //     IconButton(
                            //       onPressed: () {
                            //         setState(() {
                            //           showAllChips = !showAllChips;
                            //         });
                            //       },
                            //       icon: Icon(showAllChips
                            //           ? IconlyLight.arrow_up_2
                            //           : IconlyLight.arrow_down_2),
                            //       color: primaryWhite,
                            //       iconSize: 20,
                            //     )
                            //   ],
                            // ),
                            // Wrap(
                            //   spacing: 8.0,
                            //   runSpacing: 4.0,
                            //   children: _buildFilterChips(setState),
                            // ),
                            // // if (!showAllChips)
                            //   Center(
                            //     child: TextButton(
                            //       onPressed: () {
                            //         setState(() {
                            //           showAllChips = true;
                            //         });
                            //       },
                            //       child: const Text(
                            //         "Show More",
                            //         style: TextStyle(color: primaryYellow),
                            //       ),
                            //     ),
                            //   ),
                            // if (showAllChips)
                            //   Center(
                            //     child: TextButton(
                            //       onPressed: () {
                            //         setState(() {
                            //           showAllChips = false;
                            //         });
                            //       },
                            //       child: const Text(
                            //         "Show Less",
                            //         style: TextStyle(color: primaryYellow),
                            //       ),
                            //     ),
                            //   ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}

class CareersListingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final GetStorage _box = GetStorage();
    final userDataMap = _box.read('userData') as Map<String, dynamic>?;
    final userData =
        userDataMap != null ? UserModel.fromMap(userDataMap) : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Careers"),
        actions: [
          IconButton(
            tooltip: "Filters",
            icon: const Icon(IconlyBroken.filter),
            onPressed: () {
              _showFilterBottomSheet(context);
              // Navigator.pushNamed(context, "/shortlistScreen");
            },
          ),
          if (userData!.role != "Mentor" && userData!.role != "Learner")
            IconButton(
              tooltip: "Create Listing",
              icon: const Icon(IconlyBroken.plus),
              onPressed: () {
                Navigator.pushNamed(context, "/createCareer");
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('careers').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;
              final position = job['position'] ?? 'Position not available';
              final jobId = jobs[index].id;
              final jobType = job['type'] ?? 'internship';
              final listedBy = job['listedBy'] ?? 'Listed by not available';
              final responsibility =
                  job['responsibility'] ?? 'No responsibilities listed';
              final duration = job['duration'] ?? 'Duration not specified';
              final workMode = job['workMode'] ?? 'Work mode not specified';
              final location = job['location'] ?? 'Location not specified';
              final startDate = job['startDate'] != null
                  ? DateTime.parse(job['startDate'])
                  : DateTime.now();
              final pay = job['pay'] ?? 0.0;
              final fullOrPart = job['partFull'] ?? 'Not specified';
              final numberOfOpenings = job['numberOfOpenings'] ?? 0;
              final perks = List<String>.from(job['perks'] ?? []);
              final skills = List<String>.from(job['skills'] ?? []);
              final createdOn = job['createdOn'] != null
                  ? (job['createdOn'] as Timestamp).toDate()
                  : DateTime.now();
              final creatorName = job['name'] ?? 'name';
              final pfpImage = job['pfpImageURl'] ?? '';

              final currentUserId = FirebaseAuth.instance.currentUser?.uid;

              final List<dynamic> applications = job['applications'] ?? [];
              final alreadyApplied =
                  applications.any((app) => app['userId'] == currentUserId);
              return InkWell(
                onTap: () {
                  final jobModel = JobsModel.fromMap(job);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailScreen(job: jobModel),
                    ),
                  );
                },
                child: Container(
                  height: 225,
                  child: Card(
                    elevation: 2,
                    color: primaryWhite,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      ProfilePic(
                                        imgUrl: pfpImage,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        creatorName,
                                        style: const TextStyle(
                                          // fontFamily: "Poppins",
                                          fontSize: 18, height: (20 / 18),
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xff0f1015),
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Open till",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                              color: Colors.black,
                                            ),
                                        textAlign: TextAlign.right,
                                      ),
                                      Text(
                                        getNextMonthDate(createdOn.toString()),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                  width: double.maxFinite,
                                  height: 70,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xffF9F9F9),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      BuildInfoColumns(
                                        heading_text: 'Role',
                                        info_text: position,
                                      ),
                                      const VerticalDivider(
                                        indent: 15,
                                        endIndent: 15,
                                        width: 40,
                                        thickness: 1,
                                        color: Colors.grey,
                                      ),
                                      BuildInfoColumns(
                                        heading_text: 'Job Type',
                                        info_text: jobType,
                                      ),
                                      const VerticalDivider(
                                        indent: 15,
                                        endIndent: 15,
                                        width: 40,
                                        thickness: 1,
                                        color: Colors.grey,
                                      ),
                                      BuildInfoColumns(
                                        heading_text: 'Mode',
                                        info_text: workMode,
                                      ),
                                    ],
                                  )),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            text: 'Responsibilities ',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xff2e2e2e),
                                            ),
                                            children: [
                                              TextSpan(
                                                text: responsibility,
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xff424242),
                                                    height: 1.4),
                                              ),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          getTimeAgo(createdOn.toString()),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xff8b8b8b),
                                            height: (18 / 12),
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                          onTap: () {
                                            String shareText = "Sharing link";
                                            Share.share(shareText);
                                            //   Navigator.of(context).pop();
                                          },
                                          child: const Icon(
                                            IconlyBroken.send,
                                            size: 20,
                                            color: primaryBlack,
                                          )),
                                      const SizedBox(
                                        width: 15,
                                      ),
                                      GestureDetector(
                                          onTap: () {
                                            // String shareText = "Sharing link";
                                            // Share.share(shareText);
                                          },
                                          child: const Icon(
                                            IconlyBroken.bookmark,
                                            size: 20,
                                            color: primaryBlack,
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              // return InkWell(
              //   onTap: () {},
              //   child: ListTile(
              // title: Text(position),
              // trailing:
              //         },
              //             child: Text('Apply'),
              //           ),
              //   ),
              // );
            },
          );
        },
      ),
    );
  }
}

class BuildInfoColumns extends StatelessWidget {
  final String heading_text;
  final String info_text;

  BuildInfoColumns({
    required this.heading_text,
    required this.info_text,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 48,
        child: Column(
          children: [
            Text(
              heading_text,
              style: const TextStyle(
                // fontFamily: "Poppins",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xff9a9a9a),
                height: 18 / 12,
              ),
            ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.all(4.0),
                child: Text(
                  info_text,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    // fontFamily: "Poppins",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff424242),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String getTimeAgo(String timestampString) {
  DateTime timestamp = DateTime.parse(timestampString);

  DateTime now = DateTime.now();

  Duration difference = now.difference(timestamp);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} seconds ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    // Format the timestamp in a custom way if it's more than a week ago
    String formattedDate = DateFormat('MMM d, yyyy').format(timestamp);
    return 'on $formattedDate';
  }
}

String getNextMonthDate(String inputDate) {
  DateTime originalDate =
      DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS').parse(inputDate);

  DateTime nextMonthDate =
      DateTime(originalDate.year, originalDate.month + 1, originalDate.day);

  return DateFormat('dd MMM').format(nextMonthDate);
}

class ProfilePic extends StatelessWidget {
  final String imgUrl;
  const ProfilePic({
    super.key,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      // elevation: 4,
      shape: const CircleBorder(),
      clipBehavior: Clip.none,
      child: CircleAvatar(
        radius: 25,
        backgroundColor: imgUrl.isNotEmpty ? Colors.white : Colors.transparent,
        child: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.transparent,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: const Icon(
                IconlyBold.profile,
                color: primaryBlack,
                size: 25,
              )),
        ),
      ),
    );
  }
}
