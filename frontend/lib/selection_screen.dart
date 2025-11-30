import 'package:flutter/material.dart';
import 'parallel_Video.dart';
import 'history.dart';
import 'pilote_data.dart';

class SelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Personal Heart Monitor')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Today's Practice",
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 80),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BiofeedbackScreen()),
                );
              },
              child: Text("Start", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconButton(context, 'assets/history_icon.png', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SessionListPage()),
                  );
                }),
                _buildIconButton(context, 'assets/profile_icon.png', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SessionDataPage()),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, String assetPath, VoidCallback onTap) {
    return IconButton(
      icon: Image.asset(
        assetPath,
        width: MediaQuery.of(context).size.width * 0.1,
        height: MediaQuery.of(context).size.width * 0.1,
      ),
      onPressed: onTap,
    );
  }
}
