import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  bool _heightIsCm = true;
  bool _weightIsKg = true;
  String? _saveMessage;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _populateFields());
  }

  void _populateFields() {
    final provider = context.read<AppProvider>();
    final profile = provider.currentProfile;
    if (profile == null) return;
    _heightIsCm = provider.isMetric;
    _weightIsKg = provider.isMetric;
    _heightCtrl.text = _heightIsCm
        ? profile.heightCm.toStringAsFixed(0)
        : (profile.heightCm / 2.54).toStringAsFixed(1);
    _weightCtrl.text = _weightIsKg
        ? profile.weightKg.toStringAsFixed(1)
        : (profile.weightKg / 0.453592).toStringAsFixed(1);
    setState(() {});
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    final hStr = _heightCtrl.text.trim();
    final wStr = _weightCtrl.text.trim();
    final hRaw = double.tryParse(hStr);
    final wRaw = double.tryParse(wStr);

    if (hRaw == null || wRaw == null || hRaw <= 0 || wRaw <= 0) {
      setState(
          () => _saveMessage = 'Please enter valid height and weight.');
      return;
    }

    final hCm = _heightIsCm ? hRaw : hRaw * 2.54;
    final wKg = _weightIsKg ? wRaw : wRaw * 0.453592;

    setState(() {
      _isBusy = true;
      _saveMessage = null;
    });

    final ok = await context
        .read<AppProvider>()
        .updateCurrentProfile(heightCm: hCm, weightKg: wKg);

    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _saveMessage = ok
          ? '✓ Changes saved successfully!'
          : 'Failed to save. Try again.';
    });
  }

  void _logout() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        await context.read<AppProvider>().logout();
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (r) => false);
        }
      }
    });
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // ← back arrow is auto-shown (there IS a route to pop to)
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Sign Out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Profile Switcher ─────────────────────────
                _sectionHeader('Active Profile', tt),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.profiles.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      if (i == provider.profiles.length) {
                        // "Add User" card
                        return _AddUserCard(
                          cs: cs,
                          onTap: () => Navigator.of(context)
                              .pushNamed('/body-data-step1'),
                        );
                      }
                      final p = provider.profiles[i];
                      return _ProfileCard(
                        profile: p,
                        isActive: p.id == provider.activeProfileId,
                        cs: cs,
                        tt: tt,
                        onTap: () => provider.switchProfile(p.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Update Body Data ──────────────────────────
                _sectionHeader('Update Body Data', tt),
                Text('Keep your metrics up to date.',
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Height
                        Row(
                          children: [
                            Text('Height',
                                style: tt.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            _SmallUnitToggle(
                              leftLabel: 'CM',
                              rightLabel: 'IN',
                              leftSelected: _heightIsCm,
                              cs: cs,
                              onLeft: () {
                                if (!_heightIsCm) {
                                  final v = double.tryParse(
                                          _heightCtrl.text) ??
                                      0;
                                  _heightCtrl.text =
                                      (v * 2.54).toStringAsFixed(0);
                                }
                                setState(() => _heightIsCm = true);
                              },
                              onRight: () {
                                if (_heightIsCm) {
                                  final v = double.tryParse(
                                          _heightCtrl.text) ??
                                      0;
                                  _heightCtrl.text =
                                      (v / 2.54).toStringAsFixed(1);
                                }
                                setState(() => _heightIsCm = false);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _heightCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.height_outlined),
                            suffixText:
                                _heightIsCm ? 'cm' : 'in',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Weight
                        Row(
                          children: [
                            Text('Weight',
                                style: tt.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            _SmallUnitToggle(
                              leftLabel: 'KG',
                              rightLabel: 'LBS',
                              leftSelected: _weightIsKg,
                              cs: cs,
                              onLeft: () {
                                if (!_weightIsKg) {
                                  final v = double.tryParse(
                                          _weightCtrl.text) ??
                                      0;
                                  _weightCtrl.text =
                                      (v * 0.453592)
                                          .toStringAsFixed(1);
                                }
                                setState(() => _weightIsKg = true);
                              },
                              onRight: () {
                                if (_weightIsKg) {
                                  final v = double.tryParse(
                                          _weightCtrl.text) ??
                                      0;
                                  _weightCtrl.text =
                                      (v / 0.453592)
                                          .toStringAsFixed(1);
                                }
                                setState(() => _weightIsKg = false);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _weightCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _saveChanges(),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                                Icons.monitor_weight_outlined),
                            suffixText:
                                _weightIsKg ? 'kg' : 'lbs',
                          ),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _isBusy ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                          ),
                          child: _isBusy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Save Changes',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                        ),

                        if (_saveMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _saveMessage!,
                            style: TextStyle(
                              color: _saveMessage!.startsWith('✓')
                                  ? Colors.green
                                  : cs.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Unit preference ───────────────────────────
                _sectionHeader('Preferences', tt),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.straighten_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Measurement System',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                provider.isMetric
                                    ? 'Metric (kg, cm)'
                                    : 'Imperial (lbs, ft/in)',
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: provider.isMetric,
                          onChanged: (v) {
                            provider.setMetric(v);
                            _populateFields();
                          },
                          activeColor: cs.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(provider.isDarkMode
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Appearance',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                provider.isDarkMode
                                    ? 'Dark theme'
                                    : 'Light theme for brighter conditions',
                                style: TextStyle(
                                    color: cs.onSurfaceVariant, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: provider.isDarkMode,
                          onChanged: (value) => provider.setDarkMode(value),
                          activeColor: cs.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Current profile info card
                if (provider.currentProfile != null) ...[
                  _sectionHeader('Active Profile Info', tt),
                  const SizedBox(height: 10),
                  _ProfileInfoCard(
                      profile: provider.currentProfile!, cs: cs, tt: tt),
                ],
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, TextTheme tt) => Text(
        title,
        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      );
}

// ──────────────────── Sub-widgets ────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final Profile profile;
  final bool isActive;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;
  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.cs,
    required this.tt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: cs.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isActive ? cs.primary : cs.outline,
              child: Text(
                profile.initials,
                style: TextStyle(
                  color: isActive ? cs.onPrimary : cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.name.split(' ').first,
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? cs.onPrimaryContainer
                    : cs.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (isActive)
              Text('Active',
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.primary,
                      fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _AddUserCard extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onTap;
  const _AddUserCard({required this.cs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: cs.outline.withOpacity(0.5),
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined,
                size: 30, color: cs.primary),
            const SizedBox(height: 8),
            Text('Add User',
                style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final Profile profile;
  final ColorScheme cs;
  final TextTheme tt;
  const _ProfileInfoCard(
      {required this.profile, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    final bmi = profile.bmi;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(label: 'Name', value: profile.name),
            _InfoRow(label: 'Gender', value: profile.gender),
            _InfoRow(
              label: 'Height',
              value: '${profile.heightCm.toStringAsFixed(0)} cm',
            ),
            _InfoRow(
              label: 'Weight',
              value: '${profile.weightKg.toStringAsFixed(1)} kg',
            ),
            _InfoRow(
              label: 'BMI',
              value:
                  '${bmi.toStringAsFixed(1)} — ${profile.bmiCategory}',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: tt.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const Spacer(),
          Text(value,
              style:
                  tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SmallUnitToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final ColorScheme cs;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _SmallUnitToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.cs,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SmTab(label: leftLabel, selected: leftSelected, cs: cs, onTap: onLeft),
          _SmTab(label: rightLabel, selected: !leftSelected, cs: cs, onTap: onRight),
        ],
      ),
    );
  }
}

class _SmTab extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;
  const _SmTab(
      {required this.label,
      required this.selected,
      required this.cs,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
