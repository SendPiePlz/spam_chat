import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spam_chat/main.dart';
import 'package:spam_chat/models/conversation.dart';
import 'package:spam_chat/views/message_page.dart';

//=================================================//

///
///
///
class ConversationView extends ConsumerWidget {
  const ConversationView({super.key, required this.filter});

  final bool Function(Conversation) filter;

  ///
  void _onConversationSelected(BuildContext context, Conversation convo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MessagePage.fromConversation(convo)),
    );
  }

  ///
  Widget _notificationCircle(Color color) => Container(
    constraints: BoxConstraints.tight(
      const Size.square(8)
    ),
    decoration: ShapeDecoration(
      shape: const CircleBorder(),
      color: color,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tel = ref.read(telephonyProvider);

    return ValueListenableBuilder(
      valueListenable: tel.lastestMessage,
      builder: (ctx, _, __) => FutureBuilder(
        future: tel.getConversations(),
        initialData: const <Conversation>[],
        builder: (ctx, snapshot) {
          if (snapshot.data?.isNotEmpty ?? false) {
            final data = snapshot.requireData.where(filter).toList(growable: false);
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (ctx, i) {
                final textStyle = (data[i].hasUnread)
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : const TextStyle(fontWeight: FontWeight.normal);
                  
                return ListTile(
                  onTap: () => _onConversationSelected(ctx, data[i]),
                  leading: data[i].avatar,
                  title: Text(
                    data[i].displayName,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    data[i].snippet,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(data[i].formattedDate),
                      const SizedBox(width: 10),
                      (data[i].hasUnread)
                        ? _notificationCircle((data[i].isSpam)
                            ? Colors.red
                            : Colors.blueAccent
                          )
                        : const SizedBox(),
                    ],
                  ),
                );
              },
            );
          }
          else {
            return const Center(
              child: Text('No Conversations'),
            );
          }
        },
      ),
    );
  }
}