import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/game_service.dart';

class DrawView extends StatefulWidget {
  final String code;
  final Map<String, dynamic> room;
  const DrawView({super.key, required this.code, required this.room});
  @override
  State<DrawView> createState() => _DrawViewState();
}

class _DrawViewState extends State<DrawView> {
  final List<_Stroke> _strokes = [];
  _Stroke? _current;
  Color _color = Colors.black;
  bool _submitted = false;
  int _timeLeft = 60;
  Timer? _timer;
  final _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final ts = widget.room['roundStartedAt'];
    if (ts == null) return;
    final start = (ts as Timestamp).toDate();
    final total = (widget.room['settings']?['drawTime'] as int?) ?? 60;
    _timeLeft = total;
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final left = max(0, total - DateTime.now().difference(start).inSeconds);
      if (left <= 0) { _timer?.cancel(); _submit(); }
    });
  }

  Future<void> _submit() async {
    if (_submitted) return;
    setState(() => _submitted = true);
    _timer?.cancel();
    try {
      final url = await _export();
      await GameService.submitDrawing(widget.code, url);
    } catch (_) {}
  }

  Future<String> _export() async {
    const w = 600.0, h = 400.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec, const Rect.fromLTWH(0, 0, w, h));
    c.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);

    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final sx = w / (box?.size.width ?? w);
    final sy = h / (box?.size.height ?? h);

    for (final s in _strokes) {
      if (s.pts.length < 2) continue;
      final p = Path()..moveTo(s.pts.first.dx * sx, s.pts.first.dy * sy);
      for (var i = 1; i < s.pts.length; i++) {
        p.lineTo(s.pts[i].dx * sx, s.pts[i].dy * sy);
      }
      c.drawPath(p, Paint()..color = s.color..strokeWidth = 4 * sx..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
    }

    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(children: [
                const Text('Draw: ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Expanded(child: Text(widget.room['prompt'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                Text('${_timeLeft}s', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _timeLeft <= 10 ? Colors.pink : Colors.cyan)),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.white),
                    child: ClipRect(
                      child: GestureDetector(
                        onPanStart: _submitted ? null : (d) => setState(() => _current = _Stroke(color: _color, pts: [d.localPosition])),
                        onPanUpdate: _submitted ? null : (d) => setState(() => _current?.pts.add(d.localPosition)),
                        onPanEnd: _submitted ? null : (_) { if (_current != null) setState(() { _strokes.add(_current!); _current = null; }); },
                        child: RepaintBoundary(
                          key: _canvasKey,
                          child: CustomPaint(painter: _Painter(_strokes, _current), child: const SizedBox.expand()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final c in drawingColors)
                    GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: c, shape: BoxShape.circle,
                          border: Border.all(color: _color == c ? Colors.pink : Colors.grey, width: _color == c ? 3 : 1),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: _submitted ? null : () { if (_strokes.isNotEmpty) setState(() => _strokes.removeLast()); }, child: const Text('Undo')),
                  OutlinedButton(onPressed: _submitted ? null : () => setState(() => _strokes.clear()), child: const Text('Clear')),
                  ElevatedButton(onPressed: _submitted ? null : _submit, child: Text(_submitted ? 'Submitted!' : 'Submit')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stroke {
  final Color color;
  final List<Offset> pts;
  _Stroke({required this.color, required this.pts});
}

class _Painter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? current;
  _Painter(this.strokes, this.current);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    for (final s in [...strokes, ?current]) {
      if (s.pts.length < 2) continue;
      final path = Path()..moveTo(s.pts.first.dx, s.pts.first.dy);
      for (var i = 1; i < s.pts.length; i++) {
        path.lineTo(s.pts[i].dx, s.pts[i].dy);
      }
      canvas.drawPath(path, Paint()..color = s.color..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
