import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_privacy_policy/flutter_privacy_policy.dart';
import 'package:flutter_privacy_policy/models/Message.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ListsModel()),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Conversational Privacy Policy Builder'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  downloadFile(String fileName, String data) {
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    var content = stringToBase64.encode(data);
    var anchor = AnchorElement(
        href: "data:application/octet-stream;charset=utf-16le;base64,$content")
      ..setAttribute("download", fileName)
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    var mainWidgets = [
      Padding(
        padding: EdgeInsets.all(16),
      ),
      Consumer<ListsModel>(
        builder: (context, model, child) {
          return Visibility(
            visible:
                (model.greetingList.isNotEmpty || model.policyList.isNotEmpty),
            child: RaisedButton(
              child: Text("Preview"),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => PrivacyPolicyWidget(() {
                          Navigator.of(context).pop();
                        },
                            greetingMessages: model.greetingList.isNotEmpty
                                ? json.encode(model.greetingList.reversed.toList())
                                : null,
                            policyMessages: model.policyList.isNotEmpty
                                ? json.encode(model.policyList.reversed.toList())
                                : null));
              },
            ),
          );
        },
      ),
      Consumer<ListsModel>(
        builder: (context, model, child) {
          return Visibility(
            visible:
                (model.greetingList.isNotEmpty || model.policyList.isNotEmpty),
            child: RaisedButton(
              child: Text("Download Files"),
              onPressed: () {
                if (model.greetingList.isNotEmpty) {
                  downloadFile(
                      "greetingMessages_${DateTime.now().toLocal()}.json",
                      json.encode(model.greetingList.reversed
                          .map((e) => CompactMessage(e.from ?? "", e.text ?? ""))
                          .toList()));
                }

                if (model.policyList.isNotEmpty)
                  downloadFile(
                      "policyMessages_${DateTime.now().toLocal()}.json",
                      json.encode(model.policyList.reversed
                          .map((e) => CompactMessage(e.from ?? "", e.text ?? ""))
                          .toList()));
              },
            ),
          );
        },
      )
    ];
    mainWidgets.insert(
        0,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
            ),
            Expanded(
              child: EditorWidget("Greeting Messages"),
            ),
            Padding(
              padding: EdgeInsets.all(16),
            ),
            Expanded(
              child: EditorWidget("Policy Messages"),
            ),
            Padding(
              padding: EdgeInsets.all(16),
            ),
          ],
        ));
    mainWidgets.insert(
        0,
        Padding(
          padding: EdgeInsets.all(16),
        ));
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title ?? ""),
        ),
        body: Center(
            child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: mainWidgets,
          ),
        )));
  }
}

class EditorWidget extends StatefulWidget {
  final String name;

  EditorWidget(this.name);

  @override
  _EditorWidgetState createState() => _EditorWidgetState(name);
}

class _EditorWidgetState extends State<EditorWidget> {
  final String name;
  String messageSide = "start";
  TextEditingController textController = TextEditingController();

  _EditorWidgetState(this.name);

  @override
  Widget build(BuildContext context) {
    var listsModel = Provider.of<ListsModel>(context, listen: false);
    getEditor(String name) {
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(name),
            RaisedButton(
              child: Text("Clear"),
              onPressed: () {
                setState(() {
                  if (name.startsWith("Greeting")) {
                    listsModel.clearGreeting();
                  } else {
                    listsModel.clearPolicy();
                  }
                });
              },
            )
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.lightBlueAccent.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          height: MediaQuery.of(context).size.height / 4,
          child: ListView.builder(
            reverse: true,
            itemCount: name.startsWith("Greeting")
                ? listsModel.greetingList.length
                : listsModel.policyList.length,
            itemBuilder: (context, i) {
              var list = name.startsWith("Greeting")
                  ? listsModel.greetingList
                  : listsModel.policyList;
              return Align(
                alignment: list[i].isStart()
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Wrap(
                  children: [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(list[i].text ?? ""),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: messageSide,
              icon: Icon(Icons.arrow_downward),
              iconSize: 26,
              elevation: 16,
              underline: Container(
                height: 2,
                color: Colors.blueAccent,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  messageSide = newValue ?? "";
                });
              },
              items: <String>['start', 'end']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            Padding(
              padding: EdgeInsets.all(8),
            ),
            SizedBox(
                width: MediaQuery.of(context).size.width / 5,
                child: TextFormField(
                  maxLines: 5,
                  controller: textController,
                  decoration: InputDecoration(hintText: "Enter message"),
                  onChanged: (v) {},
                )),
            Padding(
              padding: EdgeInsets.all(8),
            ),
            RaisedButton(
              child: Text("Add"),
              onPressed: () {
                var text = textController.text;
                if (text.isNotEmpty) {
                  setState(() {
                    textController.clear();
                    var message = Message(messageSide, text);
                    message.text = text;
                    message.time = null;
                    name.startsWith("Greeting")
                        ? listsModel.addGreeting(message)
                        : listsModel.addPolicy(message);
                  });
                }
              },
            )
          ],
        )
      ];
    }

    return Container(
      child: Column(
        children: getEditor(name),
      ),
    );
  }
}

class CompactMessage {
  String from;
  String text;

  CompactMessage(this.from, this.text);


  CompactMessage.fromJson(Map<String, dynamic> json)
      : from = json['from'],
        text = json['text'];

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'text': text,
    };
  }
}

class ListsModel with ChangeNotifier {
  List<Message> greetingList = [];
  List<Message> policyList = [];

  clearGreeting() {
    greetingList.clear();
    notifyListeners();
  }

  clearPolicy() {
    policyList.clear();
    notifyListeners();
  }

  addGreeting(Message message) {
    greetingList.insert(0, message);
    notifyListeners();
  }

  addPolicy(Message message) {
    policyList.insert(0, message);
    notifyListeners();
  }
}
