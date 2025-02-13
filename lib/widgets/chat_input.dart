import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/util.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isStreaming;
  final List<PlatformFile> selectedFiles;
  final Function(String) onSend;
  final VoidCallback onPickFiles;
  final Function(PlatformFile) onRemoveFile;

  const ChatInput({
    Key? key,
    required this.controller,
    required this.isStreaming,
    required this.selectedFiles,
    required this.onSend,
    required this.onPickFiles,
    required this.onRemoveFile,
  }) : super(key: key);

  Widget _buildFilePreview(PlatformFile file) {
    if (_isImageFile(file.extension ?? '')) {
      return Container(
        width: 100,
        height: 100,
        margin: EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF2D2E32)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(file.path!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(right: 8, bottom: 8),
      child: Chip(
        label: Text(
          file.name,
          style: GoogleFonts.getFont(Util.appFont),
        ),
        onDeleted: () => onRemoveFile(file),
        backgroundColor: Color(0xFF2D2E32).withOpacity(0.3),
        side: BorderSide(color: Color(0xFF8B5CF6).withOpacity(0.2)),
        labelStyle: GoogleFonts.getFont(Util.appFont).copyWith(
          color: Colors.white.withOpacity(0.9),
          fontSize: 13,
        ),
        deleteIconColor: Colors.white70,
      ),
    );
  }

  bool _isImageFile(String extension) {
    final imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
    return imageExtensions.contains(extension.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: MediaQuery.of(context).size.width / 1.22,
        decoration: BoxDecoration(
          color: Color(0xFF1E1B2C).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF2D2E32),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8B5CF6).withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedFiles.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedFiles
                      .map((file) => _buildFilePreview(file))
                      .toList(),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.all(5),
                  child: IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.white70),
                    onPressed: isStreaming ? null : onPickFiles,
                  ),
                ),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height / 1.8,
                    ),
                    child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.enter &&
                              HardwareKeyboard.instance.isControlPressed) {
                            if (!isStreaming) {
                              onSend(controller.text);
                              controller.clear();
                            }
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Padding(
                          padding: EdgeInsets.all(3),
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: GoogleFonts.getFont(Util.appFont)
                                  .copyWith(color: Colors.white38),
                              contentPadding: EdgeInsets.all(16),
                              border: InputBorder.none,
                            ),
                            cursorColor: Color(0xFF8B5CF6),
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            minLines: 1,
                            textInputAction: TextInputAction.newline,
                            enabled: !isStreaming,
                            style: GoogleFonts.getFont(Util.appFont)
                                .copyWith(color: Colors.white70),
                          ),
                        )),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(5),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: isStreaming ? Colors.white10 : Colors.white38,
                    ),
                    onPressed: isStreaming
                        ? null
                        : () {
                            onSend(controller.text);
                            controller.clear();
                          },
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
