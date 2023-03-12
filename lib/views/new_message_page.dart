import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spam_chat/main.dart';
import 'package:spam_chat/utils/extensions.dart';
import 'package:spam_chat/utils/telephony_bloc.dart';
import 'package:spam_chat/views/message_page.dart';
import 'package:spam_chat/widgets/message_input_field.dart';
import 'package:telephony/telephony.dart';

//=================================================//

///
///
///
class NewMessagePage extends ConsumerStatefulWidget {
  const NewMessagePage({super.key});

  @override
  ConsumerState<NewMessagePage> createState() => _NewMessagePageState();
}

//=================================================//

///
class _NewMessagePageState extends ConsumerState<NewMessagePage> {
  static final isPhone = RegExp(r"\+?\d+|(\+\d)?(\d{3}) ?\d{3}-\d{4}|(\+\d)? \d{3}-\d{3}-\d{4}");

  final TextEditingController _filterController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final TelephonyBloc _telephone;
  late final Future<List<Contact>> _contacts;

  bool _useDialpad = false;
  bool _contactSelected = false;
  
  Contact? _selectedContact;
  bool _isSelectionCustom = false;

  @override
  void initState() {
    super.initState();
    _telephone = ref.read(telephonyProvider);
    _contacts = _telephone.instance.getContacts();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _filterController.dispose();
    _msgController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  ///
  void _resetSelection() {
    _contactSelected = false;
    _selectedContact = null;
    _isSelectionCustom = false;
  }

  ///
  void _handleFocusChange() {
    if (_focusNode.hasFocus && _contactSelected) {
      // focus changes back to recipient selection
      setState(_resetSelection);
    }
  }

  ///
  void _openMessageView(SmsConversation convo, String addr, Contact? contact) {
    // TODO: fix error (not crash, thankfully)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MessagePage(
        conversation: convo,
        address: addr,
        contact: contact,
      )),
    );
  }

  ///
  void _sendInitialMessage() {
    final addr = _cleanAddress(_selectedContact!.phone ?? '');
    _telephone.sendMessage(
      addr,
      _msgController.text,
      (status) {
        if (status != SmsStatus.STATUS_FAILED) {
          _telephone.instance.getConversationFromPhone(addr).then((c) {
            if (c != null) {
              _openMessageView(c, addr, (_isSelectionCustom) ? null : _selectedContact);
            }
            else {
              // Failed sending message
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text('Failed sending message to $addr'),
              ));
              setState(_resetSelection);
            }
          });
        }
      },
    );
  }

  ///
  void _onRecipientSelected() {
    final addr = _cleanAddress(_selectedContact!.phone ?? '');
    _telephone.instance.getConversationFromPhone(addr).then((c) {
      if (c != null) {
        // A conversation already exists
        _openMessageView(c, addr, (_isSelectionCustom) ? null : _selectedContact);
      }
      else {
        // New conversation
        setState(() {
          _contactSelected = true;
          _filterController.text = (_isSelectionCustom)
            ? _selectedContact!.phone ?? ''
            : _selectedContact!.displayName ?? '';
          _focusNode.unfocus();
        });
      }
    });
  }

  ///
  String _cleanAddress(String text) {
    final buf = StringBuffer();
    for (final c in text.characters) {
      if (c.isdigit()) {
        buf.write(c);
      }
    }
    if (buf.length == 11) {
      return '+${buf.toString()}';
    }
    return buf.toString();
  }

  ///
  String _tryFormatPhone(String text) {
    if (text.length == 10) {
      return '(${text.substring(0, 3)}) ${text.substring(3, 6)}-${text.substring(6)}';
    }
    else if (text.length == 11 && text[0] == '1') {
      return '+1 (${text.substring(1, 4)}) ${text.substring(4, 7)}-${text.substring(7)}';
    }
    return text;
  }

  ///
  Widget _buildContactSelectionView() {
    return Column(
      children: [
        (_contactSelected)
          ? MessageInputField(
              controller: _msgController,
              autofocus: true,
              maxHeight: 200,
              onSubmitted: (_) => _sendInitialMessage(),
            )
          : const SizedBox(),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: _filterController,
            builder: (ctx, val, _) => FutureBuilder(
              future: _contacts,
              initialData: const <Contact>[],
              builder: (ctx, snapshot) {
                // Filter contacts by names
                final items = snapshot.requireData.where((c) {
                  if (val.text.isEmpty) {
                    return true;
                  }
                  return c.displayName?.toLowerCase().startsWith(val.text.toLowerCase()) ?? false;
                }).toList();
                final len = items.length;

                // Add fake contact to the list for custom phone number (always last in the list)
                var hasCustom = false;
                if (isPhone.hasMatch(val.text)) {
                  items.add(Contact.fromMap({'displayName': 'Custom', 'phone': _tryFormatPhone(val.text)}, false));
                  hasCustom = true;
                }

                // Render contact list
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: items[i].avatar,
                    title: Text(items[i].displayName ?? ''),
                    subtitle: Text(
                      items[i].phone ?? '',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    onTap: () {
                      // Select recipient
                      _selectedContact = items[i];
                      _isSelectionCustom = hasCustom && i == len;
                      _onRecipientSelected();
                    }
                  ), 
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New conversation'),
        shadowColor: Colors.black87,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextFormField(
                style: const TextStyle(fontWeight: FontWeight.normal),
                decoration: InputDecoration(
                  hintText: "Type a name or phone number",
                  prefix: Container(
                    padding: const EdgeInsets.only(left: 15, right: 25),
                    child: Text(
                      'To',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary
                      ),
                    ),
                  ),
                  suffix: IconButton(
                    padding: const EdgeInsets.only(right: 25, left: 10),
                    icon: (_useDialpad)
                      ? const Icon(Icons.dialpad)
                      : const Icon(Icons.keyboard),
                    onPressed: () => setState(() {
                      // Toggle keyboard type
                      _useDialpad = !_useDialpad;
                      // Refresh focus to switch keyboard
                      _focusNode.unfocus();
                      Timer(const Duration(milliseconds: 50), () => _focusNode.requestFocus());
                    }),
                  ),
                ),
                keyboardType: (_useDialpad)
                  ? TextInputType.text
                  : TextInputType.phone,
                keyboardAppearance: Brightness.dark,
                controller: _filterController,
                focusNode: _focusNode,
                autofocus: true,
              ),
            ],
          ),
        ),
      ),
      body: _buildContactSelectionView(),
    );
  }
}