import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cakeu/core/services/vault_security_service.dart';
import 'package:cakeu/features/security/presentation/widgets/pin_lock_screen.dart';
import 'package:cakeu/shared/widgets/cakeu_bottom_nav_bar.dart';

/// Main shell widget with StatefulNavigationShell, App Lock overlay, and Lifecycle observer.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  final VaultSecurityService _vault = VaultSecurityService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app goes into background or is minimized
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (!_vault.isPickingMedia && (_vault.isAppLockEnabled || _vault.isVaultEnabled)) {
        _vault.lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vault,
      builder: (context, _) {
        if (!_vault.isUnlocked && (_vault.isAppLockEnabled || _vault.isVaultEnabled)) {
          return PinLockScreen(
            onUnlocked: () {},
          );
        }

        return Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: CakeuBottomNavBar(
            currentIndex: widget.navigationShell.currentIndex,
            onTap: (index) {
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            },
          ),
        );
      },
    );
  }
}
