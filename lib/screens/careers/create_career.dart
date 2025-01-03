import 'package:bloom/form.dart';
import 'package:bloom/services/services.dart';
import 'package:bloom/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';

class CreateCareerScreen extends StatefulWidget {
  @override
  _CreateCareerScreenState createState() => _CreateCareerScreenState();
}

class _CreateCareerScreenState extends State<CreateCareerScreen> {
  final _formKey = GlobalKey<FormState>();
  String? jobType;
  String? position;
  String? responsibility;
  String? duration;
  String? durationUnit;
  String? workMode;
  String? location;
  String? startDate;
  String? payType;
  double? payAmount;
  String? partFull;
  String? numberOfOpenings;
  List<String> perks = [];
  List<String> selectedSkills = [];
  List<String> dummyRoles = [
    // 'Software Engineer',
    // 'Data Analyst',
    // 'Project Manager'
  ];
  List<String> dummySkills = ['Python', 'Flutter', 'Java', 'JavaScript'];
  Timestamp createdOn = Timestamp.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Job")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Type*",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: RadioListTile(
                      title: Text(
                        "Internship",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              color: primaryBlack,
                            ),
                      ),
                      value: "Internship",
                      groupValue: jobType,
                      onChanged: (value) => setState(() {
                        jobType = value as String?;
                      }),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: RadioListTile(
                      title: Text(
                        "Apprenticeship",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              color: primaryBlack,
                            ),
                      ),
                      value: "Apprenticeship",
                      groupValue: jobType,
                      onChanged: (value) => setState(() {
                        jobType = value as String?;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Position*",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 5),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }

                  return dummyRoles.where((String option) {
                    return option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()) ||
                        option.toLowerCase() ==
                            textEditingValue.text.toLowerCase();
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    position = selection;
                    if (!dummyRoles.contains(selection)) {
                      dummyRoles.add(selection);
                    }
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onEditingComplete) {
                  return TextFormField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(IconlyBold.profile),
                      hintText: "Eg: Product Intern",
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 14,
                                color: primaryBlack,
                              ),
                    ),
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    onChanged: (value) {
                      position = value;
                    },
                    validator: (value) =>
                        value!.isEmpty ? "Please select a position" : null,
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                "Responsibility*",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                maxLines: 4,
                decoration: InputDecoration(
                  prefixIcon: Icon(IconlyBold.work),
                  hintText:
                      "Day to day responsibilities should include:*\n\n1.\n\n2.\n\n3.",
                  hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 14,
                        color: primaryBlack,
                      ),
                ),
                onChanged: (value) => responsibility = value,
                validator: (value) =>
                    value!.isEmpty ? "Please enter responsibility" : null,
              ),
              const SizedBox(height: 10),
              Text(
                "Duration*",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(IconlyBold.time_square),
                        hintText: "Eg: 6 Months",
                        hintStyle:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 14,
                                  color: primaryBlack,
                                ),
                      ),
                      onChanged: (value) => duration = value,
                      validator: (value) =>
                          value!.isEmpty ? "Please enter duration" : null,
                    ),
                  ),
                  DropdownButton<String>(
                    hint: Text(
                      "Months",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 14,
                            color: primaryBlack,
                          ),
                    ),
                    value: durationUnit,
                    items: ["Days", "Months", "Years"].map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(
                          unit,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 14,
                                    color: primaryBlack,
                                  ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        durationUnit = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Work Mode*",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Row(
                children: [
                  Flexible(
                    child: RadioListTile(
                      title: Text(
                        "In Office",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              color: primaryBlack,
                            ),
                      ),
                      value: "In Office",
                      groupValue: workMode,
                      onChanged: (value) => setState(() {
                        workMode = value as String?;
                      }),
                    ),
                  ),
                  Flexible(
                    child: RadioListTile(
                      title: Text(
                        "Hybrid",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              color: primaryBlack,
                            ),
                      ),
                      value: "Hybrid",
                      groupValue: workMode,
                      onChanged: (value) => setState(() {
                        workMode = value as String?;
                      }),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Flexible(
                    child: RadioListTile(
                      title: Text(
                        "Remote",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              color: primaryBlack,
                            ),
                      ),
                      value: "Remote",
                      groupValue: workMode,
                      onChanged: (value) => setState(() {
                        workMode = value as String?;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Office Location*",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Icon(IconlyBold.location),
                  hintText: "Eg: Bandra",
                  hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 14,
                        color: primaryBlack,
                      ),
                ),
                onChanged: (value) => location = value,
                validator: (value) =>
                    value!.isEmpty ? "Please enter location" : null,
              ),
              const SizedBox(height: 10),
              Text(
                "Start Date*",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2026),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      startDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(IconlyBold.calendar),
                      hintText: startDate ?? "Select Start Date",
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 14,
                                color: primaryBlack,
                              ),
                    ),
                    // validator: (value) =>
                    //     value!.isEmpty ? "Please start date" : null,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Pay*",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: Text(
                        "Unpaid",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              color: primaryBlack,
                            ),
                      ),
                      value: "Unpaid",
                      groupValue: payType,
                      onChanged: (value) {
                        setState(() {
                          payType = value as String?;
                          if (payType == "Unpaid") {
                            payAmount = null;
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: Text(
                        "Paid",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              color: primaryBlack,
                            ),
                      ),
                      value: "Paid",
                      groupValue: payType,
                      onChanged: (value) {
                        setState(() {
                          payType = value as String?;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (payType == "Paid")
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(IconlyBold.wallet),
                    hintText: "Eg: 9000/- Monthly",
                    hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          color: primaryBlack,
                        ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => payAmount = double.tryParse(value),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter amount" : null,
                ),
              const SizedBox(height: 10),
              Text(
                "Part/Full Time",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: Text(
                        "Part-Time",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              color: primaryBlack,
                            ),
                      ),
                      value: "Part-Time",
                      groupValue: partFull,
                      onChanged: (value) => setState(() {
                        partFull = value as String?;
                      }),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: Text(
                        "Full-Time",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              color: primaryBlack,
                            ),
                      ),
                      value: "Full-Time",
                      groupValue: partFull,
                      onChanged: (value) => setState(() {
                        partFull = value as String?;
                      }),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                "Number of opening",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "Eg: 5",
                  prefixIcon: Icon(IconlyBold.user_3),
                  hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 14,
                        color: primaryBlack,
                      ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => numberOfOpenings = value,
                validator: (value) =>
                    value!.isEmpty ? "Please enter number of openings" : null,
              ),
              SizedBox(height: 10),
              Text(
                "Perks",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              ...[
                "Letter of Recomendation",
                "Flexible Hours",
                "Informal dress code",
                "Travel allowance",
                "Certificate"
              ].map((perk) {
                return CheckboxListTile(
                  title: Text(perk),
                  value: perks.contains(perk),
                  onChanged: (isChecked) {
                    setState(() {
                      if (isChecked!) {
                        perks.add(perk);
                      } else {
                        perks.remove(perk);
                      }
                    });
                  },
                );
              }).toList(),
              SizedBox(height: 10),
              Text(
                "What skill sets are you looking for?*",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      height: (20 / 16),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 5),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }

                  return dummySkills.where((String option) {
                    return option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()) ||
                        option.toLowerCase() ==
                            textEditingValue.text.toLowerCase();
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    selectedSkills.add(selection);
                    if (!dummySkills.contains(selection)) {
                      dummySkills.add(selection);
                    }
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onEditingComplete) {
                  return TextFormField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(IconlyBold.star),
                      hintText: "Skills",
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 14,
                                color: primaryBlack,
                              ),
                    ),
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    onChanged: (value) {
                      selectedSkills =
                          value.split(',').map((s) => s.trim()).toList();
                    },
                  );
                },
              ),
              Text("${selectedSkills.join(", ")}"),
              SizedBox(
                height: 30,
              ),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    UserService userService = UserService();
                    String userName = userService.getUserName();
                    String userPfp = userService.getUserProfilePic();
                    String userUID = userService.getUserUID();

                    if (_formKey.currentState!.validate()) {
                      final jobData = {
                        'uid': '',
                        'name': userName,
                        'pfpImageURL': userPfp,
                        'jobType': jobType,
                        'position': position,
                        'responsibility': responsibility,
                        'duration': '$duration $durationUnit',
                        'workMode': workMode,
                        'location': location,
                        'startDate': startDate?.toString(),
                        'pay': payType == "Paid"
                            ? 'Paid: \$${payAmount?.toStringAsFixed(2)}'
                            : 'Unpaid',
                        'partFull': partFull,
                        'numberOfOpenings': numberOfOpenings,
                        'perks': perks,
                        'skills': selectedSkills,
                        'listingBy': userUID,
                        'createdOn': Timestamp.now(),
                      };

                      try {
                        DocumentReference docRef = await FirebaseFirestore
                            .instance
                            .collection('careers')
                            .add(jobData);

                        await docRef.update({
                          'uid': docRef.id,
                        });

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userUID)
                            .update({
                          'listingCreated': FieldValue.arrayUnion([docRef.id]),
                        });

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Job created successfully!")));
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Failed to create job: $error")));
                      }
                    }
                  },
                  child: CustomButton(
                    color: orange,
                    name: ("Create Listing"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
