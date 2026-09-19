import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../workspace/record_editor.dart';
import 'federation_client.dart';

class FederationScreen extends StatefulWidget {
  const FederationScreen({super.key});
  @override
  State<FederationScreen> createState() => _FederationState();
}

class _FederationState extends State<FederationScreen> {
  final server = TextEditingController(),
      token = TextEditingController(),
      text = TextEditingController(),
      target = TextEditingController();
  final secure = const FlutterSecureStorage();
  String mode = 'matrix', identity = '', error = '', visibility = 'private';
  String? room;
  bool busy = false, encrypted = false;
  List<String> rooms = [];
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> pending = [];
  FederationClient get client => FederationClient(server.text, token.text);
  String t(String fa, String en) => tr(context, fa, en);
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final loadingMode = mode;
    final prefs = await SharedPreferences.getInstance();
    final saved = await secure.read(key: 'federation.$loadingMode');
    final config = saved == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(saved) as Map);
    if (!mounted || loadingMode != mode) return;
    setState(() {
      server.text = config['server'] as String? ?? '';
      token.text = config['token'] as String? ?? '';
      identity = '';
      encrypted = false;
      room = null;
      rooms = [];
      events = [];
      pending =
          (jsonDecode(prefs.getString('federation.outbox') ?? '[]') as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
    });
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        error = t(
          'عملیات انجام نشد؛ نشانی، دسترسی، توکن و شبکه را بررسی کنید. اتاق رمزگذاری‌شده به کلاینت دارای رمزنگاری نیاز دارد.',
          'Request failed. Check server, permissions, token and network. Encrypted rooms require an encryption-capable client.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> connect() async {
    final c = client;
    identity = mode == 'matrix'
        ? await c.matrixIdentity()
        : (await c.mastodonIdentity())['acct'].toString();
    await secure.write(
      key: 'federation.$mode',
      value: jsonEncode({'server': c.base, 'token': token.text}),
    );
    if (mode == 'matrix') {
      rooms = await c.matrixRooms();
    } else {
      events = await c.mastodonTimeline();
    }
  }

  Future<void> openRoom(String id) async {
    final c = client;
    final isEncrypted = await c.matrixEncrypted(id);
    final messages = await c.matrixMessages(id);
    room = id;
    encrypted = isEncrypted;
    events = messages;
  }

  Future<void> saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('federation.outbox', jsonEncode(pending));
  }

  Future<void> sendPending(Map<String, dynamic> item) async {
    if (item['server'] != client.base ||
        item['identity'] != identity ||
        item['mode'] != mode) {
      throw StateError('account mismatch');
    }
    if (mode == 'matrix') {
      await client.matrixSend(
        item['room'] as String,
        item['text'] as String,
        item['id'] as String,
      );
    } else {
      await client.mastodonPublish(
        item['text'] as String,
        item['visibility'] as String,
        item['id'] as String,
      );
    }
    pending.removeWhere((e) => e['id'] == item['id']);
    await saveQueue();
    if (mode == 'matrix' && room != null) {
      await openRoom(room!);
    } else {
      events = await client.mastodonTimeline();
    }
  }

  Future<void> compose() async {
    if (text.text.trim().isEmpty ||
        identity.isEmpty ||
        (mode == 'matrix' && (room == null || encrypted))) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t('تأیید ارسال', 'Confirm sending')),
        content: SingleChildScrollView(
          child: Text('${client.base}\n${room ?? visibility}\n\n${text.text}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t('لغو', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(t('ارسال', 'Send')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final item = <String, dynamic>{
      'id': const Uuid().v4(),
      'mode': mode,
      'server': client.base,
      'identity': identity,
      'room': room,
      'visibility': visibility,
      'text': text.text.trim(),
    };
    pending.add(item);
    await saveQueue();
    text.clear();
    await sendPending(item);
  }

  @override
  void dispose() {
    for (final c in [server, token, text, target]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(t('شبکه‌های مستقل', 'Independent networks'))),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'matrix', label: Text('Matrix')),
            ButtonSegment(value: 'mastodon', label: Text('Mastodon')),
          ],
          selected: {mode},
          onSelectionChanged: busy
              ? null
              : (v) {
                  setState(() => mode = v.first);
                  load();
                },
        ),
        const SizedBox(height: 16),
        Text(
          t(
            'این اتصال اختیاری است و اطلاعات شخصی برنامه را خودکار ارسال نمی‌کند. توکن دسترسی سرور خود را وارد کنید.',
            'Optional connection. Local app data is never sent automatically. Enter your server access token.',
          ),
        ),
        if (mode == 'matrix')
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                t(
                  'نسخهٔ آزمایشی: پیام و گروه بدون رمزنگاری سرتاسری. اتاق رمزگذاری‌شده فقط در Element باز می‌شود؛ ارسال متن به آن مسدود است.',
                  'Preview: messaging and groups without end-to-end encryption. Encrypted rooms open in Element; plaintext sending is blocked.',
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        TextField(
          controller: server,
          enabled: !busy && identity.isEmpty,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: t('نشانی HTTPS سرور', 'HTTPS server'),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: token,
          enabled: !busy && identity.isEmpty,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: t('توکن دسترسی', 'Access token'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(
              onPressed: busy ? null : () => run(connect),
              child: Text(t('اتصال / تازه‌سازی', 'Connect / refresh')),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => run(() async {
                      await secure.delete(key: 'federation.$mode');
                      token.clear();
                      identity = '';
                      room = null;
                      events = [];
                      rooms = [];
                    }),
              child: Text(t('قطع اتصال محلی', 'Disconnect locally')),
            ),
          ],
        ),
        if (identity.isNotEmpty)
          Text(identity, textDirection: TextDirection.ltr),
        if (busy) const LinearProgressIndicator(),
        if (error.isNotEmpty)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (mode == 'matrix' && identity.isNotEmpty) ...[
          const SizedBox(height: 16),
          TextField(
            controller: target,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: t(
                'شناسهٔ اتاق یا نام گروه جدید',
                'Room ID or new group name',
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        await client.matrixJoin(target.text.trim());
                        await connect();
                      }),
                child: Text(t('پیوستن', 'Join')),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        final id = await client.matrixCreateRoom(
                          target.text.trim(),
                          [],
                        );
                        await connect();
                        await openRoom(id);
                      }),
                child: Text(t('ساخت گروه خصوصی', 'Create private group')),
              ),
            ],
          ),
          for (final id in rooms)
            ListTile(
              title: Text(id, maxLines: 1, overflow: TextOverflow.ellipsis),
              selected: room == id,
              onTap: busy ? null : () => run(() => openRoom(id)),
            ),
          if (room != null) ...[
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.https('app.element.io', '/', {
                  'room': room,
                }).replace(fragment: '/room/${Uri.encodeComponent(room!)}'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(t('بازکردن در Element', 'Open in Element')),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => run(() async {
                      await client.matrixLeave(room!);
                      room = null;
                      events = [];
                      await connect();
                    }),
              child: Text(t('خروج از گروه', 'Leave room')),
            ),
          ],
        ],
        if (mode == 'mastodon' && identity.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: visibility,
            items: [
              DropdownMenuItem(
                value: 'private',
                child: Text(t('فقط دنبال‌کنندگان', 'Followers only')),
              ),
              DropdownMenuItem(
                value: 'unlisted',
                child: Text(t('عمومی بدون فهرست', 'Unlisted')),
              ),
              DropdownMenuItem(
                value: 'public',
                child: Text(t('عمومی', 'Public')),
              ),
            ],
            onChanged: (v) => setState(() => visibility = v!),
          ),
        for (final event in events)
          Card(
            child: ListTile(
              title: Text(
                mode == 'matrix'
                    ? event['sender'].toString()
                    : (event['account'] as Map?)?['acct']?.toString() ?? '',
              ),
              subtitle: Text(
                mode == 'matrix'
                    ? (event['type'] == 'm.room.encrypted'
                          ? t(
                              'پیام رمزگذاری‌شده؛ در Element بخوانید.',
                              'Encrypted message; read in Element.',
                            )
                          : (event['content'] as Map?)?['body']?.toString() ??
                                '')
                    : event['content'].toString().replaceAll(
                        RegExp('<[^>]*>'),
                        '',
                      ),
              ),
              trailing: mode == 'mastodon'
                  ? IconButton(
                      icon: const Icon(Icons.star_outline),
                      onPressed: busy
                          ? null
                          : () => run(
                              () => client.mastodonFavourite(
                                event['id'].toString(),
                              ),
                            ),
                    )
                  : null,
            ),
          ),
        if (identity.isNotEmpty && (mode != 'matrix' || room != null)) ...[
          TextField(
            controller: text,
            enabled: !busy && !encrypted,
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: t('متن پیام / نوشته', 'Message / post'),
            ),
          ),
          FilledButton(
            onPressed: busy || encrypted ? null : () => run(compose),
            child: Text(t('پیش‌نمایش و ارسال', 'Preview and send')),
          ),
        ],
        for (final item in pending.where((e) => e['mode'] == mode))
          Card(
            child: ListTile(
              title: Text(t('در انتظار ارسال', 'Pending delivery')),
              subtitle: Text(item['text'].toString(), maxLines: 2),
              onTap: busy || identity.isEmpty
                  ? null
                  : () => run(() => sendPending(item)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: busy
                    ? null
                    : () => run(() async {
                        pending.remove(item);
                        await saveQueue();
                      }),
              ),
            ),
          ),
      ],
    ),
  );
}
