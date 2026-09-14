import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mod_appearance.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/mod_portrait.dart';

/// First run flow. Shown until a Mod exists, then never again.
class ModCreationPage extends StatefulWidget {
  const ModCreationPage({super.key});

  @override
  State<ModCreationPage> createState() => _ModCreationPageState();
}

class _ModCreationPageState extends State<ModCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _appearanceId = modAppearances.first.id;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createMod() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<GameState>().createMod(
      name: _nameController.text,
      appearanceId: _appearanceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = appearanceById(_appearanceId);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Your Mod',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your Mod grows stronger every time you finish a real task.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 26),

                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.panel,
                      borderRadius: AppTheme.borderRadius,
                      border: Border.all(color: selected.color, width: 2),
                    ),
                    child: Center(
                      child: ModPortrait(
                        appearanceId: selected.id,
                        size: 128,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Mod Name',
                      hintText: 'What should we call your Mod?',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'give your Mod a name';
                      }
                      if (value.trim().length > 20) {
                        return 'keep it under 20 characters';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _createMod(),
                  ),

                  const SizedBox(height: 24),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Look',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ModAppearancePicker(
                    selectedId: _appearanceId,
                    onSelected: (id) {
                      setState(() {
                        _appearanceId = id;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _createMod,
                    child: const Text(
                      'Begin',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
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

/// Grid of appearance presets, shared by creation and the Mod page.
class ModAppearancePicker extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;

  const ModAppearancePicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: modAppearances.map((appearance) {
        final isSelected = appearance.id == selectedId;

        return InkWell(
          borderRadius: AppTheme.borderRadius,
          onTap: () => onSelected(appearance.id),
          child: Container(
            width: 96,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.surface : AppTheme.panel,
              borderRadius: AppTheme.borderRadius,
              border: Border.all(
                color: isSelected ? appearance.color : AppTheme.border,
                width: isSelected ? 2.2 : 1.4,
              ),
            ),
            child: Column(
              children: [
                ModPortrait(
                  appearanceId: appearance.id,
                  size: 40,
                  animate: false,
                ),
                const SizedBox(height: 8),
                Text(
                  appearance.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
