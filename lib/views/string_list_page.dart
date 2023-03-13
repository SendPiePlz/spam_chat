import 'package:binary_tree/binary_tree.dart';
import 'package:flutter/material.dart';
import 'package:spam_chat/models/cache.dart';

//=================================================//

///
///
///
class StringListPage extends StatefulWidget {
  const StringListPage({
    super.key,
    required this.title,
    required this.items,
    required this.onClear,
    required this.onDelete,
  });

  factory StringListPage.fromCache(String title, Cache<String> cache) {
    return StringListPage(
      title: title,
      items: cache.content,
      onClear: cache.clear,
      onDelete: cache.removeAll,
    );
  }

  final String title;
  final List<String> items;
  final Function onClear;
  final void Function(Iterable<String>) onDelete;

  @override
  State<StringListPage> createState() => _StringListPageState();
}

//=================================================//

///
class _StringListPageState extends State<StringListPage> {
  final selected = BinaryTree<int>([]);

  ///
  void _clearItems() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Warning'),
        content: const Text('Delete All Items?'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.onClear();
                widget.items.clear();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  ///
  void _deleteItems() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Warning'),
        content: Text('Delete ${selected.length} Items?'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.onDelete(selected.map((i) => widget.items[i]));
                selected.toList(growable: false).reversed.forEach(widget.items.removeAt);
                selected.clear();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              setState(selected.clear);
              Navigator.of(ctx).pop();
            },
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  ///
  void _toggleSelection(int item) => setState(() {
    if (selected.contains(item)) {
      selected.remove(item);
    }
    else {
      selected.insert(item);
    }
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          (selected.isEmpty)
            ? TextButton(
                onPressed: _clearItems,
                child: const Text('Clear'),
              )
            : TextButton(
                onPressed: _deleteItems,
                child: Text('Delete (x${selected.length})'),
              ),
        ],
      ),
      body: (widget.items.isNotEmpty)
        ? ListView.builder(
          itemCount: widget.items.length,
          itemBuilder: (ctx, i) => ListTile(
            title: Text(widget.items[i]),
            onTap: () => _toggleSelection(i),
            selected: selected.contains(i),
          ),
        )
       : const Center(child: Text('No Items')),
    );
  }
}