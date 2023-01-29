import 'package:flutter/material.dart';
import 'package:spam_chat/views/new_message_page.dart';
import 'package:spam_chat/views/settings_page.dart';
import 'package:spam_chat/widgets/conversation_view.dart';

//=================================================//

///
///
///
class InboxTab extends StatelessWidget {
  const InboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          PopupMenuButton(
            initialValue: 0,
            onSelected: (value) {
              if (value == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              }
            },
            itemBuilder: (_) => const [
            PopupMenuItem(
                value: 0,
                child: Text('TODO'), // checkbox show/hide spam?
              ),
              PopupMenuItem(
                value: 1,
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewMessagePage()),
        ),
        child: const Icon(Icons.sms),
      ),
      body: const ConversationView(), // TODO: integrate the view
    );
  }
}