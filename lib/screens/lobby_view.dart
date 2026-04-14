import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import 'game_settings_page.dart';

class LobbyView extends StatelessWidget {
  final String code;
  final Map<String, dynamic> room;
  final List<Map<String, dynamic>> players;

  const LobbyView({super.key, required this.code, required this.room, required this.players});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isHost = room['hostId'] == uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DRAWE'),
        centerTitle: true,
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
              const Text('Waiting for players...', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Text(code, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 6)),
              const SizedBox(height: 24),
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    for (final p in players)
                      ListTile(
                        title: Text(p['displayName'] ?? 'Player'),
                        trailing: p['uid'] == uid ? const Text('you', style: TextStyle(color: Colors.pink)) : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isHost) ...[
                SizedBox(
                  width: 280,
                  child: ElevatedButton(
                    onPressed: players.length < 2 ? null : () => GameService.startGame(code),
                    child: Text(players.length < 2 ? 'Need 2+ players' : 'Start Game'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 280,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameSettingsPage(code: code, room: room))),
                    child: const Text('Settings'),
                  ),
                ),
              ] else
                const Text('Waiting for host to start...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
