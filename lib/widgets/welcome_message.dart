import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/util.dart';

class WelcomeMessage extends StatelessWidget {
  const WelcomeMessage({Key? key}) : super(key: key);

  Widget _buildFeatureCard(String title, String description, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1B2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF2D2E32),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Color(0xFF8B5CF6)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.getFont(
                    Util.appFont,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.getFont(
                    Util.appFont,
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: Color(0xFF8B5CF6),
            ),
            SizedBox(height: 24),
            Text(
              'Welcome to OllaChat',
              style: GoogleFonts.getFont(
                Util.appFont,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Your Local AI Assistant',
              style: GoogleFonts.getFont(
                Util.appFont,
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 32),
            _buildFeatureCard(
              'Privacy First',
              'All conversations stay on your device. No data sent to external servers.',
              Icons.security,
            ),
            _buildFeatureCard(
              'Powerful Models',
              'Access to state-of-the-art AI models running locally on your machine.',
              Icons.psychology,
            ),
            _buildFeatureCard(
              'Full Control',
              'Customize the AI behavior, temperature, and system prompts to your needs.',
              Icons.tune,
            ),
          ],
        ),
      ),
    );
  }
}
