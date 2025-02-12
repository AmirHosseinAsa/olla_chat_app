import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ollama_dart/ollama_dart.dart';
import 'package:olla_chat_app/utils/util.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  _ModelsPageState createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage> {
  final OllamaClient _ollamaClient = OllamaClient(
    baseUrl: 'http://localhost:11434/api',
  );
  List<Model> _downloadedModels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedModels();
  }

  Future<void> _loadDownloadedModels() async {
    setState(() => _isLoading = true);
    try {
      final response = await _ollamaClient.listModels();
      setState(() {
        _downloadedModels = response.models?.cast<Model>() ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading models: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteModel(String modelName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Model', style: GoogleFonts.getFont(Util.appFont)),
        content: Text(
          'Are you sure you want to delete $modelName?\n\nCommand to run in terminal:\nollama rm $modelName',
          style: GoogleFonts.getFont(Util.appFont),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.getFont(Util.appFont)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _downloadedModels.removeWhere((m) => m.model == modelName);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Please run the command in your terminal to complete deletion')),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1E1B2C),
        elevation: 0,
        title: Text(
          'Ollama Models',
          style: GoogleFonts.getFont(Util.appFont,
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Downloaded Models'),
                            Card(
                              elevation: 0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.3),
                              child: Column(
                                children: [
                                  if (_downloadedModels.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'No models downloaded yet',
                                        style:
                                            GoogleFonts.getFont(Util.appFont),
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: _downloadedModels.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final model = _downloadedModels[index];
                                        return ListTile(
                                          title: Text(
                                            model.model ?? 'Unknown Model',
                                            style: GoogleFonts.getFont(
                                                Util.appFont),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _deleteModel(model.model!),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 32),
                            _buildSectionTitle('How to Add New Models'),
                            Card(
                              elevation: 0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.3),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStep(
                                      '1. Visit the Ollama Model Library:',
                                      trailing: ElevatedButton.icon(
                                        onPressed: () => _launchUrl(
                                            'https://ollama.ai/library'),
                                        icon: Icon(
                                          Icons.open_in_new,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        label: Text('Open Model Library'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF8B5CF6),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    _buildStep(
                                        '2. Find a model you want to use'),
                                    _buildStep(
                                        '3. Copy the command (e.g., "ollama run mistral")'),
                                    _buildStep(
                                        '4. Open your terminal and paste the command'),
                                    _buildStep(
                                        '5. After download completes, refresh this page'),
                                    SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xFF1E1B2C),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Color(0xFF2D2E32),
                                        ),
                                      ),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.text,
                                        child: TextField(
                                          maxLines: null,
                                          minLines: 3,
                                          readOnly: true,
                                          controller: TextEditingController(
                                            text:
                                                'Example command:\nollama run mistral',
                                          ),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 14,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.all(16),
                                            suffixIcon: IconButton(
                                              icon: Icon(Icons.copy),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text:
                                                        'ollama run mistral'));
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Command copied to clipboard'),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadDownloadedModels,
        label: Text('Refresh'),
        icon: Icon(Icons.refresh),
        backgroundColor: Color(0xFF8B5CF6),
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

  Widget _buildStep(String text, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.getFont(Util.appFont).copyWith(
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
