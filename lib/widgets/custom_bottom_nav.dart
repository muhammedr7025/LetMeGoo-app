import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onInformPressed;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onInformPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Remove fixed height and let it size naturally
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      // Add SafeArea inside the container instead of wrapping it
      child: SafeArea(
        top: false, // Don't add padding to the top
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                selectedIcon: Icons.search,
                unselectedIcon: Icons.search_outlined,
                label: 'Search',
                onTap: () => onTap(0),
              ),
              _buildNavItem(
                index: 2,
                selectedIcon: Icons.bar_chart,
                unselectedIcon: Icons.bar_chart_outlined,
                label: 'Reports',
                onTap: onInformPressed,
              ),
              _buildNavItem(
                index: 1,
                selectedIcon: Icons.person,
                unselectedIcon: Icons.person_outline,
                label: 'Profile',
                onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  color:
                      isSelected
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.5),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
