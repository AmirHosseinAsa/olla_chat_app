import 'package:ollama_dart/ollama_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat.dart';
import 'database_service.dart';

class ChatService {
  final OllamaClient _ollamaClient;
  final DatabaseService _databaseService;

  ChatService(this._ollamaClient, this._databaseService);

  Future<List<Model>> getAvailableModels() async {
    try {
      final response = await _ollamaClient.listModels();
      return response.models?.cast<Model>() ?? [];
    } catch (e) {
      print('Error loading models: $e');
      return [];
    }
  }

  Future<String?> getDefaultModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('default_model');
  }

  Future<void> setDefaultModel(String modelName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_model', modelName);
  }

  Future<String> getSystemPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('systemPrompt') ??
        'You are a helpful AI assistant. Be concise and clear in your responses.';
  }

  Future<double> getTemperature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('temperature') ?? 0.7;
  }

  Stream<GenerateChatCompletionResponse> generateResponse({
    required String modelName,
    required List<Message> messages,
  }) async* {
    try {
      final temperature = await getTemperature();
      final systemPrompt = await getSystemPrompt();

      // Add system message at the beginning
      final allMessages = [
        Message(
          role: MessageRole.system,
          content: systemPrompt,
        ),
        ...messages,
      ];

      yield* _ollamaClient.generateChatCompletionStream(
        request: GenerateChatCompletionRequest(
          model: modelName,
          messages: allMessages,
          options: RequestOptions(temperature: temperature),
        ),
      );
    } catch (e) {
      print('Error generating response: $e');
      throw e;
    }
  }

  Future<void> deleteModel(String modelName) async {
    try {
      await _ollamaClient.deleteModel(
          request: DeleteModelRequest(model: modelName));
    } catch (e) {
      print('Error deleting model: $e');
      throw e;
    }
  }

  // Session management
  ChatSession createSession(String modelName) {
    return _databaseService.createSession(modelName);
  }

  void updateSession(ChatSession session) {
    _databaseService.updateSession(session);
  }

  void deleteSession(ChatSession session) {
    _databaseService.deleteSession(session);
  }

  List<ChatSession> getSessions({int? limit, int? offset}) {
    return _databaseService.getSessions(limit: limit, offset: offset);
  }

  // Chat management
  List<Chat> getChatsForSession(ChatSession session,
      {int? limit, int? offset}) {
    return _databaseService.getChatsForSession(session,
        limit: limit, offset: offset);
  }

  Chat createChat({
    required String message,
    required bool isUserMessage,
    required ChatSession session,
  }) {
    return _databaseService.createChat(
      message: message,
      isUserMessage: isUserMessage,
      session: session,
    );
  }

  void updateChat(Chat chat) {
    _databaseService.updateChat(chat);
  }

  void deleteChat(Chat chat) {
    _databaseService.deleteChat(chat);
  }

  // Search
  List<ChatSession> searchSessions(String query) {
    return _databaseService.searchSessions(query);
  }
}
