import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/preset_prompts.dart';
import '../utils/util.dart';

class PresetPromptsGrid extends StatelessWidget {
  final Function(String) onPromptSelected;

  const PresetPromptsGrid({
    super.key,
    required this.onPromptSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start a new conversation',
              style: GoogleFonts.getFont(
                Util.appFont,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a prompt or type your own message',
              style: GoogleFonts.getFont(
                Util.appFont,
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: presetPrompts
                  .map((prompt) => _buildPromptCard(prompt))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptCard(PresetPrompt prompt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onPromptSelected(prompt.prompt),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2C).withOpacity(0.3),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.08),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                prompt.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 12),
              Text(
                prompt.title,
                style: GoogleFonts.getFont(
                  Util.appFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                prompt.prompt,
                style: GoogleFonts.getFont(
                  Util.appFont,
                  fontSize: 12,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
