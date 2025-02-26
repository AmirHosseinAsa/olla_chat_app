class PresetPrompt {
  final String title;
  final String prompt;
  final String icon;

  const PresetPrompt({
    required this.title,
    required this.prompt,
    required this.icon,
  });
}

final List<PresetPrompt> presetPrompts = [
  PresetPrompt(
    title: 'Code Review',
    prompt:
        'Please review this code and suggest improvements for better performance, readability, and best practices:',
    icon: '🔍',
  ),
  PresetPrompt(
    title: 'Explain Code',
    prompt:
        'Please explain how this code works in simple terms, breaking down its main components and functionality:\n\n',
    icon: '📚',
  ),
  PresetPrompt(
    title: 'Debug Help',
    prompt:
        'I need help debugging this code. Here\'s what\'s happening and what I\'ve tried so far:\n\n',
    icon: '🐛',
  ),
  PresetPrompt(
    title: 'Writing Assistant',
    prompt: 'Help me write clear and professional content for:\n',
    icon: '✍️',
  ),
  PresetPrompt(
    title: 'Brainstorm Ideas',
    prompt: 'Let\'s brainstorm creative ideas for:\n',
    icon: '💡',
  ),
  PresetPrompt(
    title: 'Data Analysis',
    prompt: 'Help me analyze this data and extract meaningful insights:\n\n',
    icon: '📊',
  ),
  PresetPrompt(
    title: 'Refine Email',
    prompt:
        'Please help me refine this email to make it more professional and effective while maintaining its core message:\n\n',
    icon: '📧',
  ),
  PresetPrompt(
    title: 'Text Summary',
    prompt:
        'Please provide a clear and concise summary of the following text while keeping the important points:\n\n',
    icon: '📝',
  ),
];
