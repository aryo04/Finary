import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/app/app.dart';
import 'package:cakeu/core/services/supabase_service.dart';
import 'package:cakeu/core/services/vault_security_service.dart';
import 'package:cakeu/features/auth/data/repositories/auth_repository.dart';
import 'package:cakeu/features/auth/presentation/providers/auth_provider.dart';
import 'package:cakeu/features/categories/data/repositories/category_repository.dart';
import 'package:cakeu/features/categories/presentation/providers/category_provider.dart';
import 'package:cakeu/features/chatbot/data/repositories/chatbot_repository.dart';
import 'package:cakeu/features/chatbot/presentation/providers/chatbot_provider.dart';
import 'package:cakeu/features/transactions/data/repositories/transaction_repository.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';

import 'package:cakeu/features/wallets/data/repositories/wallet_repository.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi koneksi Supabase secara aman
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  // Inisialisasi Vault & Kunci Keamanan
  try {
    await VaultSecurityService().init();
  } catch (e) {
    debugPrint('VaultSecurityService initialization warning: $e');
  }

  // Inisialisasi repositories
  final authRepository = AuthRepository();
  final categoryRepository = CategoryRepository();
  final transactionRepository = TransactionRepository();
  final chatbotRepository = ChatbotRepository();
  final walletRepository = WalletRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository)..checkSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(
            repository: walletRepository,
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(categoryRepository),
        ),
        ChangeNotifierProvider(
          create: (ctx) {
            final txProvider = TransactionProvider(transactionRepository);
            final walletProvider = ctx.read<WalletProvider>();
            walletProvider.onTransactionsChanged = () {
              txProvider.fetchTransactions(forceRefresh: true);
            };
            return txProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (ctx) {
            final chatProvider = ChatbotProvider(chatbotRepository, transactionRepository);
            final txProvider = ctx.read<TransactionProvider>();
            txProvider.onTransactionDeleted = (deletedId) {
              chatProvider.syncTransactionDeleted(deletedId);
            };
            return chatProvider;
          },
        ),
      ],
      child: const CakeuApp(),
    ),
  );
}
