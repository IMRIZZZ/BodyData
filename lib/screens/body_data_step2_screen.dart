import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class BodyDataStep2Screen extends StatefulWidget {
  final String name;
  final int dobTimestamp;
  final String gender;

  const BodyDataStep2Screen({
    super.key,
    required this.name,
    required this.dobTimestamp,
    required this.gender,
  });

  @override
  State<BodyDataStep2Screen> createState() => _BodyDataStep2ScreenState();
}

class _BodyDataStep2ScreenState extends State<BodyDataStep2Screen> {
  // ── Height drum-roll state ──────────────────────────────────────
  bool _heightIsCm = true;
  late FixedExtentScrollController _heightCtrl;

  // CM range: 100 – 250  → 151 items, default 170 cm → index 70
  static const _cmMin = 100;
  static const _cmMax = 250;
  static const _cmDefault = 170;

  // FT range: 4'0" – 7'0" → 37 items, default 5'9" → index 21
  // represented as total-inches: 48 … 84
  static const _ftInMin = 48; // 4'0"
  static const _ftInMax = 84; // 7'0"
  static const _ftInDefault = 69; // 5'9"

  int _cmIndex = _cmDefault - _cmMin; // 70
  int _ftIndex = _ftInDefault - _ftInMin; // 21

  // ── Weight state ────────────────────────────────────────────────
  bool _weightIsKg = true;
  final _weightCtrl = TextEditingController(text: '70');

  bool _isBusy = false;

  // Helpers
  int get _selectedCm => _cmMin + _cmIndex;
  int get _selectedFtTotalIn => _ftInMin + _ftIndex;

  String _ftLabel(int totalIn) {
    final ft = totalIn ~/ 12;
    final inch = totalIn % 12;
    return "$ft'$inch\"";
  }

  double get _heightInCm {
    if (_heightIsCm) return _selectedCm.toDouble();
    // convert ft+in → cm
    return _selectedFtTotalIn * 2.54;
  }

  double get _weightInKg {
    final v = double.tryParse(_weightCtrl.text) ?? 0;
    return _weightIsKg ? v : v * 0.453592;
  }

  @override
  void initState() {
    super.initState();
    _heightCtrl = FixedExtentScrollController(initialItem: _cmIndex);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _switchHeightUnit(bool toCm) {
    if (_heightIsCm == toCm) return;
    setState(() {
      _heightIsCm = toCm;
      if (toCm) {
        // convert current ft selection → cm
        final cmVal = (_selectedFtTotalIn * 2.54).round().clamp(_cmMin, _cmMax);
        _cmIndex = cmVal - _cmMin;
        _heightCtrl = FixedExtentScrollController(initialItem: _cmIndex);
      } else {
        // convert current cm → ft
        final ftIn = (_selectedCm / 2.54).round().clamp(_ftInMin, _ftInMax);
        _ftIndex = ftIn - _ftInMin;
        _heightCtrl = FixedExtentScrollController(initialItem: _ftIndex);
      }
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final h = _heightInCm;
    final w = _weightInKg;

    if (h <= 0 || w <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid height and weight.')),
      );
      return;
    }

    setState(() => _isBusy = true);
    await context.read<AppProvider>().createProfile(
          name: widget.name,
          dobTimestamp: widget.dobTimestamp,
          gender: widget.gender,
          heightCm: h,
          weightKg: w,
        );
    if (!mounted) return;
    setState(() => _isBusy = false);
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/dashboard', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final itemCount =
        _heightIsCm ? (_cmMax - _cmMin + 1) : (_ftInMax - _ftInMin + 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Data'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1.0,
            backgroundColor: cs.surfaceContainerHighest,
            color: cs.primary,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step indicator
                Row(
                  children: [
                    _StepChip(label: 'Step 1 of 2', active: false, cs: cs),
                    const SizedBox(width: 8),
                    _StepChip(label: 'Step 2 of 2', active: true, cs: cs),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Height section ────────────────────────────
                Text('Your Height',
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Unit toggle
                _UnitToggle(
                  leftLabel: 'FT',
                  rightLabel: 'CM',
                  rightSelected: _heightIsCm,
                  cs: cs,
                  onLeft: () => _switchHeightUnit(false),
                  onRight: () => _switchHeightUnit(true),
                ),
                const SizedBox(height: 12),

                // Drum-roll picker
                SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Selection highlight band
                      Center(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ListWheelScrollView.useDelegate(
                        key: ValueKey(_heightIsCm),
                        controller: _heightCtrl,
                        itemExtent: 48,
                        perspective: 0.004,
                        diameterRatio: 2.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            if (_heightIsCm) {
                              _cmIndex = index;
                            } else {
                              _ftIndex = index;
                            }
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: itemCount,
                          builder: (context, index) {
                            final isSelected = _heightIsCm
                                ? index == _cmIndex
                                : index == _ftIndex;
                            final label = _heightIsCm
                                ? '${_cmMin + index} cm'
                                : _ftLabel(_ftInMin + index);
                            return Center(
                              child: Text(
                                label,
                                style: tt.bodyLarge?.copyWith(
                                  fontSize: isSelected ? 22 : 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? cs.primary
                                      : cs.onSurface
                                          .withOpacity(0.5),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Weight section ────────────────────────────
                Text('Your Weight',
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                _UnitToggle(
                  leftLabel: 'KG',
                  rightLabel: 'LBS',
                  rightSelected: !_weightIsKg,
                  cs: cs,
                  onLeft: () {
                    if (!_weightIsKg) {
                      final lbs = double.tryParse(_weightCtrl.text) ?? 0;
                      _weightCtrl.text =
                          (lbs * 0.453592).toStringAsFixed(1);
                    }
                    setState(() => _weightIsKg = true);
                  },
                  onRight: () {
                    if (_weightIsKg) {
                      final kg = double.tryParse(_weightCtrl.text) ?? 0;
                      _weightCtrl.text =
                          (kg / 0.453592).toStringAsFixed(1);
                    }
                    setState(() => _weightIsKg = false);
                  },
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    hintText: _weightIsKg ? 'e.g. 70' : 'e.g. 154',
                    suffixText: _weightIsKg ? 'kg' : 'lbs',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  ),
                ),

                const Spacer(),

                ElevatedButton(
                  onPressed: _isBusy ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                  child: _isBusy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save & Continue',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────

class _UnitToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool rightSelected;
  final ColorScheme cs;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _UnitToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.rightSelected,
    required this.cs,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _Tab(
            label: leftLabel,
            selected: !rightSelected,
            cs: cs,
            onTap: onLeft,
          ),
          _Tab(
            label: rightLabel,
            selected: rightSelected,
            cs: cs,
            onTap: onRight,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;
  const _Tab(
      {required this.label,
      required this.selected,
      required this.cs,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final bool active;
  final ColorScheme cs;
  const _StepChip(
      {required this.label, required this.active, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
