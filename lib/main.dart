import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'services/api_service.dart';
import 'models/user_profile.dart';
import 'models/turn_response.dart';
import 'models/chat_message.dart';
import 'providers/chat_provider.dart';

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

      // Add to chat history
      _ref.read(chatProvider.notifier).addMessage(ChatMessage(
            id: DateTime.now().toIso8601String(),
            content: response.text,
            type: MessageType.text,
            sender: MessageSender.bot,
            timestamp: DateTime.now(),
            actionItems: response.actionItems?.map((e) => e.label).toList(),
          ));
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
            Hero(
              tag: 'app_logo',
              child: const Icon(Icons.account_balance_rounded, size: 120, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'SAHAYAK AI',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Empowering Every Citizen',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 60),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Hero(
                  tag: 'app_logo',
                  child: Icon(Icons.account_balance_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome to\nNational Digital Sahayak',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
              ),
              const SizedBox(height: 12),
              const Text('Enter your mobile number to securely access government services.', style: TextStyle(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 48),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixText: '+91 ',
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 20),
                TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18, letterSpacing: 8, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: '6-Digit OTP',
                    hintText: '......',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  if (!_otpSent) {
                    setState(() => _otpSent = true);
                  } else {
                    ref.read(authProvider.notifier).state = true;
                    context.go('/consent');
                  }
                },
                child: Text(_otpSent ? 'Verify & Continue' : 'Get OTP', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Login with DigiLocker', style: TextStyle(color: Color(0xFF06038D), fontWeight: FontWeight.bold)),
                ),
              ),
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
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildConsentCard(
              Icons.privacy_tip_outlined,
              'Digital Citizen Agreement',
              'In compliance with DPDP Act 2023, your personal data (Age, Income, Occupation) is used solely to determine eligibility for government benefits.',
            ),
            const SizedBox(height: 16),
            _buildConsentCard(
              Icons.verified_user_outlined,
              'Secure Processing',
              'All information is encrypted and stored in government-authorized servers. You can withdraw consent at any time.',
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('I agree to data processing', style: TextStyle(fontWeight: FontWeight.bold)),
                    value: _dataProcessing,
                    onChanged: (v) => setState(() => _dataProcessing = v),
                    activeColor: const Color(0xFF06038D),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Enable scheme notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                    value: _schemeNotifications,
                    onChanged: (v) => setState(() => _schemeNotifications = v),
                    activeColor: const Color(0xFF06038D),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _dataProcessing ? () => context.go('/') : null,
              child: const Text('Proceed to Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Icon(icon, size: 36, color: const Color(0xFFFF9933)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.4)),
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
                child: Text('Suggested Schemes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
            tween: Tween(begin: 1.0, end: state == VoiceState.listening ? 1.25 : 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  height: 140,
                  width: 140,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.4), blurRadius: 30, spreadRadius: 15),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, size: 70, color: Colors.white),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildResponseCard(BuildContext context, TurnResponse res) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFF06038D), child: Icon(Icons.auto_awesome, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                const Text('Sahayak AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFFF9933))),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            MarkdownBody(
              data: res.text,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            if (res.actionItems != null) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: res.actionItems!.map((item) {
                  return ActionChip(
                    label: Text(item.label),
                    onPressed: () {},
                    backgroundColor: const Color(0xFF06038D).withOpacity(0.08),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: const TextStyle(color: Color(0xFF06038D), fontSize: 13, fontWeight: FontWeight.w600),
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(cat, style: const TextStyle(fontSize: 14)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
          child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }
}

class ChatHistoryScreen extends ConsumerStatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  ConsumerState<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends ConsumerState<ChatHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Sahayak Conversations', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: messages.length,
              itemExtent: null, // Dynamic height for markdown
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isBot = message.sender == MessageSender.bot;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF06038D),
              child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isBot ? Colors.white : const Color(0xFFFF9933),
                    borderRadius: BorderRadius.circular(24).copyWith(
                      bottomLeft: isBot ? const Radius.circular(0) : const Radius.circular(24),
                      bottomRight: isBot ? const Radius.circular(24) : const Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: message.type == MessageType.voice
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Voice Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(message.content, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isBot ? Colors.black87 : Colors.white,
                              fontSize: 16,
                              height: 1.5,
                              fontWeight: isBot ? FontWeight.normal : FontWeight.w500,
                            ),
                            h1: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                ),
                if (message.actionItems != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: message.actionItems!.map((item) {
                      return ActionChip(
                        label: Text(item),
                        onPressed: () {},
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF06038D), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        labelStyle: const TextStyle(color: Color(0xFF06038D), fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFFF9933),
              child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(32),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Ask your Sahayak...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onSubmitted: (val) {
                  if (val.isNotEmpty) {
                    ref.read(chatProvider.notifier).addTextMessage(val, MessageSender.user);
                    _textController.clear();
                    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 56,
            width: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF06038D),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
