import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spam_chat/utils//extensions.dart';
import 'package:telephony/telephony.dart';

//=================================================//

///
///
///
class Conversation implements Comparable<Conversation> {
  const Conversation(this.conversation, this.smsInfo, this.contact, this.isSpam);

  final SmsConversation conversation;
  final SmsMessage smsInfo;
  final Contact? contact;
  final bool isSpam;
  

  int get threadId => conversation.threadId ?? -1;
  String get snippet => conversation.snippet ?? '';
  String get address => smsInfo.address ?? '';
  bool get hasUnread => !(smsInfo.read ?? false);

  bool get hasContact => contact != null;
  String get displayName => contact?.displayName ?? getFormattedAddress();

  ///
  CircleAvatar get avatar {
    if (isSpam) {
      return CircleAvatar(
        backgroundColor: Colors.red,
        child: Icon(Icons.warning, color: Colors.pink.shade100),
      );
    }
    else if (hasContact) {
      return contact!.avatar;
    }
    else {
      final i = Random(address.hashCode).nextInt(Colors.accents.length);
      return CircleAvatar(
        backgroundColor: Colors.accents[i],
        child: const Icon(Icons.person, color: Colors.black), // Icons.account_circle_rounded
      );
    }
  }

  ///
  String getFormattedAddress() {
    if (smsInfo.address != null) {
      final addr = smsInfo.address!;
      final addr2 = (addr[0] != '+') ? addr : addr.substring(2);
      return '(${addr2.substring(0, 3)}) ${addr2.substring(3, 6)}-${addr2.substring(6)}';
    }
    return 'Unknown';
  }

  ///
  String get formattedDate {
    final date = DateTime.fromMillisecondsSinceEpoch(smsInfo.date ?? 0);
    return date.formatConversationDateTime();
  }

  @override
  int compareTo(Conversation other) {
    final d1 = smsInfo.date ?? 0;
    final d2 = other.smsInfo.date ?? 0;
    return d2.compareTo(d1); // inverse comparison
  }
}