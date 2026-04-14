import 'dart:async';
import 'package:flutter/material.dart';
import '../services/game_service.dart';
import 'lobby_view.dart';
import 'draw_view.dart';
import 'vote_view.dart';
import 'results_view.dart';

class GameScreen extends StatefulWidget {
  final String code;
  const GameScreen({super.key, required this.code});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Map<String, dynamic>? _room;
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _drawings = [];
  late final StreamSubscription _roomSub;
  late final StreamSubscription _playersSub;
  late final StreamSubscription _drawingsSub;

  @override
  void initState() {
    super.initState();
    _roomSub = GameService.roomStream(widget.code).listen((s) {
      if (mounted) setState(() => _room = s.data());
    });
    _playersSub = GameService.playersStream(widget.code).listen((s) {
      if (mounted) setState(() => _players = s.docs.map((d) => d.data()).toList());
    });
    _drawingsSub = GameService.drawingsStream(widget.code).listen((s) {
      if (mounted) setState(() => _drawings = s.docs.map((d) => d.data()).toList());
    });
  }

  @override
  void dispose() {
    _roomSub.cancel();
    _playersSub.cancel();
    _drawingsSub.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    if (_room == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return switch (_room!['status']) {
      'lobby' => LobbyView(code: widget.code, room: _room!, players: _players),
      'drawing' => DrawView(code: widget.code, room: _room!),
      'voting' => VoteView(code: widget.code, room: _room!, drawings: _drawings),
      'results' => ResultsView(code: widget.code, room: _room!, players: _players),
      _ => Scaffold(body: Center(child: Text('Unknown status : ${_room!['status']}'))),
    };
  }
}
