import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'services/api_service.dart';
import 'models/user_profile.dart';

// --- Providers ---

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.sahayak-ai.gov.in'));
  dio.interceptors.add(MockInterceptor());
  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile>>((ref) {
  return UserProfileNotifier(ref.watch(apiServiceProvider));
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final ApiService _apiService;
  UserProfileNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _apiService.getUserProfile();
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateConsent(Map<String, bool> consents) async {
    try {
      await _apiService.updateConsent(consents);
      // Refresh profile after consent update
      await loadProfile();
    } catch (e) {
      // Handle error
    }
  }
}

// --- Routing ---

final _router = GoRouter(
  initialLocation: '/consent',
  routes: [
    GoRoute(
      path: '/consent',
      builder: (context, state) => const ConsentScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);

// --- App Entry Point ---

void main() {
  runApp(
    const ProviderScope(
      child: SahayakApp(),
    ),
  );
}

class SahayakApp extends StatelessWidget {
  const SahayakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sahayak AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06038D), // Navy Blue
          primary: const Color(0xFF06038D),
          secondary: const Color(0xFFFF9933), // Saffron
          background: const Color(0xFFF5F7FA),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routerConfig: _router,
    );
  }
}

// --- UI Components ---

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _dataProcessing = false;
  bool _schemeNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Citizen Agreement')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.security, size: 64, color: Color(0xFF06038D)),
                    const SizedBox(height: 16),
                    Text(
                      'Privacy & Consent',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'In accordance with the DPDP Act 2023, Sahayak AI requires your consent to process your data for providing government scheme recommendations.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SwitchListTile(
              title: const Text('Allow Data Processing'),
              subtitle: const Text('Needed for personalized scheme discovery'),
              value: _dataProcessing,
              onChanged: (val) => setState(() => _dataProcessing = val),
            ),
            SwitchListTile(
              title: const Text('Allow Notifications'),
              subtitle: const Text('Get updates about new schemes'),
              value: _schemeNotifications,
              onChanged: (val) => setState(() => _schemeNotifications = val),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_dataProcessing && _schemeNotifications)
                  ? () async {
                      await ref.read(userProfileProvider.notifier).updateConsent({
                        'data_processing': _dataProcessing,
                        'scheme_notifications': _schemeNotifications,
                      });
                      context.go('/');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06038D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Agree & Continue', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahayak AI'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('HI / EN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: profile.when(
        data: (user) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user.name}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('How can I help you today?'),
              const SizedBox(height: 24),
              const Expanded(child: SahayakAssistantHub()),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class SahayakAssistantHub extends StatelessWidget {
  const SahayakAssistantHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _buildSchemeCard(
                context,
                'PM-KISAN',
                'Agriculture',
                'Eligible',
                Colors.green,
              ),
              _buildSchemeCard(
                context,
                'MGNREGS',
                'Employment',
                'Check Eligibility',
                Colors.blue,
              ),
            ],
          ),
        ),
        const VoiceMicButton(),
      ],
    );
  }

  Widget _buildSchemeCard(BuildContext context, String title, String category, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(category),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class VoiceMicButton extends StatefulWidget {
  const VoiceMicButton({super.key});

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: GestureDetector(
        onLongPressStart: (_) => setState(() => _isRecording = true),
        onLongPressEnd: (_) => setState(() => _isRecording = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(_isRecording ? 24 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF06038D),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06038D).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: _isRecording ? 10 : 5,
              ),
            ],
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 48),
        ),
      ),
    );
  }
}
