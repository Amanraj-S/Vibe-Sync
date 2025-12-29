class Message {
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      senderId: json['sender'],
      receiverId: json['receiver'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}