import 'collaboration_outbox.dart';
import 'package:go_router/go_router.dart';
import '../../core/sync/sync_scope.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/database_provider.dart';
import '../sync/presentation/sync_controller.dart';
import '../../core/sync/providers/backup_target.dart';
import 'record_editor.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});
  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsState();
}

class _ConnectionsState extends ConsumerState<ConnectionsScreen> {
  final url = TextEditingController(),
      username = TextEditingController(),
      password = TextEditingController(),
      code = TextEditingController(),
      friend = TextEditingController();
  final secure = const FlutterSecureStorage();
  String token = '', account = '', error = '';
  bool busy = false, register = false;
  List<Map<String, dynamic>> friends = [], shared = [];
  CollaborationOutbox get outbox => CollaborationOutbox(
    url.text.trim().replaceAll(RegExp(r'/+$'), ''),
    account,
  );
  Dio get client => Dio(
    BaseOptions(
      baseUrl: url.text.trim().replaceAll(RegExp(r'/+$'), ''),
      followRedirects: false,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
    ),
  );
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    url.text = prefs.getString('collab.url') ?? '';
    account = prefs.getString('collab.account') ?? '';
    token = await secure.read(key: 'collab.token') ?? '';
    if (token.isNotEmpty) {
      friends = await outbox.read('friends');
      shared = await outbox.read('shared');
      try {
        await refresh();
      } catch (e) {
        error = e.toString();
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await action();
    } catch (e) {
      error = e is DioException
          ? '${e.response?.data ?? e.message}'
          : e.toString();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> refresh() async {
    await outbox.retry((item) async {
      await client.post('/v1/collab/messages', data: item);
    });
    final a = await client.get<Map<String, dynamic>>('/v1/collab/friends');
    final b = await client.get<Map<String, dynamic>>('/v1/collab/shared');
    friends = (a.data?['friends'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    shared = (b.data?['records'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    await outbox.write('friends', friends);
    await outbox.write('shared', shared);
  }

  Future<void> authenticate() async {
    final uri = Uri.tryParse(url.text.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('HTTPS server URL required.');
    }
    final result = await client.post<Map<String, dynamic>>(
      '/v1/account/${register ? 'register' : 'login'}',
      data: {
        'username': username.text.trim(),
        'password': password.text,
        'registrationCode': code.text,
      },
    );
    token = result.data!['token'] as String;
    account = result.data!['accountId'] as String;
    await secure.write(key: 'collab.token', value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('collab.url', url.text.trim());
    await prefs.setString('collab.account', account);
    password.clear();
    code.clear();
    await refresh();
  }

  Future<void> friendAction(String name, String action) async {
    await client.post(
      '/v1/collab/friends',
      data: {'username': name, 'action': action},
    );
    await refresh();
  }

  Future<void> chat(Map<String, dynamic> person) async {
    final message = TextEditingController();
    var rows = <Map<String, dynamic>>[];
    String? problem;
    bool sending = false;
    Future<void> fetch() async {
      rows = await outbox.read('messages.${person['id']}');
      try {
        await outbox.retry((item) async {
          await client.post('/v1/collab/messages', data: item);
        });
        final response = await client.get<Map<String, dynamic>>(
          '/v1/collab/messages',
          queryParameters: {'peer': person['id']},
        );
        rows = (response.data?['messages'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        await outbox.write('messages.${person['id']}', rows);
        problem = null;
      } catch (_) {
        if (mounted) {
          problem = tr(
            context,
            'آفلاین یا دسترسی نامعتبر؛ پیام‌های در انتظار تا تأیید سرور نگه داشته می‌شوند.',
            'Offline or access denied. Pending messages stay queued until acknowledged.',
          );
        }
      }
      final queued = await outbox.read('outbox');
      rows = [
        ...rows,
        for (final item in queued.where((e) => e['to'] == person['id']))
          {
            'id': item['id'],
            'sender_id': account,
            'body': item['text'],
            'pending': true,
          },
      ];
    }

    await fetch();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => SizedBox(
          height: MediaQuery.sizeOf(c).height * .85,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
            child: Column(
              children: [
                ListTile(
                  title: Text(person['username'].toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await fetch();
                      if (c.mounted) set(() {});
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final row in rows)
                        Align(
                          alignment: row['sender_id'] == account
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart,
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row['body'].toString()),
                                  if (row['pending'] == true)
                                    Text(
                                      tr(
                                        c,
                                        'در انتظار ارسال؛ لمس برای لغو',
                                        'Pending; tap to cancel',
                                      ),
                                      style: Theme.of(c).textTheme.labelSmall,
                                    ),
                                  if (row['pending'] == true)
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () async {
                                        await outbox.acknowledge(
                                          row['id'] as String,
                                        );
                                        await fetch();
                                        if (c.mounted) set(() {});
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (problem != null) Text(problem!),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: message,
                          decoration: InputDecoration(
                            hintText: tr(c, 'پیام', 'Message'),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: sending
                            ? null
                            : () async {
                                if (message.text.trim().isEmpty) return;
                                set(() => sending = true);
                                try {
                                  await outbox.enqueue(
                                    person['id'] as String,
                                    message.text.trim(),
                                  );
                                  message.clear();
                                  await fetch();
                                } catch (e) {
                                  problem = e.toString();
                                } finally {
                                  if (c.mounted) set(() => sending = false);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    message.dispose();
  }

  Future<void> shareTo(Map<String, dynamic> person) async {
    final rows = await appDatabase.select(appDatabase.entityDocuments).get();
    if (!mounted) return;
    String permission = 'read';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => SizedBox(
          height: MediaQuery.sizeOf(c).height * .75,
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  tr(
                    c,
                    'اجازهٔ ویرایش نسخهٔ مشترک',
                    'Allow editing the shared copy',
                  ),
                ),
                value: permission == 'edit',
                onChanged: (v) => set(() => permission = v ? 'edit' : 'read'),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  tr(
                    c,
                    'یک نسخهٔ مستقل برای این مخاطب ارسال می‌شود.',
                    'An independent copy is shared with this person.',
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final row in rows)
                      if (row.deletedAt == null &&
                          [
                            'project',
                            'shopping_list',
                            'rich_note',
                            'home_entry',
                          ].contains(row.entityType))
                        ListTile(
                          title: Text(
                            (jsonDecode(row.payloadJson)['title'] ?? '—')
                                .toString(),
                          ),
                          onTap: () async {
                            await client.post(
                              '/v1/collab/shared',
                              data: {
                                'action': 'create',
                                'to': person['id'],
                                'permission': permission,
                                'payload': {
                                  ...Map<String, dynamic>.from(
                                    jsonDecode(row.payloadJson) as Map,
                                  ),
                                  'entityType': row.entityType,
                                  if (row.entityType == 'shopping_list')
                                    'items': [
                                      for (final child in rows)
                                        if (child.entityType ==
                                                'shopping_item' &&
                                            child.deletedAt == null &&
                                            jsonDecode(
                                                  child.payloadJson,
                                                )['listId'] ==
                                                row.id)
                                          jsonDecode(child.payloadJson),
                                    ],
                                },
                              },
                            );
                            if (c.mounted) Navigator.pop(c);
                            await refresh();
                            if (mounted) setState(() {});
                          },
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> editShared(Map<String, dynamic> row) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(row['payload_json'] as String) as Map,
    );
    final text = TextEditingController(
      text:
          (payload['description'] ??
                  payload['details'] ??
                  payload['plainText'] ??
                  '')
              .toString(),
    );
    final allowed = row['owner_id'] == account || row['permission'] == 'edit';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text((payload['title'] ?? 'Shared').toString()),
        content: TextField(
          controller: text,
          readOnly: !allowed,
          minLines: 3,
          maxLines: 8,
        ),
        actions: [
          IconButton(
            tooltip: tr(c, 'شبکه‌های مستقل', 'Independent networks'),
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => c.push('/networks'),
          ),
          if (row['owner_id'] == account)
            TextButton(
              onPressed: () async {
                await client.post(
                  '/v1/collab/shared',
                  data: {'action': 'revoke', 'id': row['id']},
                );
                if (c.mounted) Navigator.pop(c);
              },
              child: Text(tr(c, 'لغو اشتراک', 'Revoke')),
            ),
          if (allowed)
            FilledButton(
              onPressed: () async {
                final field = payload.containsKey('plainText')
                    ? 'plainText'
                    : payload.containsKey('details')
                    ? 'details'
                    : 'description';
                payload[field] = text.text;
                try {
                  await client.post(
                    '/v1/collab/shared',
                    data: {
                      'action': 'update',
                      'id': row['id'],
                      'version': row['version'],
                      'payload': payload,
                    },
                  );
                  if (c.mounted) Navigator.pop(c);
                } on DioException catch (e) {
                  if (c.mounted) {
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.response?.statusCode == 409
                              ? tr(
                                  c,
                                  'نسخه تغییر کرده؛ دوباره باز کن',
                                  'Version changed; reopen before editing',
                                )
                              : e.toString(),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(tr(c, 'ذخیره', 'Save')),
            ),
        ],
      ),
    );
    text.dispose();
    await refresh();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [url, username, password, code, friend]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(tr(c, 'ارتباطات', 'Connections')),
      actions: [
        if (token.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => run(refresh),
          ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (error.isNotEmpty)
          Text(error, style: TextStyle(color: Theme.of(c).colorScheme.error)),
        if (busy) const LinearProgressIndicator(),
        if (token.isEmpty) ...[
          Text(
            tr(
              c,
              'حساب مشترک روی دستگاه‌های تو',
              'One account across your devices',
            ),
            style: Theme.of(c).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          for (final item in [
            (url, 'نشانی HTTPS سرور', 'Server HTTPS URL'),
            (username, 'نام کاربری', 'Username'),
            (password, 'رمز عبور', 'Password'),
            if (register) (code, 'کد دعوت نصب', 'Installation invitation code'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: item.$1,
                obscureText: item.$1 == password || item.$1 == code,
                decoration: InputDecoration(labelText: tr(c, item.$2, item.$3)),
              ),
            ),
          SwitchListTile(
            title: Text(tr(c, 'ساخت حساب جدید', 'Create a new account')),
            value: register,
            onChanged: (v) => setState(() => register = v),
          ),
          FilledButton(
            onPressed: busy ? null : () => run(authenticate),
            child: Text(tr(c, 'ادامه', 'Continue')),
          ),
        ] else ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(tr(c, 'حساب متصل است', 'Account connected')),
              subtitle: Text(url.text),
              trailing: IconButton(
                tooltip: tr(c, 'خروج', 'Sign out'),
                icon: const Icon(Icons.logout),
                onPressed: () => run(() async {
                  await client.post('/v1/account/logout');
                  await secure.delete(key: 'collab.token');
                  token = '';
                  friends = [];
                  shared = [];
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              tr(
                c,
                'با افزودن Sync، اطلاعات شخصی این دستگاه با همین حساب روی سرور همگام می‌شود.',
                'Adding Sync sends this device’s personal records to this account on your server.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.sync),
            label: Text(
              tr(
                c,
                'افزودن این حساب به مرکز Sync',
                'Add this account to Sync center',
              ),
            ),
            onPressed: () => run(() async {
              await ref
                  .read(syncSettingsProvider.notifier)
                  .addConnection(
                    name: 'Raha account',
                    kind: SyncProviderKind.rahaServer,
                    purpose: SyncTargetPurpose.sync,
                    config: {
                      'baseUrl': url.text.trim(),
                      'modules': defaultSyncModules.join(','),
                    },
                    credentials: {'token': token},
                  );
            }),
          ),
          const SizedBox(height: 24),
          Text(
            tr(c, 'دوستان', 'Friends'),
            style: Theme.of(c).textTheme.titleLarge,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: friend,
                  decoration: InputDecoration(
                    hintText: tr(c, 'نام کاربری دقیق', 'Exact username'),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_add_alt),
                onPressed: () =>
                    run(() => friendAction(friend.text.trim(), 'request')),
              ),
            ],
          ),
          for (final person in friends)
            Card(
              margin: const EdgeInsets.only(top: 10),
              child: ListTile(
                title: Text(person['username'].toString()),
                subtitle: Text(person['status'].toString()),
                onTap: person['status'] == 'accepted'
                    ? () => run(() => chat(person))
                    : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => v == 'share'
                      ? run(() => shareTo(person))
                      : run(
                          () => friendAction(person['username'].toString(), v),
                        ),
                  itemBuilder: (c) => [
                    if (person['status'] == 'pending' &&
                        person['requested_by'] != account)
                      PopupMenuItem(
                        value: 'accept',
                        child: Text(tr(c, 'پذیرش', 'Accept')),
                      ),
                    if (person['status'] == 'accepted')
                      PopupMenuItem(
                        value: 'share',
                        child: Text(tr(c, 'اشتراک یک مورد', 'Share an item')),
                      ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(tr(c, 'حذف ارتباط', 'Remove')),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Text(tr(c, 'مسدودکردن', 'Block')),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            tr(c, 'موارد مشترک', 'Shared items'),
            style: Theme.of(c).textTheme.titleLarge,
          ),
          for (final row in shared)
            ListTile(
              leading: const Icon(Icons.folder_shared_outlined),
              title: Text(
                (jsonDecode(row['payload_json'] as String)['title'] ?? '—')
                    .toString(),
              ),
              onTap: () => run(() => editShared(row)),
            ),
        ],
      ],
    ),
  );
}
