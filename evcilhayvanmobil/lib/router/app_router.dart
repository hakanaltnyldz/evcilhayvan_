import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:evcilhayvanmobil/main_shell.dart';


// Auth ekranları
import '../features/auth/presentation/screens/edit_profile_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/settings_screen.dart';
import '../features/auth/presentation/screens/verification_screen.dart';

// Diğer ekranlar
import '../features/connect/presentation/screens/connect_screen.dart';
import '../features/mating/presentation/screens/mating_screen.dart';
import '../features/messages/presentation/screens/chat_screen.dart';
import '../features/messages/presentation/screens/messages_screen.dart';
import '../features/pets/domain/models/pet_model.dart';
import '../features/pets/presentation/screens/create_pet_screen.dart';
import '../features/pets/presentation/screens/home_screen.dart';
import '../features/pets/presentation/screens/pet_detail_screen.dart';
import '../features/store/presentation/screens/store_detail_screen.dart';
import '../features/store/presentation/screens/store_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Sayfa Bulunamadı!')),
  ),
  routes: [
    // Alt navigasyonlu sayfalar
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return MainShell(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/connect',
          name: 'connect',
          builder: (context, state) => const ConnectScreen(),
        ),
        GoRoute(
          path: '/store',
          name: 'store',
          builder: (context, state) => const StoreScreen(),
        ),
        GoRoute(
          path: '/mating',
          name: 'mating',
          builder: (context, state) => const MatingScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/messages',
          name: 'messages',
          builder: (context, state) => const MessagesScreen(),
        ),
      ],
    ),

    // Alt bar olmayan sayfalar
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      name: 'verify-email',
      builder: (context, state) {
        final String email = state.extra as String;
        return VerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      name: 'reset-password',
      builder: (context, state) {
        final String email = state.extra as String;
        return ResetPasswordScreen(email: email);
      },
    ),
    GoRoute(
      path: '/create-pet',
      name: 'create-pet',
      builder: (context, state) {
        Pet? petToEdit;
        if (state.extra != null && state.extra is Pet) {
          petToEdit = state.extra as Pet;
        }
        return CreatePetScreen(petToEdit: petToEdit);
      },
    ),
    GoRoute(
      path: '/pet/:id',
      name: 'pet-detail',
      builder: (context, state) {
        final String petId = state.pathParameters['id']!;
        return PetDetailScreen(petId: petId);
      },
    ),

    // Chat
    GoRoute(
      path: '/chat/:conversationId',
      name: 'chat',
      builder: (context, state) {
        final String convId = state.pathParameters['conversationId']!;
        String receiverName = 'Kullanıcı';
        String? avatarUrl;

        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          receiverName = extra['name'] as String? ?? receiverName;
          avatarUrl = extra['avatar'] as String?;
        } else if (extra is String) {
          receiverName = extra;
        }

        return ChatScreen(
          conversationId: convId,
          receiverName: receiverName,
          receiverAvatarUrl: avatarUrl,
        );
      },
    ),

    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/store/:id',
      name: 'store-detail',
      builder: (context, state) {
        final String storeId = state.pathParameters['id']!;
        return StoreDetailScreen(storeId: storeId);
      },
    ),
  ],
);