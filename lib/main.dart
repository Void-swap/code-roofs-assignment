import 'package:bloom/register_login.dart';
import 'package:bloom/screens/careers/create_career.dart';
import 'package:bloom/screens/events/create_event.dart';
import 'package:bloom/screens/events/my_events_volunteer_screen.dart';
import 'package:bloom/screens/events/verify_event.dart';
import 'package:bloom/screens/home_screen.dart';
import 'package:bloom/screens/profile/verify_screen.dart';
import 'package:bloom/screens/venue/create_venue.dart';
import 'package:bloom/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: "AIzaSyBpZcfdbZoBX_rHNa7K7TMNU7Y-yjoFzlk",
    projectId: "mumbai-hacks9",
    storageBucket: "mumbai-hacks9.appspot.com",
    messagingSenderId: "727309139299",
    appId: "1:727309139299:web:71f15c8008a12a95d6e756",
  ));

  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bloom',
      theme: ThemeData(
        primaryColor: const Color(0xFFF78104),
        secondaryHeaderColor: const Color(0xFF9262BF),
        hintColor: const Color(0xFF20706B),
        scaffoldBackgroundColor: primaryWhite,
        cardColor: const Color(0xFFFFFFFF),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: const Color(0xFFf2f2f2),
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryBlack, width: 0.9),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: orange, width: 1.5),
          ),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: primaryBlack,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIconColor: primaryBlack,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: primaryWhite,
          titleTextStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: primaryBlack,
              fontSize: 24,
              fontFamily: "Poppins"),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: orange,
          contentTextStyle: TextStyle(
            color: primaryWhite,
          ),
          actionTextColor: primaryBlack,
          behavior: SnackBarBehavior.floating,
          insetPadding: EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFFF78104),
          textTheme: ButtonTextTheme.primary,
        ),
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme(
          primary: Color(0xFFF78104),
          secondary: Color(0xFF9262BF),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFFFFFFF),
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF121212),
          onBackground: Color(0xFF121212),
          onError: Colors.white,
          brightness: Brightness.light,
        ).copyWith(background: Color(0xFFFFFFFF)),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: primaryBlack,
            fontSize: 18,
          ),
          bodySmall: TextStyle(
              color: primaryBlack, fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(
              val: 1,
            ),
        '/registerLogin': (context) => const RegisterLogin(),
        '/verifyMe': (context) => const GetVerifiedScreen(),
        '/createEvent': (context) => CreateEventScreen(),
        '/verifyEvent': (context) => const VerifyEventScreen(),
        '/createVenue': (context) => CreateVenueScreen(),
        '/createCareer': (context) => CreateCareerScreen(),
        '/myEvents': (context) => MyEventScreen(),
      },
    );
  }
}
