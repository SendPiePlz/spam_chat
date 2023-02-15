import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

//=================================================//

///
///
///
class NewMessagePage extends StatefulWidget {
  const NewMessagePage({super.key});

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

//=================================================//

///
class _NewMessagePageState extends State<NewMessagePage> {

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send New Message'),
      ),
      body: StreamBuilder(
        stream: Telephony.instance.getContacts().asStream(),
        builder: (ctx, snapshot) {
          final items = snapshot.data ?? [];
          return ListView.builder(
            itemCount: 1 + items.length,
            itemBuilder: (ctx, i) => (i == 0)
              ? ListTile( // Special item
                  leading: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white70,
                    child: Icon(Icons.dialpad),
                  ),
                  title: const Text('Phone Number'),
                  onTap: () {}, // TODO: open keypad
                )
              : ListTile( // Contact item
                  leading: const CircleAvatar(
                    child: Text('IN'),
                  ),
                  title: Text(items[i-1].displayName ?? items[i-1].phone ?? ''), // contact name
                  onTap: () {}, // TODO: open conversation
                ), 
          );
        },
      ),
    );
  }
}