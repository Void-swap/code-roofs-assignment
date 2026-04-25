import 'package:bloom/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomSplash extends StatefulWidget {
  const CustomSplash(
      {super.key,
      required this.image,
      required this.title,
      this.subTitle,
      this.buttonName,
      this.nextPath,
      this.subTitle2});
  final String image;
  final String title;
  final String? subTitle;
  final String? subTitle2;
  final String? buttonName;
  //if path empty means POP
  final String? nextPath;

  @override
  State<CustomSplash> createState() => _CustomSplashState();
}

class _CustomSplashState extends State<CustomSplash> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: primaryWhite,
      height: screenHeight,
      width: screenWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(),
            Column(
              children: [
                SvgPicture.asset(
                  widget.image,
                  height: 200,
                ),
                SizedBox(height: 20),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: primaryBlack,
                      fontFamily: "Poppins",
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none),
                ),
                if (widget.subTitle != null && widget.subTitle2 == null)
                  Text(
                    widget.subTitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: primaryBlack,
                        fontFamily: "Poppins",
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none),
                  ),
                if (widget.subTitle2 != null && widget.subTitle != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.subTitle!,
                        style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: primaryBlack,
                            decoration: TextDecoration.none),
                      ),
                      Text(
                        widget.subTitle2!,
                        style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: orange,
                            decoration: TextDecoration.none),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(),
            if (widget.buttonName != null && widget.nextPath != null)
              SizedBox(
                height: 50,
                width: double.maxFinite,
                child: ElevatedButton(
                  onPressed: () => widget.nextPath != ""
                      ? Navigator.pushReplacementNamed(
                          context, widget.nextPath!)
                      : Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.buttonName!,
                    style: TextStyle(
                      color: primaryWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
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
