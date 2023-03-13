import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spam_chat/main.dart';
import 'package:spam_chat/views/string_list_page.dart';

//=================================================//

///
///
///
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlFilter = ref.read(urlFilterProvider);
    final telephone = ref.read(telephonyProvider);
    const style = TextStyle(fontSize: 18);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // TODO: statistics
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 10
            ),
            style: ListTileStyle.drawer,
            leading: const SizedBox(width: 20),
            title: Text(
              telephone.statsCache['spam'].toString(),
              style: const TextStyle(fontSize: 30),
            ),
            subtitle: const Text('spam number(s) detected'),
          ),
          ListTile(
            title: const Text('Blacklisted numbers', style: style),
            onTap: () => _navigateTo(
              context,
              StringListPage.fromCache('Blacklisted Numbers', telephone.spamCache)
            ),
          ),
          ListTile(
            title: const Text('Whitelisted numbers', style: style),
            onTap: () => _navigateTo(
              context,
              StringListPage.fromCache('Whitelisted Numbers', telephone.hamCache)
            ),
          ),
          ListTile(
            title: const Text('Trusted URLs', style: style),
            onTap: () => _navigateTo(context, StringListPage(
              title: 'Trusted URLs',
              items: urlFilter.trustedUrls,
              onClear: urlFilter.untrustAll,
              onDelete: urlFilter.untrustUrls,
            )),
          ),
        ],
      ),
    );
  }
}