import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:suguchato/provider.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  late types.User _user;

  List<types.Message> _messages = [];

  void initState() {
    _getUser();
    _getMessages();
    super.initState();
  }

  void _getUser() async {
    final _uid = firebaseAuth.currentUser!.uid;
    final getData =
        await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    _user = types.User(id: _uid, firstName: getData.data()!["firstName"]);
  }

  // firestoreからメッセージの内容をとってきて_messageにセット
  void _getMessages() async {
    final getData = await FirebaseFirestore.instance
        .collection('chat_room')
        .doc(widget.roomId)
        .collection('contents')
        .get();

    final message = getData.docs
        .map((d) => types.TextMessage(
            author:
                types.User(id: d.data()['uid'], firstName: d.data()['name']),
            createdAt: d.data()['createdAt'],
            id: d.data()['id'],
            text: d.data()['text']))
        .toList();

    setState(() {
      _messages = [...message];
    });
  }

  // メッセージ内容をfirestoreにセット
  void _addMessage(types.TextMessage message) async {
    setState(() {
      _messages.insert(0, message);
    });
    await FirebaseFirestore.instance
        .collection('chat_room')
        .doc(widget.roomId)
        .collection('contents')
        .add({
      'uid': message.author.id,
      'name': message.author.firstName,
      'createdAt': message.createdAt,
      'id': message.id,
      'text': message.text,
    });
  }

  // リンク添付時にリンクプレビューを表示する
  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = _messages[index].copyWith(previewData: previewData);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  // メッセージ送信時の処理
  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: "id",
      text: message.text,
    );

    _addMessage(textMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "roomID: " + widget.roomId,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.grey,
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Consumer(
              builder: (context, ref, child) => UserAccountsDrawerHeader(
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: AssetImage("assets/default_icon.png"),
                ),
                otherAccountsPictures: [
                  IconButton(
                    onPressed: () => {},
                    icon: const Icon(
                      Icons.settings,
                      color: Color.fromARGB(255, 245, 245, 245),
                    ),
                  )
                ],
                accountName: Text(
                  _user.firstName!,
                  style: const TextStyle(fontSize: 24),
                ),
                accountEmail: const Text(
                  "ゲストログイン",
                  style: TextStyle(fontSize: 12),
                ),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 0, 194, 65),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
            ),
            Expanded(
              child: buildUserList(),
            ),
            const SizedBox(
              height: 8,
            ),
            TextButton(
              onPressed: () => {
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.WARNING,
                  headerAnimationLoop: false,
                  animType: AnimType.TOPSLIDE,
                  closeIcon: const Icon(Icons.close_fullscreen_outlined),
                  desc: 'ルームから退出しますか？',
                  btnCancelOnPress: () {},
                  btnOkOnPress: () {
                    final _uid = FirebaseAuth.instance.currentUser?.uid;
                    _onExitRoom(context, widget.roomId, _uid!);
                  },
                ).show()
              },
              child: const Text(
                "ルームから退出する",
                style: TextStyle(color: Colors.red),
              ),
              style: TextButton.styleFrom(
                primary: Colors.white,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("chat_room")
            .doc(widget.roomId)
            .collection("contents")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }
          return Chat(
            theme: const DefaultChatTheme(
              // メッセージ入力欄の色
              inputBackgroundColor: Color.fromARGB(255, 0, 194, 65),
              // 送信ボタン
              sendButtonIcon: Icon(Icons.send),
              sendingIcon: Icon(Icons.update_outlined),
            ),
            // ユーザーの名前を表示するかどうか
            showUserNames: true,
            // メッセージの配列
            messages: snapshot.data!.docs
                .map(
                  (d) => types.TextMessage(
                      author: types.User(id: d['uid'], firstName: d['name']),
                      createdAt: d['createdAt'],
                      id: d['id'],
                      text: d['text']),
                )
                .toList(),
            onPreviewDataFetched: _handlePreviewDataFetched,
            onSendPressed: _handleSendPressed,
            user: _user,
          );
        },
      ),
    );
  }

  Widget buildUserList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("chat_room")
          .doc(widget.roomId)
          .collection("users")
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }
        return ListView(
          children: snapshot.data!.docs.map(
            (DocumentSnapshot document) {
              final _data = document.data()! as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage("assets/default_icon.png"),
                ),
                title: Text(_data["name"].toString()),
              );
            },
          ).toList(),
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({required this.roomId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

_onExitRoom(BuildContext context, String roomId, String uid) {
  FirebaseFirestore.instance
      .collection('chat_room')
      .doc(roomId)
      .collection("users")
      .doc(uid)
      .delete();
  Routemaster.of(context).replace("/room");
}
