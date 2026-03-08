import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'services/api_service.dart';
import 'models/user_profile.dart';
import 'models/turn_response.dart';

// --- Providers ---

final languageProvider = StateProvider<String>((ref) => 'EN');

final authProvider = StateProvider<bool>((ref) => false);

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
      await loadProfile();
    } catch (e) {
      // Handle error
    }
  }
}

enum VoiceState { idle, listening, thinking, speaking }

final voiceStateProvider = StateProvider<VoiceState>((ref) => VoiceState.idle);

final voiceSessionProvider = StateNotifierProvider<VoiceSessionNotifier, AsyncValue<TurnResponse?>>((ref) {
  return VoiceSessionNotifier(ref.read(apiServiceProvider), ref);
});

class VoiceSessionNotifier extends StateNotifier<AsyncValue<TurnResponse?>> {
  final ApiService _apiService;
  final Ref _ref;
  VoiceSessionNotifier(this._apiService, this._ref) : super(const AsyncValue.data(null));

  Future<void> submitVoice(String mockUrl) async {
    _ref.read(voiceStateProvider.notifier).state = VoiceState.thinking;
    state = const AsyncValue.loading();
    try {
      // Simulate network latency for high-fidelity feel
      await Future.delayed(const Duration(seconds: 2));
      final response = await _apiService.submitTurn(mockUrl);
      state = AsyncValue.data(response);
      _ref.read(voiceStateProvider.notifier).state = VoiceState.speaking;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      _ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
    _ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
  }
}

// --- Routing ---

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/consent',
      builder: (context, state) => const ConsentScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MainContainer(),
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06038D),
          primary: const Color(0xFF06038D),
          secondary: const Color(0xFFFF9933),
          surface: Colors.white,
          background: const Color(0xFFF5F7FA),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06038D),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

// --- Screens ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06038D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_rounded, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'SAHAYAK AI',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Empowering Every Citizen',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Color(0xFFFF9933)),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Welcome to\nNational Digital Sahayak',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
              ),
              const SizedBox(height: 12),
              const Text('Enter your mobile number to get started', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 40),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixText: '+91 ',
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '6-Digit OTP',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (!_otpSent) {
                    setState(() => _otpSent = true);
                  } else {
                    ref.read(authProvider.notifier).state = true;
                    context.go('/consent');
                  }
                },
                child: Text(_otpSent ? 'Verify & Login' : 'Send OTP'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

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
      appBar: AppBar(title: const Text('Privacy Consent')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildConsentCard(
              Icons.privacy_tip_outlined,
              'Data Protection',
              'Your data is processed in compliance with DPDP Act 2023. We only use information to match you with eligible schemes.',
            ),
            const SizedBox(height: 16),
            _buildConsentCard(
              Icons.notifications_active_outlined,
              'Stay Updated',
              'Allow us to notify you when new government benefits matching your profile become available.',
            ),
            const Spacer(),
            SwitchListTile(
              title: const Text('I agree to data processing'),
              value: _dataProcessing,
              onChanged: (v) => setState(() => _dataProcessing = v),
              activeColor: const Color(0xFF06038D),
            ),
            SwitchListTile(
              title: const Text('I want to receive notifications'),
              value: _schemeNotifications,
              onChanged: (v) => setState(() => _schemeNotifications = v),
              activeColor: const Color(0xFF06038D),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _dataProcessing ? () => context.go('/') : null,
              child: const Text('Enter Sahayak Hub'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentCard(IconData icon, String title, String desc) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: const Color(0xFFFF9933)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainContainer extends ConsumerStatefulWidget {
  const MainContainer({super.key});

  @override
  ConsumerState<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends ConsumerState<MainContainer> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const VoiceHubScreen(),
    const ChatHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.mic_none_rounded), selectedIcon: Icon(Icons.mic_rounded), label: 'Sahayak'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
        ],
      ),
    );
  }
}

class VoiceHubScreen extends ConsumerWidget {
  const VoiceHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final voiceState = ref.watch(voiceStateProvider);
    final voiceSession = ref.watch(voiceSessionProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network('https://upload.wikimedia.org/wikipedia/en/thumb/4/41/Flag_of_India.svg/255px-Flag_of_India.svg.png'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionChip(
              label: Text(lang == 'EN' ? 'HI / EN' : 'हि / EN'),
              onPressed: () => ref.read(languageProvider.notifier).state = lang == 'EN' ? 'HI' : 'EN',
              backgroundColor: const Color(0xFFFF9933).withOpacity(0.1),
              side: BorderSide.none,
              labelStyle: const TextStyle(color: Color(0xFFFF9933), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              profile.when(
                data: (u) => Text(
                  'Namaste, ${u.name}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF06038D)),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Namaste!'),
              ),
              const Text('How can I help you today?', style: TextStyle(fontSize: 18, color: Colors.black54)),
              const SizedBox(height: 60),
              _buildPulseMic(ref, voiceState),
              const SizedBox(height: 40),
              voiceSession.when(
                data: (res) {
                  if (res == null) return const Text('Hold the mic to ask about schemes');
                  return _buildResponseCard(context, res);
                },
                loading: () => const Text('Processing your request...', style: TextStyle(fontStyle: FontStyle.italic)),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 40),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Suggested Schemes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              _buildSuggestedSchemes(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseMic(WidgetRef ref, VoiceState state) {
    Color color;
    String label;
    switch (state) {
      case VoiceState.listening:
        color = Colors.green;
        label = 'Listening...';
        break;
      case VoiceState.thinking:
        color = const Color(0xFF06038D);
        label = 'Thinking...';
        break;
      case VoiceState.speaking:
        color = const Color(0xFFFF9933);
        label = 'Speaking...';
        break;
      default:
        color = const Color(0xFF06038D);
        label = 'Hold to Speak';
    }

    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => ref.read(voiceStateProvider.notifier).state = VoiceState.listening,
          onLongPressEnd: (_) => ref.read(voiceSessionProvider.notifier).submitVoice('mock_url'),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: state == VoiceState.listening ? 1.2 : 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, spreadRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, size: 60, color: Colors.white),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildResponseCard(BuildContext context, TurnResponse res) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFF06038D), child: Icon(Icons.auto_awesome, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                const Text('Sahayak AI', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFFF9933))),
              ],
            ),
            const Divider(),
            MarkdownBody(data: res.text),
            if (res.actionItems != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: res.actionItems!.map((item) {
                  return ActionChip(
                    label: Text(item.label),
                    onPressed: () {},
                    backgroundColor: const Color(0xFF06038D).withOpacity(0.05),
                    labelStyle: const TextStyle(color: Color(0xFF06038D), fontSize: 12),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedSchemes(BuildContext context) {
    return Column(
      children: [
        _buildSchemeTile(context, 'PM-KISAN', 'Agriculture', 'Eligible', Colors.green),
        _buildSchemeTile(context, 'MGNREGS', 'Employment', 'Verify Info', Colors.orange),
      ],
    );
  }

  Widget _buildSchemeTile(BuildContext context, String name, String cat, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(cat),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}

class ChatHistoryScreen extends ConsumerWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Chat')),
      body: const Center(child: Text('Chat History coming soon...')),
    );
  }
}
