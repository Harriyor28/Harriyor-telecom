import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static SharedPreferences? _instance;

  static const _favoriteUssdCodesKey = 'favorite_ussd_codes';
  static const _preferredNetworkKey = 'preferred_network';
  static const _darkModeKey = 'dark_mode';

  static Future<void> initialize() async {
    _instance ??= await SharedPreferences.getInstance();
  }

  static Future<SharedPreferences> get _prefs async {
    _instance ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  static Future<Set<String>> getFavoriteUssdCodes() async {
    final prefs = await _prefs;
    return (prefs.getStringList(_favoriteUssdCodesKey) ?? const []).toSet();
  }

  static Future<void> setFavoriteUssdCodes(Set<String> favorites) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      _favoriteUssdCodesKey,
      favorites.toList()..sort(),
    );
  }

  static Future<void> toggleFavoriteUssdCode(String code) async {
    final favorites = await getFavoriteUssdCodes();
    if (favorites.contains(code)) {
      favorites.remove(code);
    } else {
      favorites.add(code);
    }
    await setFavoriteUssdCodes(favorites);
  }

  static Future<String> getPreferredNetwork() async {
    final prefs = await _prefs;
    final value = prefs.getString(_preferredNetworkKey) ?? 'MTN';
    return value.isEmpty ? 'MTN' : value;
  }

  static Future<void> setPreferredNetwork(String network) async {
    final prefs = await _prefs;
    await prefs.setString(_preferredNetworkKey, network);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await _prefs;
    return prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_darkModeKey, value);
  }

  static Future<String> getAppVersionText() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}

class AppSettingsController {
  static final ValueNotifier<bool> darkMode = ValueNotifier(false);
  static final ValueNotifier<String> preferredNetwork = ValueNotifier('MTN');

  static Future<void> load() async {
    darkMode.value = await AppPreferences.getDarkMode();
    preferredNetwork.value = await AppPreferences.getPreferredNetwork();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppPreferences.initialize();
  await AppSettingsController.load();

  // AdMob is only initialized on Android/iOS.
  // Edge/Web testing does not load AdMob.
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // Begin loading interstitials early.
  InterstitialAdManager.load();

  runApp(const HarryyorTelecomTools());
}

class InterstitialAdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;
  static bool _isShowing = false;

  static const String _realAdUnitId = 'ca-app-pub-7028384808538422/1566129156';

  static String get _adUnitId => _realAdUnitId;

