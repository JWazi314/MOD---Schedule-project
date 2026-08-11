import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback onResetDay;
  final VoidCallback onResetAll;

  const SettingsPage({
    super.key,
    required this.onResetDay,
    required this.onResetAll,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Profile', icon: Icons.person),
              _SettingsCard(
                borderColor: Colors.amber,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  title: const Text(
                    'User',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('MOD player profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile editing is coming soon.'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              const _SectionTitle(
                title: 'Quest Management',
                icon: Icons.task_alt,
              ),
              _SettingsCard(
                borderColor: Colors.orange,
                child: ListTile(
                  leading: const Icon(
                    Icons.restart_alt,
                    color: Colors.orange,
                  ),
                  title: const Text('Reset Daily Quests'),
                  subtitle: const Text(
                    'Mark every quest as incomplete while keeping rewards.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showResetDayConfirmation(context),
                ),
              ),
              const SizedBox(height: 22),
              const _SectionTitle(title: 'Data', icon: Icons.storage),
              _SettingsCard(
                borderColor: Colors.green,
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.save, color: Colors.green),
                      title: Text('Automatic Local Saving'),
                      subtitle: Text(
                        'Tasks, inventory, completion status, currency, and XP '
                        'are saved.',
                      ),
                      trailing: Icon(Icons.check_circle, color: Colors.green),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      title: const Text('Reset All Progress'),
                      subtitle: const Text(
                        'Delete every quest and inventory item, then reset '
                        'currency and XP.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showResetAllConfirmation(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _SectionTitle(title: 'About', icon: Icons.info_outline),
              const _SettingsCard(
                borderColor: Colors.grey,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.apps, color: Colors.green),
                      title: Text('MOD'),
                      subtitle: Text(
                        'Complete real-life quests and grow your Mod.',
                      ),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.code, color: Colors.green),
                      title: Text('Version'),
                      trailing: Text('1.0.0'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResetDayConfirmation(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Daily Quests?'),
          content: const Text(
            'This marks every quest as incomplete. Gold, silver, and XP stay '
            'the same.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }

    onResetDay();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily quests were reset.')),
    );
  }

  Future<void> _showResetAllConfirmation(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset All Progress?'),
          content: const Text(
            'This deletes every quest and resets all gold, silver, and XP. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reset Everything'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }

    onResetAll();
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 21),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const _SettingsCard({required this.child, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(50, 50, 50, 50),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: 1.4),
      ),
      child: child,
    );
  }
}
