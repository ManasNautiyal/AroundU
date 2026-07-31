import 'dart:async';
import 'package:flutter/material.dart';

class VoiceNoteBubblePlayer extends StatefulWidget {
  final String? audioUrl;
  final int durationSeconds;
  final bool isMe;

  const VoiceNoteBubblePlayer({
    super.key,
    this.audioUrl,
    required this.durationSeconds,
    required this.isMe,
  });

  @override
  State<VoiceNoteBubblePlayer> createState() => _VoiceNoteBubblePlayerState();
}

class _VoiceNoteBubblePlayerState extends State<VoiceNoteBubblePlayer> {
  bool _isPlaying = false;
  double _progress = 0.0;
  Timer? _playbackTimer;
  int _currentSecond = 0;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    setState(() {
      _isPlaying = true;
      if (_progress >= 1.0) {
        _progress = 0.0;
        _currentSecond = 0;
      }
    });

    final totalSeconds = widget.durationSeconds > 0 ? widget.durationSeconds : 10;

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.1 / totalSeconds;
        _currentSecond = (_progress * totalSeconds).clamp(0, totalSeconds).toInt();

        if (_progress >= 1.0) {
          _progress = 1.0;
          _isPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.isMe ? theme.colorScheme.onPrimary : theme.colorScheme.primary;
    final subTextColor = widget.isMe
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final totalSecs = widget.durationSeconds > 0 ? widget.durationSeconds : 10;
    final displaySecs = _isPlaying ? _currentSecond : totalSecs;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause Circle Button
          GestureDetector(
            onTap: _togglePlay,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: primaryColor,
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isMe ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Waveform and Duration Counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform Bars Simulation
                SizedBox(
                  height: 24,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const barCount = 20;
                      final barWidth = (constraints.maxWidth - (barCount * 2)) / barCount;
                      
                      // Mock heights for static waveform visualization
                      final heights = [12, 18, 8, 22, 14, 20, 10, 16, 24, 12, 19, 9, 21, 15, 11, 17, 23, 13, 8, 14];

                      return Row(
                        children: List.generate(barCount, (index) {
                          final barProgress = index / barCount;
                          final isPlayed = _progress >= barProgress;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: barWidth.clamp(2.0, 6.0),
                              height: (heights[index % heights.length]).toDouble(),
                              decoration: BoxDecoration(
                                color: isPlayed
                                    ? primaryColor
                                    : primaryColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),

                // Duration Text and Mic Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(displaySecs),
                      style: TextStyle(
                        fontSize: 11,
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.mic_rounded,
                      size: 14,
                      color: primaryColor.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Voice Note Recorder Mic button & Overlay Bar for recording audio notes.
class VoiceNoteRecorderButton extends StatefulWidget {
  final Function(int durationSeconds) onVoiceNoteRecorded;

  const VoiceNoteRecorderButton({
    super.key,
    required this.onVoiceNoteRecorded,
  });

  @override
  State<VoiceNoteRecorderButton> createState() => _VoiceNoteRecorderButtonState();
}

class _VoiceNoteRecorderButtonState extends State<VoiceNoteRecorderButton> {
  bool _isRecording = false;
  int _recordedSeconds = 0;
  Timer? _timer;

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordedSeconds = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordedSeconds++;
      });
    });
  }

  void _stopAndSend() {
    _timer?.cancel();
    final duration = _recordedSeconds > 0 ? _recordedSeconds : 3;
    setState(() {
      _isRecording = false;
      _recordedSeconds = 0;
    });
    widget.onVoiceNoteRecorded(duration);
  }

  void _cancelRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _recordedSeconds = 0;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isRecording) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_recordedSeconds),
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Recording voice note...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
              onPressed: _cancelRecording,
              tooltip: 'Cancel',
            ),
            IconButton(
              icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
              onPressed: _stopAndSend,
              tooltip: 'Send Voice Note',
            ),
          ],
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.mic_none_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), size: 24),
      onPressed: _startRecording,
      tooltip: 'Record Voice Note',
    );
  }
}