  static void load() {
    if (kIsWeb) return;
    if (_isLoading) return;
    if (_interstitialAd != null) return;

    _isLoading = true;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoading = false;
          _interstitialAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (Ad ad) {
              _isShowing = true;
            },
            onAdDismissedFullScreenContent: (Ad ad) {
              _isShowing = false;

              ad.dispose();
              _interstitialAd = null;

              load();
            },
            onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
              _isShowing = false;

              ad.dispose();
              _interstitialAd = null;

              load();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          _interstitialAd = null;

          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  static void show() {
    if (kIsWeb) return;
    if (_isShowing) return;

    final ad = _interstitialAd;

    if (ad == null) {
      load();
      return;
    }

    _interstitialAd = null;
    ad.show();
  }
}

// ============================================================
// APP
// ============================================================

class HarryyorTelecomTools extends StatelessWidget {
  const HarryyorTelecomTools({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettingsController.darkMode,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          title: 'Harriyor Telecom',
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFFF7F9FC),
            appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFF101827),
            appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = <ToolDefinition>[
      ToolDefinition(
        icon: Icons.phone_android,
        title: 'Airtime Tools',
        subtitle: 'Calculate airtime value',
        color: Colors.blue,
        screen: const AirtimeScreen(),
      ),
      ToolDefinition(
        icon: Icons.data_usage,
        title: 'Data Tools',
        subtitle: 'Calculate data usage',
        color: Colors.green,
        screen: const DataScreen(),
      ),
      ToolDefinition(
        icon: Icons.attach_money,
        title: 'Price Tools',
        subtitle: 'Airtime and data pricing',
        color: Colors.deepOrange,
        screen: const PriceToolsScreen(),
      ),
      ToolDefinition(
        icon: Icons.swap_horiz,
        title: 'Converter',
        subtitle: 'Convert data units',
        color: Colors.orange,
        screen: const ConverterScreen(),
      ),
      ToolDefinition(
        icon: Icons.dialpad,
        title: 'USSD Codes',
        subtitle: 'Useful network codes',
        color: Colors.purple,
        screen: const UssdScreen(),
      ),
      ToolDefinition(
        icon: Icons.network_check,
        title: 'Network Tools',
        subtitle: 'Coverage and network tips',
        color: Colors.teal,
        screen: const NetworkScreen(),
      ),
      ToolDefinition(
        icon: Icons.calculate_outlined,
        title: 'Calculator',
        subtitle: 'Full calculator',
        color: Colors.indigo,
        screen: const CalculatorScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Harryyor Telecom Tools',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              InterstitialAdManager.show();

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 600
                ? 3
                : 2;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const WelcomeCard(),

                      const SizedBox(height: 22),

                      const SectionTitle(
                        title: 'Telecom Tools',
                        subtitle: 'Useful utilities for everyday mobile needs',
                      ),

                      const SizedBox(height: 12),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tools.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.12,
                        ),
                        itemBuilder: (context, index) {
                          final tool = tools[index];

                          return ToolCard(
                            definition: tool,
                            onTap: () {
                              InterstitialAdManager.show();

                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => tool.screen),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // REAL ADMOB BANNER
                      const AdPlaceholder(),

                      const SizedBox(height: 24),

                      const SectionTitle(
                        title: 'Quick Information',
                        subtitle: 'Built for simple, useful calculations',
                      ),

                      const SizedBox(height: 12),

                      const InfoCard(
                        icon: Icons.offline_bolt_outlined,
                        title: 'Works without an account',
                        text:
                            'The calculators and converters process their calculations locally without requiring a login or server.',
                      ),

                      const SizedBox(height: 10),

                      const InfoCard(
                        icon: Icons.system_update_alt,
                        title: 'Easy to expand',
                        text:
                            'More telecom utilities can be added later without changing the existing tool structure.',
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// DRAWER
// ============================================================

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.pop(context);

    InterstitialAdManager.show();

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.indigo]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.phone_android, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Harryyor Telecom Tools',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Smart telecom utilities',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            _DrawerItem(
              icon: Icons.home_outlined,
              title: 'Home',
              onTap: () => Navigator.pop(context),
            ),

            _DrawerItem(
              icon: Icons.phone_android,
              title: 'Airtime Tools',
              onTap: () => _open(context, const AirtimeScreen()),
            ),

            _DrawerItem(
              icon: Icons.data_usage,
              title: 'Data Tools',
              onTap: () => _open(context, const DataScreen()),
            ),

            _DrawerItem(
              icon: Icons.swap_horiz,
              title: 'Converter',
              onTap: () => _open(context, const ConverterScreen()),
            ),

            _DrawerItem(
              icon: Icons.dialpad,
              title: 'USSD Codes',
              onTap: () => _open(context, const UssdScreen()),
            ),

            _DrawerItem(
              icon: Icons.network_check,
              title: 'Network Tools',
              onTap: () => _open(context, const NetworkScreen()),
            ),

            _DrawerItem(
              icon: Icons.calculate_outlined,
              title: 'Calculator',
              onTap: () => _open(context, const CalculatorScreen()),
            ),

            _DrawerItem(
              icon: Icons.attach_money,
              title: 'Price Tools',
              onTap: () => _open(context, const PriceToolsScreen()),
            ),

            const Divider(),

            _DrawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => _open(context, const SettingsScreen()),
            ),

            _DrawerItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () => _open(context, const AboutScreen()),
            ),

            _DrawerItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              onTap: () => _open(context, const PrivacyScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}

// ============================================================
// REUSABLE UI
// ============================================================

class ToolDefinition {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget screen;

  const ToolDefinition({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.screen,
  });
}

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 20,
        children: [
          SizedBox(
            width: 650,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Your collection of useful telecom tools in one place.',
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          Icon(Icons.phone_iphone, size: 72, color: scheme.onPrimary),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionTitle({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ],
    );
  }
}

class ToolCard extends StatelessWidget {
  final ToolDefinition definition;
  final VoidCallback onTap;

  const ToolCard({super.key, required this.definition, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: definition.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(definition.icon, color: definition.color, size: 26),
              ),

              const Spacer(),

              Text(
                definition.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                definition.subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADMOB BANNER
// ============================================================

class AdPlaceholder extends StatefulWidget {
  const AdPlaceholder({super.key});

  @override
  State<AdPlaceholder> createState() => _AdPlaceholderState();
}

class _AdPlaceholderState extends State<AdPlaceholder> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  static const String _bannerAdUnitId =
      'ca-app-pub-7028384808538422/3565065325';

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    final banner = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;

          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (!mounted) return;

          setState(() {
            _isLoaded = false;
          });
        },
      ),
    );

    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ads_click, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Advertisement',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// ============================================================
// AIRTIME TOOLS
// ============================================================

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final amountController = TextEditingController();

  final percentageController = TextEditingController();

  double bonus = 0;
  double total = 0;
  bool calculated = false;

  @override
  void dispose() {
    amountController.dispose();
    percentageController.dispose();
    super.dispose();
  }

  void calculate() {
    final amount = _number(amountController.text);

    final percentage = _number(percentageController.text);

    if (amount == null || amount <= 0) {
      _message('Enter a valid airtime amount.');
      return;
    }

    if (percentage == null || percentage < 0) {
      _message('Enter a valid bonus percentage.');
      return;
    }

    setState(() {
      bonus = amount * percentage / 100;

      total = amount + bonus;

      calculated = true;
    });
  }

  void clear() {
    amountController.clear();
    percentageController.clear();

    setState(() {
      bonus = 0;
      total = 0;
      calculated = false;
    });
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Airtime Tools',
      icon: Icons.phone_android,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ToolIntro(
            title: 'Airtime Value Calculator',
            description:
                'Calculate bonus value and total airtime value using a percentage.',
          ),

          const SizedBox(height: 18),

          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Airtime Amount',
              hintText: 'Example: 1000',
              prefixText: '₦ ',
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: percentageController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Bonus Percentage',
              hintText: 'Example: 20',
              suffixText: '%',
            ),
          ),

