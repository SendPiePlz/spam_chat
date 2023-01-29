import 'package:flutter/material.dart';
import 'package:spam_chat/utils/extensions.dart';
import 'package:telephony/telephony.dart';

//=================================================//

///
///
///
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.messages,
    required this.avatar,
  });

  final List<SmsMessage> messages;
  final CircleAvatar avatar;

  ///
  ///
  ///
  List<List<SmsMessage>> _groupMessages() {
    final groups = <List<SmsMessage>>[];
    var i = 0;

    while (i < messages.length) {
      final head = messages[i];
      final date = DateTime.fromMillisecondsSinceEpoch(head.date ?? head.dateSent ?? 0);
      final g = messages.skip(i).takeWhile((m) => 
        m.address == head.address &&
        m.type == head.type &&
        DateTime.fromMillisecondsSinceEpoch(m.date ?? m.dateSent ?? 0).difference(date).inMinutes >= -1
      );
      //debugPrint('$i: ${g.length}');

      if (g.isNotEmpty) {
        groups.add(g.toList(growable: false));
        i += g.length;
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final ms = _groupMessages();
    return ListView.builder(
      reverse: true,
      itemCount: ms.length,
      itemBuilder: (ctx, i) => MessageBox(
        avatar: avatar,
        messages: ms[i],
      ),
    );
  }
}

//=================================================//

///
///
///
class MessageBox extends StatelessWidget {
  MessageBox({
    super.key,
    required this.messages,
    required this.avatar,
  }) : assert(messages.isNotEmpty);

  final List<SmsMessage> messages;
  final CircleAvatar avatar;

  bool get isFromUser => messages.first.type == SmsType.MESSAGE_TYPE_SENT;
  String get formattedDateTime => DateTime.fromMillisecondsSinceEpoch(messages.first.date ?? messages.first.dateSent ?? 0).formatMessageDateTime();

  ///
  ///
  ///
  Widget _buildBodyBubble(SmsMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: (isFromUser)
          ? Colors.tealAccent[700]
          : Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: (isFromUser && message.status == SmsStatus.STATUS_FAILED)
          ? Border.all(
              color: Colors.redAccent,
              width: 2,
            )
          : null,
      ),
      child: Text(message.body.toString()), // TODO: highlight links
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubbles = messages.map((m) => _buildBodyBubble(m));
    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: (isFromUser)
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          (isFromUser) ? const SizedBox() : avatar,
          const SizedBox(width: 15),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                verticalDirection: VerticalDirection.up,
                children: bubbles.toList(growable: false),
              ),
              Container(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  formattedDateTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ),
            ],
          ),
        ], 
      ),
    );
  }
}