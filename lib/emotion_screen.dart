import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  EmotionScreenState createState() => EmotionScreenState();
}

class EmotionScreenState extends State<EmotionScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _predictedEmotion;
  Map<String, dynamic>? _confidenceScores;
  bool _loading = false;
  String _error = '';

  Future<void> _predictEmotion(String text) async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final url = Uri.parse('http://0.0.0.0:5000/predict'); // Replace <YOUR_IP>

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _predictedEmotion = data['predicted_emotion'];
          _confidenceScores = Map<String, dynamic>.from(
            data['confidence_scores'],
          );
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Server error: ${response.statusCode}";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  Widget _buildConfidenceScores() {
    if (_confidenceScores == null) return SizedBox.shrink();
    final entries =
        _confidenceScores!.entries.toList()..sort(
          (a, b) => b.value.compareTo(a.value),
        ); // Sort by confidence descending

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: LinearProgressIndicator(
                value: entry.value.toDouble(),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  entry.key == _predictedEmotion ? Colors.blue : Colors.grey,
                ),
                minHeight: 20,
                semanticsLabel: entry.key,
                semanticsValue: '${(entry.value * 100).toStringAsFixed(1)}%',
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Emotion Detector")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Enter text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  _loading
                      ? null
                      : () => _predictEmotion(_controller.text.trim()),
              child:
                  _loading
                      ? CircularProgressIndicator()
                      : Text("Detect Emotion"),
            ),
            const SizedBox(height: 20),
            if (_error.isNotEmpty)
              Text(_error, style: TextStyle(color: Colors.red)),
            if (_predictedEmotion != null)
              Text(
                "Predicted Emotion: $_predictedEmotion",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 10),
            _buildConfidenceScores(),
          ],
        ),
      ),
    );
  }
}
