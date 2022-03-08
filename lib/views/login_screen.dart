import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:routemaster/routemaster.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final nicknameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 157, 97, 1),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/splash.png",
                width: _width * 0.8,
              ),
              const SizedBox(
                height: 64,
              ),
              ElevatedButton(
                onPressed: () => {},
                child: const Text(
                  "Twitterでログインする",
                  style: TextStyle(
                    color: Color.fromRGBO(0, 157, 97, 1),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.white,
                  fixedSize: Size(_width * 0.8, 48),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              OutlinedButton(
                onPressed: () {
                  AwesomeDialog(
                    width: 400,
                    context: context,
                    headerAnimationLoop: false,
                    dialogType: DialogType.NO_HEADER,
                    body: Center(
                      child: Column(
                        children: [
                          const Text("ニックネームを入力してください"),
                          TextField(
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                            autofocus: true,
                            controller: nicknameController,
                          ),
                        ],
                      ),
                    ),
                    btnOkOnPress: () =>
                        _onSignInAnonymous(context, nicknameController.text),
                    btnOkIcon: Icons.check_circle,
                  ).show();
                },
                child: const Text(
                  "ゲストでログインする",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(width: 2.0, color: Colors.white),
                  fixedSize: Size(_width * 0.8, 48),
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                "ゲストでログインすると一部機能が制限されます",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Future _onSignInTwitter(BuildContext context) async {
//   // Twitterのアクセストークンを取得するためにTwitterLoginのインスタンスを作成する
//   final twitterLogin = TwitterLogin(
//     apiKey: dotenv.env["TWITTER_API_KEY"]!,
//     apiSecretKey: dotenv.env["TWITTER_SECRET_KEY"]!,
//     redirectURI: 'suguchato://',
//   );
//   final authResult = await twitterLogin.loginV2();

//   switch (authResult.status) {
//     case TwitterLoginStatus.loggedIn:
//       // ログイン成功
//       debugPrint('====== Login success ======');
//       // アクセストークンを取得する
//       final credential = TwitterAuthProvider.credential(
//         accessToken: authResult.authToken!,
//         secret: authResult.authTokenSecret!,
//       );

//       final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
//       firebaseAuth.signInWithCredential(credential);

//       Routemaster.of(context).push("/room");
//       break;
//     case TwitterLoginStatus.cancelledByUser:
//       // ログインキャンセル
//       debugPrint('====== Login cancel ======');
//       break;
//     case TwitterLoginStatus.error:
//     case null:
//       // ログイン失敗
//       debugPrint('====== Login error ======');
//       break;
//   }
// }

Future _onSignInAnonymous(BuildContext context, String name) async {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  try {
    final credential = await firebaseAuth.signInAnonymously();

    if (name == "") {
      name = "デフォルトユーザー";
    }

    await FirebaseChatCore.instance.createUserInFirestore(
      types.User(
        firstName: name,
        id: credential.user!.uid,
      ),
    );

    Routemaster.of(context).replace("/room");
  } catch (e) {
    debugPrint(e.toString());
  }
}
