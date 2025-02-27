import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olla_chat_app/objectbox.g.dart';
import 'package:olla_chat_app/utils/util.dart';
import 'package:olla_chat_app/widgets/chat_bubble.dart';
import 'package:olla_chat_app/widgets/chat_input.dart';
import 'package:ollama_dart/ollama_dart.dart';
import '../models/chat.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'models_page.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:excel/excel.dart' as excel;
import '../objectbox/objectbox.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../widgets/preset_prompts_grid.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const String kDefaultModelKey = 'default_model';

// Add custom scroll behavior
class SmoothScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ).applyTo(
      const ScrollPhysics(
        parent: RangeMaintainingScrollPhysics(),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    Key? key,
    this.onThemeToggle,
  }) : super(key: key);

  final VoidCallback? onThemeToggle;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  late final Box<Chat> chatBox;
  late final Box<ChatSession> sessionBox;
  List<Chat> chats = [];
  List<ChatSession> sessions = [];
  ChatSession? currentSession;
  bool isSidebarCollapsed = false;

  // Add FocusNode for the chat input
  final FocusNode _chatInputFocusNode = FocusNode();

  // Initialize Ollama client
  final OllamaClient _ollamaClient = OllamaClient(
    baseUrl: 'http://localhost:11434/api',
  );

  // Add a variable to track if we're currently streaming
  bool _isStreaming = false;

  // Add stream controller to handle stopping generation
  StreamSubscription? _streamSubscription;

  // Add editing state
  Chat? _editingChat;
  final TextEditingController _editController = TextEditingController();

  // Add TTS instance
  late FlutterTts flutterTts;
  bool isSpeaking = false;

  // Add these variables
  List<PlatformFile> _selectedFiles = [];
  final Set<String> _allowedExtensions = {
    'json',
    'md',
    'txt',
    'cs',
    'js',
    'py',
    'java',
    'cpp',
    'css',
    'html',
    'xml',
    'yaml',
    'ini',
    'toml',
    'htm',
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
  };

  // Add scroll controller
  final ScrollController _scrollController = ScrollController();

  String? selectedModel;
  List<Model> availableModels = [];

  // Add key for ListView to force rebuilds
  final _listKey = GlobalKey<SliverAnimatedListState>();

  // Add value notifier for streaming state
  final ValueNotifier<bool> _streamingNotifier = ValueNotifier<bool>(false);

  // Add these properties to _ChatPageState:
  final ScrollController _sessionsScrollController = ScrollController();
  bool _isLoadingMoreSessions = false;
  int _sessionsLimit = 20;

  // Add these properties to _ChatPageState:
  bool _showThinking = true; // Add toggle for thinking visualization
  late AnimationController _thinkingAnimationController;
  late Animation<double> _thinkingAnimation;

  // Add this to the state class properties
  TextEditingController _searchController = TextEditingController();
  List<ChatSession> _filteredSessions = [];
  bool _isSearching = false;

  // Add auto-scroll functionality
  bool _shouldAutoScroll = false;

  // Add these properties to _ChatPageState
  bool _isLoadingMoreChats = false;
  final int _chatsLimit = 10;
  bool _hasMoreChats = true;

  // Add loading state
  bool _isLoadingSession = false;

  // Add these ValueNotifiers to the _ChatPageState class
  final ValueNotifier<bool> _showScrollToBottomNotifier =
      ValueNotifier<bool>(false);

  // Add these to the _ChatPageState class properties
  final ValueNotifier<bool> _ollamaAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<String> _ollamaError = ValueNotifier<String>('');

  // Add this to the _ChatPageState class properties
  double _lastScrollPosition = 0;
  bool _userScrolledDuringStreaming = false;

  // Add a ValueNotifier for the bot message content
  final ValueNotifier<String> _botMessageNotifier = ValueNotifier<String>('');

  // Add a ValueNotifier for scrolling position
  final ValueNotifier<double> _scrollPositionNotifier =
      ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize ObjectBox boxes
    chatBox = objectbox.chatBox;
    sessionBox = objectbox.sessionBox;

    // Load sidebar state
    _loadSidebarState();
    _loadSessions();
    _loadAvailableModels();
    _initTts();

    // Add scroll listener with user scroll detection
    _scrollController.addListener(_onScroll);
    _sessionsScrollController.addListener(_onSessionsScroll);

    _thinkingAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _thinkingAnimation = CurvedAnimation(
      parent: _thinkingAnimationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadSidebarState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSidebarCollapsed = prefs.getBool('isSidebarCollapsed') ?? false;
    });
  }

  Future<void> _toggleSidebar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSidebarCollapsed = !isSidebarCollapsed;
      prefs.setBool('isSidebarCollapsed', isSidebarCollapsed);
    });
  }

  void _loadSessions() {
    setState(() {
      final results = sessionBox
          .query()
          .order(ChatSession_.lastUpdatedAt, flags: Order.descending)
          .build()
          .find();

      sessions = results.take(_sessionsLimit).toList();

      if (sessions.isNotEmpty) {
        _selectSession(sessions.first);
      }
    });
  }

  Future<void> _loadAvailableModels() async {
    // activate ollama
    Process.run('ollama', ['list']);

    try {
      final response = await _ollamaClient.listModels();
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        availableModels = response.models?.cast<Model>() ?? [];
        if (availableModels.isNotEmpty) {
          // Try to load saved default model
          String? savedModel = prefs.getString(kDefaultModelKey);
          if (savedModel != null &&
              availableModels.any((m) => m.model == savedModel)) {
            selectedModel = savedModel;
          } else {
            // If no saved model or saved model not available, use first available
            selectedModel = availableModels.first.model;
            // Save this as default
            prefs.setString(kDefaultModelKey, selectedModel!);
          }
        }
      });
      _ollamaAvailable.value = true;
      _ollamaError.value = '';
    } catch (e) {
      // print('Error loading models: $e');
      _ollamaAvailable.value = false;
      if (e.toString().contains('Connection refused')) {
        _ollamaError.value =
            'Ollama is not running. Please start Ollama and try again.';
      } else if (e.toString().contains('No models available')) {
        _ollamaError.value =
            'No models installed. Please install a model from the Models page.';
      } else {
        _ollamaError.value = 'Make sure Ollama is running and try again.';
      }
      setState(() {
        availableModels = [];
        selectedModel = null;
      });
    }
  }

  void _createNewSession() {
    if (selectedModel == null) return;

    final session = ChatSession(
      modelName: selectedModel!,
      createdAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );
    sessionBox.put(session);
    setState(() {
      sessions.insert(0, session); // Add to beginning of list
      _selectSession(session);
    });
  }

  Future<void> _sendMessage(String message) async {
    if (!_ollamaAvailable.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ollamaError.value),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((message.trim().isEmpty && _selectedFiles.isEmpty) ||
        selectedModel == null) return;

    if (currentSession == null) {
      _createNewSession();
    }

    String fullMessage =
        "Current date and time: " + DateTime.now().toString() + "\n" + message;
    String visibleMessage = message;
    List<Message> messages = [];
    List<String> filePaths = [];

    // Handle file attachments
    if (_selectedFiles.isNotEmpty) {
      visibleMessage += '\n\nAttached Files:';
      fullMessage += '\n\nAttached Files:';

      for (var file in _selectedFiles) {
        try {
          if (file.path != null) {
            filePaths.add(file.path!);
          }

          if (_isImageFile(file.extension ?? '')) {
            // For images, create a special message format
            visibleMessage += '\n- ${file.name} (Image)';
            fullMessage += '\n- ${file.name} (Image)';

            // Read image as bytes and convert to base64
            final bytes = await File(file.path!).readAsBytes();
            final base64Image = base64Encode(bytes);

            messages.add(Message(
              role: MessageRole.user,
              content:
                  message.isEmpty ? "What's shown in this image?" : message,
              images: [base64Image],
            ));
          } else {
            // For text files and documents, only show name in visible message
            visibleMessage += '\n- ${file.name} (${file.extension})';

            // Add full content to fullMessage
            final content = await _readDocumentContent(file);
            if (content != null) {
              fullMessage +=
                  '\n${file.name} (${file.extension}):\n```${file.extension}\n$content\n```\n';
            } else {
              fullMessage +=
                  '\n${file.name} (${file.extension}): [Error reading file content]\n';
            }
          }
        } catch (e) {
          print('Error reading file ${file.name}: $e');
          fullMessage +=
              '\n${file.name} (${file.extension}): [Error reading file: $e]\n';
        }
      }
    }

    // Add the user's text message if not empty and no images were added
    if (message.trim().isNotEmpty && messages.isEmpty) {
      messages.add(Message(
        role: MessageRole.user,
        content: fullMessage,
      ));
    }

    final userChat = Chat(
      message: visibleMessage,
      isUserMessage: true,
      timestamp: DateTime.now(),
      attachedFilesPath: filePaths,
    );
    userChat.chatSession.target = currentSession;
    chatBox.put(userChat);

    final botChat = Chat(
      message: '',
      isUserMessage: false,
      timestamp: DateTime.now(),
    );
    botChat.chatSession.target = currentSession;
    chatBox.put(botChat);

    // Update session metadata
    if (currentSession != null) {
      currentSession!.lastUpdatedAt = DateTime.now();
      if (currentSession!.title == 'New Chat') {
        currentSession!.title =
            message.length > 50 ? message.substring(0, 47) + '...' : message;
        sessionBox.put(currentSession!);
      }
    }

    setState(() {
      chats.add(userChat);
      chats.add(botChat);
      _controller.clear();
      _selectedFiles.clear();
    });

    // Reset the bot message notifier
    _botMessageNotifier.value = '';

    // Get system prompt
    final prefs = await SharedPreferences.getInstance();
    final systemPrompt = prefs.getString('systemPrompt') ??
        'You are a helpful AI assistant. Be concise and clear in your responses.';
    final temperature = prefs.getDouble('temperature') ?? 0.7;

    // Generate response using the messages array
    try {
      await _streamSubscription?.cancel();

      setState(() {
        _isStreaming = true;
        _streamingNotifier.value = true;
        _shouldAutoScroll = true;
        _userScrolledDuringStreaming = false;
        // Initialize last scroll position when streaming starts
        if (_scrollController.hasClients) {
          _lastScrollPosition = _scrollController.position.pixels;
        }
      });

      // Build conversation history
      final List<Message> messageList = [];

      // Find the index of the user message being regenerated
      final userChatIndex = chats.indexOf(userChat);

      // Only add system prompt if this is the first message in the session
      if (userChatIndex <= 0) {
        messageList.add(Message(
          role: MessageRole.system,
          content: systemPrompt,
        ));
      }

      // Add previous messages up to the current exchange
      for (int i = 0; i < userChatIndex; i++) {
        final chat = chats[i];
        messageList.add(Message(
          role: chat.isUserMessage ? MessageRole.user : MessageRole.assistant,
          content: chat.message,
        ));
      }

      // Add the current message
      messageList.addAll(messages);

      _streamSubscription = _ollamaClient
          .generateChatCompletionStream(
        request: GenerateChatCompletionRequest(
          model: selectedModel!,
          messages: messageList,
          options: RequestOptions(
            temperature: temperature,
          ),
        ),
      )
          .listen(
        (res) {
          if (!mounted) return;
          if (res.message?.content != null) {
            // Update the message without setState to avoid rebuilds
            botChat.message += res.message!.content;
            chatBox.put(botChat);

            // Update the notifier instead of using setState
            _botMessageNotifier.value = botChat.message;

            // Handle streaming scroll without triggering a full rebuild
            if (_shouldAutoScroll &&
                !_userScrolledDuringStreaming &&
                _scrollController.hasClients) {
              final maxScroll = _scrollController.position.maxScrollExtent;
              final currentScroll = _scrollController.position.pixels;

              // If we're close to the bottom, keep scrolling
              if (maxScroll - currentScroll < 100) {
                // Calculate small increments for smoother appearance
                final targetScroll = maxScroll;
                final increment = (targetScroll - currentScroll) * 0.1;

                // Update scrolling through the notifier instead of directly manipulating the controller
                _scrollPositionNotifier.value = currentScroll + increment;

                // Use a post-frame callback to do the actual scrolling to avoid UI blocking
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && mounted) {
                    _scrollController.jumpTo(_scrollPositionNotifier.value);
                  }
                });
              }
            }
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isStreaming = false;
              chatBox.put(botChat);
            });
            _streamingNotifier.value = false;
          }
        },
        onError: (e) {
          print('Error: $e');
          if (mounted) {
            setState(() {
              _isStreaming = false;
              botChat.message = 'Error: Failed to generate response';
              chatBox.put(botChat);
            });
            _streamingNotifier.value = false;
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() {
          _isStreaming = false;
          botChat.message = 'Error: Failed to get response from Ollama';
          chatBox.put(botChat);
        });
        _streamingNotifier.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            'Error: Failed to get response from Ollama',
            style: GoogleFonts.getFont(
              Util.appFont,
              fontSize: 16,
              color: Colors.red,
            ),
          )),
        );
      }
    }
  }

  Future<void> _selectSession(ChatSession session) async {
    if (_isLoadingSession || session.id == currentSession?.id) return;

    // Stop TTS if it's speaking
    if (isSpeaking) {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    }

    if (_isStreaming) {
      _stopGeneration();
    }

    setState(() {
      _isLoadingSession = true;
      currentSession = session;
      chats = []; // Clear existing chats immediately
    });

    try {
      // Load chats directly from the main isolate
      final query = chatBox
          .query(Chat_.chatSession.equals(session.id))
          .order(Chat_.timestamp)
          .build();

      final loadedChats = query.find();
      print('Found ${loadedChats.length} chats for session ${session.id}');

      if (!mounted) return;

      setState(() {
        chats = loadedChats;
        _isLoadingSession = false;
        _hasMoreChats = true;
      });

      // Scroll to bottom after messages are loaded
      if (chats.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      print('Error loading session: $e');
      if (mounted) {
        setState(() {
          _isLoadingSession = false;
        });
      }
    }
  }

  // Function to stop generation
  void _stopGeneration() {
    _streamSubscription?.cancel();
    setState(() {
      _isStreaming = false;
      _streamingNotifier.value = false;
    });

    // Update the actual chat message with the current notifier value
    if (chats.isNotEmpty && !chats.last.isUserMessage) {
      final botChat = chats.last;
      botChat.message = _botMessageNotifier.value;
      chatBox.put(botChat);
    }

    // Force rebuild of chat list
    setState(() {
      chats = List.from(chats);
    });

    // Maintain focus on the chat input after stopping generation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatInputFocusNode.requestFocus();
    });
  }

  // Function to regenerate response
  Future<void> _regenerateResponse(Chat userChat, Chat botChat) async {
    setState(() {
      _isStreaming = true;
      _streamingNotifier.value = true;
      botChat.message = '';
      chatBox.put(botChat);

      // Reset the bot message notifier
      _botMessageNotifier.value = '';
    });

    String fullMessage = userChat.message;
    List<Message> messages = [];

    // Load content from saved file paths
    if (userChat.attachedFilesPath.isNotEmpty) {
      fullMessage += '\n\nAttached Files:';

      for (var filePath in userChat.attachedFilesPath) {
        try {
          final file = File(filePath);
          if (!await file.exists()) {
            print('File not found: $filePath');
            fullMessage += '\n- [File not found: $filePath]';
            continue;
          }

          final fileName = file.path.split(Platform.pathSeparator).last;
          final extension = fileName.split('.').last.toLowerCase();

          fullMessage += '\n- $fileName (${extension.toUpperCase()})';

          if (_isImageFile(extension)) {
            // Handle image files
            try {
              final bytes = await file.readAsBytes();
              final base64Image = base64Encode(bytes);

              messages.add(Message(
                role: MessageRole.user,
                content: userChat.message
                    .replaceAll(
                        RegExp(r'\n\nAttached Files:.*$', dotAll: true), '')
                    .trim(),
                images: [base64Image],
              ));
            } catch (e) {
              print('Error reading image file $fileName: $e');
              fullMessage += ' [Error reading image file]';
            }
          } else {
            // Handle text-based files
            try {
              final content = await _readDocumentContentFromPath(filePath);
              if (content != null) {
                fullMessage += '\n```$extension\n$content\n```\n';
              } else {
                fullMessage += ' [Unsupported file type]';
              }
            } catch (e) {
              print('Error reading file $fileName: $e');
              fullMessage += ' [Error reading file content]';
            }
          }
        } catch (e) {
          print('Error processing file $filePath: $e');
          fullMessage += '\n- [Error processing file: $filePath]';
        }
      }
    }

    // Add the message content if no images were processed
    if (messages.isEmpty) {
      messages.add(Message(
        role: MessageRole.user,
        content: fullMessage,
      ));
    }

    // Get system prompt
    final prefs = await SharedPreferences.getInstance();
    final systemPrompt = prefs.getString('systemPrompt') ??
        'You are a helpful AI assistant. Be concise and clear in your responses.';
    final temperature = prefs.getDouble('temperature') ?? 0.7;

    try {
      await _streamSubscription?.cancel();

      setState(() {
        _isStreaming = true;
        _streamingNotifier.value = true;
        _shouldAutoScroll = true;
      });

      // Build conversation history
      final List<Message> messageList = [];

      // Find the index of the user message being regenerated
      final userChatIndex = chats.indexOf(userChat);

      // Only add system prompt if this is the first message in the session
      if (userChatIndex <= 0) {
        messageList.add(Message(
          role: MessageRole.system,
          content: systemPrompt,
        ));
      }

      // Add previous messages up to the current exchange
      for (int i = 0; i < userChatIndex; i++) {
        final chat = chats[i];
        messageList.add(Message(
          role: chat.isUserMessage ? MessageRole.user : MessageRole.assistant,
          content: chat.message,
        ));
      }

      // Add the current message
      messageList.addAll(messages);

      _streamSubscription = _ollamaClient
          .generateChatCompletionStream(
        request: GenerateChatCompletionRequest(
          model: selectedModel!,
          messages: messageList,
          options: RequestOptions(
            temperature: temperature,
          ),
        ),
      )
          .listen(
        (res) {
          if (!mounted) return;
          if (res.message?.content != null) {
            // Update the message without setState to avoid rebuilds
            botChat.message += res.message!.content;
            chatBox.put(botChat);

            // Update the notifier instead of using setState
            _botMessageNotifier.value = botChat.message;

            // Handle streaming scroll without triggering a full rebuild
            if (_shouldAutoScroll &&
                !_userScrolledDuringStreaming &&
                _scrollController.hasClients) {
              final maxScroll = _scrollController.position.maxScrollExtent;
              final currentScroll = _scrollController.position.pixels;

              // If we're close to the bottom, keep scrolling
              if (maxScroll - currentScroll < 100) {
                // Calculate small increments for smoother appearance
                final targetScroll = maxScroll;
                final increment = (targetScroll - currentScroll) * 0.1;

                // Update scrolling through the notifier instead of directly manipulating the controller
                _scrollPositionNotifier.value = currentScroll + increment;

                // Use a post-frame callback to do the actual scrolling to avoid UI blocking
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && mounted) {
                    _scrollController.jumpTo(_scrollPositionNotifier.value);
                  }
                });
              }
            }
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isStreaming = false;
              chatBox.put(botChat);
            });
            _streamingNotifier.value = false;
          }
        },
        onError: (e) {
          print('Error: $e');
          if (mounted) {
            setState(() {
              _isStreaming = false;
              botChat.message = 'Error: Failed to generate response';
              chatBox.put(botChat);
            });
            _streamingNotifier.value = false;
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() {
          _isStreaming = false;
          botChat.message = 'Error: Failed to get response from Ollama';
          chatBox.put(botChat);
        });
        _streamingNotifier.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            'Error: Failed to get response from Ollama',
            style: GoogleFonts.getFont(
              Util.appFont,
              fontSize: 16,
              color: Colors.red,
            ),
          )),
        );
      }
    }
  }

  Future<String?> _readDocumentContentFromPath(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File not found: $filePath');
        return null;
      }

      final extension = filePath.split('.').last.toLowerCase();

      switch (extension) {
        case 'pdf':
          final document = PdfDocument(inputBytes: await file.readAsBytes());
          final PdfTextExtractor extractor = PdfTextExtractor(document);
          final String text = extractor.extractText();
          document.dispose();
          return text;

        case 'doc':
        case 'docx':
          final bytes = await file.readAsBytes();
          return docxToText(bytes);

        case 'xls':
        case 'xlsx':
          final bytes = await file.readAsBytes();
          final ex = excel.Excel.decodeBytes(bytes);
          final buffer = StringBuffer();

          for (var table in ex.tables.keys) {
            buffer.writeln('Sheet: $table');
            for (var row in ex.tables[table]!.rows) {
              buffer.writeln(
                  row.map((cell) => cell?.value.toString() ?? '').join('\t'));
            }
            buffer.writeln();
          }
          return buffer.toString();

        case 'txt':
        case 'json':
        case 'md':
        case 'py':
        case 'js':
        case 'java':
        case 'cpp':
        case 'cs':
        case 'html':
        case 'css':
        case 'xml':
        case 'yaml':
        case 'ini':
        case 'toml':
        case 'htm':
          return await file.readAsString();

        default:
          print('Unsupported file type: $extension');
          return null;
      }
    } catch (e) {
      print('Error reading file content: $e');
      return null;
    }
  }

  Future<String?> _readDocumentContent(PlatformFile file) async {
    if (file.path == null) return null;
    return _readDocumentContentFromPath(file.path!);
  }

  // Function to edit message
  void _startEditing(Chat chat) {
    setState(() {
      _editingChat = chat;
      _editController.text = chat.message;
    });
  }

  // Function to save edited message
  Future<void> _saveEdit() async {
    if (_editingChat == null) return;

    final newMessage = _editController.text.trim();
    if (newMessage.isEmpty || newMessage == _editingChat!.message) {
      setState(() {
        _editingChat = null;
      });
      return;
    }

    // Save original message if this is the first edit
    if (!_editingChat!.isEdited) {
      _editingChat!.originalMessage = _editingChat!.message;
    }

    _editingChat!.message = newMessage;
    _editingChat!.isEdited = true;
    chatBox.put(_editingChat!);

    // Find the corresponding bot message and regenerate
    final chatIndex = chats.indexOf(_editingChat!);
    if (chatIndex != -1 && chatIndex + 1 < chats.length) {
      final botChat = chats[chatIndex + 1];
      await _regenerateResponse(_editingChat!, botChat);
    }

    setState(() {
      _editingChat = null;
    });
  }

  // Initialize TTS with optimized settings for desktop
  Future<void> _initTts() async {
    flutterTts = FlutterTts();

    await flutterTts.setSpeechRate(.4); // Slower for better clarity
    await flutterTts.setVolume(0.9); // Slightly reduced to prevent distortion
    await flutterTts.setPitch(1.5); // Slightly higher for better engagement
    await flutterTts.setLanguage('en-us');
    // Basic settings for natural speech

    // Get and print available voices
    final voices = await flutterTts.getVoices;
    print('Available voices: ${voices.toString()}');

    // Try to find the best voice for each platform
    for (final voice in voices) {
      if (voice is Map) {
        String name = voice['name'].toString().toLowerCase();
        String? quality = voice['quality']?.toString().toLowerCase();

        // Priority order for voice selection
        if (Platform.isWindows) {
          if (name.contains('microsoft')) {
            if (name.contains('zira') ||
                name.contains('david') ||
                name.contains('catherine')) {
              await flutterTts
                  .setVoice({"name": voice['name'], "locale": voice['locale']});
              break;
            }
          }
        } else if (Platform.isMacOS) {
          // macOS typically has higher quality voices
          if (quality == 'enhanced' || quality == 'premium') {
            if (name.contains('samantha') ||
                name.contains('karen') ||
                name.contains('daniel')) {
              await flutterTts.setVoice({
                "name": voice['name'],
                "locale": voice['locale'],
                "quality": voice['quality']
              });
              break;
            }
          }
        }
      }
    }

    // Set handlers
    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      print('TTS error: $msg');
      setState(() {
        isSpeaking = false;
      });
    });

    // For macOS, set audio session category for better performance
    if (Platform.isMacOS) {
      await flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }
  }

  // Improved speak function with better text preprocessing
  Future<void> _speak(String text) async {
    // Clean up markdown and special characters
    text = text
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // Remove code blocks
        .replaceAll(RegExp(r'`[^`]*`'), '') // Remove inline code
        .replaceAll(RegExp(r'#{1,6}\s.*'), '') // Remove headers
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), '') // Clean bold text
        .replaceAll(RegExp(r'\|(.*?)\|'), '') // Clean table syntax
        .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true),
            '') // Remove thinking blocks
        .replaceAll(RegExp(r'\$\d+'), '') // Remove dollar signs with numbers
        .replaceAll(
            RegExp(r'[\n\r\t]+'), ' ') // Replace newlines and tabs with spaces
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();

    if (isSpeaking) {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
      return;
    }

    String processedText = text.trim();

    setState(() {
      isSpeaking = true;
    });

    try {
      await flutterTts.speak(processedText);
    } catch (e) {
      setState(() {
        isSpeaking = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streamingNotifier.dispose();
    _botMessageNotifier.dispose();
    _scrollPositionNotifier.dispose();
    _controller.dispose();
    _chatController.dispose();
    _editController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _sessionsScrollController.removeListener(_onSessionsScroll);
    _sessionsScrollController.dispose();
    _streamSubscription?.cancel();
    _thinkingAnimationController.dispose();
    flutterTts.stop();
    _ollamaAvailable.dispose();
    _ollamaError.dispose();
    _chatInputFocusNode.dispose();
    super.dispose();
  }

  // Update _pickFiles method to handle dropped files
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions.toList(),
        allowMultiple: true,
        withData: true, // Enable preview for images
      );

      if (result != null) {
        setState(() {
          // Add new files to existing ones, up to a maximum of 10 files total
          final newFiles =
              result.files.take(10 - _selectedFiles.length).toList();
          _selectedFiles = [..._selectedFiles, ...newFiles];
          if (_selectedFiles.length > 10) {
            _selectedFiles = _selectedFiles.take(10).toList();
            // Show warning if files were skipped
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Maximum 10 files allowed',
                  style: GoogleFonts.getFont(Util.appFont),
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  // Add this method to show voice selection
  Future<void> _showVoiceSelector() async {
    final voices = await flutterTts.getVoices;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Color(0xFF1E1B2C),
        child: Container(
          width: 320, // Fixed width
          constraints: BoxConstraints(maxHeight: 400),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.settings_voice,
                      color: Color(0xFF8B5CF6), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Select Voice',
                    style: GoogleFonts.getFont(
                      Util.appFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: voices.length,
                  itemBuilder: (context, index) {
                    final voice = voices[index] as Map;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF2D2E32).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF8B5CF6).withOpacity(0.2),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          voice['name'].toString(),
                          style: GoogleFonts.getFont(
                            Util.appFont,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          voice['locale'].toString(),
                          style: GoogleFonts.getFont(
                            Util.appFont,
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        onTap: () async {
                          await flutterTts.setVoice({
                            "name": voice['name'],
                            "locale": voice['locale']
                          });
                          Navigator.pop(context);
                          // Test the voice
                          await _speak(
                              "Hello, this is a test of the selected voice.");
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add scroll to bottom method
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    // Use a post-frame callback to avoid UI blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration:
              Duration(milliseconds: 150), // Faster duration for streaming
          curve: Curves.easeInOut, // Smoother curve for streaming
        );
      }
    });
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    bool isNearBottom = maxScroll - currentScroll <= 100;

    // During streaming, detect any user scroll activity
    if (_isStreaming && _shouldAutoScroll) {
      // If there's any scroll activity during streaming, mark it
      if (currentScroll != _lastScrollPosition) {
        _userScrolledDuringStreaming = true;
        // Use the value notifier instead of setState
        _shouldAutoScroll = false;
      }
    }

    // Update last scroll position for next comparison
    _lastScrollPosition = currentScroll;

    if (currentSession == null) {
      isNearBottom = false;
    }

    // Only re-enable auto-scroll if user manually scrolls back to bottom
    if (isNearBottom && !_shouldAutoScroll) {
      _shouldAutoScroll = true;
      // Reset the user scroll flag when they go back to bottom
      _userScrolledDuringStreaming = false;
    }

    // Use the value notifier instead of setState
    if (_showScrollToBottomNotifier.value != !isNearBottom) {
      _showScrollToBottomNotifier.value = !isNearBottom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Color.fromARGB(255, 109, 67, 199).withOpacity(0.3),
          cursorColor: Color.fromARGB(255, 47, 11, 129),
          selectionHandleColor: Color(0xFF8B5CF6),
        ),
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              _isStreaming) {
            _stopGeneration();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFF1E1B2C),
            elevation: 0,
            title: Row(
              children: [
                Text(
                  'Olla Chat',
                  style: GoogleFonts.getFont(
                    Util.appFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                if (availableModels.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: DropdownButton<String>(
                      value: selectedModel,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                      underline: SizedBox(),
                      dropdownColor: Color(0xFF1E1B2C),
                      items: availableModels.map((model) {
                        return DropdownMenuItem(
                          value: model.model,
                          child: Text(
                            model.model ?? "",
                            style: GoogleFonts.getFont(
                              Util.appFont,
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value != null) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(kDefaultModelKey, value);

                          setState(() {
                            selectedModel = value;
                            if (currentSession != null) {
                              currentSession!.modelName = value;
                              sessionBox.put(currentSession!);
                            }
                          });
                        }
                      },
                    ),
                  ),
              ],
            ),
            actions: [
              // Toggle thinking visualization
              IconButton(
                icon: Icon(
                  _showThinking ? Icons.psychology : Icons.psychology_outlined,
                  color: _showThinking
                      ? Util.primaryPurple
                      : Theme.of(context).iconTheme.color,
                  size: 22,
                ),
                onPressed: _toggleThinking,
                tooltip: 'Toggle show reasoning',
              ),
              // Voice selector
              IconButton(
                icon: Icon(
                  Icons.settings_voice,
                  color: Theme.of(context).iconTheme.color,
                  size: 22,
                ),
                onPressed: _showVoiceSelector,
                tooltip: 'Select voice',
              ),
              // Manage Models
              IconButton(
                icon: Icon(
                  Icons.model_training,
                  color: Theme.of(context).iconTheme.color,
                  size: 22,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ModelsPage()),
                  );
                  // Refresh models when returning from Models page
                  _loadAvailableModels();
                },
                tooltip: 'Manage Models',
              ),
              // Settings
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Theme.of(context).iconTheme.color,
                  size: 22,
                ),
                onPressed: () async {
                  final shouldReload = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                  // If data was cleared, reload sessions and reset current state
                  if (shouldReload == true) {
                    setState(() {
                      currentSession = null;
                      chats = [];
                      sessions = [];
                    });
                    _loadSessions();
                  }
                },
                tooltip: 'Settings',
              ),
              SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: isSidebarCollapsed ? 80 : 250,
                    decoration: BoxDecoration(
                      color: Color(0xFF1E1B2C).withOpacity(0.9),
                      borderRadius: isSidebarCollapsed
                          ? BorderRadius.only(
                              topRight: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            )
                          : BorderRadius.zero,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF8B5CF6).withOpacity(0.1),
                          blurRadius: 24,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isSidebarCollapsed
                        ? Column(
                            children: [
                              SizedBox(height: 16),
                              Container(
                                width: 80,
                                alignment: Alignment.center,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    size: 24,
                                  ),
                                  onPressed: _createNewSession,
                                  tooltip: 'New Chat',
                                ),
                              ),
                              Expanded(
                                child: SizedBox(),
                              ),
                            ],
                          )
                        : ClipRRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: InkWell(
                                      onTap: _createNewSession,
                                      child: Container(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Color(0xFF8B5CF6)
                                                  .withOpacity(0.1)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Color(0xFF8B5CF6)
                                                        .withOpacity(0.2)
                                                    : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_circle_outline,
                                                size: 20),
                                            SizedBox(width: 8),
                                            Text('New Chat',
                                                style: GoogleFonts.getFont(
                                                        Util.appFont)
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Color(0xFF2D2E32).withOpacity(0.3)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: _handleSearch,
                                        style: GoogleFonts.getFont(Util.appFont)
                                            .copyWith(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Search chats...',
                                          hintStyle:
                                              GoogleFonts.getFont(Util.appFont)
                                                  .copyWith(
                                                      color: Colors.white38),
                                          prefixIcon: Icon(Icons.search,
                                              color: Colors.white38, size: 20),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                        ),
                                        cursorColor: Color(0xFF8B5CF6),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Expanded(
                                    flex: 6,
                                    child: ListView.builder(
                                      controller: _sessionsScrollController,
                                      itemCount: (_isSearching
                                                  ? _filteredSessions
                                                  : sessions)
                                              .length +
                                          (_isLoadingMoreSessions ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                            (_isSearching
                                                    ? _filteredSessions
                                                    : sessions)
                                                .length) {
                                          return Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }
                                        final session = _isSearching
                                            ? _filteredSessions[index]
                                            : sessions[index];
                                        return _buildSessionTile(session);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox(),
                                    flex: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 25,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E1B2C),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF8B5CF6).withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isSidebarCollapsed
                                ? Icons.chevron_right
                                : Icons.chevron_left,
                          ),
                          onPressed: _toggleSidebar,
                          tooltip: isSidebarCollapsed
                              ? 'Expand Sidebar'
                              : 'Collapse Sidebar',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(child: _buildChatArea()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTile(ChatSession session) {
    final isSelected = currentSession?.id == session.id;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 8, vertical: 2), // Reduced vertical padding
      child: GestureDetector(
        onSecondaryTapUp: (details) =>
            _showSessionContextMenu(context, session, details.globalPosition),
        onLongPress: () => _showSessionContextMenu(
          context,
          session,
          Offset(
            MediaQuery.of(context).size.width / 3,
            MediaQuery.of(context).size.height / 3,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xFF8B5CF6).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Color(0xFF8B5CF6).withOpacity(0.2)
                  : Colors.transparent,
            ),
          ),
          child: ListTile(
            dense: true, // Makes the tile more compact
            visualDensity: VisualDensity.compact,
            title: Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.getFont(Util.appFont).copyWith(
                color: isSelected ? Color(0xFF8B5CF6) : Colors.white,
                fontSize: 13, // Reduced font size
              ),
            ),
            subtitle: Text(
              _formatDate(session.lastUpdatedAt),
              style: GoogleFonts.getFont(Util.appFont).copyWith(
                fontSize: 11,
                color: Colors.white38,
              ),
            ),
            selected: isSelected,
            onTap: () => _selectSession(session),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(Chat chat, bool isLast) {
    // For the last bot message during streaming, use the ValueListenableBuilder
    if (isLast && !chat.isUserMessage && _isStreaming) {
      return ValueListenableBuilder<String>(
        valueListenable: _botMessageNotifier,
        builder: (context, streamingMessage, child) {
          return ChatBubble(
            message: streamingMessage,
            isUser: chat.isUserMessage,
            isStreaming: _isStreaming,
            isEdited: chat.isEdited,
            isSpeaking: isSpeaking,
            showThinking: _showThinking && !chat.isUserMessage,
            showThinkingIndicator: _showThinking,
            onCopy: () {
              Clipboard.setData(ClipboardData(text: streamingMessage));
            },
            onSpeak: () {
              _speak(streamingMessage);
            },
            onStopGeneration: _stopGeneration,
          );
        },
      );
    }

    // For all other messages, use the regular approach
    return ChatBubble(
      message: chat.message,
      isUser: chat.isUserMessage,
      isStreaming: _isStreaming && isLast && !chat.isUserMessage,
      isEdited: chat.isEdited,
      isSpeaking: isSpeaking,
      showThinking: _showThinking && !chat.isUserMessage,
      showThinkingIndicator:
          _isStreaming && isLast && !chat.isUserMessage && _showThinking,
      onCopy: () {
        Clipboard.setData(ClipboardData(text: chat.message));
      },
      onSpeak: () {
        _speak(chat.message);
      },
      onEdit: chat.isUserMessage
          ? (String newText) async {
              if (newText != chat.message) {
                // Save original message if this is the first edit
                if (!chat.isEdited) {
                  chat.originalMessage = chat.message;
                }

                chat.message = newText;
                chat.isEdited = true;
                chatBox.put(chat);

                // Find and regenerate the bot response immediately
                final chatIndex = chats.indexOf(chat);
                if (chatIndex != -1 && chatIndex + 1 < chats.length) {
                  final botChat = chats[chatIndex + 1];
                  setState(() {
                    botChat.message = '';
                    chatBox.put(botChat);
                    _isStreaming = true;
                  });

                  // Reset the bot message notifier
                  _botMessageNotifier.value = '';

                  // Regenerate response with edited message
                  await _regenerateResponse(chat, botChat);
                }
              }
            }
          : null,
      onRegenerate: !chat.isUserMessage && !_isStreaming
          ? () async {
              // Find the user message that generated this response
              final chatIndex = chats.indexOf(chat);
              if (chatIndex > 0) {
                final userChat = chats[chatIndex - 1];
                await _regenerateResponse(userChat, chat);
              }
            }
          : null,
      onStopGeneration: _isStreaming && isLast && !chat.isUserMessage
          ? _stopGeneration
          : null,
    );
  }

  Widget _buildChatArea() {
    return Stack(
      children: [
        Container(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width / 1.1),
            child: ValueListenableBuilder<bool>(
              valueListenable: _ollamaAvailable,
              builder: (context, isOllamaAvailable, child) {
                if (!isOllamaAvailable) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _ollamaError.value,
                          style: GoogleFonts.getFont(
                            Util.appFont,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadAvailableModels,
                          icon: Icon(Icons.refresh),
                          label: Text('Retry Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 46, 10, 129),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ValueListenableBuilder<bool>(
                  valueListenable: _streamingNotifier,
                  builder: (context, isStreaming, child) {
                    if (_isLoadingSession) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF8B5CF6)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading chat history...',
                              style: GoogleFonts.getFont(Util.appFont)
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: (chats.isEmpty && currentSession != null) ||
                                  sessions.isEmpty
                              ? PresetPromptsGrid(
                                  onPromptSelected: (prompt) {
                                    _chatController.text = prompt;
                                    // Focus the text field after setting the prompt
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      _chatInputFocusNode.requestFocus();
                                      // Set cursor to end of text
                                      _chatController.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(
                                            offset:
                                                _chatController.text.length),
                                      );
                                    });
                                  },
                                )
                              : SingleChildScrollView(
                                  controller: _scrollController,
                                  physics: SmoothScrollBehavior()
                                      .getScrollPhysics(context),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isLoadingMoreChats)
                                        Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                      Flexible(
                                        child: ListView.builder(
                                          key: _listKey,
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          cacheExtent: 1000,
                                          itemCount: chats.length,
                                          itemBuilder: (context, index) {
                                            return RepaintBoundary(
                                              child: KeyedSubtree(
                                                key: ValueKey(
                                                    'chat_${chats[index].id}'),
                                                child: _buildChatBubble(
                                                  chats[index],
                                                  index == chats.length - 1,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        ChatInput(
                          controller: _chatController,
                          isStreaming: _isStreaming,
                          selectedFiles: _selectedFiles,
                          onSend: _sendMessage,
                          onPickFiles: _pickFiles,
                          onRemoveFile: _removeFile,
                          onStopGeneration: _stopGeneration,
                          onFilesDropped: _handleDroppedFiles,
                          focusNode: _chatInputFocusNode,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (_showScrollToBottomNotifier.value)
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton(
              mini: true,
              backgroundColor:
                  Color.fromARGB(82, 150, 150, 150), // Darker purple color
              onPressed: () {
                _scrollToBottom();
                setState(() {
                  _shouldAutoScroll = true;
                });
              },
              child: Icon(Icons.arrow_downward),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Add method to handle session deletion
  void _confirmDeleteSession(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chat', style: GoogleFonts.getFont(Util.appFont)),
        content: Text(
          'Are you sure you want to delete this chat?',
          style: GoogleFonts.getFont(Util.appFont),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.getFont(Util.appFont)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSession(session);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.getFont(Util.appFont).copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteSession(ChatSession session) {
    // Delete all chats in the session
    for (final chat in session.chats) {
      chatBox.remove(chat.id);
    }
    // Delete the session
    sessionBox.remove(session.id);
    // Refresh sessions list
    _loadSessions();
    // If current session was deleted, select another one
    if (currentSession?.id == session.id) {
      setState(() {
        currentSession = sessions.isNotEmpty ? sessions.first : null;
        chats = currentSession?.chats.toList() ?? [];
        if (chats.isNotEmpty) {
          chats.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }
      });
    }
  }

  void _showSessionContextMenu(
      BuildContext context, ChatSession session, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 48,
        position.dy + 48,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename', style: GoogleFonts.getFont(Util.appFont)),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            // Need to wait for menu to close before showing dialog
            Future.delayed(Duration(milliseconds: 0), () {
              _showRenameDialog(session);
            });
          },
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              'Delete',
              style:
                  GoogleFonts.getFont(Util.appFont).copyWith(color: Colors.red),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            Future.delayed(Duration(milliseconds: 0), () {
              _confirmDeleteSession(session);
            });
          },
        ),
      ],
    );
  }

  Future<void> _showRenameDialog(ChatSession session) async {
    final TextEditingController titleController =
        TextEditingController(text: session.title);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Chat', style: GoogleFonts.getFont(Util.appFont)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter new title',
            hintStyle: GoogleFonts.getFont(Util.appFont),
          ),
          style: GoogleFonts.getFont(Util.appFont),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.getFont(Util.appFont)),
          ),
          TextButton(
            onPressed: () {
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty) {
                session.title = newTitle;
                sessionBox.put(session);
                _loadSessions();
              }
              Navigator.pop(context);
            },
            child: Text('Save', style: GoogleFonts.getFont(Util.appFont)),
          ),
        ],
      ),
    ).whenComplete(() => titleController.dispose());
  }

  // Add this method to load more sessions:
  Future<void> _loadMoreSessions() async {
    if (_isLoadingMoreSessions) return;

    setState(() {
      _isLoadingMoreSessions = true;
    });

    try {
      final query = sessionBox
          .query()
          .order(ChatSession_.lastUpdatedAt, flags: Order.descending)
          .build();

      final totalCount = query.count();

      // If we've loaded all sessions, don't try to load more
      if (sessions.length >= totalCount) {
        setState(() {
          _isLoadingMoreSessions = false;
        });
        return;
      }

      // Get all sessions and manually handle pagination
      final moreSessions =
          query.find().skip(sessions.length).take(_sessionsLimit).toList();

      if (moreSessions.isNotEmpty) {
        setState(() {
          sessions.addAll(moreSessions);
        });
      }
    } finally {
      setState(() {
        _isLoadingMoreSessions = false;
      });
    }
  }

  // Add this method to handle session scrolling
  void _onSessionsScroll() {
    if (_sessionsScrollController.position.pixels >=
            _sessionsScrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMoreSessions) {
      _loadMoreSessions();
    }
  }

  void _toggleThinking() {
    setState(() {
      _showThinking = !_showThinking;
      // No need to manually rebuild the chat list as setState will trigger a rebuild
    });
  }

  // Add this method to handle search
  void _handleSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSessions = sessions;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredSessions = sessions.where((session) {
          return session.title.toLowerCase().contains(query.toLowerCase()) ||
              session.chats.any((chat) =>
                  chat.message.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  // Add this method
  void _removeFile(PlatformFile file) {
    setState(() {
      _selectedFiles.removeWhere((f) => f.path == file.path);
    });
  }

  // Add helper method to check if file is an image
  bool _isImageFile(String extension) {
    final imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
    return imageExtensions.contains(extension.toLowerCase());
  }

  // Add this method to handle dropped files
  void _handleDroppedFiles(List<PlatformFile> files) {
    setState(() {
      // Add new files to existing ones, up to a maximum of 10 files total
      final newFiles = files.take(10 - _selectedFiles.length).toList();
      _selectedFiles = [..._selectedFiles, ...newFiles];
      if (_selectedFiles.length > 10) {
        _selectedFiles = _selectedFiles.take(10).toList();
        // Show warning if files were skipped
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Maximum 10 files allowed',
              style: GoogleFonts.getFont(Util.appFont),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }
}
