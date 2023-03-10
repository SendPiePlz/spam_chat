import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spam_chat/utils/telephony_bloc.dart';
import 'package:spam_chat/utils/url_filter.dart';
import 'package:spam_chat/views/inbox_page.dart';

//=================================================//

void main() async {
  // Locks the orientations to portrait mode
  WidgetsFlutterBinding.ensureInitialized();
  // Set the System's Navigation bar color
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ])
  .then((_) => runApp(const App()));
}

//=================================================//

///
final telephonyProvider = Provider((_) => TelephonyBloc());

///
final urlFilterProvider = Provider((_) => UrlFilter());

//=================================================//

///
///
///
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'SpamChat',
        theme: ThemeData.dark(useMaterial3: true),
        home: const InboxPage(),
      ),
    );
  }
}