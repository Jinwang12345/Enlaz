import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/home_screen.dart';
import '../screens/profile_menu_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/contacts_screen.dart';
import '../screens/add_friend_screen.dart';
import '../screens/product_detail.dart';
import '../screens/nearby_stores_screen.dart';
import '../screens/wallet/bonus_market_screen.dart';
import '../screens/wallet/top_up_screen.dart';
import '../screens/wallet/send_money_screen.dart';
import '../models/product_model.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../providers/user_provider.dart';
import '../services/chat_service.dart';

// Configuración de navegación (GoRouter)
final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(userProvider);
  if (user != null) {
    ref.watch(chatServiceProvider);
  }

  return GoRouter(
    initialLocation: user != null ? '/' : '/login',
    redirect: (context, state) {
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isGoingToAuth = isAuthRoute;

      if (!isLoggedIn && !isGoingToAuth) {
        return '/login';
      }

      if (isLoggedIn && isGoingToAuth) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/', builder: (context, state) => const ProfileMenuScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(
        path: '/chat/detail',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ChatDetailScreen(
            contactId: args['contactId'] as String,
            contactName: args['contactName'] as String,
            contactAvatar: args['contactAvatar'] as String,
          );
        },
      ),
      GoRoute(path: '/discover', builder: (context, state) => const DiscoverScreen()),
      GoRoute(path: '/contacts', builder: (context, state) => const ContactsScreen()),
      GoRoute(path: '/contacts/add', builder: (context, state) => const AddFriendScreen()),
      GoRoute(path: '/market', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/nearby', builder: (context, state) => const NearbyStoresScreen()),
      GoRoute(path: '/wallet/bonuses', builder: (context, state) => const BonusMarketScreen()),
      GoRoute(path: '/wallet/topup', builder: (context, state) => const TopUpScreen()),
      GoRoute(path: '/wallet/send', builder: (context, state) => const SendMoneyScreen()),
      GoRoute(
        path: '/product-detail',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return ProductDetailScreen(product: product);
        },
      ),
    ],
  );
});
