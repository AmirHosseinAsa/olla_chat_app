import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olla_chat_app/utils/util.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ChatBubble extends StatefulWidget {
  const ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.isStreaming = false,
    this.isEdited = false,
    this.isSpeaking = false,
    this.onEdit,
    this.onRegenerate,
    required this.onCopy,
    required this.onSpeak,
    this.showThinking = true,
    this.showThinkingIndicator = false,
    this.onStopGeneration,
  }) : super(key: key);

  final String message;
  final bool isUser;
  final bool isStreaming;
  final bool isEdited;
  final bool isSpeaking;
  final Function(String)? onEdit;
  final VoidCallback? onRegenerate;
  final VoidCallback onCopy;
  final VoidCallback onSpeak;
  final bool showThinking;
  final bool showThinkingIndicator;
  final VoidCallback? onStopGeneration;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildMessageContent() {
    if (_isEditing && widget.isUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Color(0xFF2D2E32).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(0xFF8B5CF6).withOpacity(0.2),
              ),
            ),
            child: TextField(
              controller: _editController,
              style: GoogleFonts.getFont(Util.appFont).copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: null,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Edit message...',
                hintStyle: GoogleFonts.getFont(Util.appFont).copyWith(
                  color: Colors.white38,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.check, color: Color(0xFF8B5CF6)),
                onPressed: () {
                  if (_editController.text != widget.message) {
                    widget.onEdit?.call(_editController.text);
                  }
                  setState(() {
                    _isEditing = false;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _editController.text = widget.message;
                    _isEditing = false;
                  });
                },
              ),
            ],
          ),
        ],
      );
    }

    return _buildMessageText(widget.message);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isUser
                      ? Colors.transparent
                      : Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isUser
                        ? Color(0xFF2D2E32)
                        : Color(0xFF8B5CF6).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: widget.isUser
                      ? Icon(Icons.person_outline,
                          size: 20, color: Colors.white70)
                      : Icon(Icons.auto_awesome,
                          size: 20, color: Color(0xFF8B5CF6)),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isUser ? 'You' : 'OllaChat',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (widget.isEdited)
                    Text(
                      '(edited)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
              if (widget.isStreaming && !widget.isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildThinkingAnimation(),
                ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            margin: EdgeInsets.only(left: 48),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? (widget.isUser
                      ? Color(0xFF2D2E32).withOpacity(0.3)
                      : Color(0xFF1E1B2C).withOpacity(0.4))
                  : (widget.isUser ? Colors.grey.shade100 : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? (widget.isUser
                        ? Color(0xFF2D2E32)
                        : Color(0xFF8B5CF6).withOpacity(0.2))
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: _buildMessageContent(),
                ),
                _buildActionBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingAnimation() {
    return SpinKitThreeBounce(
      color: const Color(0xFF8B5CF6).withOpacity(0.5),
      size: 20.0,
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2D2E32)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isUser && !_isEditing)
            IconButton(
              icon: Icon(Icons.edit, size: 16),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              color: Colors.white70,
            ),
          IconButton(
            icon: Icon(Icons.copy, size: 16),
            onPressed: widget.onCopy,
            color: Colors.white70,
          ),
          if (!widget.isUser)
            IconButton(
              icon: Icon(
                widget.isSpeaking ? Icons.stop : Icons.volume_up,
                size: 16,
              ),
              onPressed: widget.onSpeak,
              color: Colors.white70,
            ),
          if (widget.onRegenerate != null)
            IconButton(
              icon: Icon(Icons.refresh, size: 16),
              onPressed: widget.onRegenerate,
              color: Colors.white70,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageText(String message) {
    // If not showing thinking content, strip out the thinking tags and content first
    if (!widget.showThinking) {
      // Handle both complete and incomplete thinking tags during streaming
      message = message.replaceAll(
          RegExp(r'<think>.*?(?:</think>|$)', dotAll: true), '');
      // Also remove any empty lines that might be left
      message = message
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .join('\n');
    }

    // Then handle the remaining content
    if (widget.showThinking &&
        (message.contains('<think>') || message.contains('</think>'))) {
      return _buildThinkingContent(message);
    }

    // Check if message contains code block
    if (message.contains('```')) {
      return _buildMessageWithCode(message);
    }

    // Otherwise parse markdown
    return _buildMarkdownMessage(message);
  }

  Widget _buildMessageWithCode(String code) {
    final parts = code.split(RegExp(r'```(\w+)?\n'));
    final List<Widget> widgets = [];

    for (var i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Regular text
        if (parts[i].trim().isNotEmpty) {
          widgets.add(_buildMarkdownMessage(parts[i]));
        }
      } else {
        // Code block
        widgets.add(_buildCodeBlock(parts[i]));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF16161A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF2D2E32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code header with language and copy button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF2D2E32),
                ),
              ),
            ),
            child: Row(
              children: [
                // Code icon
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.code,
                    size: 14,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Code',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.copy, size: 16),
                  onPressed: () => Clipboard.setData(ClipboardData(text: code)),
                  color: Colors.white70,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          // Code content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: EdgeInsets.all(16),
              child: SelectableText(
                code,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownMessage(String message) {
    final List<InlineSpan> spans = [];
    final lines = message.split('\n');

    // Define consistent colors and styles
    final Color textColor = Colors.white.withOpacity(0.78);
    final Color headerColor = Colors.white.withOpacity(0.92);
    final Color tableHeaderColor = Colors.white.withOpacity(0.85);
    final Color tableBorderColor = Colors.white.withOpacity(0.2);

    bool isInTable = false;
    List<String> tableHeaders = [];
    List<List<String>> tableRows = [];

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];

      // Handle title without separator
      if (line.startsWith('Title: ')) {
        spans.add(TextSpan(
          text: line + '\n',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: headerColor,
            letterSpacing: -0.5,
          ),
        ));
        continue;
      }

      // Handle section headers (remove ### and :)
      if (line.startsWith('### ')) {
        line = line.substring(4);
        if (line.endsWith(':')) {
          line = line.substring(0, line.length - 1);
        }
        spans.add(TextSpan(
          text: '\n' + line + '\n',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.8,
            color: headerColor,
            letterSpacing: -0.3,
          ),
        ));
        continue;
      }

      // Skip separator lines
      if (line.startsWith('─') || line.startsWith('—')) {
        continue;
      }

      // Handle table
      if (line.startsWith('|')) {
        if (!isInTable) {
          isInTable = true;
          tableHeaders = _parseTableRow(line);
          continue;
        }

        // Skip separator row with dashes
        if (line.contains('---')) continue;

        tableRows.add(_parseTableRow(line));

        // If next line is not part of table, render it
        if (i == lines.length - 1 || !lines[i + 1].startsWith('|')) {
          spans.add(_buildTableSpan(
            tableHeaders,
            tableRows,
            tableHeaderColor,
            textColor,
            tableBorderColor,
          ));
          isInTable = false;
          tableHeaders = [];
          tableRows = [];

          // Add extra spacing after table if next line is not a separator
          if (i < lines.length - 1 && !lines[i + 1].startsWith('---')) {
            spans.add(const TextSpan(text: '\n'));
          }
          continue;
        }
        continue;
      }

      // Handle section separators (---)
      if (line.startsWith('---')) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Handle bold text without showing **
      final boldPattern = RegExp(r'\*\*(.*?)\*\*');
      var currentIndex = 0;
      var modifiedLine = line;
      var matches = boldPattern.allMatches(line).toList();

      if (matches.isNotEmpty) {
        for (var match in matches) {
          if (match.start > currentIndex) {
            spans.add(TextSpan(
              text: modifiedLine.substring(currentIndex, match.start),
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: textColor,
              ),
            ));
          }

          spans.add(TextSpan(
            text: match.group(1), // Only the text between **
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: headerColor,
            ),
          ));

          currentIndex = match.end;
        }

        if (currentIndex < line.length) {
          spans.add(TextSpan(
            text: line.substring(currentIndex) + '\n',
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: textColor,
            ),
          ));
        }
      } else {
        spans.add(TextSpan(
          text: line + '\n',
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.6,
            color: textColor,
          ),
        ));
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: GoogleFonts.inter(height: 1.5),
    );
  }

  List<String> _parseTableRow(String line) {
    return line
        .split('|')
        .skip(1)
        .take(line.split('|').length - 2)
        .map((cell) => cell.trim())
        .toList();
  }

  TextSpan _buildTableSpan(
    List<String> headers,
    List<List<String>> rows,
    Color headerColor,
    Color textColor,
    Color borderColor,
  ) {
    List<InlineSpan> tableSpans = [
      const TextSpan(text: '\n\n')
    ]; // Extra spacing before table

    // Calculate column widths based on content
    List<int> columnWidths = List.filled(headers.length, 0);

    // Get max width for each column including headers
    for (var i = 0; i < headers.length; i++) {
      columnWidths[i] = headers[i].length;
      for (var row in rows) {
        if (i < row.length && row[i].length > columnWidths[i]) {
          columnWidths[i] = row[i].length;
        }
      }
      // Add padding
      columnWidths[i] += 4;
    }

    // Add headers
    for (var i = 0; i < headers.length; i++) {
      tableSpans.add(TextSpan(
        text: headers[i].padRight(columnWidths[i]),
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: headerColor,
          height: 1.8,
        ),
      ));
    }
    tableSpans.add(const TextSpan(text: '\n'));

    // Add rows with proper spacing
    for (var row in rows) {
      // Add some vertical spacing between rows
      tableSpans.add(const TextSpan(text: '\n'));

      for (var i = 0; i < row.length; i++) {
        tableSpans.add(TextSpan(
          text: row[i].padRight(columnWidths[i]),
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.6,
            color: textColor,
          ),
        ));
      }
    }

    // Add extra spacing after table
    tableSpans.add(const TextSpan(text: '\n'));
    return TextSpan(children: tableSpans);
  }

  Widget _buildThinkingContent(String message) {
    final parts = message.split(RegExp(r'<think>|</think>'));
    final List<Widget> widgets = [];

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].trim().isEmpty) continue;

      if (i % 2 == 0) {
        // Regular text
        widgets.add(_buildMarkdownMessage(parts[i]));
      } else {
        // Thinking content
        widgets.add(
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF8B5CF6).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(0xFF8B5CF6).withOpacity(0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.psychology,
                  size: 16,
                  color: Color(0xFF8B5CF6).withOpacity(0.5),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    parts[i].trim(),
                    style: GoogleFonts.getFont(
                      Util.appFont,
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

// Add these extensions to help with null safety
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
