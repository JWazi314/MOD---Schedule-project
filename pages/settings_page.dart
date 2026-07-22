import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onResetDay;

  const SettingsPage({
    super.key,
    required this.onResetDay,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool dailyResetEnabled = true;
  bool darkModeEnabled = true;

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
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 20),

              const _SectionTitle(
                title: 'Profile',
                icon: Icons.person,
              ),
              _SettingsCard(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(
                      Icons.person,
                      color: Colors.black,
                    ),
                  ),
                  title: const Text(
                    'Your Mod',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Player profile and preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile editing coming soon.'),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 22),

              const _SectionTitle(
                title: 'Preferences',
                icon: Icons.tune,
              ),
              _SettingsCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications,
                        color: Colors.amber,
                      ),
                      title: const Text('Notifications'),
                      subtitle: const Text(
                        'Receive reminders for daily quests.',
                      ),
                      value: notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          notificationsEnabled = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.volume_up,
                        color: Colors.amber,
                      ),
                      title: const Text('Sound Effects'),
                      subtitle: const Text(
                        'Play sounds when quests are completed.',
                      ),
                      value: soundEnabled,
                      onChanged: (value) {
                        setState(() {
                          soundEnabled = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.refresh,
                        color: Colors.amber,
                      ),
                      title: const Text('Automatic Daily Reset'),
                      subtitle: const Text(
                        'Reset daily quests at the start of a new day.',
                      ),
                      value: dailyResetEnabled,
                      onChanged: (value) {
                        setState(() {
                          dailyResetEnabled = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.dark_mode,
                        color: Colors.amber,
                      ),
                      title: const Text('Dark Mode'),
                      subtitle: const Text(
                        'Use the dark MOD interface.',
                      ),
                      value: darkModeEnabled,
                      onChanged: (value) {
                        setState(() {
                          darkModeEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const _SectionTitle(
                title: 'Quest Management',
                icon: Icons.task_alt,
              ),
              _SettingsCard(
                child: ListTile(
                  leading: const Icon(
                    Icons.restart_alt,
                    color: Colors.orange,
                  ),
                  title: const Text('Reset Daily Quests'),
                  subtitle: const Text(
                    'Mark all daily quests as incomplete.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showResetConfirmation,
                ),
              ),

              const SizedBox(height: 22),

              const _SectionTitle(
                title: 'Data',
                icon: Icons.storage,
              ),
              _SettingsCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.cloud_sync,
                        color: Colors.lightBlueAccent,
                      ),
                      title: const Text('Sync Progress'),
                      subtitle: const Text(
                        'Cloud syncing will be available later.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cloud sync coming soon.'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.redAccent,
                      ),
                      title: const Text('Reset All Progress'),
                      subtitle: const Text(
                        'Delete quests, rewards, XP, and currency.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Full progress reset is not available yet.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const _SectionTitle(
                title: 'About',
                icon: Icons.info_outline,
              ),
              const _SettingsCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.apps,
                        color: Colors.amber,
                      ),
                      title: Text('MOD'),
                      subtitle: Text(
                        'Complete real-life quests and grow your Mod.',
                      ),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.code,
                        color: Colors.amber,
                      ),
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

  void _showResetConfirmation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Daily Quests?'),
          content: const Text(
            'This will mark all daily quests as incomplete. '
            'Your gold, silver, and XP will stay the same.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                widget.onResetDay();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Daily quests were reset.'),
                  ),
                );
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.amber,
            size: 21,
          ),
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

  const _SettingsCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2A1B3D),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Colors.white24,
        ),
      ),
      child: child,
    );
  }
}