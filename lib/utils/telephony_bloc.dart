import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spam_chat/models/conversation.dart';
import 'package:spam_chat/utils/extensions.dart';
import 'package:telephony/telephony.dart';

//=================================================//

///
///
///
Future<void> _backgroundMessageHandler(SmsMessage msg) async {
  // TODO
  debugPrint('New Background Message!');
}

//=================================================//

///
///
///
class TelephonyBloc {
  final Telephony _instance = Telephony.instance;
  final ValueNotifier<SmsMessage?> lastestMessage = ValueNotifier(null);
  //final Map<String, ValueNotifier<SmsMessage?>> _listeners = {};

  /// Holds the classification of past analyzed conversations
  final Set<String> _spamCache = {};
  

  TelephonyBloc.init() {
    [Permission.sms, Permission.contacts].request().then(
      (val) {
        if (val[Permission.sms] == PermissionStatus.granted) {
          _instance.listenIncomingSms(
            onNewMessage: _foregroundMessageHandler,
            onBackgroundMessage: _backgroundMessageHandler,
          );
        }
      }
    );
    _loadOrCreateCache();
  }

  ///
  ///
  ///
  Future<void> _loadOrCreateCache() async {
    try {
      final path = await getApplicationSupportDirectory();
      final file = File('${path.path}/convos.json');
      if (await file.exists()) {
        for (final line in await file.readAsLines()) {
          _spamCache.add(line);
        }
      }
      else {
        file.create();
      }
    }
    catch (e) {
      // TODO: handle special cases
      debugPrint('FAILED TO LOAD/CREATE CACHE: ${e.toString()}');
    }
  }

  ///
  ///
  ///
  //ValueNotifier<SmsMessage?> newFilteredNotifier(String address) {
  //  final notif = ValueNotifier(null);
  //  _listeners[address] = notif;
  //  return notif;
  //}

  ///
  ///
  ///
  //void disposeNotifier(String address) {
  //  _listeners.remove(address);
  //}

  ///
  ///
  ///
  void _foregroundMessageHandler(SmsMessage msg) {
    // 1. classifiy message
    // TODO: extract meta information
    //final isSpam = classifiy(msg.body!, ...);

    // 2. record classification
    //if (isSpam && msg.address != null) {
    //  _spamCache.add(msg.address!);
    //}

    // 3. notify
    //debugPrint('New Message: ${msg.threadId}, ${msg.address}, ${msg.date}');
    //debugPrint('${_listeners.containsKey(msg.address)}');
    //_listeners[msg.address]?.value = msg;
    lastestMessage.value = msg;
  }

  ///
  ///
  ///
  Future<List<Conversation>> getConversations() async {
    final res = <Conversation>[];
    for (final c in await _instance.getConversations()) {
      final ms = (await getConversationMessages(c.threadId)).first;
      final ct = await _instance.getContactFromPhone(ms.address!);
      final isSpam = _spamCache.contains(ms.address ?? '');
      res.sortedInsert(Conversation(c, ms, ct, isSpam));
      //res.add(Conversation(c, ms.first, ct));
    }
    return res;
  }

  ///
  ///
  ///
  Future<List<SmsMessage>> getConversationMessages(int? threadid) => _instance.getInboxSms(
    columns: const [SmsColumn.THREAD_ID, SmsColumn.READ, SmsColumn.ADDRESS, SmsColumn.DATE],
    filter: SmsFilter
      .where(SmsColumn.THREAD_ID)
      .equals(threadid.toString()),
    sortOrder: [OrderBy(SmsColumn.DATE)],
  );

  ///
  /// 
  ///
  Future<List<SmsMessage>> getMessages(int? threadid) async {
    if (threadid == null) {
      return <SmsMessage>[];
    }

    final messages = (await _instance.getInboxSms(
      columns: const [SmsColumn.THREAD_ID, SmsColumn.BODY, SmsColumn.STATUS, SmsColumn.DATE],
      filter: SmsFilter
        .where(SmsColumn.THREAD_ID)
        .equals(threadid.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE)],
    )).toList(growable: true);

    final sent = await _instance.getSentSms(
      columns: const [SmsColumn.THREAD_ID, SmsColumn.BODY, SmsColumn.STATUS, SmsColumn.DATE, SmsColumn.TYPE, SmsColumn.STATUS],
      filter: SmsFilter
        .where(SmsColumn.THREAD_ID)
        .equals(threadid.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE)],
    );

    // join both lists
    for (var m in sent) {
      messages.sortedInsert(m);
    }
    
    return messages.toList(growable: false);
  }

  ///
  ///
  ///
  void sendMessage(String address, String body, {dynamic Function(SendStatus)? callback}) {
    // TODO: get callback
    _instance.sendSms(
      to: address,
      message: body,
      statusListener: callback,
      isMultipart: body.length > 160,
    );
  }


}