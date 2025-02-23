import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/util.dart';
import '../models/chat.dart';
import 'session_tile.dart';
import 'dart:ui';

class ChatSidebar extends StatelessWidget {
  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final TextEditingController searchController;
  final bool isSearching;
  final List<ChatSession> filteredSessions;
  final bool isLoadingMoreSessions;
  final VoidCallback onNewChat;
  final Function(String) onSearch;
  final Function(ChatSession) onSelectSession;
  final Function(BuildContext, ChatSession, Offset) onSessionContextMenu;

  const ChatSidebar({
    Key? key,
    required this.sessions,
    required this.currentSession,
    required this.searchController,
    required this.isSearching,
    required this.filteredSessions,
    required this.isLoadingMoreSessions,
    required this.onNewChat,
    required this.onSearch,
    required this.onSelectSession,
    required this.onSessionContextMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Color(0xFF1E1B2C).withOpacity(0.7),
        border: Border(
          right: BorderSide(
            color: Color(0xFF2D2E32).withOpacity(0.5),
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: InkWell(
                  onTap: onNewChat,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFF8B5CF6).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF8B5CF6).withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF8B5CF6).withOpacity(0.8),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'New Chat',
                          style: GoogleFonts.getFont(Util.appFont).copyWith(
                            color: Color(0xFF8B5CF6).withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF2D2E32).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(0xFF2D2E32).withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearch,
                    style: GoogleFonts.getFont(Util.appFont).copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      hintStyle: GoogleFonts.getFont(Util.appFont).copyWith(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.3),
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    cursorColor: Color(0xFF8B5CF6),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  itemCount: (isSearching ? filteredSessions : sessions).length +
                      (isLoadingMoreSessions ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index ==
                        (isSearching ? filteredSessions : sessions).length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final session = isSearching
                        ? filteredSessions[index]
                        : sessions[index];
                    return SessionTile(
                      session: session,
                      isSelected: currentSession?.id == session.id,
                      onTap: () => onSelectSession(session),
                      onContextMenu: onSessionContextMenu,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
