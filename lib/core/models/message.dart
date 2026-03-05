import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un mensaje dentro de un chat.
class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;

  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: (data['senderId'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: (data['read'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }

  Message copyWith({bool? read}) {
    return Message(
      id: id,
      senderId: senderId,
      text: text,
      timestamp: timestamp,
      read: read ?? this.read,
    );
  }
}
