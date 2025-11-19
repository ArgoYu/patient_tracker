import 'package:flutter/material.dart';

class ChatSettingsPage extends StatelessWidget {
  const ChatSettingsPage({
    super.key,
    required this.title,
    required this.entries,
    this.footer,
  });

  final String title;
  final List<ChatSettingEntry> entries;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: entries.length + (footer == null ? 0 : 1),
        separatorBuilder: (_, index) {
          if (footer != null && index == entries.length - 1) {
            return const SizedBox(height: 24);
          }
          return const Divider(height: 0);
        },
        itemBuilder: (context, index) {
          if (footer != null && index == entries.length) {
            return footer!;
          }
          final entry = entries[index];
          return ListTile(
            leading: Icon(entry.icon),
            title: Text(entry.title),
            subtitle: entry.subtitle == null ? null : Text(entry.subtitle!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pop(entry.key),
          );
        },
      ),
    );
  }
}

class ChatSettingEntry {
  const ChatSettingEntry({
    required this.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final String key;
  final IconData icon;
  final String title;
  final String? subtitle;
}

class ChatMediaItem {
  const ChatMediaItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class ChatMediaGalleryPage extends StatelessWidget {
  const ChatMediaGalleryPage({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<ChatMediaItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: items.isEmpty
          ? const Center(child: Text('No shared media yet.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening ${item.title}...')),
                    );
                  },
                );
              },
            ),
    );
  }
}

class ChatPreferenceOption {
  ChatPreferenceOption({
    required this.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
  });

  final String key;
  final String title;
  final String? subtitle;
  final IconData icon;
  bool value;
}

class ChatPreferencesPage extends StatefulWidget {
  const ChatPreferencesPage({
    super.key,
    required this.title,
    required this.options,
  });

  final String title;
  final List<ChatPreferenceOption> options;

  @override
  State<ChatPreferencesPage> createState() => _ChatPreferencesPageState();
}

class _ChatPreferencesPageState extends State<ChatPreferencesPage> {
  late final List<ChatPreferenceOption> _options;

  @override
  void initState() {
    super.initState();
    _options = widget.options.map((opt) => ChatPreferenceOption(
          key: opt.key,
          title: opt.title,
          subtitle: opt.subtitle,
          icon: opt.icon,
          value: opt.value,
        )).toList();
  }

  void _toggle(int index, bool value) {
    setState(() => _options[index].value = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              {for (final opt in _options) opt.key: opt.value},
            ),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final opt = _options[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: SwitchListTile.adaptive(
              secondary: Icon(opt.icon),
              title: Text(opt.title),
              subtitle: opt.subtitle == null ? null : Text(opt.subtitle!),
              value: opt.value,
              onChanged: (value) => _toggle(index, value),
            ),
          );
        },
      ),
    );
  }
}
