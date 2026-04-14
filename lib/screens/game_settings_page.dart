import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/game_service.dart';

class GameSettingsPage extends StatefulWidget {
  final String code;
  final Map<String, dynamic> room;
  const GameSettingsPage({super.key, required this.code, required this.room});
  @override
  State<GameSettingsPage> createState() => _GameSettingsPageState();
}

class _GameSettingsPageState extends State<GameSettingsPage> {
  late int _rounds = (widget.room['settings']?['rounds'] as int?) ?? 3;
  late int _drawTime = (widget.room['settings']?['drawTime'] as int?) ?? 60;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await GameService.updateSettings(widget.code, {'rounds': _rounds, 'drawTime': _drawTime});
    if (mounted) Navigator.pop(context);
  }

  Widget _optionRow(List<int> options, int selected, Color color, void Function(int) onTap, {String suffix = ''}) {
    return Row(
      children: options.map((n) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            onPressed: () => onTap(n),
            style: OutlinedButton.styleFrom(
              backgroundColor: selected == n ? color : null,
              foregroundColor: selected == n ? Colors.white : color,
              side: BorderSide(color: color),
            ),
            child: Text('$n$suffix'),
          ),
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Settings'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ROUNDS', style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 2)),
              const SizedBox(height: 8),
              _optionRow(roundOptions, _rounds, Colors.pink, (n) => setState(() => _rounds = n)),
              const SizedBox(height: 24),
              const Text('DRAW TIME', style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 2)),
              const SizedBox(height: 8),
              _optionRow(drawTimeOptions, _drawTime, Colors.cyan, (n) => setState(() => _drawTime = n), suffix: 's'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
