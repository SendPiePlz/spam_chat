import 'package:flutter/material.dart';

//=================================================//

///
///
///
class MessageInputField extends StatelessWidget {
  const MessageInputField({
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.maxHeight = 300,
    required this.controller,
    required this.onSubmitted
  });

  final FocusNode? focusNode;
  final bool autofocus;
  final double maxHeight;
  final TextEditingController controller;
  final void Function(String) onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 60,
        minWidth: double.infinity,
        maxHeight: maxHeight,
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              focusNode: focusNode,
              autofocus: autofocus,
              keyboardType: TextInputType.text,
              keyboardAppearance: Brightness.dark,
              maxLines: null,
              style: const TextStyle(fontWeight: FontWeight.normal),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 2,
                ),
                hintText: 'Send a message...',
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (ctx, val, _) => IconButton(
              icon: const Icon(Icons.send),
              color: Theme.of(ctx).colorScheme.secondary,
              disabledColor: Colors.white38,
              onPressed: (val.text.isNotEmpty)
                ? () => onSubmitted(val.text)
                : null,
            ),
          ),
        ],
      ),
    );
  }
}