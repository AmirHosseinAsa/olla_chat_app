import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olla_chat_app/objectbox.g.dart';
import 'package:file_picker/file_picker.dart';
import 'package:olla_chat_app/utils/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../models/chat.dart';
import '../objectbox/objectbox.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../pages/models_page.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? selectedFont = Util.appFont;
  TextEditingController _systemPromptController = TextEditingController();
  double _temperature = 0.7; // Default temperature
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  // Add reference to ObjectBox
  late final Box<Chat> _chatBox;
  late final Box<ChatSession> _sessionBox;

  @override
  void initState() {
    super.initState();
    _loadSelectedFont();
    _loadSystemPrompt();
    _loadTemperature();

    // Initialize ObjectBox boxes
    _chatBox = objectbox.chatBox;
    _sessionBox = objectbox.sessionBox;
  }

  Future<void> _loadSelectedFont() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFont = prefs.getString('selectedFont');

    // List of valid fonts
    final validFonts = [
      'Roboto',
      'Lato',
      'Open Sans',
      'Montserrat',
      'Source Code Pro',
      'Ubuntu',
    ];

    setState(() {
      // If saved font is not in valid fonts list, use default
      selectedFont = validFonts.contains(savedFont) ? savedFont : 'Roboto';
    });
  }

  Future<void> _saveFont(String font) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setFont(font);
    setState(() {
      selectedFont = font;
      Util.appFont = font;
    });
  }

  Future<void> _loadSystemPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _systemPromptController.text = prefs.getString('systemPrompt') ??
          'You are a helpful AI assistant. Be concise and clear in your responses.';
    });
  }

  Future<void> _loadTemperature() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temperature = prefs.getDouble('temperature') ?? 0.7;
    });
  }

  Future<void> _saveTemperature(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('temperature', value);
    setState(() {
      _temperature = value;
    });
  }

  Future<void> _exportData() async {
    try {
      final sessions = _sessionBox.getAll();
      final chats = _chatBox.getAll();

      final data = {
        'sessions': sessions
            .map((s) => {
                  'id': s.id,
                  'modelName': s.modelName,
                  'title': s.title,
                  'createdAt': s.createdAt.toIso8601String(),
                  'lastUpdatedAt': s.lastUpdatedAt.toIso8601String(),
                })
            .toList(),
        'chats': chats
            .map((c) => {
                  'id': c.id,
                  'message': c.message,
                  'isUserMessage': c.isUserMessage,
                  'timestamp': c.timestamp.toIso8601String(),
                  'sessionId': c.chatSession.target?.id,
                  'isEdited': c.isEdited,
                  'originalMessage': c.originalMessage,
                })
            .toList(),
      };

      final jsonString = jsonEncode(data);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/chat_backup.json');
      await file.writeAsString(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  Future<void> _exportDataWithLocation(BuildContext context) async {
    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save chat backup',
        fileName: 'chat_backup.json',
        allowedExtensions: ['json'],
        type: FileType.custom,
      );

      if (outputFile == null) return;

      // Get system prompt and temperature
      final prefs = await SharedPreferences.getInstance();
      final systemPrompt = prefs.getString('systemPrompt');
      final temperature = prefs.getDouble('temperature') ?? 0.7;

      // Get all sessions with their chats
      final sessions = _sessionBox.getAll();
      final allChats = _chatBox.getAll();

      // Create a map of session IDs to their chats
      final Map<int, List<Chat>> sessionChats = {};
      for (final chat in allChats) {
        final sessionId = chat.chatSession.target?.id;
        if (sessionId != null) {
          sessionChats[sessionId] = sessionChats[sessionId] ?? [];
          sessionChats[sessionId]!.add(chat);
        }
      }

      final data = {
        'systemPrompt': systemPrompt,
        'temperature': temperature,
        'sessions': sessions.map((s) {
          final sessionData = {
            'id': s.id,
            'modelName': s.modelName,
            'title': s.title,
            'createdAt': s.createdAt.toIso8601String(),
            'lastUpdatedAt': s.lastUpdatedAt.toIso8601String(),
            'chats': sessionChats[s.id]
                    ?.map((c) => {
                          'id': c.id,
                          'message': c.message,
                          'isUserMessage': c.isUserMessage,
                          'timestamp': c.timestamp.toIso8601String(),
                          'isEdited': c.isEdited,
                          'originalMessage': c.originalMessage,
                        })
                    .toList() ??
                [],
          };
          return sessionData;
        }).toList(),
      };

      final jsonString = jsonEncode(data);
      await File(outputFile).writeAsString(jsonString, flush: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      if (!_isValidBackupFormat(data)) {
        throw 'Invalid backup file format';
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Import Data', style: GoogleFonts.getFont(Util.appFont)),
          content: Text(
            'This will replace all existing chats and settings. Are you sure?',
            style: GoogleFonts.getFont(Util.appFont),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.getFont(Util.appFont)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Import',
                  style: GoogleFonts.getFont(Util.appFont)
                      .copyWith(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Import settings
      final prefs = await SharedPreferences.getInstance();
      if (data['systemPrompt'] != null) {
        await prefs.setString('systemPrompt', data['systemPrompt']);
        _systemPromptController.text = data['systemPrompt'];
      }
      if (data['temperature'] != null) {
        await prefs.setDouble('temperature', data['temperature']);
        setState(() {
          _temperature = data['temperature'];
        });
      }

      objectbox.store.runInTransaction(TxMode.write, () {
        // Clear existing data
        _sessionBox.removeAll();
        _chatBox.removeAll();

        // Import sessions and their chats
        for (final sessionData in data['sessions']) {
          final session = ChatSession(
            modelName: sessionData['modelName'],
            title: sessionData['title'],
            createdAt: DateTime.parse(sessionData['createdAt']),
            lastUpdatedAt: DateTime.parse(sessionData['lastUpdatedAt']),
          );
          final newSessionId = _sessionBox.put(session);

          // Import chats for this session
          for (final chatData in sessionData['chats']) {
            final chat = Chat(
              message: chatData['message'],
              isUserMessage: chatData['isUserMessage'],
              timestamp: DateTime.parse(chatData['timestamp']),
              isEdited: chatData['isEdited'] ?? false,
              originalMessage: chatData['originalMessage'],
            );
            chat.chatSession.target = session;
            _chatBox.put(chat);
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data imported successfully')),
        );
        // Pop back to chat page and force reload
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing data: $e')),
        );
      }
    }
  }

  bool _isValidBackupFormat(Map<String, dynamic> data) {
    return data.containsKey('sessions') &&
        data['sessions'] is List &&
        (data['systemPrompt'] == null || data['systemPrompt'] is String) &&
        (data['temperature'] == null || data['temperature'] is num);
  }

  Future<void> _uploadToGoogleDrive() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final client = GoogleAuthClient(auth.accessToken!);
      final driveApi = drive.DriveApi(client);

      // Get system prompt
      final prefs = await SharedPreferences.getInstance();
      final systemPrompt = prefs.getString('systemPrompt');

      final sessions = _sessionBox.getAll();
      final chats = _chatBox.getAll();

      final data = {
        'systemPrompt': systemPrompt,
        'sessions': sessions
            .map((s) => {
                  'id': s.id,
                  'modelName': s.modelName,
                  'title': s.title,
                  'createdAt': s.createdAt.toIso8601String(),
                  'lastUpdatedAt': s.lastUpdatedAt.toIso8601String(),
                })
            .toList(),
        'chats': chats
            .map((c) => {
                  'id': c.id,
                  'message': c.message,
                  'isUserMessage': c.isUserMessage,
                  'timestamp': c.timestamp.toIso8601String(),
                  'sessionId': c.chatSession.target?.id,
                  'isEdited': c.isEdited,
                  'originalMessage': c.originalMessage,
                })
            .toList(),
      };
      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);

      final driveFile = drive.File()
        ..name = 'chat_backup.json'
        ..mimeType = 'application/json';

      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded to Google Drive successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading to Google Drive: $e')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data', style: GoogleFonts.getFont(Util.appFont)),
        content: Text(
          'This will permanently delete all chat sessions and messages. This action cannot be undone. Are you sure?',
          style: GoogleFonts.getFont(Util.appFont),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.getFont(Util.appFont)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete All',
                style: GoogleFonts.getFont(Util.appFont)
                    .copyWith(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        objectbox.store.runInTransaction(TxMode.write, () {
          _sessionBox.removeAll();
          _chatBox.removeAll();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('All data cleared successfully')),
          );
          // Pop back to chat page and force reload
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing data: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.getFont(Util.appFont,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white70)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800), // Limit width for desktop
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 2,
              child: ListView(
                padding: EdgeInsets.all(24),
                children: [
                  // App Font Section
                  _buildSectionTitle('Appearance'),
                  Card(
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('App Font',
                              style: GoogleFonts.getFont(Util.appFont)
                                  .copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedFont,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                            items: [
                              'Roboto',
                              'Lato',
                              'Open Sans',
                              'Montserrat',
                              'Source Code Pro',
                              'Ubuntu',
                            ]
                                .map((font) => DropdownMenuItem(
                                      value: font,
                                      child: Text(font,
                                          style: GoogleFonts.getFont(font)),
                                    ))
                                .toList(),
                            onChanged: (font) {
                              if (font != null) _saveFont(font);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // AI Settings Section
                  _buildSectionTitle('AI Settings'),
                  Card(
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('System Prompt',
                              style: GoogleFonts.getFont(Util.appFont)
                                  .copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          TextField(
                            controller: _systemPromptController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  'Enter system prompt to define AI behavior...',
                              hintStyle: GoogleFonts.getFont(Util.appFont),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                            style: GoogleFonts.getFont(Util.appFont),
                            onChanged: (value) async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString('systemPrompt', value);
                            },
                          ),
                          SizedBox(height: 24),
                          Text('AI Temperature',
                              style: GoogleFonts.getFont(Util.appFont)
                                  .copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _temperature,
                                  min: 0.0,
                                  max: 2.0,
                                  divisions: 20,
                                  label: _temperature.toStringAsFixed(1),
                                  onChanged: _saveTemperature,
                                ),
                              ),
                              SizedBox(width: 16),
                              Container(
                                width: 50,
                                child: Text(
                                  _temperature.toStringAsFixed(1),
                                  style: GoogleFonts.getFont(Util.appFont),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Lower values make responses more focused and deterministic. Higher values make responses more creative and varied.',
                            style: GoogleFonts.getFont(Util.appFont)
                                .copyWith(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Data Management Section
                  _buildSectionTitle('Data Management'),
                  Card(
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    child: Column(
                      children: [
                        _buildActionTile(
                          'Export Data',
                          Icons.upload,
                          () => _exportDataWithLocation(context),
                        ),
                        Divider(height: 1),
                        _buildActionTile(
                          'Import Data',
                          Icons.download,
                          _importData,
                        ),
                        Divider(height: 1),
                        _buildActionTile(
                          'Clear All Data',
                          Icons.delete_forever,
                          _clearAllData,
                        ),
                        // Divider(height: 1),
                        // _buildActionTile(
                        //   'Backup to Google Drive',
                        //   Icons.cloud_upload,
                        //   _uploadToGoogleDrive,
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.getFont(Util.appFont).copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: GoogleFonts.getFont(Util.appFont)),
      leading: Icon(icon),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      hoverColor: Colors.grey.withOpacity(0.1),
    );
  }
}

class GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}
