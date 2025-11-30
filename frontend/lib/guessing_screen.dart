import 'package:flutter/material.dart';
import 'parallel_Video.dart';
import 'animated_video_page.dart';

class GuessingScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const GuessingScreen({required this.data});

  @override
  _GuessingScreenState createState() => _GuessingScreenState();
}

class _GuessingScreenState extends State<GuessingScreen> {
  final TextEditingController _guessController = TextEditingController();
  bool _submittedGuess = false;
  int? _userGuess;
  bool _videoStage = false;
  bool _selectionMade = false;
  bool? _isCorrect;
  bool _showSignal = false;

  late List<double> realPeaks;
  late List<double> fakePeaks;
  late List<double> cleanSignal;
  late int peaksCount;
  late double duration;

  @override
  void initState() {
    super.initState();
    realPeaks = List<double>.from(widget.data["real_peaks"]);
    fakePeaks = List<double>.from(widget.data["fake_peaks"]);
    cleanSignal = List<double>.from(widget.data["clean_signal"]);
    peaksCount = widget.data["peaks_count"];
    duration = widget.data["duration"].toDouble();
  }

  void _submitGuess() {
    if (_guessController.text.isEmpty) return;
    setState(() {
      _userGuess = int.tryParse(_guessController.text);
      _submittedGuess = true;
      _videoStage = true;
    });
  }

  void _playAndSelect(List<double> peaks, bool isReal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimatedVideoPage(
          peaks: peaks,
          duration: duration,
          onFinished: () {
            setState(() {
              _selectionMade = true;
              _isCorrect = isReal;
            });

            Future.delayed(Duration(seconds: 2), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => BiofeedbackScreen()),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _videoButton({required String label, required List<double> peaks, required bool isReal}) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnimatedVideoPage(
                  peaks: peaks,
                  duration: duration,
                  onFinished: () {},
                ),
              ),
            );
          },
          child: Container(
            width: 160,
            height: 90,
            color: Colors.grey[800],
            child: Center(
              child: Text("Tap to play", style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _selectionMade
              ? null
              : () {
                  setState(() {
                    _selectionMade = true;
                    _isCorrect = isReal;
                  });

                  Future.delayed(Duration(seconds: 2), () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => BiofeedbackScreen()),
                    );
                  });
                },
          child: Text("This is real"),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Guessing")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: !_submittedGuess
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "How many beats did you count?",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _guessController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white, fontSize: 24),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[800],
                        hintText: "Enter number",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitGuess,
                      child: Text("Submit"),
                    )
                  ],
                )
              : !_videoStage
                  ? SizedBox()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "You guessed: $_userGuess\nActual: $peaksCount",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40),
                        Text(
                          "Which animation is the real one?",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _videoButton(label: "Option 1", peaks: realPeaks, isReal: true),
                            _videoButton(label: "Option 2", peaks: fakePeaks, isReal: false),
                          ],
                        ),
                        if (_selectionMade) ...[
                          SizedBox(height: 30),
                          Text(
                            _isCorrect == true ? "✅ Correct!" : "❌ Incorrect",
                            style: TextStyle(
                              color: _isCorrect == true ? Colors.green : Colors.red,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () => setState(() => _showSignal = !_showSignal),
                          child: Text(_showSignal ? "Hide Signal" : "Show Signal"),
                        ),
                        if (_showSignal)
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: SignalPainter(cleanSignal),
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class SignalPainter extends CustomPainter {
  final List<double> signal;

  SignalPainter(this.signal);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (signal.isEmpty) return;

    final maxVal = signal.reduce((a, b) => a > b ? a : b);
    final minVal = signal.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs() + 1e-6;

    for (int i = 0; i < signal.length; i++) {
      double x = (i / (signal.length - 1)) * size.width;
      double y = size.height - ((signal[i] - minVal) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
