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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlFilter = ref.read(urlFilterProvider);
    final telephone = ref.read(telephonyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Blacklisted numbers'),
            onTap: () => _navigateTo(
              context,
              StringListPage.fromCache('Blacklisted Numbers', telephone.spamCache)
            ),
          ),
          ListTile(
            title: const Text('Whitelisted numbers'),
            onTap: () => _navigateTo(
              context,
              StringListPage.fromCache('Whitelisted Numbers', telephone.hamCache)
            ),
          ),
          ListTile(
            title: const Text('Trusted URLs'),
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