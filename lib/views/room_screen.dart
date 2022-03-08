import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:routemaster/routemaster.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class RoomScreen extends StatefulWidget {
  const RoomScreen({Key? key}) : super(key: key);

  @override
  _RoomScreenState createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final roomIdController = TextEditingController();
  types.User _user = const types.User(id: "", firstName: "");

  @override
  void initState() {
    _getUser();
    super.initState();
  }

  Future<void> _getUser() async {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    firebaseUser ??= await FirebaseAuth.instance.authStateChanges().first;
    final _uid = firebaseUser!.uid;
    final getData =
        await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    setState(() {
      _user = types.User(id: _uid, firstName: getData.data()!["firstName"]);
    });
  }

  Future _onRoomCreate(BuildContext context, String roomId, String uid) async {
    FirebaseFirestore.instance.collection("chat_room").doc(roomId).set({
      "room_id": roomId,
      "createdAt": DateTime.now(),
    });
    await _onUserJoin(uid, roomId);
    Routemaster.of(context).push("/chat/" + roomId);
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

  Future _returnUser(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.data();
  }

  Future _onUserJoin(String uid, String roomId) async {
    final userDoc = await _returnUser(uid);
    FirebaseFirestore.instance
        .collection("chat_room")
        .doc(roomId)
        .collection("users")
        .doc(uid)
        .set(
      {
        "uid": uid,
        "name": userDoc["firstName"],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 157, 97, 1),
      resizeToAvoidBottomInset: false,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400.0),
          child: SizedBox(
            width: _width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _user.firstName! + "さん\nこんにちは！",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Image.asset(
                  "assets/hello.png",
                ),
                const SizedBox(
                  height: 8,
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
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
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
                      final userUid = firebaseAuth.currentUser!.uid;
                      await _onUserJoin(userUid, roomId);
                      Routemaster.of(context).replace("/chat/" + roomId);
                    } else {
                      AwesomeDialog(
                        width: 400,
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
                      width: 400,
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
                      btnOkOnPress: () async {
                        final roomId = roomIdController.text.padLeft(4, "0");
                        final exist = await _checkExist(roomId);
                        if (!exist) {
                          final userUid =
                              FirebaseAuth.instance.currentUser!.uid;
                          _onRoomCreate(context, roomId, userUid);
                        } else {
                          AwesomeDialog(
                            width: 400,
                            context: context,
                            headerAnimationLoop: false,
                            dialogType: DialogType.NO_HEADER,
                            desc: "指定された番号のルームは存在しています",
                            btnOkOnPress: () {},
                            btnOkIcon: Icons.check_circle,
                          ).show();
                        }
                      },
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
                  style: OutlinedButton.styleFrom(
                    primary: Colors.white,
                    side: const BorderSide(width: 2.0, color: Colors.white),
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
                      width: 400,
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
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
