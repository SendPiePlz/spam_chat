import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spam_chat/models/conversation.dart';
import 'package:telephony/telephony.dart';

//=================================================//

extension Classification on String {
  /// Checks if a string is composed of only letters and numbers [0-9a-z].
  /// (Assumes the string to be lower case.)
  bool isalnum() {
    for (final r in runes) {
      if (r < 48 || (r > 57 && r < 97) || r > 122) {
        return false;
      }
    }
    return true;
  }

  /// Checks if a string is composed of only hexadecimal characters [0-9a-f].
  /// (Assumes the string to be lower case.)
  bool ishex() {
    for (final r in runes) {
      if (r < 48 || (r > 57 && r < 97) || r > 102) {
        return false;
      }
    }
    return true;
  }

  /// Checks if a string is composed of only letters [a-z].
  /// (Assumes the string to be lower case.)
  bool isalpha() {
    for (final r in runes) {
      if (r < 97 || r > 122) {
        return false;
      }
    }
    return true;
  }

  /// Checks if a string is composed of only digits [0-9].
  bool isdigit() {
    for (final r in runes) {
      if (r < 48 || r > 57) {
        return false;
      }
    }
    return true; 
  }


  static const _vowels = ['a','e','i','o','u','y'];

  ///
  bool isReadable() {
    var total = 0;
    var bads  = 0;
    var i     = 0;
    var cnt   = 1;
    while (i < length) {
      cnt = 1;
      final v = _vowels.contains(this[i++]);
      while (i < length && _vowels.contains(this[i]) == v) {
        ++cnt; ++i;
      }
      if (cnt > 2) {
        ++bads;
      }
      ++total;
    }
    return (bads / total) < 0.2;
  }
}

//=================================================//

extension ContactAvatar on Contact {
  ///
  CircleAvatar get avatar {
    int cIndex = Random(displayName.hashCode).nextInt(Colors.accents.length);
    Color bColor = Colors.accents[cIndex];
    if (thumbnail != null) {
      return CircleAvatar(
        backgroundColor: bColor,
        backgroundImage: MemoryImage(thumbnail!),
      );
    }
    return CircleAvatar(
      backgroundColor: bColor,
      child: Text(
        displayName?[0] ?? 'T',
        style: const TextStyle(color: Colors.black),
      ),
    );
  }
}

//=================================================//

extension FormatDateTime on DateTime {
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
    insert(left, value);
  }
}