import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import 'bloc/settings_bloc.dart';
import 'bloc/settings_event.dart';
import 'bloc/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsBloc>().state;
    if (state is SettingsReady) {
      _hostCtrl = TextEditingController(text: state.host);
      _portCtrl = TextEditingController(text: state.port.toString());
    } else {
      _hostCtrl = TextEditingController();
      _portCtrl = TextEditingController();
      context.read<SettingsBloc>().add(const SettingsLoaded());
    }
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SettingsBloc>().add(
          SettingsSaved(
            host: _hostCtrl.text.trim(),
            port: int.parse(_portCtrl.text.trim()),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsReady && state.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved — reconnecting...')),
          );
          Navigator.of(context).pop(true); // signal dashboard to reconnect
        }
        if (state is SettingsReady) {
          _hostCtrl.text = state.host;
          _portCtrl.text = state.port.toString();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Settings'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(label: 'Server Configuration')
                        .animate()
                        .fadeIn(duration: 300.ms),
                    const SizedBox(height: 20),
                    _buildHostField()
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 60.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 16),
                    _buildPortField()
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 120.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('SAVE & RECONNECT'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 180.ms),
                    const SizedBox(height: 48),
                    const Divider(),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'AltusLink v1.0.0',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHostField() {
    return TextFormField(
      controller: _hostCtrl,
      keyboardType: TextInputType.url,
      autocorrect: false,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Host IP',
        hintText: '192.168.0.1',
        prefixIcon: Icon(Icons.dns_rounded, color: AppColors.textSecondary),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Host is required';
        return null;
      },
    );
  }

  Widget _buildPortField() {
    return TextFormField(
      controller: _portCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Port',
        hintText: '8080',
        prefixIcon: Icon(Icons.electrical_services_rounded,
            color: AppColors.textSecondary),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Port is required';
        final n = int.tryParse(v.trim());
        if (n == null || n < 1 || n > 65535) return 'Enter a valid port (1–65535)';
        return null;
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
