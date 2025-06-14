import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_state.dart';
// Import your screens
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/shop_landing_screen.dart'; // Changed from market_screen.dart
import 'screens/gold_shop_screen.dart'; // Import GoldShopScreen
import 'screens/battle_screen.dart';
import 'screens/floor_selection_screen.dart';
import 'screens/card_pedia_screen.dart'; // Import the new CardPediaScreen
import 'screens/talent_guide_landing_screen.dart'; // Import the new Talent Guide Landing Screen
import 'screens/elements_guide_screen.dart'; // Import the new Elements Guide Screen
import 'screens/talents_list_guide_screen.dart'; // Import the new Talents List Guide Screen
import 'screens/event_cards_shop_screen.dart'; // Import Event Cards Shop Screen
import 'screens/user_profile_screen.dart'; // Import UserProfileScreen
import 'widgets/themed_scaffold.dart'; // Import ThemedScaffold

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // It's good practice to save one last time when the app is fully closing,
    // though 'detached' should also cover this.
    Provider.of<GameState>(context, listen: false).saveGameState();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final gameState = Provider.of<GameState>(context, listen: false);
    if (state == AppLifecycleState.paused) {
      // App is going to the background
      gameState.saveGameState();
      print("App paused, game state saved.");
    } else if (state == AppLifecycleState.detached) {
      // App is being terminated
      // Note: 'detached' might not always be reliably called on all platforms (especially iOS).
      // 'paused' is more reliable for saving state before potential termination.
      gameState.saveGameState();
      print("App detached, game state saved.");
    } else if (state == AppLifecycleState.resumed) {
      // App is coming to the foreground
      // You might want to reload or refresh certain things here if necessary,
      // but GameState already loads on creation.
      print("App resumed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniGame Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          // You can further customize primaryContainer if needed
          // primaryContainer: Colors.deepPurple.shade100, // Example
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent, // Default scaffold is transparent
        appBarTheme: AppBarTheme(
          backgroundColor: ColorScheme.fromSeed(seedColor: Colors.deepPurple).primaryContainer, // Consistent AppBar color
        ),
      ),
      initialRoute: '/', // Use initialRoute for clarity
      routes: {
        '/': (context) => const HomeScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/shop_landing': (context) => const ShopLandingScreen(), // Changed route and screen
        '/gold_shop': (context) => const GoldShopScreen(), // Added GoldShopScreen route
        '/battle': (context) => const BattleScreen(),
        '/floor_selection': (context) => const FloorSelectionScreen(),
        '/card_pedia': (context) => const CardPediaScreen(),
        '/talent_guide': (context) => const TalentGuideLandingScreen(),
        '/elements_guide': (context) => const ElementsGuideScreen(),
        '/talents_list_guide': (context) => const TalentsListGuideScreen(),
        '/user_profile': (context) => const UserProfileScreen(), // Updated route
        '/events': (context) => const PlaceholderScreen(title: "Events"), // Added Events route
        '/event_cards_shop': (context) => const EventCardsShopScreen(), // Added route
      },
    );
  }
}

// A simple placeholder widget for unimplemented screens
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold( // Use ThemedScaffold
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 20.0, // Smaller icon
          padding: const EdgeInsets.all(5.0), // Reduced padding
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(title),
        toolbarHeight: 30, // Set the AppBar height to 30
      ),
      body: Center(
        child: Text("$title Screen - Coming Soon!", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white.withOpacity(0.85))), // Adjusted text color for better visibility on background
      ),
    );
  }
}
