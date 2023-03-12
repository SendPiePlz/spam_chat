import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spam_chat/models/conversation.dart';
import 'package:spam_chat/models/cache.dart';
import 'package:spam_chat/utils/extensions.dart';
import 'package:spam_chat/utils/spam_filter.dart';
import 'package:telephony/telephony.dart';

//=================================================//

///
///
///
class TelephonyBloc {

  final Telephony instance = Telephony.instance;
  final StringCache spamCache = StringCache.load('spams.txt');
  final StringCache hamCache = StringCache.load('hams.txt');
  final SpamFilter _filter = SpamFilter();

  final ValueNotifier<SmsMessage?> lastestMessage = ValueNotifier(null);

  //---------------------------------------//

  TelephonyBloc() {
    // TODO: https://stackoverflow.com/a/13895702
    [Permission.sms, Permission.contacts].request().then(
      (ps) {
        if (ps[Permission.sms] == PermissionStatus.granted) {
          instance.listenIncomingSms(
            onNewMessage: _foregroundMessageHandler,
            //onBackgroundMessage: _backgroundMessageHandler,
            listenInBackground: false,
          );
        }
      }
    );
  }

  //---------------------------------------//

  void markAsSpam(String address) {
    spamCache.add(address);
    hamCache.remove(address);
  }
  void unmarkAddress(String address) => spamCache.remove(address);
  void unmarkAll() => spamCache.clear();

  void trustAddress(String address) {
    hamCache.add(address);
    spamCache.remove(address);
  }
  void untrustAddress(String address) => hamCache.remove(address);
  void untrustAll() => spamCache.clear();

  bool isSpam(String address) => spamCache.contains(address);
  bool isNotSpam(String address) => !isSpam(address);
  bool isHam(String address) => hamCache.contains(address);
  bool isNotHam(String address) => !isHam(address);

  //---------------------------------------//

  ///
  Future<void> _foregroundMessageHandler(SmsMessage msg) async {
    // 1. classifiy message
    final addr = msg.address ?? '';
    var spam = spamCache.contains(addr);
    if (!spam && !hamCache.contains(addr)) {
      final contact = await instance.getContactFromPhone(addr);
      if (contact == null) {
        spam = _filter.isSpam(msg.body!);
      }
    }

    // 2. record classification
    if (spam && addr.isNotEmpty) {
      spamCache.add(addr);
    }

    // 3. notify
    lastestMessage.value = msg;
  }

  //---------------------------------------//

  ///
  Future<List<Conversation>> getConversations() async {
    final res = <Conversation>[];
    // Get information about each conversations
    for (final c in await instance.getConversations()) {
      final first = await _getSingleMessage(c.threadId);
      if (first != null) {
        // Try retrieving a contact
        final ct = await instance.getContactFromPhone(first.address!);
        var spam = false;
        if (ct == null && isNotHam(first.address!)) {
          // Check if conversation is spam
          final last = await _getSingleMessage(c.threadId, Sort.ASC);
          spam = isSpam(first.address!);
          if (!spam &&
            last!.type == SmsType.MESSAGE_TYPE_INBOX &&
            first.type == SmsType.MESSAGE_TYPE_INBOX &&
            first.body != null &&
            first.body!.isNotEmpty &&
            _filter.isSpam(first.body!)
          ) {
            // Newly found spam conversation
            spam = true;
            spamCache.add(first.address!);
          }
        }
        // Insert conversation in datetime order
        res.sortedInsert(Conversation(c, first, ct, spam));
        //res.add(Conversation(c, m, ct, spam));
      }
    }
    return res;
  }

  //---------------------------------------//

  Future<SmsMessage?> _getSingleMessage(int? threadid, [Sort order = Sort.DESC]) async {
    final msg = await instance.getAllSms(
      columns: [SmsColumn.THREAD_ID, SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.READ, SmsColumn.DATE, SmsColumn.TYPE, SmsColumn.STATUS],
      filter: SmsFilter
        .where(SmsColumn.THREAD_ID)
        .equals(threadid.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: order)],
      amount: 1,
    );
    if (msg.isNotEmpty) {
      return msg.first;
    }
    return null;
  }

  //---------------------------------------//

  ///
  Future<List<SmsMessage>> getMessages(int? threadid, [int amount = 0]) async {
    if (threadid == null) {
      return <SmsMessage>[];
    }
    return instance.getAllSms(
      columns: [SmsColumn.THREAD_ID, SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.READ, SmsColumn.DATE, SmsColumn.TYPE, SmsColumn.STATUS],
      filter: SmsFilter
        .where(SmsColumn.THREAD_ID)
        .equals(threadid.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE)],
      amount: amount,
    );
  }

  //---------------------------------------//

  ///
  void sendMessage(String address, String body, [dynamic Function(SendStatus)? callback]) {
    instance.sendSms(
      to: address,
      message: body,
      statusListener: callback,
      isMultipart: body.length > 160,
    );
  }
}