import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../settings/bloc/settings_bloc.dart';
import '../settings/bloc/settings_event.dart';
import '../settings/settings_screen.dart';
import 'bloc/dashboard_bloc.dart';
import 'bloc/dashboard_event.dart';
import 'bloc/dashboard_state.dart';
import 'widgets/all_on_off_bar.dart';
import 'widgets/connection_status_bar.dart';
import 'widgets/led_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const DashboardStarted());
  }

  Future<void> _openSettings() async {
    // Load current settings before pushing
    context.read<SettingsBloc>().add(const SettingsLoaded());

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );

    // If settings changed, reload dashboard
    if (changed == true && mounted) {
      context.read<DashboardBloc>().add(const DashboardStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardBloc, DashboardState>(
      listenWhen: (prev, curr) =>
          curr is DashboardLoaded && prev is DashboardLoaded
              ? false // suppress constant stream updates from triggering snackbar
              : true,
      listener: (context, state) {
        if (state is DashboardError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error.withValues(alpha: 0.9),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, state),
          body: _buildBody(context, state),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, DashboardState state) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AltusLink'),
          Text(
            'Industrial Control Panel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
          ),
        ],
      ),
      actions: [
        if (state is DashboardLoaded)
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => context
                .read<DashboardBloc>()
                .add(const DashboardRefreshRequested()),
          ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Settings',
          onPressed: _openSettings,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    return switch (state) {
      DashboardInitial() || DashboardLoading() => _buildLoading(),
      DashboardError(:final message) => _buildError(context, message),
      DashboardLoaded() => _buildLoaded(context, state),
      _ => _buildLoading(),
    };
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: 20),
          Text(
            'Connecting to server...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms);
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.textDisabled),
            const SizedBox(height: 20),
            Text(
              'Could not reach server',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context
                  .read<DashboardBloc>()
                  .add(const DashboardRefreshRequested()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _openSettings,
              child: const Text(
                'Check Settings',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildLoaded(BuildContext context, DashboardLoaded state) {
    return Column(
      children: [
        ConnectionStatusBar(
          plcConnected: state.plcConnected,
          wsConnected: state.wsConnected,
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () async => context
                .read<DashboardBloc>()
                .add(const DashboardRefreshRequested()),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          'LED Outputs',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Spacer(),
                        _ActiveCount(lamps: state.lamps),
                      ],
                    ),
                  ),
                ),
                LedGrid(
                  lamps: state.lamps,
                  pendingIds: state.pendingIds,
                  plcConnected: state.plcConnected,
                  onToggle: (id, s) => context.read<DashboardBloc>().add(
                        LampToggleRequested(id: id, newState: s),
                      ),
                ),
              ],
            ),
          ),
        ),
        AllOnOffBar(
          enabled: state.plcConnected,
          onAllOn: () => context
              .read<DashboardBloc>()
              .add(const AllLampsToggleRequested(state: true)),
          onAllOff: () => context
              .read<DashboardBloc>()
              .add(const AllLampsToggleRequested(state: false)),
        ),
      ],
    );
  }
}

class _ActiveCount extends StatelessWidget {
  final List lamps;
  const _ActiveCount({required this.lamps});

  @override
  Widget build(BuildContext context) {
    final on = lamps.where((l) => l.isOn).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: on > 0 ? AppColors.accentGlow : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: on > 0 ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Text(
        '$on / ${lamps.length} ON',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: on > 0 ? AppColors.accent : AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
