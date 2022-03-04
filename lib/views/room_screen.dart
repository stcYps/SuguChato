import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:suguchato/provider.dart';

class RoomScreen extends StatelessWidget {
  RoomScreen({Key? key}) : super(key: key);

  final roomIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(110, 255, 125, 1),
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Container(
          width: _width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref, child) => Text(
                  ref.read(userProvider) + "さん\nこんにちは！",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Image.asset(
                "assets/hello.png",
                width: _width * 0.6,
              ),
              const SizedBox(
                height: 8,
              ),
              const Text(
                "下の欄からルーム番号を入力してチャットに入室するか、ルーム作成ボタンを押してチャットを作成してね！",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              TextField(
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 21, 180, 0),
                      width: 2,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 21, 180, 0),
                      width: 2,
                    ),
                  ),
                ),
                controller: roomIdController,
                maxLength: 4,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[0-9]")),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              OutlinedButton(
                onPressed: () async {
                  final roomId = roomIdController.text.padLeft(4, "0");
                  final exist = await _checkExist(roomId);
                  if (exist) {
                    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
                    final userUid = firebaseAuth.currentUser?.uid;
                    final userDoc = await _getUser(userUid!);
                    FirebaseFirestore.instance
                        .collection("chat_room")
                        .doc(roomId)
                        .collection("users")
                        .doc(userUid)
                        .set(
                      {
                        "uid": userUid,
                        "name": userDoc["name"],
                      },
                    );
                    Routemaster.of(context).replace("/chat/" + roomId);
                  } else {
                    AwesomeDialog(
                      context: context,
                      headerAnimationLoop: false,
                      dialogType: DialogType.NO_HEADER,
                      desc: "指定された番号のルームが存在しません",
                      btnOkOnPress: () {},
                      btnOkIcon: Icons.check_circle,
                    ).show();
                  }
                },
                child: const Text(
                  "入室",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  primary: Colors.white,
                  side: const BorderSide(width: 2.0, color: Colors.white),
                  fixedSize: Size(_width * 0.85, 48),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              const Text(
                "- または -",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              OutlinedButton(
                onPressed: () => {
                  AwesomeDialog(
                    context: context,
                    headerAnimationLoop: false,
                    dialogType: DialogType.NO_HEADER,
                    body: Center(
                      child: Column(
                        children: [
                          const Text("ルーム番号を入力してください"),
                          TextField(
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                            autofocus: true,
                            controller: roomIdController,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9]")),
                            ],
                          ),
                        ],
                      ),
                    ),
                    btnOkOnPress: () =>
                        _onRoomCreate(context, roomIdController.text),
                    btnOkIcon: Icons.check_circle,
                  ).show()
                },
                child: const Text(
                  "ルームを作成",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  side: const BorderSide(
                    width: 2.0,
                    color: Colors.white,
                  ),
                  fixedSize: Size(_width * 0.85, 48),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextButton(
                onPressed: () => {
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.WARNING,
                    headerAnimationLoop: false,
                    animType: AnimType.TOPSLIDE,
                    closeIcon: const Icon(Icons.close_fullscreen_outlined),
                    desc: '本当にログアウトしますか？',
                    btnCancelOnPress: () {},
                    btnOkOnPress: () => _onSignOut(context),
                  ).show()
                },
                child: const Text(
                  "ログアウト",
                  style: TextStyle(
                    color: Color.fromARGB(255, 21, 180, 0),
                  ),
                ),
                style: TextButton.styleFrom(
                  fixedSize: Size(_width * 0.85, 48),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Future _onRoomCreate(BuildContext context, String roomId) async {
  final _roomId = roomId.padLeft(4, "0");
  FirebaseFirestore.instance.collection("chat_room").doc(_roomId).set({
    "room_id": _roomId,
    "createdAt": DateTime.now(),
  });

  Routemaster.of(context).push("/chat/" + _roomId);
}

Future _onSignOut(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Routemaster.of(context).replace("/");
}

Future<bool> _checkExist(String roomId) async {
  final doc = await FirebaseFirestore.instance
      .collection("chat_room")
      .doc(roomId)
      .get();
  return doc.exists;
}

Future _getUser(String uid) async {
  final doc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();
  return doc.data();
}
