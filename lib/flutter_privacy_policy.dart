library flutter_privacy_policy;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/rich_text_parser.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:provider/provider.dart';

import 'models/Message.dart';
import 'package:flutter/services.dart' show rootBundle;

const String defaultFriendName = "Privacy Helper";
const String defaultAllowText = "Allow";
const String defaultContinueText = "Continue";
const String defaultSkipText = "Skip";

enum Steps { GREETING, CHOICE_GREETING, POLICY, CHOICE_POLICY }

class PrivacyPolicyWidget extends StatelessWidget {
  final String friendName;
  final String allowText;
  final String continueText;
  final String skipText;
  final String greetingMessages;
  final String policyMessages;
  final VoidCallback allowCallBack;
  final Color color;
  final OnLinkTap onLinkTap;

  PrivacyPolicyWidget(this.allowCallBack,
      {Key key,
      this.friendName,
      this.continueText,
      this.allowText,
      this.skipText,
      this.greetingMessages,
      this.policyMessages,
      this.color = Colors.lightBlueAccent,
      this.onLinkTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MessagesModel()),
        ChangeNotifierProvider(create: (context) => ItemsVisibleModel()),
      ],
      child: _PrivacyPolicyWidget(
          this.allowCallBack,
          friendName ?? defaultFriendName,
          continueText ?? defaultContinueText,
          allowText ?? defaultAllowText,
          skipText ?? defaultSkipText,
          greetingMessages,
          policyMessages,
          color,
          onLinkTap),
    );
  }
}

class _PrivacyPolicyWidget extends StatefulWidget {
  final String friendName;
  final String allowText;
  final String continueText;
  final String skipText;
  final String greetingMessages;
  final String policyMessages;
  final VoidCallback allowCallBack;
  final Color color;
  final OnLinkTap onLinkTap;

  _PrivacyPolicyWidget(
      this.allowCallBack,
      this.friendName,
      this.continueText,
      this.allowText,
      this.skipText,
      this.greetingMessages,
      this.policyMessages,
      this.color,
      this.onLinkTap,
      {Key key})
      : super(key: key);

  @override
  _PrivacyPolicyWidgetState createState() => _PrivacyPolicyWidgetState(
      this.allowCallBack,
      friendName ?? defaultFriendName,
      continueText ?? defaultContinueText,
      allowText ?? defaultAllowText,
      skipText ?? defaultSkipText,
      greetingMessages,
      policyMessages,
      color,
      onLinkTap);
}

class _PrivacyPolicyWidgetState extends State<_PrivacyPolicyWidget> {
  final VoidCallback allowCallBack;
  Color color;
  var _friendName;
  var _allowText;
  var _continueText;
  var _skipText;
  var _greetingMessagesJson = "";
  var _policyMessagesJson = "";
  var _steps = Steps.GREETING;
  OnLinkTap _onLinkTap;
  List<Message> _policyMessages;
  List<Message> _greetingMessages;
  var currentReadSeconds = 0;
  var totalReadSeconds = 0;
  ScrollController _scrollController;
  double scrollProgress = 0.0;
  bool pausePostPolicy = false;

  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  VoidCallback _listener = () {};

