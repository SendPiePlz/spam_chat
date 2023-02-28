import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spam_chat/main.dart';
import 'package:spam_chat/models/conversation.dart';
import 'package:spam_chat/utils/telephony_bloc.dart';
import 'package:spam_chat/views/message_page.dart';

//=================================================//

///
///
///
class ConversationView extends ConsumerStatefulWidget {
  const ConversationView({super.key, required this.filter});

  final bool Function(Conversation) filter;

  @override
  ConsumerState<ConversationView> createState() => _ConversationViewState();
}

//=================================================//

///
class _ConversationViewState extends ConsumerState<ConversationView> {
  late final TelephonyBloc _telephone;

  @override
  void initState() {
    super.initState();
    _telephone = ref.read(telephonyProvider);
    _telephone.lastestMessage.addListener(_handleNewMessage);
  }

  @override
  void dispose() {
    _telephone.lastestMessage.removeListener(_handleNewMessage);
    super.dispose();
  }

  ///
  void _handleNewMessage() => setState(() {});

  ///
  void _onConversationSelected(BuildContext context, Conversation convo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MessagePage.fromConversation(convo)),
    ).then((_) => setState(() {})); // !?
  }

  ///
  Widget _notificationCircle(Color color) => Container(
    constraints: const BoxConstraints(maxWidth: 8, maxHeight: 8),
    decoration: ShapeDecoration(
      shape: const CircleBorder(),
      color: color,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _telephone.getConversations(),
      initialData: const <Conversation>[],
      builder: (ctx, snapshot) {
        if (snapshot.data?.isNotEmpty ?? false) {
          final data = snapshot.requireData.where(widget.filter).toList(growable: false);
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (ctx, i) {
              final textStyle = (data[i].hasUnread)
                ? const TextStyle(fontWeight: FontWeight.bold)
                : const TextStyle(fontWeight: FontWeight.normal);
                
              return ListTile(
                onTap: () => _onConversationSelected(ctx, data[i]),
                //onLongPress: () {},
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
    );
  }
}