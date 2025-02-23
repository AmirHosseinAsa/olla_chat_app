import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/util.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isStreaming;
  final List<PlatformFile> selectedFiles;
  final Function(String) onSend;
  final VoidCallback onPickFiles;
  final Function(PlatformFile) onRemoveFile;
  final VoidCallback? onStopGeneration;
  final Function(List<PlatformFile>)? onFilesDropped;

  ChatInput({
    Key? key,
    required this.controller,
    required this.isStreaming,
    required this.selectedFiles,
    required this.onSend,
    required this.onPickFiles,
    required this.onRemoveFile,
    this.onStopGeneration,
    this.onFilesDropped,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late final FocusNode _focusNode;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _isImageFile(String extension) {
    final imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
    return imageExtensions.contains(extension.toLowerCase());
  }

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
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(file.path!),
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 16),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                  onPressed: () => widget.onRemoveFile(file),
                ),
              ),
            ),
          ],
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
        onDeleted: () => widget.onRemoveFile(file),
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

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          if (widget.isStreaming) {
            widget.onStopGeneration?.call();
          }
        }
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            HardwareKeyboard.instance.isControlPressed &&
            !widget.isStreaming) {
          if (widget.controller.text.trim().isNotEmpty) {
            widget.onSend(widget.controller.text);
            widget.controller.clear();
          }
        }
      },
      child: DropTarget(
        onDragDone: (detail) async {
          final files = detail.files;
          final platformFiles = <PlatformFile>[];

          for (final file in files) {
            try {
              final path = file.path;
              final name = file.name;
              final bytes = await File(path).readAsBytes();

              platformFiles.add(PlatformFile(
                path: path,
                name: name,
                size: bytes.length,
                bytes: bytes,
              ));
            } catch (e) {
              print('Error processing dropped file: $e');
            }
          }

          if (platformFiles.isNotEmpty && widget.onFilesDropped != null) {
            widget.onFilesDropped!(platformFiles);
          }
        },
        onDragEntered: (detail) {
          setState(() => _isDragging = true);
        },
        onDragExited: (detail) {
          setState(() => _isDragging = false);
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width / 1.22,
              decoration: BoxDecoration(
                color: _isDragging
                    ? Color(0xFF8B5CF6).withOpacity(0.1)
                    : Color(0xFF1E1B2C).withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDragging
                      ? Color(0xFF8B5CF6).withOpacity(0.3)
                      : Color(0xFF2D2E32).withOpacity(0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8B5CF6).withOpacity(0.05),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.selectedFiles.isNotEmpty)
                    Container(
                      padding:
                          EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 2),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: widget.selectedFiles
                              .map((file) => _buildFilePreview(file))
                              .toList(),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.attach_file,
                          color: Colors.white.withOpacity(0.4),
                          size: 20,
                        ),
                        onPressed: widget.onPickFiles,
                        splashRadius: 20,
                        tooltip: 'Attach files',
                      ),
                      Expanded(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: TextField(
                            controller: widget.controller,
                            decoration: InputDecoration(
                              hintText: _isDragging
                                  ? 'Drop files here...'
                                  : 'Type a message...',
                              hintStyle:
                                  GoogleFonts.getFont(Util.appFont).copyWith(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 14,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: InputBorder.none,
                            ),
                            cursorColor: Color(0xFF8B5CF6),
                            keyboardType: TextInputType.multiline,
                            maxLines: 5,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            style: GoogleFonts.getFont(Util.appFont).copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        child: IconButton(
                          tooltip: widget.isStreaming
                              ? 'Stop (Esc)'
                              : 'Send (Ctrl+Enter)',
                          icon: Icon(
                            widget.isStreaming ? Icons.stop : Icons.send,
                            color: widget.controller.text.trim().isNotEmpty
                                ? Color(0xFF8B5CF6)
                                : Colors.white.withOpacity(0.3),
                            size: 20,
                          ),
                          onPressed: widget.isStreaming
                              ? widget.onStopGeneration
                              : () {
                                  if (widget.controller.text
                                      .trim()
                                      .isNotEmpty) {
                                    widget.onSend(widget.controller.text);
                                    widget.controller.clear();
                                  }
                                },
                          splashRadius: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
