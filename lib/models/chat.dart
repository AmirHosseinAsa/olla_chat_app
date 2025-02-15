import 'dart:convert';
import 'package:objectbox/objectbox.dart';

@Entity()
class Chat {
  @Id()
  int id;
  String message;
  bool isUserMessage;

  @Property(type: PropertyType.date)
  DateTime timestamp;

  bool isEdited;
  String? originalMessage;

  @Property()
  String attachedFilesPathJson = '[]';

  List<String> get attachedFilesPath =>
      List<String>.from(jsonDecode(attachedFilesPathJson));

  set attachedFilesPath(List<String> value) {
    attachedFilesPathJson = jsonEncode(value);
  }

  final chatSession = ToOne<ChatSession>();

  Chat({
    this.id = 0,
    required this.message,
    required this.isUserMessage,
    required this.timestamp,
    this.isEdited = false,
    this.originalMessage,
    List<String> attachedFilesPath = const [],
  }) {
    this.attachedFilesPath = attachedFilesPath;
  }
}

@Entity()
class ChatSession {
  @Id()
  int id;
  String modelName;
  String title;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime lastUpdatedAt;

  @Backlink('chatSession')
  final chats = ToMany<Chat>();

  ChatSession({
    this.id = 0,
    required this.modelName,
    this.title = 'New Chat',
    required this.createdAt,
    DateTime? lastUpdatedAt,
  }) : lastUpdatedAt = lastUpdatedAt ?? createdAt;
}
