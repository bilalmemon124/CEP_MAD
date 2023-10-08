import 'dart:convert';

class Message {
  String? text;

  MessageStatus? status;
  MessageType? type;

  Message(this.text, {this.status, this.type = MessageType.regular});

  Message.initial(this.text, {this.status, this.type = MessageType.initial});
  Message.disconnect(this.text,
      {this.status, this.type = MessageType.disconnect});
  Message.file(this.text, {this.status, this.type = MessageType.file});

  Message.fromJson(dynamic map) {
    text = map['text'] ?? '';
    type = MessageType.values[map['type'] as int];

    status = MessageStatus.recieved;
  }

  Message.fromString(String data) {
    dynamic map = json.decode(data);

    text = map['text'] ?? '';
    type = MessageType.values[map['type'] as int];

    status = MessageStatus.recieved;
  }

  dynamic toJson() {
    return {
      'text': text,
      'type': type!.index,
    };
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}

enum MessageType {
  initial,
  regular,
  disconnect,
  file,
}

enum MessageStatus {
  sent,
  recieved,
}
