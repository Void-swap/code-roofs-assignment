import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:bloom/form.dart';
import 'package:bloom/model/venue.dart';
import 'package:bloom/screens/venue/venue_detail.dart';
import 'package:bloom/services/services.dart';
import 'package:bloom/utils/colors.dart';
import 'package:bloom/utils/random_colors.dart';
import 'package:bloom/utils/reusable_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:vibration/vibration.dart';

import '../../model/event.dart';
import 'event_screen.dart';

class CreateEventScreen extends StatefulWidget {
  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late PageController _controller;
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _meetingLinkController = TextEditingController();

  String capacityHintText = "Capacity";
  String? selectedVenue;
  String? selectedCity;
  int? selectedVenueCapacity;
  String? selectedVenueAddress;
  String? selectedVenueAccessibility;
  List<String>? availableDates;
  String? selectedDate;
  String? selectedTime;
  List<DocumentSnapshot> availableVenues = [];
  int? selectedVenueIndex;
  String eventType = 'In person';
  bool isAvailableForever = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<XFile> _images = [];
  final List<String> _imageUrls = [];

  final _picker = ImagePicker();

  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (index < _images.length) {
          _images[index] = pickedFile;
        } else {
          _images.add(pickedFile);
        }
      });
      await _uploadImages();
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    try {
      List<String> urls = [];
      for (var image in _images) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef =
            FirebaseStorage.instance.ref().child('eventImages').child(fileName);

        // Create metadata
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'max-age=3600',
        );

        await storageRef.putFile(File(image.path), metadata);

        final imageUrl = await storageRef.getDownloadURL();
        urls.add(imageUrl);
      }

      setState(() {
        _imageUrls.clear();
        _imageUrls.addAll(urls);
      });
    } catch (e) {
      _showError('Error uploading images: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  final List<String> availableInterests = [
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
    "Soft Skills"
  ];

  List<String> selectedInterests = [];

  String searchQuery = '';
  void _showInterestsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Interests'), // Search field
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Interests',
                      prefixIcon: Icon(IconlyBroken.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListBody(
                      children: availableInterests
                          .where((interest) =>
                              interest.toLowerCase().contains(searchQuery))
                          .map((interest) {
                        return CheckboxListTile(
                          title: Text(interest),
                          value: selectedInterests.contains(interest),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedInterests.add(interest);
                              } else {
                                selectedInterests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tagsController.text = selectedInterests.join(', ');
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAvailableDatesForInPerson() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Date'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableDates?.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(formatDate(availableDates![index].toString())),
                  onTap: () {
                    setState(() {
                      selectedDate = availableDates![index];
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _fetchVenues();
  }

  Future<void> _fetchVenues() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('venues').get();
      setState(() {
        availableVenues = querySnapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching venues: $e')));
    }
  }

  void _submit() async {
    final box = GetStorage();
    final userrr = box.read('userData') ?? 'User not found';
    print(userrr);

    UserService userService = UserService();
    String userName = userService.getUserName();
    String userPfp = userService.getUserProfilePic();
    String userUID = userService.getUserUID();
    String isVerified = userrr?['isVerified'] ?? 'Not Applied';

    if (isVerified == "Verified") {
      if (_validateInputs()) {
        if (_images.isNotEmpty) {
          await _uploadImages();
        }

        // if (_imageUrls.isNotEmpty) {
        final eventData = EventModel(
          UID: '',
          organizer: userUID ?? 'No UID found',
          name: _eventNameController.text,
          description: _descriptionController.text,
          date: selectedDate ?? '',
          time: selectedTime ?? '',
          venue: eventType == 'Virtual'
              ? _meetingLinkController.text
              : selectedVenue ?? '',
          city: selectedCity ?? '',
          reviews: [],
          status: 'pending',
          tags:
              _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
          volunteers: [],
          attendees: [],
          contact: '',
          accessibilityInfo: selectedVenueAccessibility ?? '',
          specialInstruction: '',
          type: eventType,
          images: _imageUrls,
        );

        try {
          DocumentReference docRef = await FirebaseFirestore.instance
              .collection('Events')
              .add(eventData.toMap());
          await docRef.update({'UID': docRef.id});
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event created successfully!')));
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) {
            return CustomSplash(
              image: "assets/images/phone.svg",
              title: " 🎉 You're event request is sent",
              subTitle: "Thank you for joining us—exciting things are ahead!",
              buttonName: "Next",
              nextPath: "/home",
            );
          }));
          _clearForm();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create event: $e')));
        }
        // } else {
        //   _showError(
        //       'Please upload at least one image before submitting the event.');
        // }
      }
      await _audioPlayer.setSource(AssetSource('success.mp3'));
      _audioPlayer.resume(); // Play the sound
      if (await Vibration.hasVibrator() != null) {
        Vibration.vibrate(duration: 500);
      }
    } else {
      _showError("Uh-Oh! please get verified to create events.");
    }
  }

  void _clearForm() {
    _eventNameController.clear();
    _descriptionController.clear();
    _capacityController.clear();
    _tagsController.clear();
    _meetingLinkController.clear();
    selectedVenue = null;
    selectedCity = null;
    selectedDate = null;
    selectedTime = null;
    availableDates = null;
    isAvailableForever = false;
    eventType = 'In person';
    setState(() {});
  }

  bool _validateInputs() {
    if (_eventNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        (eventType == 'In person' && selectedVenue == null) ||
        _capacityController.text.isEmpty ||
        selectedDate == null ||
        (eventType == 'Virtual' && _meetingLinkController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields!')));
      return false;
    }
    return true;
  }

  void _onVenueSelected(DocumentSnapshot venue, int index) {
    setState(() {
      selectedVenue = venue['name'];
      selectedCity = venue['city'];
      selectedVenueCapacity = venue['capacity'];
      selectedVenueAddress = venue['address'];
      selectedVenueAccessibility = venue['accessibilityInfo'];
      capacityHintText = selectedVenueCapacity.toString();
      selectedVenueIndex = index;

      availableDates =
          (venue.data() as Map<String, dynamic>)['availability'] != null
              ? List<String>.from(venue['availability'])
              : [];

      selectedDate = availableDates != null && availableDates!.isNotEmpty
          ? availableDates![0]
          : null;

      isAvailableForever = (venue['isAvailableAllTime']);
    });
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime.format(context);
      });
    }
  }

  Future<void> _generateDescription() async {
    String inputText = _descriptionController.text.trim();

    if (inputText.isNotEmpty) {
      try {
        String generatedText = await generateFeedbackWithAI(inputText);
        setState(() {
          _descriptionController.text = generatedText;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Hold on! It looks like your description field is empty'),
        ),
      );
    }
  }

  Future<String> generateFeedbackWithAI(String inputText) async {
    const String apiKey = 'AIzaSyDT_p6t2MjZhrfNocqQri2ovGPeqrV_n08';
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

    // Specific prompt structure
    String modifiedInput =
        "Elaborate on the following statement with enthusiasm, using an active voice and an assertive tone: '$inputText'. Avoid adding any extra text or questions.";

    final response = await http.post(
      Uri.parse('$apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': modifiedInput}
            ]
          }
        ]
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print('Decoded response: $responseBody');

      if (responseBody.containsKey('candidates') &&
          responseBody['candidates'].isNotEmpty &&
          responseBody['candidates'][0].containsKey('content') &&
          responseBody['candidates'][0]['content']['parts'].isNotEmpty) {
        return responseBody['candidates'][0]['content']['parts'][0]['text'] ??
            'No content returned';
      } else {
        throw Exception('Expected content structure not found in response');
      }
    } else {
      throw Exception('Failed to generate feedback: ${response.body}');
    }
  }

  // Future<String> generateFeedbackWithAI(String inputText) async {
  //   // Specific prompt structure
  //   String modifiedInput =
  //       "Elaborate on the following statement with enthusiasm, using an active voice and an assertive tone: '$inputText'. Avoid adding any extra text or questions.";

  //   // Groq client API interaction
  //   final String groqApiUrl =
  //       'https://api.groq.com/openai/v1/chat/completions'; // Assume this is the correct endpoint

  //   final response = await http.post(
  //     Uri.parse(groqApiUrl),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization':
  //           'Bearer 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', // Add your actual API key here
  //     },
  //     body: jsonEncode({
  //       'model': 'llama-3.1-70b-versatile',
  //       'messages': [
  //         {
  //           'role': 'user',
  //           'content': modifiedInput,
  //         }
  //       ],
  //       'temperature': 1,
  //       'max_tokens': 1024,
  //       'top_p': 1,
  //       'stream': false, // Keeping it simple without streaming
  //     }),
  //   );

  //   print('Response status: ${response.statusCode}');
  //   print('Response body: ${response.body}');

  //   if (response.statusCode == 200) {
  //     final responseBody = jsonDecode(response.body);
  //     // Debugging: Check the entire response body
  //     print('Decoded response: $responseBody');

  //     // Extract the relevant text from the response
  //     if (responseBody.containsKey('choices') &&
  //         responseBody['choices'].isNotEmpty &&
  //         responseBody['choices'][0].containsKey('message') &&
  //         responseBody['choices'][0]['message'].containsKey('content')) {
  //       return responseBody['choices'][0]['message']['content'] ??
  //           'No content returned';
  //     } else {
  //       throw Exception('Expected content structure not found in response');
  //     }
  //   } else {
  //     throw Exception('Failed to generate feedback: ${response.body}');
  //   }
  // }

// // Function to generate feedback using LLaMA from Hugging Face
//   Future<String> generateFeedbackWithLlama(String inputText) async {
//     const String apiKey = 'YOUR_NEW_TOKEN'; // Replace with your new API key
//     const String apiUrl =
//         'https://api-inference.huggingface.co/models/distilgpt2'; // Using DistilGPT-2 model

//     // Construct the input prompt
//     String modifiedInput =
//         "Elaborate on the following statement with enthusiasm: '$inputText'.";

//     // Make the API call
//     final response = await http.post(
//       Uri.parse(apiUrl),
//       headers: {
//         'Authorization': 'Bearer $apiKey',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'inputs': modifiedInput,
//         'options': {'use_cache': false}, // Optional settings
//       }),
//     );

//     // Log response status and body
//     print('Response status: ${response.statusCode}');
//     print('Response body: ${response.body}');

//     // Handle the response
//     if (response.statusCode == 200) {
//       final responseBody = jsonDecode(response.body);
//       if (responseBody is List && responseBody.isNotEmpty) {
//         return responseBody[0]['generated_text'] ?? 'No content returned';
//       } else {
//         throw Exception('Expected content structure not found in response');
//       }
//     } else {
//       throw Exception('Failed to generate feedback: ${response.body}');
//     }
//   }

// // Example function to call generateFeedbackWithLlama
//   Future<void> _generateDescription() async {
//     String inputText = _descriptionController.text
//         .trim(); // Assuming _descriptionController is defined
//     if (inputText.isNotEmpty) {
//       try {
//         String generatedText = await generateFeedbackWithLlama(inputText);
//         setState(() {
//           _descriptionController.text = generatedText;
//         });
//       } catch (e) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('Error: $e')));
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//           content:
//               Text('Hold on! It looks like your description field is empty')));
//     }
//   }

  Widget _buildImageUpload() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Row(
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: () =>
                      _images.length > 0 ? _deleteImage(0) : _pickImage(0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    height: 150,
                    width: 150,
                    color: Colors.grey[800],
                    child: _images.length > 0
                        ? Image.file(
                            File(_images[0].path),
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () =>
                      _images.length > 1 ? _deleteImage(1) : _pickImage(1),
                  child: Container(
                    height: 150,
                    width: 150,
                    color: Colors.grey[800],
                    child: _images.length > 1
                        ? Image.file(
                            File(_images[1].path),
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _images.length > 2 ? _deleteImage(2) : _pickImage(2),
              child: Container(
                height: 310,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: _images.length > 2
                    ? Image.file(
                        File(_images[2].path),
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _eventNameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _tagsController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  children: [
                    _buildPage1(),
                    _buildPage2(),
                    _buildPage3(),
                  ],
                ),
              ),
            ],
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: WormEffect(
                    radius: 5.0,
                    dotHeight: 4.0,
                    dotWidth: 70.0,
                    spacing: 8.0,
                    activeDotColor: orange,
                    type: WormType.thin,
                    dotColor: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onTap: () {
                    // Navigator.pushReplacement(context,
                    //     MaterialPageRoute(builder: (context) {
                    //   return CustomSplash(
                    //     image: "assets/images/connect.svg",
                    //     title: "Welcome aboard, ",
                    //     subTitle: "You're all set to ",
                    //     subTitle2: "Bridge the gap",
                    //     buttonName: "Get Started",
                    //     nextPath: "/home",
                    //   );
                    // }));
                    if (currentPage < 2) {
                      _controller.nextPage(
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeInOut);
                    } else {
                      _submit();
                    }
                  },
                  child: CustomButton(
                    color: orange,
                    name: (currentPage < 2 ? 'Next' : 'Submit'),
                  ),
                ),
                const SizedBox(
                  height: 30,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeaders(Header: "Event Name*", context: context),
            TextField(
              controller: _eventNameController,
              decoration: InputDecoration(
                  hintText: 'Event Name',
                  hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                  prefixIcon: const Icon(IconlyBold.ticket_star)),
            ),
            const SizedBox(
              height: 15,
            ),
            CustomHeaders(Header: "Event Description*", context: context),
            TextField(
              controller: _descriptionController,
              maxLines: 4, // Make the text field larger
              decoration: InputDecoration(
                prefixIcon: const Icon(IconlyBold.star),
                hintText: 'Give a quick overview of your event\n\n',
                hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                suffixIcon: GestureDetector(
                  onTap: _generateDescription,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      "assets/images/ai.png",
                      fit: BoxFit.contain,
                      height: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            CustomHeaders(Header: "Event Type*", context: context),
            Row(
              children: [
                Radio<String>(
                  value: 'In person',
                  groupValue: eventType,
                  onChanged: (value) {
                    setState(() {
                      eventType = value!;
                      _meetingLinkController
                          .clear(); // Clear meeting link if switching to In person
                    });
                  },
                ),
                Text(
                  'In person',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(),
                ),
                Radio<String>(
                  value: 'Virtual',
                  groupValue: eventType,
                  onChanged: (value) {
                    setState(() {
                      eventType = value!;
                    });
                  },
                ),
                Text(
                  'Virtual',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            if (eventType == 'In person') ...[
              CustomHeaders(Header: "Available Venues*", context: context),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  expansionTileTheme: const ExpansionTileThemeData(
                    textColor: orange,
                    iconColor: orange,
                    collapsedIconColor: Colors.black,
                  ),
                ),
                child: ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(IconlyBold.discovery),
                      const SizedBox(
                        width: 10,
                      ),
                      Flexible(
                        child: Text(
                          'Where will your event take place',
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    SizedBox(
                      height: 600,
                      child: ListView.builder(
                        itemCount: availableVenues.length,
                        itemBuilder: (context, index) {
                          var venue = availableVenues[index];
                          bool isSelected = selectedVenueIndex == index;

                          return GestureDetector(
                            onTap: () {
                              try {
                                VenueModel venueModel = VenueModel(
                                  UID: venue.id,
                                  name: venue['name'],
                                  address: venue['address'],
                                  city: venue['city'],
                                  owner: venue['owner'],
                                  description: venue['description'],
                                  capacity: venue['capacity'],
                                  facilities:
                                      List<String>.from(venue['facilities']),
                                  contactPerson: venue['contactPerson'],
                                  contactEmail: venue['contactEmail'],
                                  contactPhone: venue['contactPhone'],
                                  images: List<String>.from(venue['images']),
                                  reviews: List<Map<String, dynamic>>.from(
                                      venue['reviews'] ?? []),
                                  accessibilityInfo: venue['accessibilityInfo'],
                                  tags: List<String>.from(venue['tags']),
                                  Availibility:
                                      List<String>.from(venue['availability']),
                                  isAvailableAllTime:
                                      venue['isAvailableAllTime'],
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VenueDetailsScreen(venue: venueModel),
                                  ),
                                );
                              } catch (e) {
                                print('Error navigating to venue details: $e');
                              }
                            },
                            child: Container(
                              height: 200,
                              child: Card(
                                color: getRandomColor(),
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    if (venue['images'] != null &&
                                        venue['images'].isNotEmpty)
                                      Positioned.fill(
                                        child: PageView.builder(
                                          itemCount: venue['images'].length,
                                          itemBuilder: (context, imgIndex) {
                                            return Image.network(
                                              venue['images'][imgIndex],
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      ),

                                    // Foreground content
                                    Container(
                                      width: double.maxFinite,
                                      decoration: const BoxDecoration(
                                        color: Colors
                                            .black54, // Semi-transparent overlay
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
                                                  MainAxisAlignment.end,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    _onVenueSelected(
                                                        venue, index);
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                                Radius.circular(
                                                                    5)),
                                                        border: Border.all(
                                                          width: 1,
                                                          color: isSelected
                                                              ? Colors.green
                                                                  .shade400
                                                              : Colors.orange
                                                                  .shade400,
                                                        )),
                                                    child: Text(
                                                      isSelected
                                                          ? "Selected"
                                                          : "Select",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium!
                                                          .copyWith(
                                                            fontSize: 12,
                                                            color: isSelected
                                                                ? Colors.green
                                                                    .shade400
                                                                : Colors.orange
                                                                    .shade400,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                // const SizedBox(
                                                //   width: 8,
                                                // ),
                                                // GestureDetector(
                                                //     onTap: () {
                                                //       // String shareText = "Sharing link";
                                                //       // Share.share(shareText);
                                                //     },
                                                //     child: const Icon(
                                                //       IconlyBroken.bookmark,
                                                //       size: 20,
                                                //       color: primaryWhite,
                                                //     )),
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
                                                  venue['name'] ?? 'No name',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: primaryWhite,
                                                      ),
                                                ),

                                                Row(
                                                  children: [
                                                    if (venue['capacity'] !=
                                                        null)
                                                      Text(
                                                        "${venue['capacity']} Seating Limit",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium!
                                                            .copyWith(
                                                              fontSize: 12,
                                                              color:
                                                                  primaryWhite,
                                                            ),
                                                      ),
                                                    (venue['isAvailableAllTime'] ==
                                                            true)
                                                        ? Text(
                                                            " • 365-Day Available",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium!
                                                                .copyWith(
                                                                  fontSize: 12,
                                                                  color:
                                                                      primaryWhite,
                                                                ),
                                                          )
                                                        : Text(
                                                            " • Limited Day Availability",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium!
                                                                .copyWith(
                                                                  fontSize: 12,
                                                                  color:
                                                                      primaryWhite,
                                                                ),
                                                          ),
                                                    // if (venue['type'] ==
                                                    //         "offline" &&
                                                    //     venue['city'] != null)
                                                    //   Text(
                                                    //     ' • ${venue['city']} ',
                                                    //     style: Theme.of(context)
                                                    //         .textTheme
                                                    //         .bodyMedium!
                                                    //         .copyWith(
                                                    //           fontSize: 12,
                                                    //           color: primaryWhite,
                                                    //         ),
                                                    // ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    if (venue['city'] != null)
                                                      Text(
                                                        venue['city'],
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium!
                                                            .copyWith(
                                                              fontSize: 12,
                                                              color:
                                                                  primaryWhite,
                                                            ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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

                          return Card(
                            color: isSelected ? orange : Colors.white,
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(venue['name']),
                                  subtitle: Text(venue['city']),
                                  onTap: () {
                                    _onVenueSelected(venue, index);
                                  },
                                ),
                                TextButton(
                                  onPressed: () {
                                    try {
                                      VenueModel venueModel = VenueModel(
                                        UID: venue.id,
                                        name: venue['name'],
                                        address: venue['address'],
                                        city: venue['city'],
                                        owner: venue['owner'],
                                        description: venue['description'],
                                        capacity: venue['capacity'],
                                        facilities: List<String>.from(
                                            venue['facilities']),
                                        contactPerson: venue['contactPerson'],
                                        contactEmail: venue['contactEmail'],
                                        contactPhone: venue['contactPhone'],
                                        images:
                                            List<String>.from(venue['images']),
                                        reviews:
                                            List<Map<String, dynamic>>.from(
                                                venue['reviews'] ?? []),
                                        accessibilityInfo:
                                            venue['accessibilityInfo'],
                                        tags: List<String>.from(venue['tags']),
                                        Availibility: List<String>.from(
                                            venue['availability']),
                                        isAvailableAllTime:
                                            venue['isAvailableAllTime'],
                                      );

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              VenueDetailsScreen(
                                                  venue: venueModel),
                                        ),
                                      );
                                    } catch (e) {
                                      print(
                                          'Error navigating to venue details: $e');
                                    }
                                  },
                                  child: const Text('View More'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded(
              //   child: ListView.builder(
              //     itemCount: availableVenues.length,
              //     itemBuilder: (context, index) {
              //       var venue = availableVenues[index];
              //       bool isSelected = selectedVenueIndex == index;
              //       return Card(
              //         color: isSelected ? primaryBlack : Colors.white,
              //         child: Column(
              //           children: [
              //             ListTile(
              //               title: Text(venue['name']),
              //               subtitle: Text(venue['city']),
              //               onTap: () {
              //                 _onVenueSelected(venue, index);
              //               },
              //             ),
              //             TextButton(
              //               onPressed: () {
              //                 try {
              //                   VenueModel venueModel = VenueModel(
              //                     UID: venue.id,
              //                     name: venue['name'],
              //                     address: venue['address'],
              //                     city: venue['city'],
              //                     owner: venue['owner'],
              //                     description: venue['description'],
              //                     capacity: venue['capacity'],
              //                     facilities:
              //                         List<String>.from(venue['facilities']),
              //                     contactPerson: venue['contactPerson'],
              //                     contactEmail: venue['contactEmail'],
              //                     contactPhone: venue['contactPhone'],
              //                     images: List<String>.from(venue['images']),
              //                     reviews: List<Map<String, dynamic>>.from(
              //                         venue['reviews'] ?? []),
              //                     accessibilityInfo: venue['accessibilityInfo'],
              //                     tags: List<String>.from(venue['tags']),
              //                     Availibility:
              //                         List<String>.from(venue['availability']),
              //                     isAvailableAllTime: venue['isAvailableAllTime'],
              //                   );

              //                   Navigator.push(
              //                     context,
              //                     MaterialPageRoute(
              //                       builder: (context) =>
              //                           VenueDetailsScreen(venue: venueModel),
              //                     ),
              //                   );
              //                 } catch (e) {
              //                   print('Error navigating to venue details: $e');
              //                 }
              //               },
              //               child: const Text('View More'),
              //             ),
              //           ],
              //         ),
              //       );
              //     },
              //   ),
              // ),
            ] else ...[
              CustomHeaders(Header: "Meeting Link*", context: context),
              TextField(
                controller: _meetingLinkController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.link_rounded),
                  hintText: 'Provide link for online access',
                  hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomHeaders(Header: "Capacity*", context: context),
          TextField(
            controller: _capacityController,
            // readOnly: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(IconlyBold.user_3),
              hintText: 'Seating Limit: ${selectedVenueCapacity ?? ""}',
              hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),

              // labelText: 'Capacity (Max $capacityHintText)',
              // hintText: selectedVenueCapacity != null
              //     ? 'Enter event capacity here'
              //     : 'Select a venue to see capacity',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(
            height: 15,
          ),
          CustomHeaders(Header: "Date*", context: context),
          // if (isAvailableForever)
          //   GestureDetector(
          //     onTap: _pickDate,
          //     child: AbsorbPointer(
          //       child: TextField(
          //         decoration: InputDecoration(
          //           hintText: (formatDate(selectedDate.toString()) == "null")
          //               ? "Piate"
          //               : "${formatDate(selectedDate.toString())}",
          //           hintStyle:
          //               Theme.of(context).textTheme.bodySmall!.copyWith(),
          //           prefixIcon: const Icon(IconlyBold.calendar),
          //         ),
          //       ),
          //     ),
          //   ),
          if (eventType == 'In person')
            GestureDetector(
              onTap: availableDates == null || isAvailableForever
                  ? _pickDate
                  : _showAvailableDatesForInPerson,
              child: AbsorbPointer(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: (formatDate(selectedDate.toString()) == "null" ||
                            formatDate(selectedDate.toString()) == "Forever")
                        ? "Pick a Date"
                        : "${formatDate(selectedDate.toString())}",
                    prefixIcon: const Icon(IconlyBold.calendar),
                  ),
                ),
              ),
            ),
          if (eventType == 'Virtual') ...[
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextField(
                  // controller: _tagsController,
                  decoration: InputDecoration(
                    hintText: (formatDate(selectedDate.toString()) == "null")
                        ? "Pick a Date"
                        : "${formatDate(selectedDate.toString())}",
                    hintStyle:
                        Theme.of(context).textTheme.bodySmall!.copyWith(),
                    prefixIcon: const Icon(IconlyBold.calendar),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(
            height: 15,
          ),
          CustomHeaders(Header: "Time*", context: context),
          GestureDetector(
            onTap: _pickTime,
            child: AbsorbPointer(
              child: TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: selectedTime ?? 'Select Time',
                  prefixIcon: const Icon(IconlyBold.time_circle),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          if (eventType == 'In person')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomHeaders(Header: "Selected Venue*", context: context),

                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    fillColor: Colors.grey[300],
                    prefixIcon: const Icon(IconlyBold.discovery),
                    hintText: '${selectedVenue ?? "Choose your venue"}',
                    hintStyle:
                        Theme.of(context).textTheme.bodySmall!.copyWith(),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),

                CustomHeaders(Header: "Location*", context: context),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    fillColor: Colors.grey[300],
                    prefixIcon: const Icon(IconlyBold.location),
                    hintText: '${selectedVenueAddress ?? "Venue's address"}',
                    hintStyle:
                        Theme.of(context).textTheme.bodySmall!.copyWith(),
                  ),
                ),
                // Text('Address: $selectedVenueAddress'),
                // Text('City: $selectedCity'),

                CustomHeaders(Header: "Accessibility Info*", context: context),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    fillColor: Colors.grey[300],
                    prefixIcon: const Icon(Icons.wheelchair_pickup_rounded),
                    hintText:
                        '${selectedVenueAccessibility ?? "accessibility features of the venue"}',
                    hintStyle:
                        Theme.of(context).textTheme.bodySmall!.copyWith(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomHeaders(Header: "Tags*", context: context),
          GestureDetector(
            onTap: _showInterestsDialog,
            child: AbsorbPointer(
              child: TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                    prefixIcon: Icon(IconlyBold.star), labelText: 'Tags '),
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          CustomHeaders(Header: "Banner/Images*", context: context),
          _buildImageUpload(),
        ],
      ),
    );
  }
}

class CustomHeaders extends StatelessWidget {
  String Header;
  CustomHeaders({
    super.key,
    required this.context,
    required this.Header,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          Header,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 16,
                height: (20 / 16),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: 10,
        )
      ],
    );
  }
}
