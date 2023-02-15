import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spam_chat/main.dart';
import 'package:spam_chat/utils/extensions.dart';
import 'package:spam_chat/utils/url_filter.dart';
import 'package:telephony/telephony.dart';
// import 'package:url_launcher/url_launcher.dart';

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
      //if (g.isNotEmpty) {
      groups.add(g.toList(growable: false));
      i += g.length;
      //}
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
class MessageBox extends ConsumerWidget {
  const MessageBox({
    super.key,
    required this.messages,
    required this.avatar,
  }) : assert(messages.length > 0);


  final List<SmsMessage> messages;
  final CircleAvatar avatar;

  bool get isFromUser => messages.first.type == SmsType.MESSAGE_TYPE_SENT;
  String get formattedDateTime => DateTime.fromMillisecondsSinceEpoch(messages.first.date ?? 0).formatMessageDateTime();

  ///
  void _launchUrl(String url, bool isBad) {
    // TODO
  }

  ///
  List<TextSpan> _createHyperlinks(String msg, UrlFilter filter) {
    // Highlight URLs
    final ms = UrlFilter.urlPattern.allMatches(msg);
    final spans = <TextSpan>[];
    if (ms.isNotEmpty) { // Contains URL(s)
      var e = 0;
      for (final m in ms) {
        // Add text before the URL
        if (e != m.start) {
          spans.add(TextSpan(text: msg.substring(e, m.start)));
        }
        // Add the URL
        final url = m[0]!;
        final isBad = filter.isTrusted(url);
        e = m.end;
        spans.add(TextSpan(
          text: url,
          style: (isBad)
            ? const TextStyle(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
                decorationColor: Colors.redAccent,
                decorationStyle: TextDecorationStyle.wavy
              )
            : const TextStyle(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
                decorationColor: Colors.blueAccent,
                decorationStyle: TextDecorationStyle.solid
              ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchUrl(url, isBad),
        ));
      }
      // Add trailing text
      if (e < msg.length) {
        spans.add(TextSpan(text: msg.substring(e)));
      }
    }
    else { // No URLs; add everything
      spans.add(TextSpan(text: msg));
    }
    return spans;
  }

  ///
  Widget _buildBodyBubble(SmsMessage message, UrlFilter filter) {
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
          ? Border.all(color: Colors.redAccent, width: 2)
          : null,
      ),
      child: RichText(
        text: TextSpan(children: _createHyperlinks(message.body!, filter))
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(urlFilterProvider);
    final bubbles = messages.map((m) => _buildBodyBubble(m, filter));
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