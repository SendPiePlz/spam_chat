import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:spam_chat/utils/extensions.dart';
import 'package:spam_chat/utils/url_filter.dart';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';

//=================================================//

///
///
///
class MessageBox extends StatefulWidget {
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

  @override
  State<MessageBox> createState() => _MessageBoxState();
}

//=================================================//

///
class _MessageBoxState extends State<MessageBox> {

  ///
  void _launchUrl(UrlMatch url) {
    final cs = url.components;
    launchUrl(Uri.https(cs[0], cs[1]), mode: LaunchMode.externalApplication);
  }

  ///
  void _handleUrlAction(UrlMatch url) {
    final actions = [
      TextButton(
        onPressed: () {
          widget.filter.trustUrl(url.url);
          _launchUrl(url);
          Navigator.of(context).pop();
          setState(() {});
        },
        child: const Text('Trust'),
      ),
      TextButton(
        onPressed: () {
          _launchUrl(url);
          Navigator.of(context).pop();
        },
        child: const Text('Yes'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(), // Do Nothing
        child: const Text('No'),
      ),
    ];
    if (widget.isSpam || url.isBad) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Open malicious URL?'),
          content: const Text('SpamChat has determined that this URL is malicious in nature. It is advised to not open it.'),
          actions: actions,
        ),
      );
    }
    else if (!url.isTrusted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Open unknown URL?'),
          content: const Text('Proceed with caution when opening unknown URLs.'),
          actions: actions,
        ),
      );
    }
    else {
      _launchUrl(url);
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
  List<TextSpan> _createHyperlinks(String msg) {
    // Highlight URLs
    final urls = widget.filter.extractUrls(msg);
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
          style: (widget.isSpam || url.isBad)
            ? _getUrlStyle(Colors.redAccent, TextDecorationStyle.wavy)
            : (!url.isTrusted) 
              ? _getUrlStyle(Colors.yellow, TextDecorationStyle.wavy)
              : _getUrlStyle(Colors.blueAccent, TextDecorationStyle.solid),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _handleUrlAction(url),
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
  Widget _buildBodyBubble(SmsMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: (widget.isFromUser)
          ? Colors.tealAccent[700]
          : Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: (widget.isFromUser && message.status == SmsStatus.STATUS_FAILED)
          ? Border.all(color: Colors.redAccent, width: 2)
          : null,
      ),
      child: RichText(
        text: TextSpan(children: _createHyperlinks(message.body!))
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
    final bubbles = widget.messages.map(_buildBodyBubble);
    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: (widget.isFromUser)
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          (widget.isFromUser) ? const SizedBox() : widget.avatar,
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: (widget.isFromUser)
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: (widget.isFromUser)
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
                verticalDirection: VerticalDirection.up,
                children: bubbles.toList(growable: false),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  widget.formattedDateTime,
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