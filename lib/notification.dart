import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationModel {
  final String id;
  final String type;
  final String? time;
  final String? title;
  final String? subtitle;
  final bool isUnread;
  final String? sender;
  final String? group;
  final String? message;

  NotificationModel({
    required this.id,
    required this.type,
    this.time,
    this.title,
    this.subtitle,
    this.isUnread = false,
    this.sender,
    this.group,
    this.message,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      type: data['type'] ?? 'event',
      time: data['time'],
      title: data['title'],
      subtitle: data['subtitle'],
      isUnread: data['isUnread'] ?? false,
      sender: data['sender'],
      group: data['group'],
      message: data['message'],
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DatabaseReference _notificationsRef =
      FirebaseDatabase.instance.ref().child('notifications');

  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notificationsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final loaded = data.entries
            .map((e) => NotificationModel.fromMap(
                  e.key,
                  Map<String, dynamic>.from(e.value),
                ))
            .toList();
        setState(() {
          notifications = loaded;
          isLoading = false;
        });
      } else {
        setState(() {
          notifications = [];
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          TextButton(
            onPressed: () {
              // Optional: Mark all as read logic here
            },
            child: const Text(
              "Tout lire",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                if (n.type == 'conversation') {
                  return ConversationItem(
                    sender: n.sender ?? '',
                    group: n.group ?? '',
                    message: n.message ?? '',
                  );
                } else {
                  return NotificationItem(
                    time: n.time,
                    title: n.title ?? '',
                    subtitle: n.subtitle ?? '',
                    isUnread: n.isUnread,
                  );
                }
              },
            ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String? time;
  final String title;
  final String subtitle;
  final bool isUnread;

  const NotificationItem({
    super.key,
    this.time,
    required this.title,
    required this.subtitle,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today, color: Colors.deepPurple),
          ),
          title: Row(
            children: [
              if (time != null) Text("$time "),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              color: isUnread ? Colors.black : Colors.grey,
            ),
          ),
          trailing: isUnread
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class ConversationItem extends StatelessWidget {
  final String sender;
  final String group;
  final String message;

  const ConversationItem({
    super.key,
    required this.sender,
    required this.group,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group, color: Colors.blue),
          ),
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: sender,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: " dans "),
                TextSpan(
                  text: group,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          subtitle: Text(message),
          trailing: TextButton(
            onPressed: () {},
            child: const Text(
              "Voir conversation",
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
