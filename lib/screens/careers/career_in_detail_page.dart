import 'package:bloom/form.dart';
import 'package:bloom/model/careers.dart';
import 'package:bloom/screens/careers/application_page.dart';
import 'package:bloom/screens/careers/shortListingScreen.dart';
import 'package:bloom/screens/events/create_event.dart';
import 'package:bloom/utils/colors.dart';
import 'package:bloom/utils/custom_headers.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'careers_page.dart';

class JobDetailScreen extends StatefulWidget {
  final JobsModel job;

  const JobDetailScreen({Key? key, required this.job}) : super(key: key);

  @override
  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${widget.job.position} at ${widget.job.name}"), // Title using job position
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ApplicantManagementScreen(
                          jobId: widget.job.uid,
                        )),
              );
            },
            icon: Icon(IconlyBroken.message),
            tooltip: "Applicants",
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ProfilePic(
                            imgUrl: widget.job.pfpImageURL,
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          Text(
                            widget.job.name,
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
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildColumns(IconlyBold.work, "Job type",
                          widget.job.type.toString()),
                      buildColumns(IconlyBold.profile, "Job Position",
                          widget.job.position),
                      buildColumns(IconlyBold.wallet, "Stipend",
                          "₹" + widget.job.pay.toString() + "/-")
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildColumns(
                          IconlyBold.calendar, "Duration", widget.job.duration),
                      buildColumns(
                          IconlyBold.home, "Work Mode", widget.job.workMode),
                      buildColumns(
                          IconlyBold.location, "Location", widget.job.location)
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  CustomHeaders(context: context, Header: "Responsibilities"),
                  Text(widget.job.responsibility,
                      style: TextStyle(fontSize: 14)),
                  SizedBox(
                    height: 30,
                  ),
                  CustomHeaders(context: context, Header: "Openings"),
                  Text(widget.job.numberOfOpenings.toString(),
                      style: TextStyle(fontSize: 14)),
                  SizedBox(
                    height: 30,
                  ),

                  // Text('Position: ${widget.job.position}',
                  //     style:
                  //         TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  // SizedBox(height: 8),
                  // Text('Listed By: ${widget.job.listedBy}',
                  //     style: TextStyle(fontSize: 16)),
                  // SizedBox(height: 8),
                  // Text(':',
                  //     style:
                  //         TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  // SizedBox(height: 8),
                  // Text('Duration: ${widget.job.duration}',
                  //     style: TextStyle(fontSize: 16)),
                  // SizedBox(height: 8),
                  // Text('Location: ${widget.job.location}',
                  //     style: TextStyle(fontSize: 16)),
                  // SizedBox(height: 8),
                  // Text(
                  //     'Pay: ${widget.job.pay == 0.0 ? "Unpaid" : "\$${widget.job.pay}"}',
                  //     style: TextStyle(fontSize: 16)),
                  // SizedBox(height: 8),
                  CustomHeaders(context: context, Header: "Perks"),

                  for (var perk in widget.job.perks)
                    Text('- $perk', style: TextStyle(fontSize: 14)),
                  SizedBox(
                    height: 30,
                  ),
                  CustomHeaders(context: context, Header: "Skills required"),

                  for (var skill in widget.job.skills)
                    Text('- $skill', style: TextStyle(fontSize: 14)),
                  SizedBox(
                    height: 100,
                  )
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ApplicationPage(jobId: widget.job.uid)),
                  );
                },
                child: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: CustomButton(
                        name: "Send your application", color: orange))),
          )
        ],
      ),
    );
  }

  Widget buildColumns(IconData imgSrc, String heading, String value) {
    const int maxChars = 20;

    String truncateWithEllipsis(String text, int maxLength) {
      return (text.length <= maxLength)
          ? text
          : '${text.substring(0, maxLength)}...';
    }

    void showDialogFullText() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 5,
                ),
                Icon(imgSrc),
                SizedBox(
                  height: 10,
                ),
                Text(
                  truncateWithEllipsis(heading, maxChars),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    //
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff2e2e2e),
                    height: 19 / 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff666666),
                    height: 19 / 12,
                  ),
                  softWrap: true,
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    return InkWell(
      onTap: showDialogFullText,
      child: Container(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(imgSrc),
            SizedBox(
              height: 5,
            ),
            Text(
              truncateWithEllipsis(heading, maxChars),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                //
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xff2e2e2e),
                height: 19 / 12,
              ),
            ),
            Text(
              truncateWithEllipsis(value, maxChars),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xff666666),
                height: 19 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
