import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/lamp_repository.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/settings/bloc/settings_bloc.dart';

class App extends StatefulWidget {
  final SharedPreferences prefs;
  const App({super.key, required this.prefs});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final LampRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = LampRepository(prefs: widget.prefs);
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _repository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => DashboardBloc(_repository)),
          BlocProvider(create: (_) => SettingsBloc(_repository)),
        ],
        child: MaterialApp(
          title: 'AltusLink',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}
