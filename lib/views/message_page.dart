import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spam_chat/main.dart';
import 'package:spam_chat/models/conversation.dart';
import 'package:spam_chat/utils/telephony_bloc.dart';
import 'package:spam_chat/widgets/message_view.dart';
import 'package:telephony/telephony.dart';

//=================================================//

///
///
///
class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({super.key, required this.conversation});
  //const MessagePage.fromContact({super.key, required this.contact});

  final Conversation conversation;

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

//=================================================//

///
class _MessagePageState extends ConsumerState<MessagePage> {
  late TextEditingController _controller;
  late TelephonyBloc _telephone;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _telephone = ref.read(telephonyProvider);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  ///
  ///
  ///
  void _sendMessage() {
    _telephone.sendMessage(
      widget.conversation.address,
      _controller.text,
      (_) => setState(() {}), // ??
    );
    _controller.clear();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.displayName),
        actions: [
          // TODO
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.block),
          ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder(
            valueListenable: _telephone.lastestMessage,
            builder: (ctx, _, __) => StreamBuilder(
              stream: _telephone.getMessages(widget.conversation.threadId).asStream(),
              initialData: const <SmsMessage>[],
              builder: (ctx, snapshot) {
                if (snapshot.hasData) {
                  return Expanded (
                    child: MessageView(
                      avatar: widget.conversation.avatar,
                      messages: snapshot.requireData,
                    ),
                  );
                }
                else {
                  return const Expanded(
                    child: Center(
                      child: Text('No Messages'),
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            height: 50,
            padding: const EdgeInsets.all(5),
            //decoration: const BoxDecoration(
            //  border: Border(top: BorderSide(color: Colors.white24)),
            //),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    keyboardType: TextInputType.text,
                    keyboardAppearance: Brightness.dark,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      //fontSize: 12, // ??
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      hintText: 'Send a message...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  color: Colors.white30,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}