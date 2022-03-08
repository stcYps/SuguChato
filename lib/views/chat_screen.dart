import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:routemaster/routemaster.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({required this.roomId, Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final textController = TextEditingController();
  types.User _user = const types.User(id: "", firstName: "");

  // List<types.Message> _messages = [];

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

  void _onExitRoom(BuildContext context, String roomId, String uid) async {
    FirebaseFirestore.instance
        .collection('chat_room')
        .doc(roomId)
        .collection("users")
        .doc(uid)
        .delete();

    final doc = await FirebaseFirestore.instance
        .collection("chat_room")
        .doc(roomId)
        .collection("users")
        .get();
    if (doc.docs.isEmpty) {
      FirebaseFirestore.instance
          .collection('chat_room')
          .doc(roomId)
          .collection("contents")
          .get()
          .then(
        (snapshot) {
          for (DocumentSnapshot ds in snapshot.docs) {
            ds.reference.delete();
          }
        },
      );
      FirebaseFirestore.instance.collection('chat_room').doc(roomId).delete();
    }
    Routemaster.of(context).replace("/room");
  }

  // メッセージ内容をfirestoreにセット
  void _addMessage(types.TextMessage message) async {
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
            UserAccountsDrawerHeader(
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
            Expanded(
              child: buildUserList(),
            ),
            const SizedBox(
              height: 8,
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
            customBottomWidget: buildChatForm(),
            l10n: const ChatL10nEn(
              emptyChatPlaceholder: "まだメッセージがありません",
            ),
            showUserNames: true,
            messages: snapshot.data!.docs
                .map(
                  (d) => types.TextMessage(
                      author: types.User(id: d['uid'], firstName: d['name']),
                      createdAt: d['createdAt'],
                      id: d['id'],
                      text: d['text']),
                )
                .toList(),
            onSendPressed: _handleSendPressed,
            user: _user,
          );
        },
      ),
    );
  }

  Widget buildChatForm() {
    return TextField(
      controller: textController,
      keyboardType: TextInputType.multiline,
      minLines: 1,
      maxLines: 5,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        fillColor: const Color.fromARGB(255, 0, 194, 65),
        filled: true,
        hintText: "メッセージを入力",
        hintStyle: const TextStyle(color: Colors.white70),
        hoverColor: const Color.fromARGB(255, 0, 194, 65),
        isCollapsed: true,
        suffixIcon: IconButton(
          onPressed: () {
            if (textController.text == "") {
              return;
            }
            _handleSendPressed(
              types.PartialText(text: textController.text.trim()),
            );
            textController.text = "";
          },
          icon: const Icon(
            Icons.send,
            color: Colors.black,
          ),
        ),
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
