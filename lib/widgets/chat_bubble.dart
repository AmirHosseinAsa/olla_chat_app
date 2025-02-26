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
  void didUpdateWidget(ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller text if message actually changed
    if (oldWidget.message != widget.message) {
      _editController.text = widget.message;
    }
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
            decoration: BoxDecoration(
              color: const Color(0xFF2D2E32).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
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
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Color(0xFF8B5CF6)),
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
                icon: const Icon(Icons.close, color: Colors.white70),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isUser
                      ? Colors.transparent
                      : const Color(0xFF8B5CF6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isUser
                        ? const Color(0xFF2D2E32).withOpacity(0.5)
                        : const Color(0xFF8B5CF6).withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: widget.isUser
                      ? Icon(Icons.person_outline,
                          size: 16, color: Colors.white.withOpacity(0.7))
                      : Icon(Icons.auto_awesome,
                          size: 16, color: const Color(0xFF8B5CF6).withOpacity(0.8)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.isUser ? 'You' : 'OllaChat',
                style: GoogleFonts.getFont(Util.appFont).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              if (widget.isEdited)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '(edited)',
                    style: GoogleFonts.getFont(Util.appFont).copyWith(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              if (widget.isStreaming && !widget.isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildThinkingAnimation(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: widget.isUser
                        ? const Color(0xFF2D2E32).withOpacity(0.2)
                        : const Color(0xFF1E1B2C).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isUser
                          ? const Color(0xFF2D2E32).withOpacity(0.3)
                          : const Color(0xFF8B5CF6).withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildMessageContent(),
                      ),
                      _buildActionBar(),
                    ],
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF2D2E32).withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isUser && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, size: 14),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              color: Colors.white.withOpacity(0.4),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            onPressed: widget.onCopy,
            color: Colors.white.withOpacity(0.4),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
          if (!widget.isUser)
            IconButton(
              icon: Icon(
                widget.isSpeaking ? Icons.stop : Icons.volume_up,
                size: 14,
              ),
              onPressed: widget.onSpeak,
              color: Colors.white.withOpacity(0.4),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
          if (widget.onRegenerate != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 14),
              onPressed: widget.onRegenerate,
              color: Colors.white.withOpacity(0.4),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
        ],
      ),
    );
  }

  // Memoize expensive widget builds for better performance
  final Map<String, Widget> _cachedWidgets = {};

  Widget _buildMessageText(String message) {
    // Simple cache for complex rendered messages to reduce rebuilds
    // Only cache non-streaming messages to prevent display issues
    if (!widget.isStreaming && _cachedWidgets.containsKey(message)) {
      return _cachedWidgets[message]!;
    }

    // For user messages, just show the raw text
    if (widget.isUser) {
      final result = SelectableText(
        message,
        style: GoogleFonts.getFont(Util.appFont).copyWith(
          fontSize: 15,
          height: 1.6,
          color: Colors.white.withOpacity(0.78),
        ),
      );
      
      if (!widget.isStreaming) {
        _cachedWidgets[message] = result;
      }
      
      return result;
    }

    // For bot messages, apply all the formatting
    if (!widget.showThinking) {
      message = message
          .replaceAll(
            RegExp(r'<think>.*?</think>|<think>.*',
                caseSensitive: false, dotAll: true),
            '',
          )
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
    }

    // First handle code blocks with triple backticks
    final codeBlockRegex = RegExp(r'```(?:\w+)?\s*\n?[\s\S]*?(?:```|$)');
    final parts = message.split(codeBlockRegex);
    final codeMatches = codeBlockRegex.allMatches(message).toList();

    final List<Widget> widgets = [];
    int matchIndex = 0;

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].trim().isNotEmpty) {
        // Handle non-code text (may contain inline backticks)
        if (parts[i].contains('|')) {
          widgets.add(_buildMessageWithTable(parts[i]));
        } else {
          // Convert single backticks to bold before passing to markdown
          var text = parts[i].replaceAllMapped(
              RegExp(r'`([^`]+)`'), (match) => '**${match.group(1)}**');

          if (widget.showThinking &&
              (text.contains('<think>') || text.contains('</think>'))) {
            widgets.add(_buildThinkingContent(text));
          } else {
            widgets.add(_buildMarkdownMessage(text.trim()));
          }
        }
      }

      // Handle code block if there is one
      if (matchIndex < codeMatches.length && i < parts.length - 1) {
        final codeBlock = codeMatches[matchIndex].group(0)!;
        // Multi-line code block
        final code = codeBlock
            .replaceAll(RegExp(r'^```\w*\s*\n?'), '') // Remove opening ```
            .replaceAll(
                RegExp(r'\n?```$'), '') // Remove closing ``` if it exists
            .trim();
        if (code.isNotEmpty) {
          widgets.add(_buildCodeBlock(code));
        }
        matchIndex++;
      }
    }

    final result = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
    
    // Only cache non-streaming messages
    if (!widget.isStreaming) {
      _cachedWidgets[message] = result;
    }
    
    return result;
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
                  style: GoogleFonts.getFont(Util.appFont).copyWith(
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
                style: GoogleFonts.getFont(Util.appFont).copyWith(
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

    for (var line in lines) {
      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Handle title without separator
      if (line.startsWith('Title: ')) {
        spans.add(TextSpan(
          text: line + '\n',
          style: GoogleFonts.getFont(Util.appFont).copyWith(
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
          style: GoogleFonts.getFont(Util.appFont).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.8,
            color: headerColor,
            letterSpacing: -0.3,
          ),
        ));
        continue;
      }

      // Handle bold text without showing **
      final boldPattern = RegExp(r'\*\*(.*?)\*\*');
      var currentIndex = 0;
      var matches = boldPattern.allMatches(line).toList();

      if (matches.isNotEmpty) {
        for (var match in matches) {
          // Add text before bold
          if (match.start > currentIndex) {
            spans.add(TextSpan(
              text: line.substring(currentIndex, match.start),
              style: GoogleFonts.getFont(Util.appFont).copyWith(
                fontSize: 15,
                height: 1.6,
                color: textColor,
              ),
            ));
          }

          // Add bold text
          spans.add(TextSpan(
            text: match.group(1), // Only the text between **
            style: GoogleFonts.getFont(Util.appFont).copyWith(
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: headerColor,
            ),
          ));

          currentIndex = match.end;
        }

        // Add remaining text after last bold
        if (currentIndex < line.length) {
          spans.add(TextSpan(
            text: line.substring(currentIndex) + '\n',
            style: GoogleFonts.getFont(Util.appFont).copyWith(
              fontSize: 15,
              height: 1.6,
              color: textColor,
            ),
          ));
        }
      } else {
        // No bold text in line
        spans.add(TextSpan(
          text: line + '\n',
          style: GoogleFonts.getFont(Util.appFont).copyWith(
            fontSize: 15,
            height: 1.6,
            color: textColor,
          ),
        ));
      }
    }

    return Container(
      width: double.infinity,
      child: SelectableText.rich(
        TextSpan(children: spans),
        style: GoogleFonts.getFont(Util.appFont).copyWith(height: 1.5),
        textAlign: TextAlign.left,
        enableInteractiveSelection: true,
      ),
    );
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

  Widget _buildMessageWithTable(String message) {
    final lines = message.split('\n');
    final List<Widget> widgets = [];
    List<String> tableLines = [];
    bool inTable = false;

    for (String line in lines) {
      if (line.trim().startsWith('|')) {
        inTable = true;
        tableLines.add(line);
      } else {
        if (inTable) {
          // Render collected table
          widgets.add(_buildTable(tableLines));
          tableLines = [];
          inTable = false;
        }
        if (line.trim().isNotEmpty) {
          widgets.add(_buildMarkdownMessage(line));
        }
      }
    }

    // Handle table at end of message
    if (tableLines.isNotEmpty) {
      widgets.add(_buildTable(tableLines));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTable(List<String> tableLines) {
    try {
      final rows = tableLines
          .where((line) => line.trim().startsWith('|') && !line.contains('---'))
          .map((line) {
        final cells = line
            .split('|')
            .skip(1)
            .take(line.split('|').length - 2)
            .map((cell) => cell.trim())
            .toList();
        return cells;
      }).toList();

      if (rows.isEmpty) return SizedBox();

      final headers = rows.removeAt(0);

      // During streaming, ensure all rows have same number of cells as headers
      final normalizedRows = rows.map((row) {
        if (row.length < headers.length) {
          return [...row, ...List.filled(headers.length - row.length, '')];
        } else if (row.length > headers.length) {
          return row.take(headers.length).toList();
        }
        return row;
      }).toList();

      return Container(
        margin: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
            columns: headers
                .map((header) => DataColumn(
                      label: SelectableText(
                        header,
                        style: GoogleFonts.getFont(Util.appFont).copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ))
                .toList(),
            rows: normalizedRows
                .map((row) => DataRow(
                      cells: row
                          .map((cell) => DataCell(
                                SelectableText(
                                  cell,
                                  style: GoogleFonts.getFont(Util.appFont).copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ))
                          .toList(),
                    ))
                .toList(),
          ),
        ),
      );
    } catch (e) {
      // Fallback to text representation during streaming
      return SelectableText(
        tableLines.join('\n'),
        style: GoogleFonts.getFont(Util.appFont).copyWith(
          fontSize: 13,
          height: 1.5,
          color: Colors.white.withOpacity(0.9),
        ),
      );
    }
  }
}
