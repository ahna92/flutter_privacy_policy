import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Message.g.dart';

const MESSAGE_START = "start";
const MESSAGE_END = "end";

@JsonSerializable(nullable: false)
class Message {
  final String? from;
  String? text;
  int? time;
  int? readTimeSeconds = 0;

  Message(this.from, this.text, {this.time, this.readTimeSeconds}) {
    this.time = DateTime.now().millisecondsSinceEpoch;
    if (this.readTimeSeconds == null) this.readTimeSeconds = getTotalReadTime();
    this.text = "<p style='text-align: justify;'>${this.text}</p>";
  }

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  bool isStart() {
    return from == MESSAGE_START;
  }

  bool isEnd() {
    return from == MESSAGE_END;
  }

  int getTotalReadTime() {
    var wordCount = this.text!.split(" ").length;
    var minAndSec = (wordCount / 200.0).toStringAsFixed(2);
    var minutes = int.parse(minAndSec.split(".")[0]);
    var seconds =
        ((double.parse("0.${minAndSec.split(".")[1]}") * 0.60) * 100).toInt();
//    print("**************************");
//    print(this.text);
//    print(wordCount);
//    print(minAndSec);
//    print(minutes);
//    print(seconds);
//    print(seconds.toInt() + (minutes * 60));
//    print("**************************");
    return seconds.toInt() + (minutes * 60);
  }

  String getHourMinute() {
    return DateFormat.Hm()
        .format(DateTime.fromMicrosecondsSinceEpoch(time!).toLocal());
  }
}

List<Message> fromJsonToMessageList(List<dynamic> json) =>
    json.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
