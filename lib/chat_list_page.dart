import 'package:flutter/material.dart';
import 'app.dart'; // App shell with navigation
import 'direct_chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          for (final contact in personalChatContacts)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: contact.color.withValues(alpha: 0.16),
                child: Icon(contact.icon, color: contact.color),
              ),
              title: Text(contact.name),
              subtitle: Text(contact.subtitle),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DirectChatPage(contact: contact),
                  ),
                );
              },
            ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.group),
            ),
            title: const Text('General Support Group'),
            subtitle: const Text('Alice: That sounds like a good plan!'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessagesPage(), // Navigate to the chat page
                ),
              );
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.group),
            ),
            title: const Text('Meditation Group'),
            subtitle: const Text('Bob: I found a great new meditation app.'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessagesPage(), // Navigate to the chat page
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
