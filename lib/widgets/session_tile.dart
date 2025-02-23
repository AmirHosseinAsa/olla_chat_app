import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/util.dart';
import '../models/chat.dart';

class SessionTile extends StatelessWidget {
  final ChatSession session;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(BuildContext, ChatSession, Offset) onContextMenu;

  const SessionTile({
    Key? key,
    required this.session,
    required this.isSelected,
    required this.onTap,
    required this.onContextMenu,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onSecondaryTapUp: (details) =>
            onContextMenu(context, session, details.globalPosition),
        onLongPress: () => onContextMenu(
          context,
          session,
          Offset(
            MediaQuery.of(context).size.width / 3,
            MediaQuery.of(context).size.height / 3,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color(0xFF8B5CF6).withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Color(0xFF8B5CF6).withOpacity(0.15)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFF8B5CF6).withOpacity(0.1)
                          : Color(0xFF2D2E32).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? Color(0xFF8B5CF6).withOpacity(0.2)
                            : Color(0xFF2D2E32).withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.chat_outlined,
                      size: 14,
                      color: isSelected
                          ? Color(0xFF8B5CF6).withOpacity(0.8)
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.getFont(Util.appFont).copyWith(
                            fontSize: 13,
                            color: isSelected
                                ? Color(0xFF8B5CF6).withOpacity(0.9)
                                : Colors.white.withOpacity(0.8),
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatDate(session.lastUpdatedAt),
                          style: GoogleFonts.getFont(Util.appFont).copyWith(
                            fontSize: 11,
                            color: isSelected
                                ? Color(0xFF8B5CF6).withOpacity(0.5)
                                : Colors.white.withOpacity(0.3),
                          ),
                        ),
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
}
