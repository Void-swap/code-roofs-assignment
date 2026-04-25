import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:bloom/form.dart';
import 'package:bloom/screens/events/create_event.dart';
import 'package:bloom/screens/events/event_screen.dart';
import 'package:bloom/services/services.dart';
import 'package:bloom/utils/colors.dart';
import 'package:bloom/utils/custom_headers.dart';
import 'package:bloom/utils/reusable_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:vibration/vibration.dart';

class CreateVenueScreen extends StatefulWidget {
  @override
  _CreateVenueScreenState createState() => _CreateVenueScreenState();
}

class _CreateVenueScreenState extends State<CreateVenueScreen> {
  final PageController _controller = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _accessibilityInfoController =
      TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Use AudioCache for assets

  final List<XFile> _images = [];
  final List<String> _imageUrls = [];
  final List<String> _availableDays = [];

  int currentPage = 0;

  List<String> facilitiesOptions = [
    'Wi-Fi',
    'AV Equipment',
    'Parking',
    'Restrooms',
    'Wheelchair Access'
  ];
  List<bool> selectedFacilities = [false, false, false, false, false];

  // Availability options
  bool isAvailableForever = false;
  bool isAvailableSpecificDays = false;

  void _submit() async {
    if (_validateInputs()) {
      await _audioPlayer.setSource(AssetSource('success.mp3'));
      _audioPlayer.resume(); // Play the sound
      if (await Vibration.hasVibrator() != null) {
        Vibration.vibrate(duration: 500);
      }
      try {
        if (_images.isNotEmpty) {
          await _uploadImages();
        }
        UserService userService = UserService();
        String userName = userService.getUserName();
        String userPfp = userService.getUserProfilePic();
        String userUID = userService.getUserUID();
        Map<String, dynamic> newVenue = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'owner': userUID ?? 'No UID found',
          'capacity': int.tryParse(_capacityController.text) ?? 0,
          'tags':
              _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
          'facilities': selectedFacilities
              .asMap()
              .entries
              .where((entry) => entry.value)
              .map((entry) => facilitiesOptions[entry.key])
              .toList(),
          'contactPerson': _contactPersonController.text,
          'contactEmail': _contactEmailController.text,
          'contactPhone': _contactPhoneController.text,
          'accessibilityInfo': _accessibilityInfoController.text,
          'images': _imageUrls,
          'availability': isAvailableForever ? ['Forever'] : _availableDays,
          "reviews": [],
          "isAvailableAllTime": isAvailableForever,
        };

        DocumentReference docRef =
            await FirebaseFirestore.instance.collection('venues').add(newVenue);
        await docRef.update({'UID': docRef.id});
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venue created successfully!')));
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return CustomSplash(
            image: "assets/images/486.svg",
            title: "🌟 Yay! Your venue is now live!",
            subTitle:
                "We’re thrilled to have your space on board—exciting opportunities await!",
            buttonName: "Next",
            nextPath: "/home",
          );
        }));
      } catch (e) {
        print('Error creating venue: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create venue: $e')));
      }
    }
  }

  bool _validateInputs() {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _capacityController.text.isEmpty ||
        _contactPersonController.text.isEmpty ||
        _contactEmailController.text.isEmpty ||
        _contactPhoneController.text.isEmpty ||
        (!isAvailableForever && !isAvailableSpecificDays)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields!')));
      return false;
    }
    return true;
  }

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
    }
  }

  Future<void> _uploadImages() async {
    try {
      List<String> urls = [];
      for (var image in _images) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef =
            FirebaseStorage.instance.ref().child('eventImages').child(fileName);

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
      print('Error uploading images: $e');
    }
  }

  void _showCalendar() {
    showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _availableDays.add(selectedDate.toLocal().toString().split(' ')[0]);
        });
      }
    });
  }

  void _deleteImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
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
                  const Text('Select Interests'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Venue')),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomHeaders(Header: "Venue Name*", context: context),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Venue Name',
              hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
              prefixIcon: const Icon(IconlyBold.discovery),
            ),
          ),
          const SizedBox(height: 15),
          CustomHeaders(Header: "Description*", context: context),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                prefixIcon: const Icon(IconlyBold.star)),
          ),
          const SizedBox(height: 15),
          CustomHeaders(Header: "Address*", context: context),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
                hintText: 'Address',
                hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                prefixIcon: const Icon(IconlyBold.location)),
          ),
          const SizedBox(height: 15),
          CustomHeaders(Header: "City*", context: context),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
                hintText: 'City',
                hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                prefixIcon: const Icon(IconlyBold.location)),
          ),
          const SizedBox(height: 15),
          CustomHeaders(Header: "State*", context: context),
          TextField(
            controller: _stateController,
            decoration: InputDecoration(
                hintText: 'State',
                hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                prefixIcon: const Icon(IconlyBold.discovery)),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeaders(Header: "Capacity*", context: context),
            TextField(
              controller: _capacityController,
              decoration: InputDecoration(
                hintText: 'Maximum capacity',
                hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                prefixIcon: const Icon(IconlyBold.user_3),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            CustomHeaders(Header: "Accessibility Info*", context: context),
            TextField(
              controller: _accessibilityInfoController,
              decoration: InputDecoration(
                hintText: 'Enter accessibility info...',
                hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                prefixIcon: const Icon(Icons.wheelchair_pickup_rounded),
              ),
            ),
            const SizedBox(height: 15),
            const Text('Facilities:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ..._buildFacilitiesCheckboxes(),
            const SizedBox(height: 15),
            const Text('Availability:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Radio(
                  value: true,
                  groupValue: isAvailableForever,
                  onChanged: (value) {
                    setState(() {
                      isAvailableForever = true;
                      isAvailableSpecificDays = false;
                      _availableDays.clear();
                    });
                  },
                ),
                Text(
                  'Within the year',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(),
                ),
                Radio(
                  value: false,
                  groupValue: isAvailableForever,
                  onChanged: (value) {
                    setState(() {
                      isAvailableForever = false;
                      isAvailableSpecificDays = true;
                    });
                  },
                ),
                Text(
                  'Specific Days',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(),
                ),
              ],
            ),
            if (isAvailableSpecificDays) ...[
              GestureDetector(
                onTap: _showCalendar,
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      // labelText: 'Tags ',
                      hintText: 'Add Available Days',
                      hintStyle:
                          Theme.of(context).textTheme.bodySmall!.copyWith(),
                      prefixIcon: const Icon(IconlyBold.calendar),
                    ),
                  ),
                ),
              ),
              ..._availableDays
                  .map((date) => Text(
                      formatDate(
                        date.toString(),
                      ),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith()))
                  .toList(),
            ],
            SizedBox(
              height: 100,
            )
          ],
        ),
      ),
    );
  }

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

  List<Widget> _buildFacilitiesCheckboxes() {
    return List.generate(facilitiesOptions.length, (index) {
      return CheckboxListTile(
        title: Text(facilitiesOptions[index]),
        value: selectedFacilities[index],
        onChanged: (bool? value) {
          setState(() {
            selectedFacilities[index] = value!;
          });
        },
      );
    });
  }

  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeaders(context: context, Header: "Tags"),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: _showInterestsDialog,
              child: AbsorbPointer(
                child: TextField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    // labelText: 'Tags ',
                    hintText: 'Tags',
                    hintStyle:
                        Theme.of(context).textTheme.bodySmall!.copyWith(),
                    prefixIcon: const Icon(IconlyBold.star),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            CustomHeaders(context: context, Header: "Banner/Images"),
            const SizedBox(height: 5),
            Center(
              child: _buildImageUpload(),
            ),
            const SizedBox(height: 15),
            CustomHeaders(
                context: context, Header: "SPOC (Single point of contact):"),
            const SizedBox(height: 5),
            TextField(
              controller: _contactPersonController,
              decoration: InputDecoration(
                  hintText: 'Contact Person',
                  hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                  prefixIcon: const Icon(IconlyBold.profile)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _contactEmailController,
              decoration: InputDecoration(
                  hintText: 'Mail',
                  hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                  prefixIcon: const Icon(IconlyBold.message)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _contactPhoneController,
              decoration: InputDecoration(
                  hintText: 'Phone No.',
                  hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(),
                  prefixIcon: const Icon(IconlyBold.call)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