  _PrivacyPolicyWidgetState(
      this.allowCallBack,
      this._friendName,
      this._continueText,
      this._allowText,
      this._skipText,
      this._greetingMessagesJson,
      this._policyMessagesJson,
      this.color,
      this._onLinkTap);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (pausePostPolicy && _scrollController.offset == 0) {
        pausePostPolicy = false;
        postPolicyMessages(_policyMessages,
            Provider.of<MessagesModel>(context, listen: false));
      }
    });

    loadMessages("en").then((value) {
      postGreetingMessages(_greetingMessages,
          Provider.of<MessagesModel>(context, listen: false));
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadMessages(String local) async {
    if (_greetingMessagesJson != null && _greetingMessagesJson.isNotEmpty) {
      _greetingMessages =
          fromJsonToMessageList(json.decode(_greetingMessagesJson));
    } else {
      String jsonString = await rootBundle.loadString(
          'packages/flutter_privacy_policy/assets/i18n/default_conversation_greeting_$local.json');
      _greetingMessages = fromJsonToMessageList(json.decode(jsonString));
    }
    if (_policyMessagesJson != null && _policyMessagesJson.isNotEmpty) {
      List<Message> conversation =
          fromJsonToMessageList(json.decode(_policyMessagesJson));
      _policyMessages = conversation;
    } else {
      String jsonString = await rootBundle.loadString(
          'packages/flutter_privacy_policy/assets/i18n/default_conversation_policy_$local.json');
      _policyMessages = fromJsonToMessageList(json.decode(jsonString));
    }

    _greetingMessages.forEach((element) {
      totalReadSeconds += element.readTimeSeconds;
    });
    _policyMessages.forEach((element) {
      totalReadSeconds += element.readTimeSeconds;
    });
    currentReadSeconds = totalReadSeconds;
  }

  void postGreetingMessages(
      List<Message> greetingMessages, MessagesModel messagesModel) {
    Timer(Duration(seconds: 1), () {
      if (greetingMessages.length > 0) {
        messagesModel.add(greetingMessages.first);
        greetingMessages.removeAt(0);
        if (greetingMessages.length > 0) {
          postGreetingMessages(greetingMessages, messagesModel);
        } else {
          setState(() {
            _steps = Steps.CHOICE_GREETING;
          });
        }
      }
    });
  }

  void postPolicyMessages(
      List<Message> policyMessages, MessagesModel messagesModel) {
    Timer(Duration(seconds: 1), () {
      if (_steps == Steps.POLICY) {
        if (_scrollController.offset != 0) {
          pausePostPolicy = true;
          return;
        }

        if (policyMessages.length > 0) {
          messagesModel.add(policyMessages.first);
          policyMessages.removeAt(0);
          postPolicyMessages(policyMessages, messagesModel);
        } else {
          setState(() {
            _steps = Steps.CHOICE_POLICY;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var messagesModel = Provider.of<MessagesModel>(context, listen: false);
    var itemsVisibleModel =
        Provider.of<ItemsVisibleModel>(context, listen: false);

//    void postMessage(
//        {Message message, List<Message> messages, VoidCallback afterPost}) {
//      if (message == null && messages == null) return;
//      setState(() {
//        var milliseconds = 100;
//        if (message != null) {
//          _messages.add(message);
//          milliseconds = 50;
//        } else if (messages != null) {
//          _messages.addAll(messages);
//          milliseconds = 100;
//        }
//        Timer(Duration(milliseconds: milliseconds), () {
//          _scrollController.scrollTo(
//              index: _messages.length - 1,
//              curve: Curves.easeOut,
//              duration: Duration(seconds: 1));
//          afterPost?.call();
//        });
//      });
//    }
    void handleAllow() {
      itemPositionsListener.itemPositions.removeListener(_listener);
      setState(() {
        _steps = Steps.GREETING;
        messagesModel.add(Message(MESSAGE_END, _allowText));
        Timer(Duration(milliseconds: 300), () {
          messagesModel.add(Message(MESSAGE_START, "Great! enjoy the app!"));
          Timer(Duration(milliseconds: 1500), () {
            allowCallBack.call();
          });
        });
      });
    }

    void handleContinue() {
      //itemPositionsListener.itemPositions.addListener(_listener);
      setState(() {
        _steps = Steps.POLICY;
        messagesModel.add(Message(MESSAGE_END, _continueText));
        Timer(Duration(milliseconds: 50), () {
          postPolicyMessages(_policyMessages, messagesModel);
        });
      });
    }

    void handleSkip() {
      setState(() {
        _steps = Steps.CHOICE_POLICY;
        if (_policyMessages != null && _policyMessages.isNotEmpty) {
          messagesModel.addAll(_policyMessages);
          _policyMessages.clear();
        }
      });
    }

    var gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.3),
        color.withOpacity(0.4),
        color.withOpacity(0.3),
      ],
    );

    Widget getChatOptionBox(String text, VoidCallback onPressed) {
      return Expanded(
        flex: 8,
        child: RaisedButton(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(16.0),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 17),
          ),
        ),
      );
    }

    var chatBoxChildren = <Widget>[
      Padding(
        padding: EdgeInsets.only(right: 16),
        child: Card(
            color: color,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              height: 48,
              width: 48,
              child: InkWell(
                onTap: () => {},
                child: Ink(
                  color: color,
                  child: Transform.rotate(
                    angle: -45 * pi / 180,
                    child: Transform.translate(
                      offset: const Offset(4, 0),
                      child: Icon(
                        Icons.send,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )),
      ),
    ];

    switch (_steps) {
      case Steps.CHOICE_GREETING:
        chatBoxChildren.insert(
            0,
            Spacer(
              flex: 1,
            ));
        chatBoxChildren.insert(
            1, getChatOptionBox(_continueText, () => {handleContinue()}));
        chatBoxChildren.insert(
            2,
            Spacer(
              flex: 1,
            ));
        chatBoxChildren.insert(
            3, getChatOptionBox(_allowText, () => {handleAllow()}));
        chatBoxChildren.insert(
          4,
          Spacer(
            flex: 2,
          ),
        );
        break;
      case Steps.POLICY:
        chatBoxChildren.insert(
            0,
            Spacer(
              flex: 1,
            ));
        chatBoxChildren.insert(
            1, getChatOptionBox(_skipText, () => {handleSkip()}));
        chatBoxChildren.insert(
          2,
          Spacer(
            flex: 1,
          ),
        );
        break;
      case Steps.CHOICE_POLICY:
        chatBoxChildren.insert(
            0,
            Spacer(
              flex: 1,
            ));
        chatBoxChildren.insert(
            1, getChatOptionBox(_allowText, () => {handleAllow()}));
        chatBoxChildren.insert(
          2,
          Spacer(
            flex: 1,
          ),
        );
        break;
      default:
        chatBoxChildren.insert(
            0,
            Text(
              "Write Message",
              style: TextStyle(
                  color: Colors.white, fontSize: 16),
            ));
        chatBoxChildren.insert(1, Spacer());
    }

    return Material(color: Colors.white,child: Container(
        decoration: BoxDecoration(
            gradient: RadialGradient(
                focal: Alignment.center,
                radius: 2,
                colors: [color.withOpacity(0.4), Colors.transparent])),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.zero, bottom: Radius.circular(32))),
                      child: Container(
                          decoration: BoxDecoration(gradient: gradient),
                          height: 96,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  )),
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  _friendName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 18),
                                ),
                              ),
                              Spacer(),
                              if (totalReadSeconds > 0)
                                Consumer<ItemsVisibleModel>(builder:
                                    (context, scrollNotificationModel, child) {
                                  if (messagesModel.items.isNotEmpty) {
//                                    print(scrollNotificationModel
//                                        .visibleItemIndex);
                                    var newIndex = messagesModel.items.length -
                                        1 -
                                        scrollNotificationModel
                                            .visibleItemIndex;

                                    var seconds = 0;
                                    _policyMessages.forEach((element) {
                                      seconds += element.readTimeSeconds;
                                    });
                                    var list = messagesModel.items;
                                    list
                                        .sublist(newIndex, list.length - 1)
                                        .forEach((element) {
                                      seconds += element.readTimeSeconds;
                                    });
                                    currentReadSeconds = seconds;
                                  }

                                  return Text(
                                    "${max(1, currentReadSeconds ~/ 60)} \n minutes read",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white),
                                  );
                                }),
                              Spacer(),
                              Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircleAvatar(
                                    radius: 32.0,
                                    backgroundImage: AssetImage(
                                        "packages/flutter_privacy_policy/assets/images/man.jpg"),
                                  )),
                            ],
                          ))),
                )
              ],
            ),
            Visibility(
              visible:
              _steps != Steps.GREETING && _steps != Steps.CHOICE_GREETING,
              child: Consumer<ItemsVisibleModel>(
                  builder: (context, scrollNotificationModel, child) {
                    switch (_steps) {
                      case Steps.POLICY:
                        scrollProgress = max(scrollProgress,
                            1 - (currentReadSeconds / totalReadSeconds));
                        break;
                      default:
                        if (_scrollController.position.maxScrollExtent > 0) {
                          scrollProgress = 1 -
                              (_scrollController.offset /
                                  _scrollController.position.maxScrollExtent);
                        }
                        break;
                    }

                    return LinearProgressIndicator(
                      value: scrollProgress,
                    );
                  }),
            ),
            Expanded(
                flex: 5,
                child: Consumer<MessagesModel>(
                  builder: (context, messageModel, child) {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
//                        scrollNotificationModel
//                            .setScrollNotification(scrollNotification);
                        return false;
                      },
                      child: Scrollbar(
                        controller: _scrollController,
                        isAlwaysShown: true,
                        child: ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.only(left: 16, right: 16),
                            itemCount: messageModel.items.length,
//                        itemScrollController: _scrollController,
//                        itemPositionsListener: itemPositionsListener,
//                        initialScrollIndex: messageModel.initialScrollPosition,
//                        initialAlignment:
//                        messageModel.initialScrollPosition == 0
//                            ? 0
//                            : -50,
                            controller: _scrollController,
                            physics: BouncingScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              if (index >= messageModel.items.length)
                                return null;
                              var message = messageModel.items[index];

                              var children = [
                                Flexible(
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                              focal: Alignment.center,
                                              radius: 0.6,
                                              colors: message.isStart()
                                                  ? [
                                                color.withOpacity(0.7),
                                                color.withOpacity(0.6)
                                              ]
                                                  : [
                                                color.withOpacity(0.9),
                                                color
                                              ])),
                                      padding:
                                      EdgeInsets.only(left: 16, right: 16),
                                      child: Html(
                                        shrinkToFit: true,
                                        data: message.text,
                                        onLinkTap: _onLinkTap ?? (url) {},
                                        defaultTextStyle: TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: message.isStart()
                                      ? EdgeInsets.only(bottom: 8, right: 48)
                                      : EdgeInsets.only(bottom: 8, left: 48),
                                  child: Text(
                                    message.getHourMinute(),
                                    style: TextStyle(color: Colors.white,fontSize: 13),
                                  ),
                                )
                              ];
                              if (message.isEnd()) {
                                children = children.reversed.toList();
                              }
                              return VisibilityDetector(
                                  key: Key("$index"),
                                  onVisibilityChanged: (VisibilityInfo info) {
                                    if (info.visibleFraction > 0.5)
                                      itemsVisibleModel.setVisibleItem(index);
                                  },
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: message.isStart()
                                        ? MainAxisAlignment.start
                                        : MainAxisAlignment.end,
                                    children: children,
                                  ));
                            }),
                      ),
                    );
                  },
                )),
            Expanded(
                flex: 1,
                child: Padding(
                  padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      child: Container(
                          padding: EdgeInsets.only(left: 16),
                          decoration: BoxDecoration(
                            gradient: gradient,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: chatBoxChildren,
                          ))),
                )),
          ],
        )),);
  }
}

