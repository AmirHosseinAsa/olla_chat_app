import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/util.dart';
import 'package:ollama_dart/ollama_dart.dart';

class ModelList extends StatelessWidget {
  final List<Model> models;
  final Function(String) onDeleteModel;

  const ModelList({
    Key? key,
    required this.models,
    required this.onDeleteModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.3),
      child: Column(
        children: [
          if (models.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No models downloaded yet',
                style: GoogleFonts.getFont(Util.appFont),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: models.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final model = models[index];
                return ListTile(
                  title: Text(
                    model.model ?? 'Unknown Model',
                    style: GoogleFonts.getFont(Util.appFont),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDeleteModel(model.model!),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class ModelInstructions extends StatelessWidget {
  final VoidCallback onOpenLibrary;
  final VoidCallback onCopyCommand;

  const ModelInstructions({
    Key? key,
    required this.onOpenLibrary,
    required this.onCopyCommand,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Card(
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
                onPressed: onOpenLibrary,
                icon: Icon(Icons.open_in_new, size: 16),
                label: Text('Open Model Library'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            _buildStep('2. Find a model you want to use'),
            _buildStep('3. Copy the command (e.g., "ollama pull mistral")'),
            _buildStep('4. Open your terminal and paste the command'),
            _buildStep('5. After download completes, refresh this page'),
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
                    text: 'Example command:\nollama pull mistral',
                  ),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: onCopyCommand,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
