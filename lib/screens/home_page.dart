import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import 'game_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showJoin = false;
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';

  Future<void> _handleHost() async {
    setState(() { _error = ''; _loading = true; });
    try {
      final code = await GameService.createRoom({'rounds': 3, 'drawTime': 60});
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(code: code)));
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to create room.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleJoin() async {
    setState(() { _error = ''; _loading = true; });
    try {
      final code = _codeCtrl.text.toUpperCase();
      await GameService.joinRoom(code);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(code: code)));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DRAWE'),
        centerTitle: true,
        actions: [
          TextButton(onPressed: () => AuthService.logOut(), child: const Text('Sign out')),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleHost,
                  child: const Text('Host Room', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              if (_showJoin) ...[
                TextField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(hintText: 'Room code', border: OutlineInputBorder()),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 5,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: (_loading || _codeCtrl.text.length < 5) ? null : _handleJoin,
                    child: const Text('Join'),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showJoin = true),
                    child: const Text('Join Room', style: TextStyle(fontSize: 16)),
                  ),
                ),
              if (_error.isNotEmpty) Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
