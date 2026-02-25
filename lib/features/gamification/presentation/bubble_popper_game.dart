import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BubblePopperGame extends StatefulWidget {
  const BubblePopperGame({super.key});

  @override
  State<BubblePopperGame> createState() => _BubblePopperGameState();
}

class _BubblePopperGameState extends State<BubblePopperGame> {
  final List<Offset> _bubbles = [];
  int _score = 0;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _spawnBubbles();
  }

  void _spawnBubbles() {
    for (int i = 0; i < 10; i++) {
      _bubbles.add(Offset(_rnd.nextDouble() * 300, _rnd.nextDouble() * 500));
    }
  }

  void _popBubble(int index) {
    setState(() {
      _bubbles.removeAt(index);
      _score += 10;
    });
    if (_bubbles.isEmpty) {
      // Game Over / Win
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Urge Defeated!'),
          content: Text('You popped them all! Score: $_score'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pop the Urge')),
      body: Stack(
        children: [
          ..._bubbles.asMap().entries.map((entry) {
            return Positioned(
              left: entry.value.dx,
              top: entry.value.dy,
              child: GestureDetector(
                onTap: () => _popBubble(entry.key),
                child:
                    Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('😡', style: TextStyle(fontSize: 30)),
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          duration: 1.seconds,
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.1, 1.1),
                        ),
              ),
            );
          }),
          Positioned(
            top: 20,
            right: 20,
            child: Text(
              'Score: $_score',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
