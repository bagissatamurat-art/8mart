import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../domain/models.dart';
import '../../state/stories_cubit.dart';
import '../../ui/ui.dart';

/// Слайд с фото — 6 с (как STORY_DURATION на сайте); видео — по его длине.
const _slideDuration = Duration(seconds: 6);

/// Просмотр сторис на весь экран (как на сайте): полоски прогресса, тап слева/справа — назад/вперёд,
/// удержание — пауза, свайп вбок — соседняя история, свайп вниз — закрыть. Видео — без звука по умолчанию, кнопка звука в шапке.
Future<void> openStoryViewer(BuildContext context, List<Story> stories, int start) => Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
      opaque: false, barrierColor: Colors.black,
      transitionDuration: MartMotion.page, reverseTransitionDuration: MartMotion.sheet,
      pageBuilder: (_, __, ___) => _StoryViewer(stories: stories, start: start),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: child)),
    ));

class _StoryViewer extends StatefulWidget {
  const _StoryViewer({required this.stories, required this.start});
  final List<Story> stories;
  final int start;
  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> {
  late final _pages = PageController(initialPage: widget.start);
  late int _cur = widget.start;
  /// Звук — выключен по умолчанию; выбор держится до закрытия просмотра.
  bool _muted = true;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    context.read<StoriesCubit>().markSeen(widget.stories[_cur].id);
  }

  @override
  void dispose() { _pages.dispose(); super.dispose(); }

  void _close() => Navigator.of(context).maybePop();
  void _go(int i) {
    if (i < 0) return;
    if (i >= widget.stories.length) { _close(); return; }
    _pages.animateToPage(i, duration: const Duration(milliseconds: 340), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    // Material — у текстов просмотра есть тема (без него Flutter подчёркивает текст жёлтым).
    return Material(color: Colors.black, child: GestureDetector(
      // Свайп вниз — закрыть (карточка едет за пальцем).
      onVerticalDragUpdate: (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0, 400)),
      onVerticalDragEnd: (d) { if (_drag > 90 || (d.primaryVelocity ?? 0) > 700) { _close(); } else { setState(() => _drag = 0); } },
      child: AnimatedContainer(
        duration: _drag == 0 ? MartMotion.sheet : Duration.zero,
        transform: Matrix4.translationValues(0, _drag, 0)..scaleByDouble(1 - _drag / 2000, 1 - _drag / 2000, 1, 1),
        transformAlignment: Alignment.center,
        child: PageView.builder(
          controller: _pages, itemCount: widget.stories.length,
          onPageChanged: (i) { setState(() => _cur = i); context.read<StoriesCubit>().markSeen(widget.stories[i].id); },
          itemBuilder: (_, i) => _StoryPage(
            story: widget.stories[i], active: i == _cur, muted: _muted, holdOff: _drag > 0,
            onMute: () => setState(() => _muted = !_muted),
            onNextStory: () => _go(i + 1), onPrevStory: () => _go(i - 1), onClose: _close,
          ),
        ),
      ),
    ));
  }
}

class _StoryPage extends StatefulWidget {
  const _StoryPage({required this.story, required this.active, required this.muted, required this.holdOff, required this.onMute,
      required this.onNextStory, required this.onPrevStory, required this.onClose});
  final Story story;
  final bool active, muted, holdOff;
  final VoidCallback onMute, onNextStory, onPrevStory, onClose;
  @override
  State<_StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<_StoryPage> with SingleTickerProviderStateMixin {
  late final _progress = AnimationController(vsync: this)..addStatusListener((s) { if (s == AnimationStatus.completed) _next(); });
  int _i = 0;
  bool _held = false, _copied = false;
  VideoPlayerController? _video;
  bool _videoFailed = false;

  StorySlide get _slide => widget.story.slides[_i];

  @override
  void initState() { super.initState(); if (widget.active) _start(); }

  @override
  void didUpdateWidget(covariant _StoryPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) { _i = 0; _start(); }
    if (!widget.active && old.active) _stop();
    if (widget.muted != old.muted) _video?.setVolume(widget.muted ? 0 : 1);
    if (widget.holdOff != old.holdOff) _syncPause();
  }

  @override
  void dispose() { _progress.dispose(); _video?.dispose(); super.dispose(); }

  /// Запуск текущего слайда: видео — прогресс по времени ролика, конец — следующий слайд; не загрузилось — таймер на обложке.
  Future<void> _start() async {
    _stop();
    _progress.value = 0;
    _videoFailed = false;
    final url = _slide.video;
    if (url == null) { _progress.duration = _slideDuration; _syncPause(); return; }
    _progress.duration = Duration(seconds: _slide.duration ?? 6);
    final v = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = v;
    try {
      await v.initialize();
      if (!mounted || _video != v) { await v.dispose(); return; }
      await v.setVolume(widget.muted ? 0 : 1);
      v.addListener(() {
        final d = v.value.duration.inMilliseconds;
        if (d > 0 && mounted) _progress.value = (v.value.position.inMilliseconds / d).clamp(0, 1);
        if (v.value.isCompleted) _next();
      });
      setState(() {});
      _syncPause();
    } catch (_) {
      if (!mounted) return;
      setState(() => _videoFailed = true);
      _syncPause();
    }
  }

