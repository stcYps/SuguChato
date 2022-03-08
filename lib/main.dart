import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:suguchato/firebase_options.dart';
import 'package:suguchato/views/chat_screen.dart';
import 'package:suguchato/views/login_screen.dart';
import 'package:suguchato/views/room_screen.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

final routes = RouteMap(
  routes: {
    "/": (_) => MaterialPage(child: LoginScreen()),
    "/login": (_) => MaterialPage(child: LoginScreen()),
    "/room": (_) => const MaterialPage(child: RoomScreen()),
    "/chat/:roomId": (_) => MaterialPage(
          child: ChatScreen(roomId: _.pathParameters["roomId"]!),
        ),
  },
);

final routeMaster = RoutemasterDelegate(routesBuilder: (context) => routes);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setUrlStrategy(PathUrlStrategy());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routeInformationParser: const RoutemasterParser(),
      routerDelegate: routeMaster,
    );
  }
}
