import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spam_chat/main.dart';
import 'package:spam_chat/models/conversation.dart';
import 'package:spam_chat/utils/extensions.dart';
import 'package:spam_chat/utils/telephony_bloc.dart';
import 'package:spam_chat/widgets/message_input_field.dart';
import 'package:spam_chat/widgets/message_view.dart';
import 'package:telephony/telephony.dart';

//=================================================//

///
///
///
class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({
    super.key,
    required this.conversation,
    required this.address,
    this.contact,
    this.isSpam = false
  });

  factory MessagePage.fromConversation(Conversation conversation) {
    return MessagePage(
      conversation: conversation.conversation,
      address: conversation.address,
      contact: conversation.contact,
      isSpam: conversation.isSpam,
    );
  }

  final SmsConversation conversation;
  final String address;
  final Contact? contact;
  final bool isSpam;

  String get displayName => contact?.displayName ?? address;

  CircleAvatar get avatar {
    if (contact != null) {
      return contact!.avatar;
    }
    else if (isSpam) {
      return CircleAvatar(
        backgroundColor: Colors.red,
        child: Icon(Icons.warning, color: Colors.pink.shade100),
      );
    }
    else {
      final i = Random(conversation.threadId).nextInt(Colors.accents.length);
      return CircleAvatar(
        backgroundColor: Colors.accents[i],
        child: const Icon(Icons.person, color: Colors.black),
      );
    }
  }

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

//=================================================//

///
class _MessagePageState extends ConsumerState<MessagePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final TelephonyBloc _telephone;

  @override
  void initState() {
    super.initState();
    _telephone = ref.read(telephonyProvider);
  }

  ///
  void _sendMessage(String text) {
    _telephone.sendMessage(
      widget.address,
      _controller.text,
      (status) {
        setState(() {
          _focusNode.unfocus();
          _controller.clear();
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName),
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
            builder: (ctx, _, __) => FutureBuilder(
              future: _telephone.getMessages(widget.conversation.threadId),
              initialData: const <SmsMessage>[],
              builder: (ctx, snapshot) {
                return Expanded (
                  child: MessageView(
                    avatar: widget.avatar,
                    isSpam: widget.isSpam,
                    messages: snapshot.data ?? [],
                  ),
                );
              },
            ),
          ),
          MessageInputField(
            focusNode: _focusNode,
            controller: _controller,
            onSubmitted: _sendMessage,
          ),
        ],
      ),
    );
  }
}