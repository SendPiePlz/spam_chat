import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spam_chat/main.dart';
import 'package:spam_chat/utils/extensions.dart';
import 'package:spam_chat/utils/url_filter.dart';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';

//=================================================//

///
///
///
class MessageView extends ConsumerWidget {
  const MessageView({
    super.key,
    required this.messages,
    required this.isSpam,
    required this.avatar,
  });

  final List<SmsMessage> messages;
  final bool isSpam;
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

//=================================================//

///
///
///
class MessageBox extends StatelessWidget {
  const MessageBox({
    super.key,
    required this.messages,
    required this.isSpam,
    required this.avatar,
    required this.filter
  }) : assert(messages.length > 0);


  final List<SmsMessage> messages;
  final CircleAvatar avatar;
  final bool isSpam;
  final UrlFilter filter;

  bool get isFromUser => messages.first.type == SmsType.MESSAGE_TYPE_SENT;
  String get formattedDateTime => DateTime.fromMillisecondsSinceEpoch(messages.first.date ?? 0).formatMessageDateTime();

  ///
  void _launchUrl(UrlMatch url) {
    final uri = Uri.https(Uri.encodeComponent(url.urlWithoutProtocol));
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  ///
  void _handleUrlAction(BuildContext ctx, UrlMatch url) {
    final actions = [
      TextButton(
        onPressed: () {
          filter.trustUrl(url.urlWithoutProtocol);
          _launchUrl(url);  
        },
        child: const Text('Trust'),
      ),
      TextButton(
        onPressed: () => _launchUrl(url),
        child: const Text('Yes'),
      ),
      TextButton(
        onPressed: () {}, // Do Nothing
        child: const Text('No'),
      ),
    ];
    if (isSpam || url.isBad) {
      showDialog(
        context: ctx,
        builder: (ctx) => AlertDialog(
          title: const Text('Open malicious URL?'),
          content: const Text('SpamChat has determined that this URL is malicious in nature. It is advised to not open it.'),
          actions: actions,
        ),
      );
    }
    else if (!url.isTrusted) {
      showDialog(
        context: ctx,
        builder: (ctx) => AlertDialog(
          title: const Text('Open unknown URL?'),
          content: const Text('Proceed with caution when opening unknown URLs.'),
          actions: actions,
        ),
      );
    }
  }

  ///
  TextStyle _getUrlStyle(Color decorationColor, TextDecorationStyle style) {
    return TextStyle(
      color: Colors.blueAccent,
      decoration: TextDecoration.underline,
      decorationColor: decorationColor,
      decorationStyle: style,
    );
  }

  ///
  List<TextSpan> _createHyperlinks(BuildContext ctx, String msg) {
    // Highlight URLs
    final urls = filter.extractUrls(msg);
    final spans = <TextSpan>[];
    if (urls.isNotEmpty) { // Contains URL(s)
      var e = 0;
      for (final url in urls) {
        // Add text before the URL
        if (e != url.start) {
          spans.add(TextSpan(text: msg.substring(e, url.start)));
        }
        e = url.end;
        // Add the URL
        spans.add(TextSpan(
          text: url.url,
          style: (isSpam || url.isBad)
            ? _getUrlStyle(Colors.redAccent, TextDecorationStyle.wavy)
            : (!url.isTrusted) 
              ? _getUrlStyle(Colors.yellow, TextDecorationStyle.wavy)
              : _getUrlStyle(Colors.blueAccent, TextDecorationStyle.solid),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _handleUrlAction(ctx, url),
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
  Widget _buildBodyBubble(BuildContext ctx, SmsMessage message) {
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
        text: TextSpan(children: _createHyperlinks(ctx, message.body!))
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ListView.builder only builds list items on screen,
    // meaning that we mark message that are being rendered as read
    //if (messages.first.read == false) {
    //  tel.instance.markSmsAsRead(messages.first);
    //}
    final bubbles = messages.map((m) => _buildBodyBubble(context, m));
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
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: (isFromUser)
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: (isFromUser)
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
                verticalDirection: VerticalDirection.up,
                children: bubbles.toList(growable: false),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
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