import 'package:flutter/material.dart';
import 'package:spam_chat/views/new_message_page.dart';
import 'package:spam_chat/views/settings_page.dart';
import 'package:spam_chat/widgets/conversation_view.dart';

//=================================================//

///
///
///
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

//=================================================//

///
class _InboxPageState extends State<InboxPage> {

  bool _hideSpam = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hide Spam'),
              Checkbox(
                value: _hideSpam,
                onChanged: (v) => setState(() { _hideSpam = v!; }),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
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
      body: ConversationView(
        filter: (_hideSpam)
          ? (c) => !c.isSpam
          : (_) => true,
      ),
    );
  }
}