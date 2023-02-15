import 'package:flutter/material.dart';

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

  final String title;
  final List<String> items;
  final Function onClear;
  final Function(Iterable<String>) onDelete;

  @override
  State<StringListPage> createState() => _StringListPageState();
}

//=================================================//

///
class _StringListPageState extends State<StringListPage> {

  final Set<int> selected = {};

  void _clearItems(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Warning'),
        content: const Text('Delete All Items?'),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              widget.onClear();
              widget.items.clear();
            }),
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  void _deleteItems(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Warning'),
        content: Text('Delete ${selected.length} Items?'),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              widget.onDelete(selected.map((i) => widget.items[i]));
              selected.forEach(widget.items.removeAt);
              selected.clear();
            }),
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () => setState(selected.clear),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int item) => setState(() {
    if (!selected.add(item)) {
      selected.remove(item);
    }
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          (selected.isEmpty)
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _clearItems(context),
              )
            : IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteItems(context),
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