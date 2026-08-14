import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> shareTextFromContext(
  BuildContext context, {
  required String text,
  String? subject,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null
      ? const Rect.fromLTWH(0, 0, 1, 1)
      : box.localToGlobal(Offset.zero) & box.size;
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        sharePositionOrigin: origin,
      ),
    );
    return true;
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: text));
    return false;
  }
}
