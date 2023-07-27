import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:letschat/components/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:letschat/components/colors.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final _firestore = FirebaseFirestore.instance;
User? loggedInuser;
final focusNode = FocusNode();
bool isToxicMessage = false;

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String messageText = '';
  final controller = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool isEmojiVisible = false;
  bool isKeyboardVisible = false;
  //var messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardVisibilityController.onChange.listen((bool isKeyboardVisible) {
      setState(() {
        this.isKeyboardVisible = isKeyboardVisible;
      });

      if (isKeyboardVisible && isEmojiVisible) {
        setState(() {
          isEmojiVisible = false;
        });
      }
    });
  }

  Future toggleEmojiKeyboard() async {
    if (isKeyboardVisible) {
      FocusScope.of(context).unfocus();
    }
    setState(() {
      isEmojiVisible = !isEmojiVisible;
    });
  }

  Future<bool> onBackPress() {
    if (isEmojiVisible) {
      toggleEmojiKeyboard();
    } else {
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  void dispose() async {
    super.dispose();
    await _auth.signOut();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInuser = user;
        print(loggedInuser);
      }
    } catch (e) {
      print(e);
    }
  }

  void onEmojiSelected(String emoji) => setState(() {
        controller.text = controller.text + emoji;
        messageText += emoji;
      });

  @override
  Widget build(BuildContext context) {
    Widget buildSticker() {
      return Expanded(child: EmojiPicker(
        onEmojiSelected: (emoji, category) {
          onEmojiSelected(category.emoji);
        },
      ));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('Messages'),
        backgroundColor: PalletteColors.primaryRed,
      ),
      body: SafeArea(
        child: WillPopScope(
          onWillPop: onBackPress,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MessagesStream(),
              Container(
                width: double.infinity,
                height: 50.0,
                decoration: new BoxDecoration(
                    border: new Border(
                        top:
                            new BorderSide(color: Colors.blueGrey, width: 0.5)),
                    color: Colors.white),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Material(
                      child: new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 1.0),
                        child: new IconButton(
                          icon: new Icon(isEmojiVisible
                              ? Icons.keyboard_rounded
                              : Icons.emoji_emotions),
                          onPressed: onClickedEmoji,
                          color: Colors.blueGrey,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    Flexible(
                      child: Container(
                        child: TextField(
                          textInputAction: TextInputAction.send,
                          keyboardType: TextInputType.multiline,
                          focusNode: focusNode,
                          onSubmitted: (value) async {
                            bool isToxicMessage = await isToxic(messageText);
                            if (!isToxicMessage) {
                              // Message is not toxic, add it to the 'messages' collection.

                              _firestore.collection('messages').add({
                                'sender': loggedInuser!.email,
                                'text': messageText,
                                'timestamp': Timestamp.now(),
                                'is_toxic':
                                    false, // Set 'is_toxic' to false for non-toxic messages.
                              });
                            } else {
                              // Message is toxic, add it to the 'messages' collection with 'is_toxic' set to true.
                              _firestore.collection('messages').add({
                                'sender': loggedInuser!.email,
                                'text': messageText,
                                'timestamp': Timestamp.now(),
                                'is_toxic':
                                    true, // Set 'is_toxic' to true for toxic messages.
                              });
                            }
                            controller.clear();
                            setState(() {
                              messageText = '';
                            });
                          },
                          maxLines: null,
                          controller: controller,
                          onChanged: (value) {
                            messageText = value;
                          },
                          style:
                              TextStyle(color: Colors.blueGrey, fontSize: 15.0),
                          decoration: kMessageTextFieldDecoration,
                        ),
                      ),
                    ),
                    Material(
                      child: new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 8.0),
                        child: new IconButton(
                          icon: new Icon(Icons.send),
                          onPressed: () async {
                            bool isToxicMessage = await isToxic(messageText);
                            if (!isToxicMessage) {
                              // Message is not toxic, add it to the 'messages' collection.

                              _firestore.collection('messages').add({
                                'sender': loggedInuser!.email,
                                'text': messageText,
                                'timestamp': Timestamp.now(),
                                'is_toxic':
                                    false, // Set 'is_toxic' to false for non-toxic messages.
                              });
                            } else {
                              // Message is toxic, add it to the 'messages' collection with 'is_toxic' set to true.
                              _firestore.collection('messages').add({
                                'sender': loggedInuser!.email,
                                'text': messageText,
                                'timestamp': Timestamp.now(),
                                'is_toxic':
                                    true, // Set 'is_toxic' to true for toxic messages.
                              });
                            }
                            controller.clear();
                            setState(() {
                              messageText = '';
                            });
                          },
                          color: Colors.blueGrey,
                        ),
                      ),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              (isEmojiVisible ? buildSticker() : Container()),
            ],
          ),
        ),
      ),
    );
  }

  void onClickedEmoji() async {
    if (isEmojiVisible) {
      // Emoji picker is visible, so we want to hide it.
      setState(() {
        isEmojiVisible = false;
      });
    } else {
      // Emoji picker is not visible, so we want to show it.
      // Make sure to hide the keyboard before showing the emoji picker.
      FocusScope.of(context).unfocus();

      setState(() {
        isEmojiVisible = true;
      });
    }
  }
}

