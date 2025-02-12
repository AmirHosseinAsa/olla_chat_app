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
        color: Color(0xFF1E1B2C).withOpacity(0.9),
        border: Border(
          right: BorderSide(color: Color(0xFF2D2E32)),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withOpacity(0.1),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // New Chat Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: onNewChat,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF8B5CF6).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline,
                            color: Color(0xFF8B5CF6), size: 20),
                        SizedBox(width: 8),
                        Text('New Chat',
                            style: GoogleFonts.getFont(Util.appFont).copyWith(
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF2D2E32).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearch,
                    style: GoogleFonts.getFont(Util.appFont)
                        .copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      hintStyle: GoogleFonts.getFont(Util.appFont)
                          .copyWith(color: Colors.white38),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.white38, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    cursorColor: Color(0xFF8B5CF6),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Chat List
              Expanded(
                child: ListView.builder(
                  itemCount:
                      (isSearching ? filteredSessions : sessions).length +
                          (isLoadingMoreSessions ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index ==
                        (isSearching ? filteredSessions : sessions).length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final session =
                        isSearching ? filteredSessions[index] : sessions[index];
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
