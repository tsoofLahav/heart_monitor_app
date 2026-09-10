import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/shell/selection_screen.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Gradual fade effect
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..forward();

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Navigate to selection page after welcome animation
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SelectionScreen()),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  context.l10n.welcomeToHeartMonitor,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppType.metric, // Larger text
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: ".SF Pro Display",
                  ),
                ),
              ),
              SizedBox(height: 40), // More spacing
              Image.asset(
                'assets/logo_monitor_mark.png',
                width: 168,
                height: 168,
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