class ItemsVisibleModel with ChangeNotifier {
  ScrollNotification scrollNotification;
  var visibleItemIndex = 0;

  setVisibleItem(int index) {
    visibleItemIndex = index;
    notifyListeners();
  }

  setScrollNotification(ScrollNotification scrollNotification) {
    this.scrollNotification = scrollNotification;
    notifyListeners();
  }
}

class MessagesModel with ChangeNotifier {
  final List<Message> _items = [];

  int initialScrollPosition = 0;

  /// An unmodifiable view of the items
  UnmodifiableListView<Message> get items => UnmodifiableListView(_items);

  /// Adds [item] to cart. This and [removeAll] are the only ways to modify the
  /// cart from the outside.
  void add(Message item, {bool scrollTo = false}) {
    _items.insert(0, item);
    // This call tells the widgets that are listening to this model to rebuild.
    if (scrollTo) {
      initialScrollPosition = _items.length - 1;
    }
    notifyListeners();
  }

  /// Adds [item] to cart. This and [removeAll] are the only ways to modify the
  /// cart from the outside.
  void addAll(List<Message> list, {bool scrollTo = false}) {
    _items.insertAll(0, list.reversed);
    // This call tells the widgets that are listening to this model to rebuild.
    if (scrollTo) {
      initialScrollPosition = _items.length - 1;
    }
    notifyListeners();
  }

  /// Removes all items from the cart.
  void removeAll() {
    _items.clear();
    // This call tells the widgets that are listening to this model to rebuild.
    notifyListeners();
  }
}

class MyScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