String giveUsername(String email) {
  return email.replaceAll(new RegExp(r'@g(oogle)?mail\.com$'), '');
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('messages')
          // Sort the messages by timestamp DESC because we want the newest messages on bottom.
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // If we do not have data yet, show a progress indicator.
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        // Create the list of message widgets.

        // final messages = snapshot.data.documents.reversed;

        List<Widget> messageWidgets = snapshot.data!.docs.map<Widget>((m) {
          final data = m.data as dynamic;
          final messageText = data()['text'];
          final messageSender = data()['sender'];
          final currentUser = loggedInuser!.email;
          final timeStamp = data()['timestamp'];
          final isToxicMessage = data()['is_toxic'];
          return MessageBubble(
            sender: messageSender,
            text: messageText,
            timestamp: timeStamp,
            isMe: currentUser == messageSender,
            isToxicMessage: isToxicMessage,
          );
        }).toList();

        return Expanded(
          child: ListView(
            shrinkWrap: true,
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageWidgets,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble(
      {this.sender,
      this.text,
      this.timestamp,
      this.isMe,
      this.isToxicMessage = false});
  final String? sender;
  final String? text;
  final Timestamp? timestamp;
  final bool? isMe;
  final bool? isToxicMessage;

  @override
  Widget build(BuildContext context) {
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp!.seconds * 1000);
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe! ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "${giveUsername(sender!)}",
            style: TextStyle(fontSize: 12.0, color: Colors.black54),
          ),
          Material(
            borderRadius: isMe!
                ? BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    topLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  )
                : BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
            elevation: 5.0,
            color:
                isMe! ? PalletteColors.primaryGrey : PalletteColors.lightBlue,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
              child: Column(
                crossAxisAlignment:
                    isMe! ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text!,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: isMe! ? Colors.white : Colors.black54,
                    ),
                  ),
                  if (isToxicMessage == true)
                    Image.asset('images/Warning.png', height: 50, width: 50),
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      "${DateFormat('h:mm a').format(dateTime)}",
                      style: TextStyle(
                        fontSize: 9.0,
                        color: isMe!
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black54.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> isToxic(String message) async {
  final perspectiveUrl =
      'https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key=AIzaSyC6RPPVmZ3Bdnfo7IYAXc9JsbnG8U5rzOs';

  final Map<String, dynamic> body = {
    'comment': {'text': message},
    'languages': ['en'],
    'requestedAttributes': {'TOXICITY': {}},
  };

  final response = await http.post(Uri.parse(perspectiveUrl),
      headers: {'Content-Type': 'application/json'}, body: json.encode(body));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final toxicityScore =
        data['attributeScores']['TOXICITY']['summaryScore']['value'];

    // print('Toxicity Score: $toxicityScore'); // Add this debug statement

    // Set the toxicity threshold as per your requirement
    return toxicityScore >= 0.5;
  } else {
    throw Exception('Failed to analyze message');
  }
}
