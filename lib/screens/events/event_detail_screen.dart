import 'package:audioplayers/audioplayers.dart';
import 'package:bloom/form.dart';
import 'package:bloom/model/user.dart';
import 'package:bloom/screens/events/create_event.dart';
import 'package:bloom/screens/events/event_screen.dart';
import 'package:bloom/screens/events/verify_event_detail.dart';
import 'package:bloom/utils/colors.dart';
import 'package:bloom/utils/custom_headers.dart';
import 'package:bloom/utils/reusable_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vibration/vibration.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({super.key, required this.event});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final AudioPlayer _audioCache = AudioPlayer(); // Use AudioCache for assets
  final _box = GetStorage(); // Initialize GetStorage
  UserModel? userData;
  bool isApplied = false; // Tracks whether user has applied

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
        _checkIfApplied(); // if the user has already applied
      });
    }
  }

  // if the current user is in the attendees list
  Future<void> _checkIfApplied() async {
    final eventDocRef = FirebaseFirestore.instance
        .collection('Events')
        .doc(widget.event['UID']);

    if (userData!.role == "Learner") {
      final eventSnapshot = await eventDocRef.get();
      final attendees = List.from(eventSnapshot.data()?['attendees'] ?? []);
      setState(() {
        isApplied =
            attendees.any((attendee) => attendee['userId'] == userData!.uid);
      });
    } else {
      final eventSnapshot = await eventDocRef.get();
      final volunteers = List.from(eventSnapshot.data()?['volunteers'] ?? []);
      setState(() {
        isApplied =
            volunteers.any((attendee) => attendee['userId'] == userData!.uid);
      });
    }
  }

  Future<void> _onCodeScanned(BarcodeCapture barcodeCapture) async {
    if (barcodeCapture.barcodes.isNotEmpty) {
      final barcode = barcodeCapture.barcodes.first;

      final qrData = barcode.rawValue?.split(',');
      if (qrData == null || qrData.length != 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR code format')),
        );
        return;
      }
      final String scannedEventId = qrData[0];
      final String scannedUserId = qrData[1];
      print(scannedEventId);
      print(scannedEventId);
      print(scannedEventId);
      print(scannedEventId);
      print(scannedEventId);
      print(scannedEventId);
      print(scannedUserId);
      print(scannedUserId);
      print(scannedUserId);
      print(scannedUserId);
      print(scannedUserId);

      if (scannedEventId != widget.event['UID']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code does not match this event')),
        );
        return;
      }
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      DocumentReference eventRef =
          _firestore.collection('Events').doc(scannedEventId);
      DocumentReference userDoc =
          _firestore.collection('users').doc(scannedUserId);

      final eventSnapshot = await eventRef.get();

      if (!eventSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event not found')),
        );
        return;
      }

      final eventData = eventSnapshot.data() as Map<String, dynamic>;

      if (userData!.role == "Learner") {
        List<dynamic> attendees = eventData['attendees'] ?? [];

        bool userIsAttendee = false;
        for (var attendee in attendees) {
          if (attendee['userId'] == scannedUserId) {
            attendee['status'] = 'Present';
            userIsAttendee = true;
            break;
          }
        }
        if (userIsAttendee) {
          await eventRef.update({'attendees': attendees});
          await userDoc.update({
            'attendedEvents': FieldValue.arrayUnion([scannedEventId]),
          });
          await userDoc.update({
            'attendedEvents': FieldValue.arrayUnion(["1st Event Badge"]),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Successfully checked in user with ID: $scannedUserId')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User not found in the attendee list')),
          );
        }
      }
      if (userData!.role != "Learner") {
        List<dynamic> volunteers = eventData['volunteers'] ?? [];

        bool userIsAttendee = false;
        for (var volunteer in volunteers) {
          if (volunteer['userId'] == scannedUserId) {
            volunteer['status'] = 'Present';
            userIsAttendee = true;
            break;
          }
        }
        if (userIsAttendee) {
          await eventRef.update({'volunteers': volunteers});
          await userDoc.update({
            'badges': FieldValue.arrayUnion(["1st Event Badge"]),
            'attendedEvents': FieldValue.arrayUnion([scannedEventId]),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Successfully checked in user with ID: $scannedUserId')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User not found in the attendee list')),
          );
        }
      }
    }
  }

  Future<void> _rsvpToEvent(String eventId, String role) async {
    final eventDocRef =
        FirebaseFirestore.instance.collection('Events').doc(eventId);
    try {
      if (isApplied) {
        if (role == "Learner") {
          await eventDocRef.update({
            'attendees': FieldValue.arrayRemove([
              {'userId': userData!.uid, 'status': 'Applied'}
            ])
          });
        } else {
          await eventDocRef.update({
            'volunteers': FieldValue.arrayRemove([
              {'userId': userData!.uid, 'status': 'Applied'}
            ])
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You have successfully removed your RSVP.')),
        );
      } else {
        if (role == "Learner") {
          await eventDocRef.update({
            'attendees': FieldValue.arrayUnion([
              {'userId': userData!.uid, 'status': 'Applied'}
            ])
          });
        } else {
          await eventDocRef.update({
            'volunteers': FieldValue.arrayUnion([
              {'userId': userData!.uid, 'status': 'Applied'}
            ])
          });
        }
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return CustomSplash(
            image: "assets/images/phone.svg",
            title: " 🎉 You're Registered for the Event!",
            subTitle: "Thank you for joining us—exciting things are ahead!",
            buttonName: "Next",
            nextPath: "/home",
          );
        }));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You have successfully RSVP\'d to this event!')),
        );
      }

      await _audioCache.setSource(AssetSource('success.mp3'));
      _audioCache.resume();
      if (await Vibration.hasVibrator() != null) {
        Vibration.vibrate(duration: 500);
      }

      setState(() {
        isApplied = !isApplied;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update RSVP: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event['name'] ?? 'Event Detail'),
        actions: [
          if (widget.event['organizer'] == userData!.uid)
            IconButton(
              icon: const Icon(IconlyBroken.scan),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        QRScannerScreen(onCodeScanned: _onCodeScanned),
                  ),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if (isApplied)
                  Container(
                    // height: 250,
                    child: Stack(
                      children: [
                        Center(
                          child: SvgPicture.asset(
                            "assets/svg/ticketBg-2.svg",
                            height: 300,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(
                              height: 50,
                            ),
                            Center(
                              child: QrImageView(
                                data: widget.event['UID'] + "," + userData!.uid,
                                version: QrVersions.auto,
                                size: 125.0,
                              ),
                            ),
                            const SizedBox(
                              height: 75,
                            ),
                            const Text("1x Admit")
                          ],
                        ),
                      ],
                    ),
                  ),
                // ListTile(
                //   title: Text(userData!.uid),
                // ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomHeaders(context: context, Header: "Name"),
                    Text(widget.event['name'] ?? 'No name'),
                    SizedBox(
                      height: 30,
                    ),
                    CustomHeaders(context: context, Header: "Description"),
                    Text(widget.event['description'] ?? 'No description'),
                    SizedBox(
                      height: 30,
                    ),
                    CustomHeaders(context: context, Header: "Date"),
                    Text(formatDate(widget.event['date']) ?? 'No date'),
                    SizedBox(
                      height: 30,
                    ),
                    CustomHeaders(context: context, Header: "Time"),
                    Text(widget.event['time'] ?? 'No time'),
                    SizedBox(
                      height: 30,
                    ),
                    CustomHeaders(context: context, Header: "Venue"),
                    Text(widget.event['venue'] ?? 'No venue'),
                    SizedBox(
                      height: 30,
                    ),
                    CustomHeaders(context: context, Header: "City"),
                    Text(widget.event['city'] ?? 'No city'),
                    SizedBox(
                      height: 30,
                    ),
                    CustomHeaders(context: context, Header: "Contact"),
                    Text(widget.event['contact'] ?? 'No contact'),
                    SizedBox(
                      height: 30,
                    ),

                    // ListTile(
                    //   title: const Text('Special Instructions'),
                    //   subtitle: Text(
                    //       widget.event['specialInstruction'] ?? 'No instructions'),
                    // ),
                    // ListTile(
                    //   title: const Text('Perks'),
                    //   subtitle: Text(widget.event['perks'] ?? 'No perks'),
                    // ),
                    const SizedBox(height: 20),
                  ],
                )
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                userData != null
                    ? GestureDetector(
                        onTap: () {
                          _rsvpToEvent(widget.event['UID'], userData!.role);
                        },
                        child: userData!.role == "Learner"
                            ? CustomButton(
                                name:
                                    isApplied ? "Applied" : "Apply as attendee",
                                color: orange)
                            : CustomButton(
                                name: isApplied
                                    ? "Applied"
                                    : "Apply as collaborator",
                                color: isApplied ? primaryWhite : orange))
                    : const Center(
                        child: Text('Please log in to Apply'),
                      ),
                const SizedBox(
                  height: 47,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
