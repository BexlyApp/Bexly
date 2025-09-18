import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:invoiceandbilling/views/analytics/analytics.dart';
import 'package:invoiceandbilling/views/settings/settings.dart';

import '../views/home/home.dart';
import '../views/invoices/invoices.dart';
import '../views/reports/reports.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const InvoiceListScreen(),
     ReportsScreen(),
    AnalyticsDashboard(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.6 * 255).toInt()),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF6C5CE7),
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 0
                        ? const Color(0xFF6C5CE7).withAlpha((0.2 * 255).toInt())
                        : Colors.transparent,
                  ),
                  child: const Icon(Iconsax.home),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 1
                        ? const Color(0xFF6C5CE7).withAlpha((0.1 * 255).toInt())
                        : Colors.transparent,
                  ),
                  child: const Icon(Iconsax.receipt),
                ),
                label: 'Invoices',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 2
                        ? const Color(0xFF6C5CE7).withAlpha((0.4 * 255).toInt())
                        : Colors.transparent,
                  ),
                  child: const Icon(Iconsax.chart),
                ),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 3
                        ? const Color(0xFF6C5CE7).withAlpha((0.4 * 255).toInt())
                        : Colors.transparent,
                  ),
                  child: const Icon(Iconsax.activity),
                ),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 4
                        ? const Color(0xFF6C5CE7).withAlpha((0.4 * 255).toInt())
                        : Colors.transparent,
                  ),
                  child: const Icon(Iconsax.setting),
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}