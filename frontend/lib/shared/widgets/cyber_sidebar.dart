import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_provider.dart';

class CyberSidebar extends ConsumerWidget {
  final String currentRoute;

  const CyberSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final role = user?.role ?? 'apprenant';

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: AppColors.sidebarGradient,
        border: Border(
          right: BorderSide(color: Color(0xFF1e293b), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1e293b), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.cyberGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCyan.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'CA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CYBER ACADEMY',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'E-DEFENCE',
                      style: GoogleFonts.inter(
                        color: AppColors.accentCyan,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  if (role == 'apprenant' || role == 'admin') ...[
                    _NavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Accueil',
                      route: '/dashboard',
                      currentRoute: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.school_outlined,
                      label: 'Mes parcours',
                      route: '/dashboard',
                      currentRoute: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.terminal_outlined,
                      label: 'Cyber Range',
                      route: '/dashboard/parcours/-/labs',
                      currentRoute: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Mes badges',
                      route: '/dashboard/badges',
                      currentRoute: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.smart_toy_outlined,
                      label: 'TARGUI IA',
                      route: '/dashboard/targui',
                      currentRoute: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Agenda mentors',
                      route: '/dashboard',
                      currentRoute: currentRoute,
                    ),
                  ],
                  if (role == 'mentor') ...[
                    _NavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Tableau de bord',
                      route: '/mentor/dashboard',
                      currentRoute: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.people_outlined,
                      label: 'Mes apprenants',
                      route: '/mentor/dashboard',
                      currentRoute: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Sessions',
                      route: '/mentor/dashboard',
                      currentRoute: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.assignment_outlined,
                      label: 'Livrables',
                      route: '/mentor/dashboard',
                      currentRoute: currentRoute,
                    ),
                  ],
                  if (role == 'admin') ...[
                    const _SidebarDivider(label: 'Administration'),
                    _NavItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Back-office',
                      route: '/admin/dashboard',
                      currentRoute: currentRoute,
                    ),
                  ],
                  if (role == 'b2b') ...[
                    _NavItem(
                      icon: Icons.business_outlined,
                      label: 'Mon entreprise',
                      route: '/b2b/dashboard',
                      currentRoute: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.people_outlined,
                      label: 'Mon équipe',
                      route: '/b2b/dashboard',
                      currentRoute: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Facturation',
                      route: '/b2b/dashboard',
                      currentRoute: currentRoute,
                    ),
                  ],
                  const Spacer(),
                  // Catalogue link
                  _NavItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Catalogue',
                    route: '/catalogue',
                    currentRoute: currentRoute,
                  ),
                ],
              ),
            ),
          ),

          // User section at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1e293b))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.cyberGradient,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Center(
                        child: Text(
                          user?.initials ?? 'U',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.prenom ?? 'Utilisateur',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            user?.profil ?? '',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(
                        Icons.logout_outlined,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      tooltip: 'Se déconnecter',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  bool get isActive => currentRoute.startsWith(route) && route != '/dashboard' ||
      currentRoute == route;

  @override
  Widget build(BuildContext context) {
    final active = currentRoute == route ||
        (route != '/dashboard' && currentRoute.startsWith(route));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.accentCyan.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active
                ? Border.all(color: AppColors.accentCyan.withOpacity(0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.accentCyan : const Color(0xFF64748b),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: active ? Colors.white : const Color(0xFF94a3b8),
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (active) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.accentCyan,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  final String label;
  const _SidebarDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              color: const Color(0xFF475569),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: Color(0xFF1e293b), height: 1)),
        ],
      ),
    );
  }
}
