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

  final Telephony _instance = Telephony.instance;
  final StringCache _cache = StringCache.load('spams.txt');
  final SpamFilter _filter = const SpamFilter();

  final ValueNotifier<SmsMessage?> lastestMessage = ValueNotifier(null);
  //final Map<String, ValueNotifier<SmsMessage?>> _listeners = {};

  //---------------------------------------//

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
  }

  //---------------------------------------//

  List<String> get blockedAddresses => _cache.content;
  void blockAddress(String address) => _cache.add(address);
  void unblockAddress(String address) => _cache.remove(address);
  void unblockAddresses(Iterable<String> addresses) => _cache.removeAll(addresses);
  void unblockAll() => _cache.clear();

  //---------------------------------------//

  ///
  void _foregroundMessageHandler(SmsMessage msg) {
    // 1. classifiy message
    // TODO: extract meta information
    final isSpam = _filter.isSpam(msg.body!);
    debugPrint(msg.address.toString());
    debugPrint(isSpam.toString());
    
    // 2. record classification
    if (isSpam && msg.address != null) {
      _cache.add(msg.address!);
    }

    // 3. notify
    //debugPrint('New Message: ${msg.threadId}, ${msg.address}, ${msg.date}');
    //debugPrint('${_listeners.containsKey(msg.address)}');
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
    for (final c in await _instance.getConversations()) {
      final ms = (await getConversationMessages(c.threadId)).first;
      final ct = await _instance.getContactFromPhone(ms.address!);
      final isSpam = _cache.contains(ms.address ?? '');
      res.sortedInsert(Conversation(c, ms, ct, isSpam));
      //res.add(Conversation(c, ms.first, ct));
    }
    return res;
  }

  //---------------------------------------//

  ///
  Future<List<SmsMessage>> getConversationMessages(int? threadid) => _instance.getInboxSms(
    columns: const [SmsColumn.THREAD_ID, SmsColumn.READ, SmsColumn.ADDRESS, SmsColumn.DATE],
    filter: SmsFilter
      .where(SmsColumn.THREAD_ID)
      .equals(threadid.toString()),
    sortOrder: [OrderBy(SmsColumn.DATE)],
  );

  //---------------------------------------//

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

  //---------------------------------------//

  ///
  void sendMessage(String address, String body, [dynamic Function(SendStatus)? callback]) {
    _instance.sendSms(
      to: address,
      message: body,
      statusListener: callback,
      isMultipart: body.length > 160,
    );
  }

}