import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spam_chat/main.dart';
import 'package:spam_chat/widgets/message_box.dart';
import 'package:telephony/telephony.dart';

//=================================================//

///
///
///
class MessageView extends ConsumerWidget {
  const MessageView({
    super.key,
    required this.messages,
    required this.avatar,
    required this.isSpam,
  });

  final List<SmsMessage> messages;
  final CircleAvatar avatar;
  final bool isSpam;

  /// Groups messages that were
  List<List<SmsMessage>> _groupMessages() {
    final groups = <List<SmsMessage>>[];
    var i = 0;
    while (i < messages.length) {
      final head = messages[i];
      final date = DateTime.fromMillisecondsSinceEpoch(head.date ?? 0);
      final g = messages.skip(i).takeWhile((m) => 
        m.address == head.address &&
        m.type == head.type &&
        DateTime.fromMillisecondsSinceEpoch(m.date ?? 0)
                .difference(date).inMinutes >= -1
      );

      // NOTE: in theory, `g` should always contains at least the head
      groups.add(g.toList(growable: false));
      i += g.length;
    }
    return groups;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.read(urlFilterProvider);
    final groups = _groupMessages();
    return ListView.builder(
      reverse: true,
      itemCount: groups.length,
      itemBuilder: (ctx, i) => MessageBox(
        avatar: avatar,
        isSpam: isSpam,
        messages: groups[i],
        filter: filter,
      ),
    );
  }
}