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

  TelephonyBloc.init() {
    // TODO: https://stackoverflow.com/a/13895702
    [Permission.sms, Permission.contacts].request().then(
      (val) {
        if (val[Permission.sms] == PermissionStatus.granted) {
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
    var isSpam = spamCache.contains(addr);
    if (!isSpam && !hamCache.contains(addr)) {
      final contact = await instance.getContactFromPhone(addr);
      if (contact == null) {
        isSpam = _filter.isSpam(msg.body!);
      }
    }

    // 2. record classification
    if (isSpam && addr.isNotEmpty) {
      spamCache.add(addr);
    }

    // 3. notify
    lastestMessage.value = msg;
  }

  //---------------------------------------//

  ///
  Future<List<Conversation>> getConversations() async {
    final res = <Conversation>[];
    for (final c in await instance.getConversations()) {
      //final ms = await _getConversationMessages(c.threadId);
      final ms = await getMessages(c.threadId);
      if (ms.isNotEmpty) {
        final m = ms.first;
        final ct = await instance.getContactFromPhone(m.address!);
        var spam = false;
        if (ct == null && isNotHam(m.address!)) {
          spam = isSpam(m.address!) ||
                (ms.last.type == SmsType.MESSAGE_TYPE_INBOX && // conversation initiated by the other party
                 m.type == SmsType.MESSAGE_TYPE_INBOX && // message body from other party
                 _filter.isSpam(m.body ?? '')
                );
        }
        res.sortedInsert(Conversation(c, m, ct, spam));
        //res.add(Conversation(c, m, ct, spam));
      }
    }
    return res;
  }

  //---------------------------------------//

  ///
  Future<List<SmsMessage>> getMessages(int? threadid) async {
    if (threadid == null) {
      return <SmsMessage>[];
    }
    return instance.getAllSms(
      columns: [SmsColumn.THREAD_ID, SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.READ, SmsColumn.DATE, SmsColumn.TYPE, SmsColumn.STATUS],
      filter: SmsFilter
        .where(SmsColumn.THREAD_ID)
        .equals(threadid.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE)],
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