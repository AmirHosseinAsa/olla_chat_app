import 'package:objectbox/objectbox.dart';
import '../models/chat.dart';
import '../objectbox.g.dart';

class DatabaseService {
  final Store store;
  late final Box<Chat> chatBox;
  late final Box<ChatSession> sessionBox;

  DatabaseService(this.store) {
    chatBox = Box<Chat>(store);
    sessionBox = Box<ChatSession>(store);
  }

  // Session methods
  List<ChatSession> getSessions({int? limit, int? offset}) {
    final query = sessionBox
        .query()
        .order(ChatSession_.lastUpdatedAt, flags: Order.descending)
        .build();

    if (limit != null) {
      query.limit = limit;
    }
    if (offset != null) {
      query.offset = offset;
    }

    return query.find();
  }

  ChatSession createSession(String modelName, {String title = 'New Chat'}) {
    final session = ChatSession(
      modelName: modelName,
      title: title,
      createdAt: DateTime.now(),
    );
    sessionBox.put(session);
    return session;
  }

  void updateSession(ChatSession session) {
    session.lastUpdatedAt = DateTime.now();
    sessionBox.put(session);
  }

  void deleteSession(ChatSession session) {
    // Delete all chats in the session
    for (final chat in session.chats) {
      chatBox.remove(chat.id);
    }
    // Delete the session
    sessionBox.remove(session.id);
  }

  // Chat methods
  List<Chat> getChatsForSession(ChatSession session,
      {int? limit, int? offset}) {
    final query = chatBox
        .query(Chat_.chatSession.equals(session.id))
        .order(Chat_.timestamp)
        .build();

    if (limit != null) {
      query.limit = limit;
    }
    if (offset != null) {
      query.offset = offset;
    }

    return query.find();
  }

  Chat createChat({
    required String message,
    required bool isUserMessage,
    required ChatSession session,
  }) {
    final chat = Chat(
      message: message,
      isUserMessage: isUserMessage,
      timestamp: DateTime.now(),
    );
    chat.chatSession.target = session;
    chatBox.put(chat);
    return chat;
  }

  void updateChat(Chat chat) {
    chatBox.put(chat);
  }

  void deleteChat(Chat chat) {
    chatBox.remove(chat.id);
  }

  // Search methods
  List<ChatSession> searchSessions(String query) {
    return sessionBox
        .query()
        .order(ChatSession_.lastUpdatedAt, flags: Order.descending)
        .build()
        .find()
        .where((session) =>
            session.title.toLowerCase().contains(query.toLowerCase()) ||
            session.chats.any((chat) =>
                chat.message.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  // Cleanup methods
  void clearAllData() {
    chatBox.removeAll();
    sessionBox.removeAll();
  }
}
