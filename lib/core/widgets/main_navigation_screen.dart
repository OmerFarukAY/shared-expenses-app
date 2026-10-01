import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:denk/features/groups/presentation/group_action_sheet.dart';
import 'package:denk/features/groups/presentation/groups_list_screen.dart';
import 'package:denk/features/settings/presentation/settings_screen.dart';
import 'package:denk/l10n/l10n.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    GroupsListScreen(isTab: true),
    SettingsScreen(isTab: true),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isApple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    final showLiquidGlass = NativeLiquidGlassUtils.supportsLiquidGlass;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          if (showLiquidGlass)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LiquidGlassTabBar(
                currentIndex: _currentIndex,
                onTabSelected: _onTabTapped,
                selectedItemColor: theme.colorScheme.primary,
                iosItemPositioning: LiquidGlassTabBarItemPositioning.centered,
                iosItemSpacing: 48,
                iosItemWidth: 100,
                iosActionButton: LiquidGlassTabItem(
                  label: l10n?.createGroup ?? 'Ekle',
                  icon: const NativeLiquidGlassIcon.sfSymbol('plus'),
                ),
                onActionButtonPressed: () => GroupActionSheet.show(context),
                items: [
                  LiquidGlassTabItem(
                    label: l10n?.appName ?? 'Denk',
                    icon: const NativeLiquidGlassIcon.sfSymbol('person.3'),
                    selectedIcon: const NativeLiquidGlassIcon.sfSymbol(
                      'person.3.fill',
                    ),
                  ),
                  LiquidGlassTabItem(
                    label: l10n?.settingsTitle ?? 'Settings',
                    icon: const NativeLiquidGlassIcon.sfSymbol('gearshape'),
                    selectedIcon: const NativeLiquidGlassIcon.sfSymbol(
                      'gearshape.fill',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: showLiquidGlass
          ? null
          : (isApple
                ? CupertinoTabBar(
                    currentIndex: _currentIndex,
                    onTap: _onTabTapped,
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF8E8E93),
                    backgroundColor: isDark
                        ? const Color(0xE61C1C1E)
                        : const Color(0xE6F8F8F8),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0x2EFFFFFF)
                            : const Color(0x33000000),
                        width: 0.5,
                      ),
                    ),
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(CupertinoIcons.person_3),
                        activeIcon: const Icon(CupertinoIcons.person_3_fill),
                        label: l10n?.appName ?? 'Denk',
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(CupertinoIcons.gear),
                        activeIcon: const Icon(CupertinoIcons.gear_solid),
                        label: l10n?.settingsTitle ?? 'Settings',
                      ),
                    ],
                  )
                : NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _onTabTapped,
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.group_outlined),
                        selectedIcon: const Icon(Icons.group),
                        label: l10n?.appName ?? 'Denk',
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.settings_outlined),
                        selectedIcon: const Icon(Icons.settings),
                        label: l10n?.settingsTitle ?? 'Settings',
                      ),
                    ],
                  )),
    );
  }
}
