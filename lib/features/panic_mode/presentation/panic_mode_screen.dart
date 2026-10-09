import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/panic_mode/panic_audio.dart';

/// Offline 90-second guided breathing / urge surfing session.
class PanicModeScreen extends StatefulWidget {
  const PanicModeScreen({super.key});

  @override
  State<PanicModeScreen> createState() => _PanicModeScreenState();
}

class _PanicModeScreenState extends State<PanicModeScreen> {
  static const _prompts = ['Breathe in', 'Hold', 'Breathe out', 'Hold'];

  late final AudioPlayer _player;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _audioReady = false;
  bool _audioFailed = false;
  bool _isPlaying = false;
  bool _completed = false;
  bool _rewardClaimed = false;
  double _volume = 0.7;
  int _promptIndex = 0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _prepareAudio();
    _startSession();
  }

  Future<void> _prepareAudio() async {
    try {
      await _player.setAsset(PanicAudioPaths.primary);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_volume);
      if (!mounted) return;
      setState(() {
        _audioReady = true;
        _audioFailed = false;
      });
      await _player.play();
      if (mounted) setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint('Panic audio load failed (session continues offline): $e');
      if (mounted) {
        setState(() {
          _audioReady = false;
          _audioFailed = true;
          _isPlaying = false;
        });
      }
    }
  }

  void _startSession() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _completed) return;
      setState(() {
        _elapsed += const Duration(seconds: 1);
        _promptIndex = (_elapsed.inSeconds ~/ 4) % _prompts.length;
      });
      if (_elapsed.inSeconds > 0 && _elapsed.inSeconds % 4 == 0) {
        HapticFeedback.lightImpact();
      }
      if (_elapsed >= PanicAudioPaths.sessionDuration) {
        _onComplete();
      }
    });
  }

  Future<void> _onComplete() async {
    if (_completed) return;
    _ticker?.cancel();
    setState(() => _completed = true);
    HapticFeedback.mediumImpact();
    try {
      await _player.pause();
    } catch (_) {}
    if (!_rewardClaimed && mounted) {
      _rewardClaimed = true;
      await context.read<GameProvider>().addXp(
            PanicAudioPaths.xpReward,
            coinBonus: PanicAudioPaths.coinReward,
          );
    }
  }

  Future<void> _togglePlay() async {
    if (_completed) return;
    if (!_audioReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _audioFailed
                ? 'Audio unavailable — keep breathing with the guide.'
                : 'Loading audio…',
          ),
        ),
      );
      return;
    }
    try {
      if (_isPlaying) {
        await _player.pause();
        setState(() => _isPlaying = false);
      } else {
        await _player.play();
        setState(() => _isPlaying = true);
      }
      HapticFeedback.selectionClick();
    } catch (_) {
      setState(() => _audioFailed = true);
    }
  }

  Future<void> _setVolume(double v) async {
    setState(() => _volume = v);
    try {
      await _player.setVolume(v);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    super.dispose();
  }

  double get _progress =>
      (_elapsed.inMilliseconds / PanicAudioPaths.sessionDuration.inMilliseconds).clamp(0.0, 1.0);

  int get _secondsLeft =>
      (PanicAudioPaths.sessionDuration.inSeconds - _elapsed.inSeconds)
          .clamp(0, PanicAudioPaths.sessionDuration.inSeconds);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BfColors.ink,
      appBar: AppBar(
        title: const Text(
          'Breathing',
          style: TextStyle(color: BfColors.textPrimaryDark, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: BfColors.textPrimaryDark),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BfSpacing.xl),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: BfColors.inkMuted,
                color: BfColors.accent,
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: BfSpacing.sm),
              Text(
                _completed ? 'Session complete' : '$_secondsLeft s remaining',
                style: const TextStyle(color: BfColors.textTertiaryDark, letterSpacing: 0.4),
              ),
              const SizedBox(height: BfSpacing.xl),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: BfColors.accent.withValues(alpha: 0.35), width: 1),
                        color: BfColors.accentSoft,
                      ),
                      child: Center(
                        child: Text(
                          _completed ? 'Still' : _prompts[_promptIndex],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: BfColors.textPrimaryDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    )
                        .animate(target: _completed ? 0 : 1, onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          duration: 4.seconds,
                          begin: const Offset(0.94, 0.94),
                          end: const Offset(1.06, 1.06),
                        ),
                    const SizedBox(height: BfSpacing.xl),
                    Text(
                      _completed
                          ? 'The wave passed.  +${PanicAudioPaths.xpReward} XP'
                          : 'This feeling will pass.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: BfColors.textSecondaryDark,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (_audioFailed) ...[
                      const SizedBox(height: BfSpacing.xs),
                      const Text(
                        'Running without audio — breathing guide still works offline.',
                        style: TextStyle(color: BfColors.textTertiaryDark, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              if (!_completed) ...[
                IconButton(
                  iconSize: 56,
                  icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                  color: BfColors.accent,
                  onPressed: _togglePlay,
                ),
                Text(
                  _audioReady ? 'Calming audio' : 'Guided breathing',
                  style: const TextStyle(color: BfColors.textSecondaryDark),
                ),
                Row(
                  children: [
                    const Icon(Icons.volume_mute, color: BfColors.textTertiaryDark, size: 20),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        onChanged: _setVolume,
                        activeColor: BfColors.accent,
                        inactiveColor: BfColors.inkMuted,
                      ),
                    ),
                    const Icon(Icons.volume_up, color: BfColors.textTertiaryDark, size: 20),
                  ],
                ),
                const SizedBox(height: BfSpacing.xs),
                BfSecondaryButton(
                  label: 'Open recovery plan',
                  onPressed: () => context.push('/help'),
                ),
                const SizedBox(height: BfSpacing.xs),
                TextButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    context.push('/urge');
                  },
                  child: const Text(
                    'I still have an urge',
                    style: TextStyle(color: BfColors.danger),
                  ),
                ),
              ] else ...[
                BfPrimaryButton(
                  label: 'I feel steadier',
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: BfSpacing.xs),
                BfSecondaryButton(
                  label: 'Open recovery plan',
                  onPressed: () => context.push('/help'),
                ),
                TextButton(
                  onPressed: () => context.push('/urge'),
                  child: const Text(
                    'I still have an urge',
                    style: TextStyle(color: BfColors.danger),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
