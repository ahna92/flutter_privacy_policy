import 'package:flutter/material.dart';
import 'package:flutter_privacy_policy/flutter_privacy_policy.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var allow = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example conversational',
      home: Scaffold(
        appBar: AppBar(
          title: Text("Conversatinal Privacy Policy"),
        ),
        body: Center(
            child: allow
                ? Text("Start your app :D !")
                : PrivacyPolicyWidget(() {
                    setState(() {
                      allow = true;
                    });
                  })),
      ),
    );
  }
}
