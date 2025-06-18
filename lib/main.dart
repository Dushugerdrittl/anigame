import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import generated Firebase options
import 'game_state.dart';
// Import your screens
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/shop_landing_screen.dart'; // Changed from market_screen.dart
import 'screens/gold_shop_screen.dart'; // Import GoldShopScreen
import 'screens/battle_screen.dart';
import 'screens/floor_selection_screen.dart';
import 'screens/card_pedia_screen.dart'; // Import the new CardPediaScreen
import 'screens/talent_guide_screen.dart'; // Import the new Talent Guide Landing Screen
import 'screens/elements_guide_screen.dart'; // Import the new Elements Guide Screen
import 'screens/event_cards_shop_screen.dart'; // Import Event Cards Shop Screen
import 'screens/event_screen.dart'; // Import the actual EventScreen
import 'screens/raid_battle_screen.dart'; // Import RaidBattleScreen
import 'screens/raid_lobby_screen.dart'; // Import RaidLobbyScreen
import 'screens/user_profile_screen.dart'; // Import UserProfileScreen
import 'screens/login_screen.dart'; // Import LoginScreen
import 'screens/register_screen.dart'; // Import RegisterScreen
import 'widgets/themed_scaffold.dart'; // Import ThemedScaffold
import 'screens/raid_guide_screen.dart'; // Import RaidGuideScreen
import 'utils/admin_actions.dart'; // Import your AdminActions

void main() async {
  // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp(
    // Initialize Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create GameState instance
  final gameState = GameState();

  // !!! --- TEMPORARY ADMIN ACTION CALL --- !!!
  // This will run every time the app starts.
  // REMEMBER TO REMOVE OR COMMENT THIS OUT AFTER TESTING.
  // Ensure the user "astolf" is logged in for UI to update,
  // or check Firestore directly for other users.
  //AdminActions admin = AdminActions(gameState);
  // Example: Give gold to Astolf every time the app starts (for testing)
  //await admin.giveGoldToAstolf();
  // print("MAIN.DART: Attempted to run admin.giveGoldToAstolf()");

  runApp(
    // Your existing runApp call
    ChangeNotifierProvider(
      create: (context) => gameState, // Use the instance we created
      child: MyApp(
        gameState: gameState,
      ), // Pass gameState if needed by MyApp directly
    ),
  );
}

class MyApp extends StatefulWidget {
  // const MyApp({super.key}); // Old constructor

  // If MyApp needs gameState directly, you can pass it like this:
  final GameState gameState;
  const MyApp({super.key, required this.gameState});

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
        appBarTheme: AppBarTheme(
          backgroundColor: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          ).primaryContainer, // Consistent AppBar color
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white24,
        ),
      ),
      home: const AuthWrapper(), // Use AuthWrapper to determine initial screen
      routes: {
        // '/': (context) => const HomeScreen(), // AuthWrapper handles initial '/'
        '/inventory': (context) => const InventoryScreen(),
        '/raid_guide': (context) =>
            const RaidGuideScreen(), // Added RaidGuideScreen route
        '/shop_landing': (context) =>
            const ShopLandingScreen(), // Changed route and screen
        '/gold_shop': (context) =>
            const GoldShopScreen(), // Added GoldShopScreen route
        '/battle': (context) => const BattleScreen(),
        '/floor_selection': (context) => const FloorSelectionScreen(),
        '/card_pedia': (context) => const CardPediaScreen(),
        '/talent_guide': (context) => const TalentGuideScreen(),
        '/elements_guide': (context) => const ElementsGuideScreen(),
        '/user_profile': (context) =>
            const UserProfileScreen(), // Updated route
        '/event_cards_shop': (context) =>
            const EventCardsShopScreen(), // Added route
        '/events': (context) => const EventScreen(),
        '/raid_lobby': (context) {
          // Route for RaidLobbyScreen
          final raidId = ModalRoute.of(context)!.settings.arguments as String?;
          if (raidId == null) {
            return const PlaceholderScreen(
              title: "Error: Raid ID missing",
            ); // Or handle error differently
          }
          return RaidLobbyScreen(raidId: raidId);
        },
        '/raid_battle': (context) {
          // Route for RaidBattleScreen
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          if (args == null ||
              args['raidId'] == null ||
              args['playerTeamCardIds'] == null) {
            return const PlaceholderScreen(
              title: "Error: Missing arguments for battle",
            );
          }
          return RaidBattleScreen(
            raidId: args['raidId'] as String,
            playerTeamCardIds: args['playerTeamCardIds'] as List<String>,
          );
        },
        // Keep named routes for explicit navigation if needed
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to GameState to react to login status changes
    final gameState = context.watch<GameState>();

    // GameState's auth listener updates isUserLoggedIn based on Firebase's persisted session.
    if (gameState.isUserLoggedIn) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}

// A simple placeholder widget for unimplemented screens
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      // Use ThemedScaffold
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
        child: Text(
          "$title Screen - Coming Soon!",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white.withOpacity(0.85),
          ),
        ), // Adjusted text color for better visibility on background
      ),
    );
  }
}
