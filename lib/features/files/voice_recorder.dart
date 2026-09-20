import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../../core/persistence/attachments.dart';

Uint8List pcmToWave(Uint8List pcm, {int sampleRate = 16000}) {
  final length = pcm.length - (pcm.length % 2);
  final header = ByteData(44);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      header.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, length, Endian.little);
  return (BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List())
        ..add(pcm.sublist(0, length)))
      .takeBytes();
}

class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});
  @override
  State<VoiceRecorderScreen> createState() => _VoiceState();
}

class _VoiceState extends State<VoiceRecorderScreen>
    with WidgetsBindingObserver {
  final recorder = AudioRecorder();
  final bytes = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? subscription;
  Timer? timer;
  bool recording = false, busy = false;
  int seconds = 0;
  String? error;
  String t(String fa, String en) =>
      Localizations.localeOf(context).languageCode == 'fa' ? fa : en;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        recording) {
      unawaited(stop());
    }
  }

  Future<void> start() async {
    if (busy || recording) return;
    setState(() => busy = true);
    try {
      if (!await recorder.hasPermission()) {
        throw StateError('Permission denied');
      }
      if (!mounted) return;
      bytes.clear();
      seconds = 0;
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      subscription = stream.listen(
        (part) {
          if (bytes.length + part.length > AttachmentStore.maxBytes - 44) {
            unawaited(stop());
            return;
          }
          bytes.add(part);
        },
        onError: (Object e) {
          if (mounted) {
            setState(
              () => error = t('ضبط صدا ناموفق بود.', 'Recording failed.'),
            );
          }
          unawaited(stop());
        },
      );
      if (!mounted) {
        await recorder.stop();
        return;
      }
      setState(() {
        recording = true;
        error = null;
      });
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => seconds++);
        if (seconds >= 600) unawaited(stop());
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => error = t(
            'میکروفون در دسترس نیست؛ مجوز و تنظیمات دستگاه را بررسی کنید.',
            'Microphone unavailable. Check permission and device settings.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> stop() async {
    if (busy || !recording) return;
    setState(() => busy = true);
    timer?.cancel();
    try {
      await recorder.stop();
      await subscription?.cancel();
    } catch (_) {
      if (mounted) {
        setState(
          () => error = t(
            'توقف ضبط با خطا مواجه شد.',
            'Could not stop recording.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          recording = false;
          busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    subscription?.cancel();
    recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(t('ضبط صدا', 'Voice recording'))),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              recording ? Icons.mic : Icons.mic_none,
              size: 64,
              color: recording ? Theme.of(c).colorScheme.error : null,
            ),
            const SizedBox(height: 20),
            Text(
              '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
              style: Theme.of(c).textTheme.headlineLarge,
            ),
            Text(
              t(
                'ضبط فقط با دکمه شروع فعال می‌شود؛ حداکثر ۱۰ دقیقه.',
                'Recording starts only when you press Start; maximum 10 minutes.',
              ),
            ),
            if (error != null) Text(error!),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : recording
                  ? stop
                  : start,
              icon: Icon(recording ? Icons.stop : Icons.mic),
              label: Text(
                recording
                    ? t('توقف', 'Stop')
                    : t('شروع ضبط جدید', 'Start new recording'),
              ),
            ),
            if (!recording && bytes.length > 0)
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => Navigator.pop(c, pcmToWave(bytes.takeBytes())),
                child: Text(t('استفاده از این صدا', 'Use recording')),
              ),
          ],
        ),
      ),
    ),
  );
}
