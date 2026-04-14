import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import 'game_screen.dart';

class ResultsView extends StatelessWidget {
  final String code;
  final Map<String, dynamic> room;
  final List<Map<String, dynamic>> players;
  const ResultsView({super.key, required this.code, required this.room, required this.players});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final sorted = List<Map<String, dynamic>>.from(players)
      ..sort((a, b) => ((b['score'] as int?) ?? 0).compareTo((a['score'] as int?) ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('DRAWE'), centerTitle: true, automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              await AuthService.logOut();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sorted.isNotEmpty)
                Text('${sorted.first['displayName']} wins!', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Final Scores', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    for (var i = 0; i < sorted.length; i++)
                      ListTile(
                        leading: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        title: Text(sorted[i]['displayName'] ?? 'Player'),
                        trailing: Text('${(sorted[i]['score'] as int?) ?? 0}pts', style: const TextStyle(fontWeight: FontWeight.w900)),
                        selected: sorted[i]['uid'] == uid,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 280,
                child: ElevatedButton(
                  onPressed: () async {
                    final settings = (room['settings'] as Map<String, dynamic>?) ?? {'rounds': 3, 'drawTime': 60};
                    final newCode = await GameService.createRoom(Map<String, dynamic>.from(settings));
                    if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameScreen(code: newCode)));
                  },
                  child: const Text('Play Again'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 280,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
