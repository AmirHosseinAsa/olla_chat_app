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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.getFont(Util.appFont).copyWith(
                color: isSelected ? Color(0xFF8B5CF6) : Colors.white,
                fontSize: 13,
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
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
