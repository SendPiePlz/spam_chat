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
  final StringCache _cache = StringCache.load('spams.txt');
  final SpamFilter _filter = SpamFilter();

  final ValueNotifier<SmsMessage?> lastestMessage = ValueNotifier(null);
  //final Map<String, ValueNotifier<SmsMessage?>> _listeners = {};

  //---------------------------------------//

  TelephonyBloc.init() {
    // TODO: https://stackoverflow.com/a/13895702
    [Permission.sms, Permission.contacts].request().then(
      (val) {
        if (val[Permission.sms] == PermissionStatus.granted) {
          instance.listenIncomingSms(
            onNewMessage: _foregroundMessageHandler,
            onBackgroundMessage: _backgroundMessageHandler,
          );
        }
      }
    );
  }

  //---------------------------------------//

  List<String> get blockedAddresses => _cache.content;
  void blockAddress(String address) => _cache.add(address);
  void unblockAddress(String address) => _cache.remove(address);
  void unblockAddresses(Iterable<String> addresses) => _cache.removeAll(addresses);
  void unblockAll() => _cache.clear();

  bool isSpam(String address) => _cache.contains(address);
  bool isNotSpam(String address) => !isSpam(address);

  //---------------------------------------//

  ///
  Future<void> _foregroundMessageHandler(SmsMessage msg) async {
    // 1. classifiy message
    final addr = msg.address ?? '';
    //debugPrint(addr);
    var isSpam = _cache.contains(addr);
    if (!isSpam) {
      final contact = await instance.getContactFromPhone(addr);
      if (contact == null) {
        isSpam = _filter.isSpam(msg.body!);
      }
    }

    // 2. record classification
    if (isSpam && addr.isNotEmpty) {
      _cache.add(addr);
    }

    // 3. notify
    //_listeners[msg.address]?.value = msg;
    lastestMessage.value = msg;
  }

  //---------------------------------------//

  ///
  static Future<void> _backgroundMessageHandler(SmsMessage msg) async {
    // TODO
    debugPrint('New Background Message!');
  }

  //---------------------------------------//

  ///
  Future<List<Conversation>> getConversations() async {
    final res = <Conversation>[];
    for (final c in await instance.getConversations()) {
      final ms = await _getConversationMessages(c.threadId);
      if (ms.isNotEmpty) {
        final ct = await instance.getContactFromPhone(ms.first.address!);
        final isSpam = _cache.contains(ms.first.address!);
        res.sortedInsert(Conversation(c, ms.first, ct, isSpam));
        //res.add(Conversation(c, ms.first, ct, isSpam));
      }
    }
    return res;
  }

  //---------------------------------------//

  ///
  Future<List<SmsMessage>> _getConversationMessages(int? threadid) {
    return instance.getAllSms(
      columns: const [SmsColumn.THREAD_ID, SmsColumn.READ, SmsColumn.ADDRESS, SmsColumn.DATE],
      filter: SmsFilter
        .where(SmsColumn.THREAD_ID)
        .equals(threadid.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE)],
    );
  }

  //---------------------------------------//

  ///
  Future<List<SmsMessage>> getMessages(int? threadid) async {
    if (threadid == null) {
      return <SmsMessage>[];
    }
    return instance.getAllSms(
      columns: [SmsColumn.ID, SmsColumn.THREAD_ID, SmsColumn.BODY, SmsColumn.READ, SmsColumn.DATE, SmsColumn.TYPE, SmsColumn.STATUS],
      filter: SmsFilter
        .where(SmsColumn.THREAD_ID)
        .equals(threadid.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE)],
    );
  }

  //---------------------------------------//

  ///
  //Future<void> markSmsAsRead(SmsMessage from) async {
  //  final messages = await instance.getInboxSms(
  //    columns: const [SmsColumn.ID, SmsColumn.THREAD_ID, SmsColumn.READ, SmsColumn.DATE],
  //    filter: SmsFilter
  //      .where(SmsColumn.THREAD_ID)
  //      .equals(from.threadId.toString())
  //      .and(SmsColumn.READ)
  //      .equals(false.toString())
  //      .and(SmsColumn.DATE)
  //      .lessThan(from.date.toString()),
  //    sortOrder: [OrderBy(SmsColumn.DATE)],
  //  );
  //  final idx = messages.map((m) => m.id ?? 0).toList(growable: false);
  //  instance.markSmsAsRead(idx);
  //}

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