import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';

class VoteView extends StatefulWidget {
  final String code;
  final Map<String, dynamic> room;
  final List<Map<String, dynamic>> drawings;
  const VoteView({super.key, required this.code, required this.room, required this.drawings});
  @override
  State<VoteView> createState() => _VoteViewState();
}

class _VoteViewState extends State<VoteView> {
  bool _submitted = false;
  final Map<String, int> _ratings = {};

  List<Map<String, dynamic>> get _others {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return widget.drawings.where((d) => d['uid'] != uid).toList();
  }

  bool get _allRated => _others.isNotEmpty && _others.every((d) => (_ratings[d['uid']] ?? 0) > 0);

  Future<void> _submit() async {
    if (_submitted) return;
    setState(() => _submitted = true);
    try {
      await GameService.submitVotes(widget.code, _ratings);
    } catch (e) {
      if (mounted) setState(() => _submitted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.room['prompt'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const Text('Rate everyone\'s drawings', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            if (_others.isEmpty)
              const Text('Waiting for drawings...', style: TextStyle(color: Colors.grey))
            else
              Wrap(
                alignment: WrapAlignment.center, spacing: 24, runSpacing: 24,
                children: _others.map((d) {
                  final dUid = d['uid'] as String;
                  final rating = _ratings[dUid] ?? 0;
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 200, height: 140,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), color: Colors.white),
                      clipBehavior: Clip.antiAlias,
                      child: _img(d['dataURL'] as String?),
                    ),
                    const SizedBox(height: 4),
                    Text(d['displayName'] ?? 'Player', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) => IconButton(
                        icon: Icon(i < rating ? Icons.star : Icons.star_border, color: i < rating ? Colors.pink : Colors.grey.shade300),
                        onPressed: _submitted ? null : () => setState(() => _ratings[dUid] = i + 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      )),
                    ),
                  ]);
                }).toList(),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_submitted || !_allRated) ? null : _submit,
              child: Text(_submitted ? 'Votes submitted!' : 'Submit Votes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _img(String? url) {
    if (url == null || url.isEmpty) return const Center(child: Text('No drawing'));
    try {
      return Image.memory(Uint8List.fromList(base64Decode(url.split(',').last)), fit: BoxFit.contain);
    } catch (_) {
      return const Center(child: Text('Error'));
    }
  }
}
