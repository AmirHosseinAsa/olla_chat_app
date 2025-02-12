import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/util.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const SettingsSection({
    Key? key,
    required this.title,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.getFont(Util.appFont).copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SettingsActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const SettingsActionTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: GoogleFonts.getFont(Util.appFont)),
      leading: Icon(icon),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      hoverColor: Colors.grey.withOpacity(0.1),
    );
  }
}

class SettingsSlider extends StatelessWidget {
  final String title;
  final String description;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int divisions;

  const SettingsSlider({
    Key? key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.getFont(Util.appFont)
              .copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: value.toStringAsFixed(1),
                onChanged: onChanged,
              ),
            ),
            SizedBox(width: 16),
            Container(
              width: 50,
              child: Text(
                value.toStringAsFixed(1),
                style: GoogleFonts.getFont(Util.appFont),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        Text(
          description,
          style: GoogleFonts.getFont(Util.appFont)
              .copyWith(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class SettingsTextField extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const SettingsTextField({
    Key? key,
    required this.title,
    required this.hintText,
    required this.controller,
    this.maxLines = 1,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.getFont(Util.appFont)
              .copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.getFont(Util.appFont),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          style: GoogleFonts.getFont(Util.appFont),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class SettingsDropdown<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;

  const SettingsDropdown({
    Key? key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.getFont(Util.appFont)
              .copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(itemLabel(item),
                        style: GoogleFonts.getFont(Util.appFont)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
