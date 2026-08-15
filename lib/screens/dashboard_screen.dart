import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/profile.dart';
import '../widgets/weight_chart_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _lastBackPress;

  void _onBackPress() {
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 1)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPress();
      },
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final profile = provider.currentProfile;
          if (profile == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildScaffold(context, provider, profile);
        },
      ),
    );
  }

  Widget _buildScaffold(
      BuildContext context, AppProvider provider, Profile profile) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      // ── App bar — NO back button ─────────────────────────────
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${profile.name.split(' ').first}! 👋',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text('Track your wellness journey',
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          // Profile avatar
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _Avatar(profile: profile, cs: cs),
          ),
          // Settings
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ── BMI Card ──────────────────────────────────────
            _BmiCard(profile: profile, cs: cs, tt: tt),
            const SizedBox(height: 16),

            // ── Weight History ────────────────────────────────
            Text('Weight History — Last 7 Days',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                child: SizedBox(
                  height: 200,
                  child: WeightChartWidget(
                    records: provider.recentWeightRecords,
                    isMetric: provider.isMetric,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats row ─────────────────────────────────────
            Text('Current Stats',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Weight',
                    value: provider.isMetric
                        ? '${profile.weightKg.toStringAsFixed(1)} kg'
                        : '${(profile.weightKg / 0.453592).toStringAsFixed(1)} lbs',
                    icon: Icons.monitor_weight_outlined,
                    color: cs.primaryContainer,
                    onColor: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Height',
                    value: provider.isMetric
                        ? '${profile.heightCm.toStringAsFixed(0)} cm'
                        : _cmToFtIn(profile.heightCm),
                    icon: Icons.height_outlined,
                    color: cs.tertiaryContainer,
                    onColor: cs.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Gender',
                    value: profile.gender,
                    icon: Icons.person_outlined,
                    color: cs.secondaryContainer,
                    onColor: cs.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Profile',
                    value: '${provider.profiles.length} user(s)',
                    icon: Icons.group_outlined,
                    color: cs.surfaceContainerHighest,
                    onColor: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Quick action ──────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.tune_outlined),
              label: const Text('Update Weight / Settings'),
              onPressed: () =>
                  Navigator.of(context).pushNamed('/settings'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _cmToFtIn(double cm) {
    final totalInches = cm / 2.54;
    final ft = totalInches ~/ 12;
    final inch = (totalInches % 12).round();
    return "$ft'$inch\"";
  }
}

// ─────────────────────── Sub-widgets ──────────────────────────────

class _Avatar extends StatelessWidget {
  final Profile profile;
  final ColorScheme cs;
  const _Avatar({required this.profile, required this.cs});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: cs.primaryContainer,
      child: Text(
        profile.initials,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  final Profile profile;
  final ColorScheme cs;
  final TextTheme tt;
  const _BmiCard(
      {required this.profile, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    final bmi = profile.bmi;
    final category = profile.bmiCategory;
    final color = profile.bmiColor;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header stripe
          Container(
            width: double.infinity,
            color: color.withOpacity(0.15),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's BMI",
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(category,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Big BMI number
                Text(
                  bmi.toStringAsFixed(1),
                  style: tt.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text('Body Mass Index',
                    style: tt.labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 20),

                // Gradient indicator bar
                _BmiBar(bmi: bmi),
                const SizedBox(height: 8),

                // Range labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('15', style: TextStyle(fontSize: 11)),
                    Text('18.5',
                        style: TextStyle(
                            fontSize: 11, color: Colors.blue)),
                    Text('25',
                        style: TextStyle(
                            fontSize: 11, color: Colors.green)),
                    Text('30',
                        style: TextStyle(
                            fontSize: 11, color: Colors.orange)),
                    Text('40', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BmiBar extends StatelessWidget {
  final double bmi;
  const _BmiBar({required this.bmi});

  @override
  Widget build(BuildContext context) {
    const minBmi = 15.0;
    const maxBmi = 40.0;
    final progress =
        ((bmi - minBmi) / (maxBmi - minBmi)).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const barHeight = 14.0;
        const markerW = 4.0;
        const markerH = 22.0;

        return SizedBox(
          height: markerH,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Gradient bar
              Center(
                child: Container(
                  width: width,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2196F3), // blue – underweight
                        Color(0xFF4CAF50), // green – normal
                        Color(0xFFFF9800), // orange – overweight
                        Color(0xFFF44336), // red – obese
                      ],
                      stops: [0.0, 0.14, 0.60, 1.0],
                    ),
                  ),
                ),
              ),
              // Marker
              Positioned(
                left: (width * progress - markerW / 2)
                    .clamp(0.0, width - markerW),
                child: Container(
                  width: markerW,
                  height: markerH,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: Colors.black54, width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(
                          blurRadius: 2,
                          color: Colors.black26,
                          offset: Offset(0, 1))
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color onColor;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      color: color,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: onColor, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: tt.titleMedium?.copyWith(
                    color: onColor, fontWeight: FontWeight.bold)),
            Text(label,
                style: tt.labelSmall?.copyWith(color: onColor)),
          ],
        ),
      ),
    );
  }
}