          const SizedBox(height: 16),

          ActionButtons(
            primaryText: 'Calculate',
            primaryIcon: Icons.calculate,
            onPrimary: calculate,
            secondaryText: 'Clear',
            onSecondary: clear,
          ),

          if (calculated) ...[
            const SizedBox(height: 18),

            ResultCard(
              rows: [
                ResultRow(
                  label: 'Original Airtime',
                  value: _naira(_number(amountController.text)!),
                ),
                ResultRow(label: 'Bonus', value: _naira(bonus)),
                ResultRow(
                  label: 'Total Value',
                  value: _naira(total),
                  highlight: true,
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          const AdPlaceholder(),
        ],
      ),
    );
  }
}

// ============================================================
// DATA TOOLS
// ============================================================

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final usedController = TextEditingController();

  final totalController = TextEditingController();

  double? remaining;
  double? percentage;

  @override
  void dispose() {
    usedController.dispose();
    totalController.dispose();
    super.dispose();
  }

  void calculate() {
    final used = _number(usedController.text);

    final total = _number(totalController.text);

    if (used == null || total == null || total <= 0 || used < 0) {
      _message('Enter valid data values.');
      return;
    }

    if (used > total) {
      _message('Used data cannot be greater than total data.');
      return;
    }

    setState(() {
      remaining = total - used;

      percentage = ((total - used) / total) * 100;
    });
  }

  void clear() {
    usedController.clear();
    totalController.clear();

    setState(() {
      remaining = null;
      percentage = null;
    });
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Data Tools',
      icon: Icons.data_usage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ToolIntro(
            title: 'Data Usage Calculator',
            description:
                'Enter your total data and amount already used to calculate what remains.',
          ),

          const SizedBox(height: 18),

          TextField(
            controller: totalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total Data',
              hintText: 'Example: 10',
              suffixText: 'GB',
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: usedController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Data Used',
              hintText: 'Example: 3.5',
              suffixText: 'GB',
            ),
          ),

          const SizedBox(height: 16),

          ActionButtons(
            primaryText: 'Calculate',
            primaryIcon: Icons.calculate,
            onPrimary: calculate,
            secondaryText: 'Clear',
            onSecondary: clear,
          ),

