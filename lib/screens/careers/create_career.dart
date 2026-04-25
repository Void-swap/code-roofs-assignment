import 'dart:math';

import 'package:bloom/form.dart';
import 'package:bloom/services/services.dart';
import 'package:bloom/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:faker/faker.dart';

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
  final faker = Faker();

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
                    // ------------------------------------------ Adding fake data -----------------------------------------------------------------
                    final dummyOrgNames = [
                      'Google',
                      'Microsoft',
                      'Amazon',
                      'Meta',
                      'Apple',
                      'Netflix',
                      'Adobe',
                      'Salesforce',
                      'IBM',
                      'Oracle',
                      'SAP',
                      'Accenture',
                      'Infosys',
                      'TCS',
                      'Wipro',
                      'Capgemini',
                      'NVIDIA',
                      'Flipkart',
                      'Paytm',
                      'Zoho',
                      'Freshworks',
                      'Cognizant',
                      'HCLTech',
                      'Swiggy',
                      'Zomato',
                      'Ola',
                      'Udaan',
                      'Byjus',
                      'Delhivery',
                      'Bytewave',
                      'PixelWorks',
                      'Nova Labs',
                      'Blueleaf',
                      'NextWave',
                      'Harbor Soft',
                      'Aperture Tech'
                    ];

                    final jobTypes = [
                      'Internship',
                      'Full-Time',
                      'Part-Time',
                      'Freelance'
                    ];
                    final workModes = ['Remote', 'Hybrid', 'On-site'];

                    final locations = [
                      'Mumbai',
                      'Bangalore',
                      'Delhi',
                      'Pune',
                      'Chennai',
                      'Hyderabad',
                      'Kolkata',
                      'Gurgaon'
                    ];
                    final perks = [
                      'Flexible Hours',
                      'Health Insurance',
                      'Free Meals',
                      'Work From Home',
                      'Learning Stipend',
                      'Gym Membership',
                      'Office Parties',
                      'Travel Allowance',
                    ];

                    final List<String> dummySkills = [
                      // Technical / Hard

                      'Big Data',
                      'Tableau',
                      'PowerBI',
                      'Excel',

                      'Video Editing',

                      'Storyboarding',
                      // Marketing & Sales
                      'Digital Marketing', 'SEO', 'SEM', 'Google Analytics',
                      'Social Media',
                    ];

                    final List<String> positions = [
                      'Software Engineer',
                      'Frontend Developer',
                      'Backend Developer',
                      'Full Stack Developer',
                      'Mobile Developer',
                      'iOS Developer',
                      'Android Developer',
                      'Flutter Developer',
                      'React Native Developer',
                      'Data Analyst',
                      'Data Engineer',
                      'Business Intelligence Engineer',
                      'Machine Learning Engineer',
                      'AI Researcher',
                      'DevOps Engineer',
                      'Site Reliability Engineer',
                      'Cloud Architect',
                      'Security Analyst',
                      'Penetration Tester',
                      'QA Engineer',
                      'Test Automation Engineer',
                      'Performance Engineer',
                      'UI/UX Designer',
                      'Product Designer',
                      'Graphic Designer',
                      'Motion Designer',
                      'Visual Designer',
                      'Product Manager',
                      'Project Manager',
                      'Program Manager',
                      'Business Analyst',
                      'Scrum Master',
                      'Digital Marketer',
                      'Growth Marketer',
                      'Content Strategist',
                      'SEO Specialist',
                      'PPC Specialist',
                      'Content Writer',
                      'Technical Writer',
                      'Copywriter',
                      'Social Media Manager',
                      'Sales Executive',
                      'Account Manager',
                      'Business Development Representative',
                      'Customer Success Manager',
                      'Customer Support',
                      'Technical Support Engineer',
                      'HR Executive',
                      'Talent Acquisition Specialist',
                      'Finance Associate',
                      'Accounting Analyst',
                      'Operations Executive',
                      'Logistics Coordinator',
                      'Research Scientist',
                      'Clinical Researcher',
                      'Laboratory Technician',
                      'Quality Assurance Specialist'
                    ];

                    final List<String> responsibilities = [
                      'Develop and maintain software applications; review code and follow best practices.',
                      'Collaborate with cross-functional teams to deliver product features on schedule.',
                      'Design, implement and optimize APIs and backend services for scalability.',
                      'Create responsive and accessible UI components; improve user experience.',
                      'Analyze datasets, build dashboards and provide actionable business insights.',
                      'Build and maintain CI/CD pipelines and cloud infrastructure; automate deployments.',
                      'Conduct user research, design wireframes and high-fidelity prototypes.',
                      'Plan and execute digital marketing campaigns; monitor KPIs and optimise ROI.',
                      'Write technical documentation, help articles and content for the web.',
                      'Manage project timelines, coordinate stakeholders and ensure delivery quality.',
                      'Perform security assessments and implement protective measures.',
                      'Implement testing strategies and maintain automated test suites.',
                      'Partner with product to define requirements and prioritise roadmap items.',
                      'Support customers with technical troubleshooting and issue resolution.',
                      'Prepare financial reports, assist with budgeting and forecasting.',
                      'Design experiments, run A/B tests and measure impact of product changes.',
                      'Lead hiring efforts, onboard new employees and manage HR processes.',
                      'Optimize infrastructure costs and improve system observability and monitoring.'
                    ];

                    for (int i = 0; i < 1000; i++) {
                      final careerData = {
                        'uid': faker.guid.guid(),
                        'name': faker.randomGenerator.element(dummyOrgNames),
                        'pfpImageURL': faker.image.image(random: true),
                        'type': faker.randomGenerator.element(jobTypes),
                        'position': faker.randomGenerator.element(positions),
                        'responsibility': List.generate(
                          5,
                          (_) =>
                              faker.randomGenerator.element(responsibilities),
                        ).join(', '),
                        'duration': '${random.integer(12, min: 1)} months',
                        'workMode': faker.randomGenerator.element(workModes),
                        'location': faker.randomGenerator.element(locations),
                        'startDate': DateTime.now()
                            .add(Duration(
                                days: faker.randomGenerator.integer(30)))
                            .toString(),
                        'pay': (Random().nextInt(200000) + 10000),
                        'partFull': faker.randomGenerator
                            .element(['Part-time', 'Full-time']),
                        'numberOfOpenings':
                            faker.randomGenerator.integer(10, min: 1),
                        'perks': List.generate(
                          5,
                          (_) => faker.randomGenerator.element(perks),
                        ),
                        'skills': List.generate(
                          5,
                          (_) => faker.randomGenerator.element(dummySkills),
                        ),
                        'listingBy': userUID,
                        'createdOn': Timestamp.fromDate(
                          DateTime.now().subtract(Duration(
                            days: faker.randomGenerator.integer(730),
                            hours: faker.randomGenerator.integer(24),
                            minutes: faker.randomGenerator.integer(60),
                          )),
                        ),
                      };

                      DocumentReference docRef = await FirebaseFirestore
                          .instance
                          .collection('careers')
                          .add(careerData);

                      await docRef.update({
                        'uid': docRef.id,
                      });

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userUID)
                          .update({
                        'listingCreated': FieldValue.arrayUnion([docRef.id]),
                      });
                    }

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
