import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BodyDataStep1Screen extends StatefulWidget {
  const BodyDataStep1Screen({super.key});

  @override
  State<BodyDataStep1Screen> createState() => _BodyDataStep1ScreenState();
}

class _BodyDataStep1ScreenState extends State<BodyDataStep1Screen> {
  final _nameCtrl = TextEditingController();
  DateTime? _dob;
  String _gender = 'Male';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1930),
      lastDate: now,
      helpText: 'Select Date of Birth',
      fieldLabelText: 'Date of Birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  bool get _canContinue => _nameCtrl.text.trim().isNotEmpty && _dob != null;

  void _continue() {
    if (!_canContinue) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed(
      '/body-data-step2',
      arguments: {
        'name': _nameCtrl.text.trim(),
        'dobTimestamp': _dob!.millisecondsSinceEpoch,
        'gender': _gender,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Data'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: canGoBack,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.5,
            backgroundColor: cs.surfaceContainerHighest,
            color: cs.primary,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _StepChip(label: 'Step 1 of 2', active: true, cs: cs),
                    const SizedBox(width: 8),
                    _StepChip(label: 'Step 2 of 2', active: false, cs: cs),
                  ],
                ),
                const SizedBox(height: 12),
                Text("Let's personalise your health journey.",
                    style:
                        tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 32),
                Text('Full Name',
                    style: tt.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Alex Johnson',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Date of Birth',
                    style: tt.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _dob == null
                          ? 'Select your date of birth'
                          : DateFormat('MMMM d, yyyy').format(_dob!),
                      style: tt.bodyLarge?.copyWith(
                        color: _dob == null ? cs.onSurfaceVariant : cs.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Biological Sex',
                    style: tt.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: ['Male', 'Female', 'Other'].map((g) {
                    final selected = _gender == g;
                    return ChoiceChip(
                      label: Text(g),
                      selected: selected,
                      onSelected: (_) => setState(() => _gender = g),
                      avatar: Icon(
                        g == 'Male'
                            ? Icons.male
                            : g == 'Female'
                                ? Icons.female
                                : Icons.transgender,
                        size: 18,
                        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                      ),
                      selectedColor: cs.primary,
                      labelStyle: TextStyle(
                        color: selected ? cs.onPrimary : cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      // This stays above the keyboard on this onboarding screen, so the
      // action remains fully visible and tappable while entering details.
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 8,
          ),
          child: ElevatedButton(
            onPressed: _canContinue ? _continue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            child: const Text('Continue',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
