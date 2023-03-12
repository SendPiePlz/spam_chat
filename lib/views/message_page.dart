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
  });

  factory MessagePage.fromConversation(Conversation conversation) {
    return MessagePage(
      conversation: conversation.conversation,
      address: conversation.address,
      contact: conversation.contact,
    );
  }

  final SmsConversation conversation;
  final String address;
  final Contact? contact;

  String get displayName => contact?.displayName ?? address;

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

//=================================================//

///
class _MessagePageState extends ConsumerState<MessagePage> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final TelephonyBloc _telephone;

  @override
  void initState() {
    super.initState();
    _telephone = ref.read(telephonyProvider);
    _telephone.lastestMessage.addListener(_handleNewMessage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Redraw when app comes back into the foreground
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _telephone.lastestMessage.removeListener(_handleNewMessage);
    super.dispose();
  }

  ///
  void _handleNewMessage() {
    final msg = _telephone.lastestMessage.value;
    // Filter messages
    if (msg != null && msg.address == widget.address) {
      setState(() {});
    }
  }

  ///
  Future<void> _showDialog(String title, Function action) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () {
              action();
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Do Nothing
            child: const Text('No'),
          ),
        ],
      ),
    );
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

  CircleAvatar _getAvatar(bool isSpam) {
    if (isSpam) {
      return CircleAvatar(
        backgroundColor: Colors.red,
        child: Icon(Icons.warning, color: Colors.pink.shade100),
      );
    }
    else if (widget.contact != null) {
      return widget.contact!.avatar;
    }
    else {
      final i = Random(widget.conversation.threadId).nextInt(Colors.accents.length);
      return CircleAvatar(
        backgroundColor: Colors.accents[i],
        child: const Icon(Icons.person, color: Colors.black),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isSpam = _telephone.isSpam(widget.address);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName),
        actions: [
          (widget.contact != null)
            ? const SizedBox()
            : (isSpam)
              ? IconButton(
                  onPressed: () => _showDialog('Trust sender?', () => setState(() => _telephone.trustAddress(widget.address))),
                  icon: const Icon(Icons.add_moderator),
                )
              : IconButton(
                  onPressed: () => _showDialog('Mark As Spam?', () => setState(() => _telephone.markAsSpam(widget.address))),
                  icon: const Icon(Icons.block),
                ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder(
            future: _telephone.getMessages(widget.conversation.threadId),
            initialData: const <SmsMessage>[],
            builder: (ctx, snapshot) {
              return Expanded (
                child: MessageView(
                  messages: snapshot.data ?? [],
                  avatar: _getAvatar(isSpam),
                  isSpam: isSpam,
                ),
              );
            },
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