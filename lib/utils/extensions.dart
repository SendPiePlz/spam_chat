import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:spam_chat/models/conversation.dart';
import 'package:telephony/telephony.dart';

//=================================================//

extension FormatMessageDateTime on DateTime {
  ///
  ///
  ///
  String formatConversationDateTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = difference(today);
    if (diff > const Duration()) { // today
      return DateFormat.jm().format(this);
    }
    else if (diff.inDays > -6) { // within a week
      return DateFormat('EEE').format(this);
    }
    else if (diff.inDays > -30) { // within a month
      return DateFormat('MMM, dd').format(this);
    }
    else {
      return DateFormat.yMd().format(this);
    }
  }

  ///
  ///
  ///
  String formatMessageDateTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = difference(today);
    if (diff > const Duration()) { // today
      return DateFormat.jm().format(this);
    }
    else if (diff.inDays > -6) { // within a week
      return DateFormat('EEE, HH:mm').format(this);
    }
    else if (diff.inDays > -30) { // within a month
      return DateFormat('MMM dd, HH:mm').format(this);
    }
    else {
      return DateFormat('M/d/yy, HH:mm').format(this);
    }
  }
}

//=================================================//

extension SortedInsertConversations on List<Conversation> {
  ///
  ///
  ///
  void sortedInsert(Conversation value) {
    var left = 0;
    var right = length-1;
    while (left <= right) {
      final int mid = left + (right - left) ~/ 2;
      if (this[mid] < value) {
        left = mid + 1;
      }
      else if (this[mid] > value) {
        right = mid - 1;
      }
      else {
        right = mid + 1;
      }
    }
    insert(left, value);
  }
}

extension SortedInsertMessages on List<SmsMessage> {
  ///
  ///
  ///
  void sortedInsert(SmsMessage value) {
    final date = value.date ?? 0;
    var left = 0;
    var right = length-1;
    while (left <= right) {
      final int mid = left + (right - left) ~/ 2;
      final midValue = this[mid].date ?? 0;
      if (midValue > date) {
        left = mid + 1;
      }
      else if (midValue < date) {
        right = mid - 1;
      }
      else {
        right = mid + 1;
      }
    }
    //debugPrint('$left');
    insert(left, value);
  }
}