  void _stop() {
    _progress.stop();
    final v = _video;
    _video = null;
    v?.dispose();
  }

  bool get _paused => _held || widget.holdOff || !widget.active;
  /// Удержание, свайп вниз — пауза и для таймера, и для видео.
  void _syncPause() {
    final v = _video;
    final playingVideo = v != null && v.value.isInitialized && !_videoFailed;
    if (_paused) { _progress.stop(); v?.pause(); return; }
    if (playingVideo) { v.play(); } else { _progress.forward(); }
  }

  void _next() {
    if (_i < widget.story.slides.length - 1) { setState(() => _i++); _start(); } else { widget.onNextStory(); }
  }

  void _prev() {
    if (_i > 0) { setState(() => _i--); _start(); } else { widget.onPrevStory(); }
  }

  void _cta() {
    final s = _slide;
    if (s.ctaCopy != null) {
      Clipboard.setData(ClipboardData(text: s.ctaCopy!));
      setState(() => _copied = true);
      Future<void>.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _copied = false); });
      return;
    }
    if (s.ctaPath != null) {
      final router = GoRouter.of(context);
      widget.onClose();
      router.go(s.ctaPath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _slide;
    final top = MediaQuery.paddingOf(context).top, bottom = MediaQuery.paddingOf(context).bottom;
    final v = _video;
    final hasText = s.title.isNotEmpty || s.text.isNotEmpty;
    const ink = Color(0xFF17151A);
    return ColoredBox(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [
        // Фото (у видео — обложка, пока ролик грузится).
        MartImage(s.img, radius: 0, fit: BoxFit.cover),
        if (v != null && v.value.isInitialized && !_videoFailed)
          FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: v.value.size.width, height: v.value.size.height, child: VideoPlayer(v))),
        // Тапы: левая треть — назад, остальное — вперёд; удержание — пауза.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => d.localPosition.dx < MediaQuery.sizeOf(context).width / 3 ? _prev() : _next(),
          onLongPressStart: (_) { setState(() => _held = true); _syncPause(); },
          onLongPressEnd: (_) { setState(() => _held = false); _syncPause(); },
        ),
        // Шапка на светлой подложке: полоски, автор, звук, закрыть; ниже — текст слайда.
        Positioned(left: 0, right: 0, top: 0, child: Container(
          padding: EdgeInsets.fromLTRB(12, top + 8, 12, hasText ? 28 : 20),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: hasText ? const [Color(0xE6FFFFFF), Color(0xB8FFFFFF), Color(0x00FFFFFF)] : const [Color(0xB8FFFFFF), Color(0x00FFFFFF)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              for (var k = 0; k < widget.story.slides.length; k++) ...[
                if (k > 0) const SizedBox(width: 4),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2), child: SizedBox(height: 3, child: Stack(children: [
                  const Positioned.fill(child: ColoredBox(color: Color(0x2E17151A))),
                  if (k < _i) const Positioned.fill(child: ColoredBox(color: ink))
                  else if (k == _i) AnimatedBuilder(animation: _progress, builder: (_, __) => FractionallySizedBox(widthFactor: _progress.value, child: const ColoredBox(color: ink))),
                ])))),
              ],
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                  child: ClipOval(child: MartImage(widget.story.cover, radius: 0, fit: BoxFit.cover))),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.story.title, style: MartText.small.copyWith(fontWeight: FontWeight.w600, color: ink))),
              if (_held) const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: _PauseMark()),
              if (s.video != null && !_videoFailed) _RoundBtn(label: widget.muted ? 'Включить звук' : 'Выключить звук', onTap: widget.onMute,
                  child: Icon(widget.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 18, color: ink)),
              const SizedBox(width: 8),
              _RoundBtn(label: 'Закрыть', onTap: widget.onClose, child: const MartCross(size: 14, color: ink)),
            ]),
            if (hasText) ...[
              const SizedBox(height: 12),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.title, style: MartText.h2.copyWith(color: ink)),
                const SizedBox(height: 8),
                Text(s.text, style: MartText.body.copyWith(color: ink)),
              ])),
            ],
          ]),
        )),
        if (s.ctaLabel != null)
          Positioned(left: 16, right: 16, bottom: bottom + 16,
              child: MartButton(label: s.ctaCopy != null && _copied ? 'Код скопирован' : s.ctaLabel!, expanded: true, onPressed: _cta)),
      ]),
    );
  }
}

/// Круглая кнопка 40 в шапке сторис (звук, закрыть).
class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.label, required this.onTap, required this.child});
  final String label;
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) => Semantics(button: true, label: label, child: GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onTap,
        child: SizedBox.square(dimension: MartHeight.hit, child: Center(child: Container(width: 40, height: 40, alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xD9FFFFFF), shape: BoxShape.circle), child: child)))));
}

class _PauseMark extends StatelessWidget {
  const _PauseMark();
  @override
  Widget build(BuildContext context) => Semantics(label: 'Пауза', child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var k = 0; k < 2; k++) ...[if (k > 0) const SizedBox(width: 3), Container(width: 3, height: 12, decoration: BoxDecoration(color: const Color(0xFF17151A), borderRadius: BorderRadius.circular(1)))],
      ]));
}
