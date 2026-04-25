import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, double> rolesData = {};
  Map<String, double> interestsData = {};
  Map<String, double> skillsData = {};

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchCareerData();
  }

  Future<void> fetchUserData() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> users = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      await analyzeUserData(users);
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> fetchCareerData() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('careers').get();
      List<Map<String, dynamic>> careers = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      await analyzeCareers(careers);
    } catch (e) {
      print("Error fetching career data: $e");
    }
  }

  Future<void> analyzeUserData(List<Map<String, dynamic>> users) async {
    await analyzeRoles(users);
    await analyzeInterests(users);
  }

  Future<void> analyzeRoles(List<Map<String, dynamic>> users,
      {int retries = 3}) async {
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
    const String apiKey = 'AIzaSyDT_p6t2MjZhrfNocqQri2ovGPeqrV_n08';

    String prompt =
        "Based on the following user data, provide only the role percentages in this format: Role1: X%, Role2: Y%, ... without any additional text.\n\nUser data: ${json.encode(users)}";

    while (retries > 0) {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final text =
            responseBody['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text != null) {
          final percentages = _extractPercentages(text);
          if (percentages.isNotEmpty) {
            setState(() {
              rolesData = percentages;
            });
          } else {
            print("No valid percentages found.");
          }
          return;
        }
      } else {
        print("Error: ${response.body}");
        retries--;
        if (retries == 0) {
          print("Final failure after retries.");
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> analyzeInterests(List<Map<String, dynamic>> users,
      {int retries = 3}) async {
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
    const String apiKey = 'AIzaSyDT_p6t2MjZhrfNocqQri2ovGPeqrV_n08';

    List<String> interestsList = [];
    for (var user in users) {
      if (user['interests'] is List) {
        for (var interest in user['interests']) {
          if (interest is String && interest.isNotEmpty) {
            interestsList.add(interest);
          }
        }
      }
    }

    if (interestsList.isEmpty) {
      print("No valid interests found.");
      return;
    }

    String prompt =
        "Based on the following list of interests: [${interestsList.join(', ')}], please provide only the interest percentages in this format: Interest1: X%, Interest2: Y%, ... without any additional text.";

    while (retries > 0) {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final text =
            responseBody['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text != null) {
          final percentages = _extractPercentages(text);
          if (percentages.isNotEmpty) {
            setState(() {
              interestsData = percentages;
            });
          } else {
            print("No valid percentages found for interests.");
          }
          return;
        }
      } else {
        print("Error: ${response.body}");
        retries--;
        if (retries == 0) {
          print("Final failure after retries.");
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> analyzeCareers(List<Map<String, dynamic>> careers,
      {int retries = 3}) async {
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
    const String apiKey = 'AIzaSyDT_p6t2MjZhrfNocqQri2ovGPeqrV_n08';

    List<String> skillsList = [];
    for (var career in careers) {
      if (career['skills'] is List) {
        for (var skill in career['skills']) {
          if (skill is String && skill.isNotEmpty) {
            skillsList.add(skill);
          }
        }
      }
    }

    if (skillsList.isEmpty) {
      print("No valid skills found.");
      return;
    }

    String prompt =
        "Based on the following list of skills: [${skillsList.join(', ')}], please provide only the skill percentages in this format: Skill1: X%, Skill2: Y%, ... without any additional text.";

    while (retries > 0) {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final text =
            responseBody['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text != null) {
          final percentages = _extractPercentages(text);
          if (percentages.isNotEmpty) {
            setState(() {
              skillsData = percentages;
            });
          } else {
            print("No valid percentages found for skills.");
          }
          return;
        }
      } else {
        print("Error: ${response.body}");
        retries--;
        if (retries == 0) {
          print("Final failure after retries.");
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Map<String, double> _extractPercentages(String content) {
    final RegExp regex = RegExp(r'(\w+): ([\d.]+)%');
    final matches = regex.allMatches(content);

    Map<String, double> percentages = {};
    for (var match in matches) {
      final role = match.group(1);
      final percentageStr = match.group(2);

      if (role != null && percentageStr != null) {
        final percentage = double.tryParse(percentageStr);
        if (percentage != null) {
          percentages[role] = percentage;
        }
      }
    }
    return percentages;
  }

  List<PieChartSectionData> _getRoleSections() {
    return rolesData.entries.map((entry) {
      final percentage = entry.value;
      final title = '${entry.key}\n${percentage.toStringAsFixed(1)}%';

      return PieChartSectionData(
        value: percentage,
        title: title,
        color: Colors.primaries[rolesData.keys.toList().indexOf(entry.key) %
            Colors.primaries.length],
        titleStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 12,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _getInterestSections() {
    return interestsData.entries.map((entry) {
      final percentage = entry.value;
      final title = '${entry.key}\n${percentage.toStringAsFixed(1)}%';

      return PieChartSectionData(
        value: percentage,
        title: title,
        color: Colors.primaries[interestsData.keys.toList().indexOf(entry.key) %
            Colors.primaries.length],
        titleStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 12,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _getSkillsSections() {
    return skillsData.entries.map((entry) {
      final percentage = entry.value;
      final title = '${entry.key}\n${percentage.toStringAsFixed(1)}%';

      return PieChartSectionData(
        value: percentage,
        title: title,
        color: Colors.primaries[skillsData.keys.toList().indexOf(entry.key) %
            Colors.primaries.length],
        titleStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 12,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Center(
        child: rolesData.isEmpty && interestsData.isEmpty && skillsData.isEmpty
            ? CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Text('Roles Distribution'),
                    Container(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: _getRoleSections(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Interests Distribution'),
                    Container(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: _getInterestSections(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Skills Distribution'),
                    Container(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: _getSkillsSections(),
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