          if (remaining != null && percentage != null) ...[
            const SizedBox(height: 18),

            ResultCard(
              rows: [
                ResultRow(
                  label: 'Remaining Data',
                  value: '${remaining!.toStringAsFixed(2)} GB',
                ),
                ResultRow(
                  label: 'Remaining Percentage',
                  value: '${percentage!.toStringAsFixed(1)}%',
                  highlight: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// DATA CONVERTER
// ============================================================

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final valueController = TextEditingController();

  String from = 'GB';
  String to = 'MB';
  String result = '';

  final units = const ['KB', 'MB', 'GB', 'TB'];

  double toBytes(double value, String unit) {
    switch (unit) {
      case 'KB':
        return value * 1024;
      case 'MB':
        return value * 1024 * 1024;
      case 'GB':
        return value * 1024 * 1024 * 1024;
      case 'TB':
        return value * 1024 * 1024 * 1024 * 1024;
      default:
        return value;
    }
  }

  double fromBytes(double value, String unit) {
    switch (unit) {
      case 'KB':
        return value / 1024;
      case 'MB':
        return value / (1024 * 1024);
      case 'GB':
        return value / (1024 * 1024 * 1024);
      case 'TB':
        return value / (1024 * 1024 * 1024 * 1024);
      default:
        return value;
    }
  }

  void convert() {
    final value = _number(valueController.text);

    if (value == null || value < 0) {
      _message('Enter a valid value.');
      return;
    }

    final bytes = toBytes(value, from);

    final converted = fromBytes(bytes, to);

    setState(() {
      result = '${_pretty(converted)} $to';
    });
  }

  void clear() {
    valueController.clear();

    setState(() {
      result = '';
    });
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Data Converter',
      icon: Icons.swap_horiz,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ToolIntro(
            title: 'Data Unit Converter',
            description:
                'Convert between KB, MB, GB and TB using 1024-based binary units.',
          ),

          const SizedBox(height: 18),

          TextField(
            controller: valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Value',
              hintText: 'Example: 2.5',
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: from,
                  decoration: const InputDecoration(labelText: 'From'),
                  items: units
                      .map(
                        (unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        from = value;
                      });
                    }
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward),
              ),

              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: to,
                  decoration: const InputDecoration(labelText: 'To'),
                  items: units
                      .map(
                        (unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        to = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ActionButtons(
            primaryText: 'Convert',
            primaryIcon: Icons.swap_horiz,
            onPrimary: convert,
            secondaryText: 'Clear',
            onSecondary: clear,
          ),

          if (result.isNotEmpty) ...[
            const SizedBox(height: 18),

            ResultCard(
              rows: [
                ResultRow(label: 'Result', value: result, highlight: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// REAL CALCULATOR
// ============================================================

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String expression = '';
  String result = '0';

  void add(String value) {
    setState(() {
      if (expression == 'Error') {
        expression = '';
      }

      expression += value;
    });
  }

  void clear() {
    setState(() {
      expression = '';
      result = '0';
    });
  }

  void delete() {
    if (expression.isEmpty) return;

    setState(() {
      expression = expression.substring(0, expression.length - 1);
    });
  }

  void toggleSign() {
    if (expression.isEmpty) return;

    setState(() {
      if (expression.startsWith('-')) {
        expression = expression.substring(1);
      } else {
        expression = '-$expression';
      }
    });
  }

  void calculate() {
    if (expression.trim().isEmpty) {
      return;
    }

    try {
      final normalized = expression.replaceAll('×', '*');

      final parser = _ExpressionParser(normalized);

      final value = parser.parse();

      if (value.isNaN || value.isInfinite) {
        throw Exception();
      }

      setState(() {
        result = _pretty(value);
      });
    } catch (_) {
      setState(() {
        result = 'Error';
      });
    }
  }

  Widget button(
    String text, {
    Color? color,
    Color? textColor,
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: SizedBox(
          height: 64,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  color ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor:
                  textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onPressed ?? () => add(text),
            child: Text(
              text,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.bottomRight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Text(
                              expression.isEmpty ? '0' : expression,
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.grey,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          FittedBox(
                            child: Text(
                              result,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      button(
                        'AC',
                        color: Colors.red.shade100,
                        textColor: Colors.red.shade800,
                        onPressed: clear,
                      ),
                      button(
                        'DEL',
                        color: Colors.orange.shade100,
                        textColor: Colors.orange.shade900,
                        onPressed: delete,
                      ),
                      button('%'),
                      button('÷', color: primary, textColor: Colors.white),
                    ],
                  ),

                  Row(
                    children: [
                      button('7'),
                      button('8'),
                      button('9'),
                      button('×', color: primary, textColor: Colors.white),
                    ],
                  ),

                  Row(
                    children: [
                      button('4'),
                      button('5'),
                      button('6'),
                      button('-', color: primary, textColor: Colors.white),
                    ],
                  ),

                  Row(
                    children: [
                      button('1'),
                      button('2'),
                      button('3'),
                      button('+', color: primary, textColor: Colors.white),
                    ],
                  ),

                  Row(
                    children: [
                      button('+/-', onPressed: toggleSign),
                      button('0'),
                      button('.'),
                      button(
                        '=',
                        color: Colors.green,
                        textColor: Colors.white,
                        onPressed: calculate,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CALCULATOR EXPRESSION PARSER
// ============================================================

class _ExpressionParser {
  final String input;
  int position = 0;

  _ExpressionParser(this.input);

  double parse() {
    final value = _parseExpression();

    _skipSpaces();

    if (position != input.length) {
      throw FormatException('Unexpected character');
    }

    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();

    while (true) {
      _skipSpaces();

      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        break;
      }
    }

    return value;
  }

  double _parseTerm() {
    var value = _parseFactor();

    while (true) {
      _skipSpaces();

      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        final divisor = _parseFactor();

        if (divisor == 0) {
          throw FormatException('Division by zero');
        }

        value /= divisor;
      } else {
        break;
      }
    }

    return value;
  }

  double _parseFactor() {
    _skipSpaces();

    if (_match('+')) {
      return _parseFactor();
    }

    if (_match('-')) {
      return -_parseFactor();
    }

    if (_match('(')) {
      final value = _parseExpression();

      if (!_match(')')) {
        throw FormatException('Missing parenthesis');
      }

      return _parsePercentage(value);
    }

    final number = _parseNumber();

    return _parsePercentage(number);
  }

  double _parsePercentage(double value) {
    while (true) {
      _skipSpaces();

      if (_match('%')) {
        value /= 100;
      } else {
        break;
      }
    }

    return value;
  }

  double _parseNumber() {
    _skipSpaces();

    final start = position;

    bool hasDigit = false;
    bool hasDot = false;

    while (position < input.length) {
      final char = input[position];

      if (_isDigit(char)) {
        hasDigit = true;
        position++;
      } else if (char == '.' && !hasDot) {
        hasDot = true;
        position++;
      } else {
        break;
      }
    }

    if (!hasDigit) {
      throw FormatException('Number expected');
    }

    return double.parse(input.substring(start, position));
  }

  bool _match(String char) {
    if (position >= input.length) {
      return false;
    }

    if (input[position] == char) {
      position++;
      return true;
    }

    return false;
  }

  void _skipSpaces() {
    while (position < input.length && input[position].trim().isEmpty) {
      position++;
    }
  }

  bool _isDigit(String char) {
    return char.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
        char.codeUnitAt(0) <= '9'.codeUnitAt(0);
  }
}

// ============================================================
// USSD CODE LIBRARY
// ============================================================

class UssdCode {
  final String network;
  final String category;
  final String title;
  final String code;
  final String note;
  final String sourceLabel;

  const UssdCode({
    required this.network,
    required this.category,
    required this.title,
    required this.code,
    required this.note,
    required this.sourceLabel,
  });
}

const verifiedUssdCodes = <UssdCode>[
  // ==========================================================
  // MTN
  // ==========================================================
  UssdCode(
    network: 'MTN',
    category: 'Balance',
    title: 'Airtime Balance',
    code: '*310#',
    note: 'Check your MTN account balance.',
    sourceLabel: 'MTN official support',
  ),

  UssdCode(
    network: 'MTN',
    category: 'Data',
    title: 'Data Plans',
    code: '*312#',
    note: 'Open MTN data bundle options.',
    sourceLabel: 'MTN official support',
  ),

  UssdCode(
    network: 'MTN',
    category: 'Data',
    title: 'Data Balance',
    code: '*323#',
    note: 'Check your MTN main data and bonus balance.',
    sourceLabel: 'MTN official support',
  ),

  UssdCode(
    network: 'MTN',
    category: 'Information',
    title: 'Data Balance via SMS',
    code: '2 to 323',
    note: 'MTN also documents checking data balance by sending 2 to 323.',
    sourceLabel: 'MTN official support',
  ),

  // ==========================================================
  // AIRTEL
  // ==========================================================
  UssdCode(
    network: 'Airtel',
    category: 'Balance',
    title: 'Airtime Balance',
    code: '*310#',
    note: 'Check your Airtel account balance.',
    sourceLabel: 'Airtel official support',
  ),

  UssdCode(
    network: 'Airtel',
    category: 'Data',
    title: 'Data Balance',
    code: '*323#',
    note: 'Check your Airtel data balance.',
    sourceLabel: 'Airtel official support',
  ),

  UssdCode(
    network: 'Airtel',
    category: 'Data',
    title: 'Data Plans',
    code: '*312#',
    note: 'Open Airtel data plans.',
    sourceLabel: 'Airtel official support',
  ),

  UssdCode(
    network: 'Airtel',
    category: 'Recharge',
    title: 'Recharge',
    code: '*311#',
    note: 'Recharge your Airtel line using a recharge PIN.',
    sourceLabel: 'Airtel official support',
  ),

  UssdCode(
    network: 'Airtel',
    category: 'Recharge',
    title: 'Recharge Format',
    code: '*311*PIN#',
    note: 'Replace PIN with the 16-digit recharge PIN.',
    sourceLabel: 'Airtel official support',
  ),

  UssdCode(
    network: 'Airtel',
    category: 'Borrow',
    title: 'Borrow Airtime',
    code: '*303#',
    note: 'Access Airtel airtime loan services.',
    sourceLabel: 'Airtel official support',
  ),

  UssdCode(
    network: 'Airtel',
    category: 'Transfer',
    title: 'Me2U',
    code: '*321#',
    note: 'Access Airtel credit/data transfer services.',
    sourceLabel: 'Airtel official support',
  ),

  UssdCode(
    network: 'Airtel',
    category: 'Customer Care',
    title: 'Customer Care',
    code: '300',
    note: 'Airtel customer-care number.',
    sourceLabel: 'Airtel official support',
  ),

  UssdCode(
    network: 'Airtel',
    category: 'NIN',
    title: 'NIN Services',
    code: '*996#',
    note: 'Access Airtel NIN services.',
    sourceLabel: 'Airtel official support',
  ),

  // ==========================================================
  // GLO
  // ==========================================================
  UssdCode(
    network: 'Glo',
    category: 'Main Menu',
    title: 'Universal Self Service',
    code: '*301#',
    note:
        'Glo identifies *301# as its universal code for managing data, recharge, tariff services, borrowing and other services.',
    sourceLabel: 'Glo official website',
  ),

  UssdCode(
    network: 'Glo',
    category: 'Borrow',
    title: 'Borrow Airtime',
    code: '*303#',
    note: 'Access Glo Borrow Me Credit services.',
    sourceLabel: 'Glo official website',
  ),

  UssdCode(
    network: 'Glo',
    category: 'Customer Care',
    title: 'Customer Care',
    code: '300',
    note: 'Glo customer care short code.',
    sourceLabel: 'Glo official website',
  ),

  // ==========================================================
  // T2MOBILE
  // ==========================================================
  UssdCode(
    network: 'T2mobile',
    category: 'Main Menu',
    title: 'All-in-One Self Service',
    code: '*301#',
    note: 'T2mobile lists *301# as its all-in-one self-service short code.',
    sourceLabel: 'T2mobile official website',
  ),

  UssdCode(
    network: 'T2mobile',
    category: 'Data',
    title: 'Gift Data',
    code: '*312*6#',
    note: 'Use the T2mobile data gifting service.',
    sourceLabel: 'T2mobile official website',
  ),

  UssdCode(
    network: 'T2mobile',
    category: 'Data',
    title: 'Transfer Data',
    code: '*312*7#',
    note: 'Transfer data to another T2mobile user.',
    sourceLabel: 'T2mobile official website',
  ),

  UssdCode(
    network: 'T2mobile',
    category: 'Data',
    title: 'Family Share Data',
    code: '*312*8#',
    note: 'Access T2mobile family data sharing.',
    sourceLabel: 'T2mobile official website',
  ),

  UssdCode(
    network: 'T2mobile',
    category: 'Customer Care',
    title: 'Customer Care',
    code: '300',
    note: 'T2mobile customer care short code.',
    sourceLabel: 'T2mobile official website',
  ),

  UssdCode(
    network: 'T2mobile',
    category: 'Customer Care',
    title: 'Customer Care From Other Networks',
    code: '0809 000 0300',
    note:
        'T2mobile lists this number for customers calling from other networks.',
    sourceLabel: 'T2mobile official website',
  ),
];

// ============================================================
// USSD SCREEN
// ============================================================

class UssdScreen extends StatefulWidget {
  const UssdScreen({super.key});

  @override
  State<UssdScreen> createState() => _UssdScreenState();
}

class _UssdScreenState extends State<UssdScreen> {
  String selectedNetwork = 'MTN';
  String selectedCategory = 'All';
  String searchText = '';
  Set<String> favoriteCodes = const {};

  final networks = const ['MTN', 'Airtel', 'Glo', 'T2mobile'];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final codes = await AppPreferences.getFavoriteUssdCodes();
    if (!mounted) return;
    setState(() {
      favoriteCodes = codes;
    });
  }

  Future<void> _toggleFavorite(UssdCode code) async {
    await AppPreferences.toggleFavoriteUssdCode(code.code);
    await _loadFavorites();
  }

  List<UssdCode> get filteredCodes {
    return verifiedUssdCodes.where((item) {
      final matchesNetwork = item.network == selectedNetwork;

      final matchesCategory =
          selectedCategory == 'All' || item.category == selectedCategory;

      final query = searchText.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query) ||
          item.note.toLowerCase().contains(query);

      return matchesNetwork && matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> get categories {
    final values = verifiedUssdCodes
        .where((item) => item.network == selectedNetwork)
        .map((item) => item.category)
        .toSet()
        .toList();

    values.sort();

    return ['All', ...values];
  }

  List<UssdCode> get favoriteUssdCodes {
    return verifiedUssdCodes
        .where((item) => favoriteCodes.contains(item.code))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final codes = filteredCodes;

    return ToolScaffold(
      title: 'USSD Codes',
      icon: Icons.dialpad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ToolIntro(
            title: 'USSD Code Library',
            description:
                'Search useful network codes, save favorites, and copy them directly.',
          ),

          const SizedBox(height: 18),

          if (favoriteUssdCodes.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Favorites',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: favoriteUssdCodes.map((item) {
                      return ActionChip(
                        avatar: const Icon(Icons.star_rounded, size: 16),
                        label: Text(item.code),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${item.code} copied')),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          DropdownButtonFormField<String>(
            initialValue: selectedNetwork,
            decoration: const InputDecoration(labelText: 'Network'),
            items: networks
                .map(
                  (network) =>
                      DropdownMenuItem(value: network, child: Text(network)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                selectedNetwork = value;
                selectedCategory = 'All';
                searchText = '';
              });
            },
          ),

          const SizedBox(height: 12),

          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Codes',
              hintText: 'Example: balance, data, recharge',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: categories.contains(selectedCategory)
                ? selectedCategory
                : 'All',
            decoration: const InputDecoration(labelText: 'Category'),
            items: categories
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                selectedCategory = value;
              });
            },
          ),

          const SizedBox(height: 18),

          if (codes.isEmpty)
            const InfoCard(
              icon: Icons.search_off,
              title: 'No Matching Code',
              text: 'No code in this app version matches your search.',
            )
          else
            ...codes.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: UssdCodeCard(
                  code: item,
                  isFavorite: favoriteCodes.contains(item.code),
                  onToggleFavorite: () => _toggleFavorite(item),
                ),
              ),
            ),

          const SizedBox(height: 8),

          const InfoCard(
            icon: Icons.verified_outlined,
            title: 'Verification Note',
            text:
                'USSD services can change. Check the network operator before relying on a code for an important transaction.',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// USSD CODE CARD
// ============================================================

class UssdCodeCard extends StatelessWidget {
  final UssdCode code;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const UssdCodeCard({
    super.key,
    required this.code,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  Future<void> copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code.code));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${code.title} code copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    code.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFavorite ? Colors.amber : null,
                  ),
                ),
                Chip(
                  label: Text(code.category),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                code.code,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              code.note,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),

            const SizedBox(height: 8),

            Text(
              'Source: ${code.sourceLabel}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => copyCode(context),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NETWORK TOOLS
// ============================================================

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  String selectedNetwork = 'MTN';

  @override
  Widget build(BuildContext context) {
    final networkTips = {
      'MTN': [
        'Use *323# to check data balance quickly.',
        'Keep a note of your mobile data expiry day.',
        'Use the MTN self-service menu for plan changes.',
      ],
      'Airtel': [
        'Use *311# for recharge and quick account actions.',
        'Check *310# for account balance when needed.',
        'Use *321# for data and airtime transfer options.',
      ],
      'Glo': [
        'Use *301# for the primary self-service menu.',
        'Data and recharge actions are usually available from the menu.',
        'Check your bundle expiry from the balance menu if available.',
      ],
      'T2mobile': [
        'Use *301# for the all-in-one self-service menu.',
        'Gift and family data services are usually under the data menu.',
        'Check customer care details if a plan is not showing on the handset.',
      ],
    };

    final tips = networkTips[selectedNetwork] ?? networkTips['MTN']!;

    return ToolScaffold(
      title: 'Network Tools',
      icon: Icons.network_check,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ToolIntro(
            title: 'Network Utilities',
            description:
                'Smart tips, account checks, and quick mobile-network actions.',
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: selectedNetwork,
            decoration: const InputDecoration(labelText: 'Network'),
            items: networkTips.keys
                .map(
                  (network) =>
                      DropdownMenuItem(value: network, child: Text(network)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedNetwork = value;
                });
              }
            },
          ),

          const SizedBox(height: 18),

          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoCard(
                icon: Icons.check_circle_outline,
                title: 'Useful tip',
                text: tip,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const InfoCard(
            icon: Icons.signal_cellular_alt,
            title: 'Service status',
            text:
                'If your line is slow or not connecting, check coverage, APN settings, and the current service alerts from your mobile network.',
          ),

          const SizedBox(height: 12),

          const InfoCard(
            icon: Icons.speed,
            title: 'Data performance',
            text:
                'Use the data calculator, converter, and price tools together to better plan data use and avoid surprise top-ups.',
          ),
        ],
      ),
    );
  }
}

class PriceToolsScreen extends StatefulWidget {
  const PriceToolsScreen({super.key});

  @override
  State<PriceToolsScreen> createState() => _PriceToolsScreenState();
}

class _PriceToolsScreenState extends State<PriceToolsScreen> {
  final airtimeController = TextEditingController();
  final dataController = TextEditingController();
  final perMbController = TextEditingController();
  String airtimeResult = '';
  String dataResult = '';

  @override
  void dispose() {
    airtimeController.dispose();
    dataController.dispose();
    perMbController.dispose();
    super.dispose();
  }

  void _calculateAirtimePrice() {
    final value = _number(airtimeController.text);
    if (value == null || value < 0) {
      _message('Enter a valid airtime value.');
      return;
    }
    setState(() {
      airtimeResult = '₦${value.toStringAsFixed(2)}';
    });
  }

  void _calculateDataPrice() {
    final value = _number(dataController.text);
    final perMb = _number(perMbController.text);
    if (value == null || value <= 0) {
      _message('Enter a valid data amount in GB.');
      return;
    }
    if (perMb == null || perMb <= 0) {
      _message('Enter a valid price per GB.');
      return;
    }

    final estimatedCost = (value * 1024 * 1024 * perMb) / 1000000;
    setState(() {
      dataResult = '₦${estimatedCost.toStringAsFixed(2)}';
    });
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Price Tools',
      icon: Icons.attach_money,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ToolIntro(
            title: 'Airtime and Data Price Planner',
            description:
                'Quickly estimate airtime and data costs before buying a voucher or bundle.',
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Airtime value estimate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: airtimeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₦ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _calculateAirtimePrice,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Estimate Airtime'),
                  ),
                  if (airtimeResult.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ResultCard(
                      rows: [
                        ResultRow(
                          label: 'Airtime Value',
                          value: airtimeResult,
                          highlight: true,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data bundle estimate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dataController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Data amount',
                      suffixText: 'GB',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: perMbController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price per GB',
                      prefixText: '₦ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _calculateDataPrice,
                    icon: const Icon(Icons.attach_money),
                    label: const Text('Estimate Bundle Cost'),
                  ),
                  if (dataResult.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ResultCard(
                      rows: [
                        ResultRow(
                          label: 'Estimated Total',
                          value: dataResult,
                          highlight: true,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String preferredNetwork = 'MTN';
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    preferredNetwork = await AppPreferences.getPreferredNetwork();
    darkMode = await AppPreferences.getDarkMode();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _updateTheme(bool value) async {
    await AppPreferences.setDarkMode(value);
    AppSettingsController.darkMode.value = value;
    setState(() {
      darkMode = value;
    });
  }

  Future<void> _updateNetwork(String value) async {
    await AppPreferences.setPreferredNetwork(value);
    AppSettingsController.preferredNetwork.value = value;
    setState(() {
      preferredNetwork = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Settings',
      icon: Icons.settings_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ToolIntro(
            title: 'App Settings',
            description:
                'Customize the app to match your preferred mobile-network and theme setup.',
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark mode'),
                    subtitle: const Text(
                      'Use the dark theme throughout the app.',
                    ),
                    value: darkMode,
                    onChanged: _updateTheme,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: preferredNetwork,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Preferred network',
                    ),
                    items: const ['MTN', 'Airtel', 'Glo', 'T2mobile']
                        .map(
                          (network) => DropdownMenuItem(
                            value: network,
                            child: Text(network),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateNetwork(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AppPreferences.getAppVersionText(),
      builder: (context, snapshot) {
        final version = snapshot.data ?? '1.0.0 (1)';
        return ToolScaffold(
          title: 'About',
          icon: Icons.info_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToolIntro(
                title: 'Harryyor Telecom Tools',
                description:
                    'A practical telecom utility app built for airtime, data, USSD, and everyday network tasks.',
              ),
              const SizedBox(height: 18),
              InfoCard(
                icon: Icons.info_outline,
                title: 'App Version',
                text: 'Version $version',
              ),
              const SizedBox(height: 12),
              const InfoCard(
                icon: Icons.calculate_outlined,
                title: 'Built-in Calculator',
                text:
                    'Includes arithmetic, percentages, decimals, and parentheses for quick calculations.',
              ),
              const SizedBox(height: 12),
              const InfoCard(
                icon: Icons.dialpad,
                title: 'USSD Library',
                text:
                    'Search, save favorites, and copy the common telecom codes most users need every day.',
              ),
              const SizedBox(height: 12),
              const InfoCard(
                icon: Icons.ads_click,
                title: 'Advertising',
                text:
                    'AdMob support is enabled for supported mobile platforms. Web development testing does not load mobile AdMob ads.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Privacy',
      icon: Icons.privacy_tip_outlined,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToolIntro(
            title: 'Privacy Policy',
            description:
                'This privacy policy explains how this app handles your data and what remains private by design.',
          ),
          SizedBox(height: 18),
          InfoCard(
            icon: Icons.lock_outline,
            title: 'Local processing only',
            text:
                'The calculator, airtime tools, data tools, and converters process values locally on the device. No account is required and no personal telecom account data is transmitted by the app.',
          ),
          SizedBox(height: 12),
          InfoCard(
            icon: Icons.favorite_border,
            title: 'Favorites and settings',
            text:
                'Favorite USSD codes and app settings are saved on the device using local preferences so the app can remember your preferred network and theme choices.',
          ),
          SizedBox(height: 12),
          InfoCard(
            icon: Icons.dialpad,
            title: 'USSD code information',
            text:
                'The app shows public telecom USSD codes for informational use only. The app does not collect or store your mobile number, call logs, contacts, or message content when using these codes.',
          ),
          SizedBox(height: 12),
          InfoCard(
            icon: Icons.ads_click,
            title: 'Advertising data',
            text:
                'When ads are shown on supported mobile platforms, Google AdMob may process advertising-related data according to its own policies. The app itself does not require sign-in or upload personal account data.',
          ),
          SizedBox(height: 12),
          InfoCard(
            icon: Icons.update_outlined,
            title: 'Changes to this policy',
            text:
                'We may update this policy from time to time to reflect new features or legal requirements. The most recent version is the one presented in this app.',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMMON TOOL SCAFFOLD
// ============================================================

class ToolScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const ToolScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TOOL INTRO
// ============================================================

class ToolIntro extends StatelessWidget {
  final String title;
  final String description;

  const ToolIntro({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                description,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACTION BUTTONS
// ============================================================

class ActionButtons extends StatelessWidget {
  final String primaryText;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String secondaryText;
  final VoidCallback onSecondary;

  const ActionButtons({
    super.key,
    required this.primaryText,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryText,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: onPrimary,
          icon: Icon(primaryIcon),
          label: Text(primaryText),
        ),

        OutlinedButton(onPressed: onSecondary, child: Text(secondaryText)),
      ],
    );
  }
}

// ============================================================
// RESULT CARD
// ============================================================

class ResultCard extends StatelessWidget {
  final List<ResultRow> rows;

  const ResultCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              rows[i],

              if (i != rows.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: highlight ? 17 : 15,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),

        const SizedBox(width: 16),

        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: highlight ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

double? _number(String value) {
  return double.tryParse(value.replaceAll(',', '').trim());
}

String _pretty(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value
      .toStringAsFixed(8)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _naira(double value) {
  return '₦${value.toStringAsFixed(2)}';
}
