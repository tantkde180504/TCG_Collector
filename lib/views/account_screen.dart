import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../services/user_service.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';

// ── Shared pref keys ──────────────────────────────────────────────────────────
const _kNotifications = 'settings_notifications';
const _kSounds = 'settings_sounds';
const _kHaptics = 'settings_haptics';
const _kCurrency = 'settings_currency';
const _kLanguage = 'settings_language';

// ══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _AccountHeader(authVM: authVM)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── GENERAL ───────────────────────────────────────────────
                  _SectionHeader(label: 'General'),
                  _SettingsGroup(items: [
                    _SettingsTile(
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFF7B61FF),
                      label: 'Settings',
                      subtitle: 'Notifications, sound & currency',
                      onTap: () => _showSettings(context),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── ACCOUNT & LEGAL ───────────────────────────────────────
                  _SectionHeader(label: 'Account & Legal'),
                  _SettingsGroup(items: [
                    _SettingsTile(
                      icon: Icons.manage_accounts_rounded,
                      iconColor: Colors.amber,
                      label: 'Account Details',
                      subtitle: authVM.email.isNotEmpty
                          ? authVM.email
                          : 'Manage your trainer profile',
                      onTap: () => _showAccountDetails(context, authVM),
                    ),
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      iconColor: Colors.redAccent,
                      label: 'Delete Account',
                      subtitle: 'Permanently remove your data',
                      onTap: () => _showDeleteAccount(context, authVM),
                      isDestructive: true,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── HELP ─────────────────────────────────────────────────
                  _SectionHeader(label: 'Help'),
                  _SettingsGroup(items: [
                    _SettingsTile(
                      icon: Icons.rate_review_rounded,
                      iconColor: const Color(0xFF00C896),
                      label: 'Leave Feedback',
                      subtitle: 'Help us improve your experience',
                      onTap: () => _showFeedback(context, authVM),
                    ),
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFF4FC3F7),
                      label: 'Help Center',
                      subtitle: 'FAQs and support articles',
                      onTap: () => _showHelpCenter(context),
                    ),
                  ]),
                  // ── SHOPPING ──────────────────────────────────────────────
                  _SectionHeader(label: 'Shopping'),
                  _SettingsGroup(items: [
                    _SettingsTile(
                      icon: Icons.receipt_long_rounded,
                      iconColor: const Color(0xFF00C896),
                      label: 'Order History',
                      subtitle: 'View your recent purchases',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── ADDRESS ───────────────────────────────────────────────
                  _SectionHeader(label: 'Address'),
                  _SettingsGroup(items: [
                    _SettingsTile(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFFF7043),
                      label: 'Saved Addresses',
                      subtitle: 'Manage delivery locations',
                      onTap: () => _showAddresses(context, authVM),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── MORE OPTIONS ──────────────────────────────────────────
                  _SectionHeader(label: 'More Options'),
                  _SettingsGroup(items: [
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: Colors.redAccent,
                      label: 'Sign Out',
                      subtitle: 'Log out of your trainer account',
                      onTap: () => _confirmSignOut(context, authVM),
                      isDestructive: true,
                      showChevron: false,
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'PokéTCG Collector · v1.0.0',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _showSettings(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _SettingsSheet(),
      );

  void _showAccountDetails(BuildContext context, AuthViewModel authVM) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AccountDetailsSheet(authVM: authVM),
      );

  void _showDeleteAccount(BuildContext context, AuthViewModel authVM) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DeleteAccountSheet(authVM: authVM),
      );

  void _showFeedback(BuildContext context, AuthViewModel authVM) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FeedbackSheet(authVM: authVM),
      );

  void _showHelpCenter(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _HelpCenterSheet(),
      );

  void _showAddresses(BuildContext context, AuthViewModel authVM) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddressSheet(authVM: authVM),
      );

  void _confirmSignOut(BuildContext context, AuthViewModel authVM) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out of your trainer account?',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authVM.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ACCOUNT HEADER
// ══════════════════════════════════════════════════════════════════════════════

class _AccountHeader extends StatelessWidget {
  final AuthViewModel authVM;
  const _AccountHeader({required this.authVM});

  @override
  Widget build(BuildContext context) {
    final initials = authVM.displayName.trim().isNotEmpty
        ? authVM.displayName
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'T';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF2A2010)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 18,
                  spreadRadius: 3,
                )
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            authVM.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined,
                  size: 13, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 5),
              Text(
                authVM.email,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.amber.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.catching_pokemon, size: 14, color: Colors.amber),
                SizedBox(width: 6),
                Text(
                  'Pokémon Trainer',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
          ),
        ),
      );
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTile> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: List.generate(items.length, (i) {
            final isLast = i == items.length - 1;
            return Column(
              children: [
                items[i],
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
              ],
            );
          }),
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isDestructive
                              ? Colors.redAccent
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.22),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      );
}

// ── Sheet handle bar ──────────────────────────────────────────────────────────
Widget _sheetHandle() => Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

// ── Sheet decoration ──────────────────────────────────────────────────────────
BoxDecoration _sheetDecoration() => const BoxDecoration(
      color: Color(0xFF1A1A1A),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    );

// ── Sheet title row ───────────────────────────────────────────────────────────
Widget _sheetTitle(IconData icon, Color color, String title) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

// ══════════════════════════════════════════════════════════════════════════════
// 1. SETTINGS SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: _sheetDecoration(),
        child: Column(
          children: [
            _sheetHandle(),
            _sheetTitle(
                Icons.tune_rounded, const Color(0xFF7B61FF), 'Settings'),
            const SizedBox(height: 20),
            Expanded(
              child: !settingsVM.isLoaded
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.amber))
                  : ListView(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // ── Notifications ─────────────────────────────────
                        _SettingsCategoryLabel('Notifications & Sound'),
                        _ToggleRow(
                          icon: Icons.notifications_active_rounded,
                          iconColor: Colors.amber,
                          label: 'Push Notifications',
                          value: settingsVM.notifications,
                          onChanged: settingsVM.setNotifications,
                        ),
                        _ToggleRow(
                          icon: Icons.volume_up_rounded,
                          iconColor: const Color(0xFF4FC3F7),
                          label: 'Sound Effects',
                          value: settingsVM.sounds,
                          onChanged: settingsVM.setSounds,
                        ),
                        _ToggleRow(
                          icon: Icons.vibration_rounded,
                          iconColor: const Color(0xFF7B61FF),
                          label: 'Haptic Feedback',
                          value: settingsVM.haptics,
                          onChanged: (v) {
                            settingsVM.setHaptics(v);
                            settingsVM.triggerHaptic();
                          },
                        ),
                        const SizedBox(height: 20),
                        // ── Currency ──────────────────────────────────────
                        _SettingsCategoryLabel('Display'),
                        _SegmentRow(
                          icon: Icons.attach_money_rounded,
                          iconColor: const Color(0xFF00C896),
                          label: 'Currency',
                          options: const ['USD', 'EUR', 'VND'],
                          selected: settingsVM.currency,
                          onSelected: settingsVM.setCurrency,
                        ),
                        const SizedBox(height: 12),
                        _SegmentRow(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFFFF7043),
                          label: 'Language',
                          options: const ['English', 'Tiếng Việt'],
                          selected: settingsVM.language,
                          onSelected: settingsVM.setLanguage,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCategoryLabel extends StatelessWidget {
  final String label;
  const _SettingsCategoryLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      );
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
              Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.amber,
              activeTrackColor: Colors.amber.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.white12,
            ),
          ],
        ),
      );
}

class _SegmentRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _SegmentRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: options.map((opt) {
                final isSelected = selected == opt;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelected(opt),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? iconColor.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? iconColor
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        opt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? iconColor : Colors.white54,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. ACCOUNT DETAILS SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _AccountDetailsSheet extends StatefulWidget {
  final AuthViewModel authVM;
  const _AccountDetailsSheet({required this.authVM});

  @override
  State<_AccountDetailsSheet> createState() => _AccountDetailsSheetState();
}

class _AccountDetailsSheetState extends State<_AccountDetailsSheet> {
  late final TextEditingController _nameCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.authVM.displayName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final success =
        await widget.authVM.updateDisplayName(_nameCtrl.text.trim());
    if (!mounted) return;
    if (success) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to update profile. Try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = widget.authVM;
    final uid = authVM.userId;
    final shortId =
        uid.isNotEmpty && uid != 'mock_user_id' && uid.length >= 8
            ? '#${uid.substring(0, 8).toUpperCase()}'
            : '#DEMO0001';

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: _sheetDecoration(),
          child: Column(
            children: [
              _sheetHandle(),
              _sheetTitle(Icons.manage_accounts_rounded, Colors.amber,
                  'Account Details'),
              const SizedBox(height: 20),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Display Name
                      _DetailLabel('Trainer Name'),
                      if (_editing)
                        TextFormField(
                          controller: _nameCtrl,
                          style: const TextStyle(color: Colors.white),
                          autofocus: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.amber, width: 1.5),
                            ),
                            hintText: 'Enter your trainer name',
                            hintStyle:
                                TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name cannot be empty'
                              : null,
                        )
                      else
                        _DetailCard(
                          icon: Icons.person_rounded,
                          label: authVM.displayName,
                        ),
                      const SizedBox(height: 14),

                      // Email (read-only)
                      _DetailLabel('Email Address'),
                      _DetailCard(
                        icon: Icons.email_rounded,
                        label: authVM.email,
                        trailing: const Icon(Icons.lock_outline,
                            size: 14, color: Colors.white24),
                      ),
                      const SizedBox(height: 14),

                      // Trainer ID
                      _DetailLabel('Trainer ID'),
                      _DetailCard(
                        icon: Icons.badge_rounded,
                        label: shortId,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: uid));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Trainer ID copied!'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        trailing: const Icon(Icons.copy_rounded,
                            size: 14, color: Colors.white24),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      if (!_editing)
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _editing = true),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Profile'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber,
                              side: BorderSide(
                                  color:
                                      Colors.amber.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _nameCtrl.text = authVM.displayName;
                                  setState(() => _editing = false);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white54,
                                  side: const BorderSide(
                                      color: Colors.white24),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: authVM.isLoading
                                    ? null
                                    : _saveProfile,
                                icon: authVM.isLoading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2),
                                      )
                                    : const Icon(
                                        Icons.save_rounded,
                                        size: 16),
                                label: const Text('Save'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  final String text;
  const _DetailLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _DetailCard({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.amber, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. DELETE ACCOUNT SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _DeleteAccountSheet extends StatefulWidget {
  final AuthViewModel authVM;
  const _DeleteAccountSheet({required this.authVM});

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _pwCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _confirmed = false;

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please check the confirmation checkbox first.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success =
        await widget.authVM.deleteAccount(_pwCtrl.text.trim());
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '❌ Incorrect password or error. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: _sheetDecoration(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              _sheetTitle(Icons.delete_forever_rounded,
                  Colors.redAccent, 'Delete Account'),
              const SizedBox(height: 16),

              // Warning box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This will permanently delete your account, collection data, orders, and addresses. This action CANNOT be undone.',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Password field
              const Text('Enter your password to confirm:',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pwCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  hintText: 'Your password',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3)),
                  prefixIcon: const Icon(Icons.lock_rounded,
                      color: Colors.redAccent, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white38,
                        size: 18),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Colors.redAccent, width: 1.5),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Confirmation checkbox
              Row(
                children: [
                  Checkbox(
                    value: _confirmed,
                    onChanged: (v) =>
                        setState(() => _confirmed = v ?? false),
                    activeColor: Colors.redAccent,
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  const Expanded(
                    child: Text(
                      'I understand this action is permanent and cannot be undone.',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Delete button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: widget.authVM.isLoading
                      ? null
                      : _deleteAccount,
                  icon: widget.authVM.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(
                          Icons.delete_forever_rounded, size: 18),
                  label: const Text('Delete My Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. FEEDBACK SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _FeedbackSheet extends StatefulWidget {
  final AuthViewModel authVM;
  const _FeedbackSheet({required this.authVM});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  int _rating = 0;
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _sending = true);
    final success = await UserService.instance.submitFeedback(
      AppFeedback(
        rating: _rating,
        message: _msgCtrl.text.trim(),
        userId: widget.authVM.userId,
        userEmail: widget.authVM.email,
      ),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Thank you for your feedback!'
            : '❌ Failed to send feedback. Please try again.'),
        backgroundColor: success ? const Color(0xFF00C896) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: _sheetDecoration(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            _sheetTitle(Icons.rate_review_rounded,
                const Color(0xFF00C896), 'Leave Feedback'),
            const SizedBox(height: 20),

            const Text('How would you rate your experience?',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _msgCtrl,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tell us what you think... (optional)',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.28)),
                filled: true,
                fillColor: const Color(0xFF252525),
                counterStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF00C896), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 16),
                label: const Text('Submit Feedback',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 5. HELP CENTER SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _HelpCenterSheet extends StatelessWidget {
  const _HelpCenterSheet();

  static const _faqs = [
    {
      'q': 'How do I track my card prices?',
      'a':
          'Open any card\'s Detail page. The Market Price History chart fetches live prices from pokemontcg.io (TCGPlayer) and builds a daily history stored in our database. Tap the refresh icon to update manually.',
    },
    {
      'q': 'How does device verification work?',
      'a':
          'On first login from a new device, we send a 6-digit code to your email to verify it\'s really you. Once verified, that device is trusted automatically.',
    },
    {
      'q': 'Can I use the app offline?',
      'a':
          'Yes! The app falls back to local SQLite cache for card browsing, cart, and order history. Price updates and cloud sync require internet.',
    },
    {
      'q': 'How do I pay for orders?',
      'a':
          'We use PayOS for payments. Accepted methods include bank transfer, QR code, and e-wallets. All transactions are secured and encrypted.',
    },
    {
      'q': 'How do I update my delivery address?',
      'a':
          'Go to Account → Address → Saved Addresses. You can add, edit, delete addresses, or set one as your default.',
    },
    {
      'q': 'How do I delete my account?',
      'a':
          'Go to Account → Account & Legal → Delete Account. You\'ll need to enter your password to confirm. All your data will be permanently removed.',
    },
    {
      'q': 'I forgot my password. What do I do?',
      'a':
          'On the Login screen, tap "Forgot Password?" and enter your email. We\'ll send a password reset link from Firebase Authentication.',
    },
    {
      'q': 'How do I contact support?',
      'a':
          'Use the Leave Feedback section in Account, or chat with our AI assistant (Prof. Oak) via the Support tab for quick answers.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: _sheetDecoration(),
        child: Column(
          children: [
            _sheetHandle(),
            _sheetTitle(Icons.help_outline_rounded,
                const Color(0xFF4FC3F7), 'Help Center'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _faqs.length,
                separatorBuilder: (_, s1) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final faq = _faqs[i];
                  return Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                      childrenPadding: const EdgeInsets.fromLTRB(
                          14, 0, 14, 14),
                      backgroundColor: const Color(0xFF232323),
                      collapsedBackgroundColor: const Color(0xFF232323),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4FC3F7)
                              .withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.help_outline_rounded,
                            color: Color(0xFF4FC3F7), size: 15),
                      ),
                      title: Text(
                        faq['q']!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      iconColor: const Color(0xFF4FC3F7),
                      collapsedIconColor: Colors.white38,
                      children: [
                        Text(
                          faq['a']!,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              height: 1.55),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 6. ADDRESS SHEET (Full CRUD)
// ══════════════════════════════════════════════════════════════════════════════

class _AddressSheet extends StatefulWidget {
  final AuthViewModel authVM;
  const _AddressSheet({required this.authVM});

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  List<UserAddress> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);
    final result =
        await UserService.instance.getAddresses(widget.authVM.userId);
    if (!mounted) return;
    setState(() {
      _addresses = result;
      _loading = false;
    });
  }

  Future<void> _deleteAddress(String id) async {
    final ok = await UserService.instance
        .deleteAddress(widget.authVM.userId, id);
    if (!mounted) return;
    if (ok) {
      setState(
          () => _addresses.removeWhere((a) => a.id == id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setDefault(UserAddress addr) async {
    final updated = addr.copyWith(isDefault: true);
    final ok = await UserService.instance
        .updateAddress(widget.authVM.userId, updated);
    if (!mounted) return;
    if (ok) await _loadAddresses();
  }

  void _openAddForm({UserAddress? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(
        userId: widget.authVM.userId,
        editing: editing,
        onSaved: (_) => _loadAddresses(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: _sheetDecoration(),
        child: Column(
          children: [
            _sheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7043)
                          .withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Color(0xFFFF7043), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Saved Addresses',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _openAddForm(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.amber),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.amber))
                  : _addresses.isEmpty
                      ? _EmptyAddresses(onAdd: () => _openAddForm())
                      : ListView.separated(
                          controller: ctrl,
                          padding: const EdgeInsets.fromLTRB(
                              20, 4, 20, 20),
                          itemCount: _addresses.length,
                          separatorBuilder: (_, s2) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final addr = _addresses[i];
                            return _AddressTile(
                              address: addr,
                              onEdit: () =>
                                  _openAddForm(editing: addr),
                              onDelete: () =>
                                  _deleteAddress(addr.id),
                              onSetDefault: () =>
                                  _setDefault(addr),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyAddresses({required this.onAdd});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded,
              size: 48, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text('No saved addresses',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 15)),
          const SizedBox(height: 6),
          Text('Add your first delivery address',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 12)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_location_alt_rounded, size: 18),
            label: const Text('Add Address'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF7043),
              side: BorderSide(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      );
}

class _AddressTile extends StatelessWidget {
  final UserAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  IconData _labelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'office':
      case 'work':
        return Icons.business_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: address.isDefault
              ? Colors.amber.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7043).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _labelIcon(address.label),
                    color: const Color(0xFFFF7043),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  address.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                if (address.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.white38, size: 18),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 18),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (address.fullName.isNotEmpty || address.phoneNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  [if (address.fullName.isNotEmpty) address.fullName, if (address.phoneNumber.isNotEmpty) address.phoneNumber].join(' - '),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            Text(
              address.street,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13),
            ),
            Text(
              '${address.city}, ${address.country}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12),
            ),
            if (!address.isDefault) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onSetDefault,
                child: Text(
                  'Set as default',
                  style: TextStyle(
                      color: Colors.amber.withValues(alpha: 0.7),
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor:
                          Colors.amber.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 7. ADDRESS FORM SHEET (Add / Edit)
// ══════════════════════════════════════════════════════════════════════════════

class _AddressFormSheet extends StatefulWidget {
  final String userId;
  final UserAddress? editing;
  final void Function(UserAddress) onSaved;

  const _AddressFormSheet({
    required this.userId,
    this.editing,
    required this.onSaved,
  });

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  String _label = 'Home';
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _streetCtrl = TextEditingController(text: e?.street ?? '');
    _cityCtrl = TextEditingController(text: e?.city ?? '');
    _countryCtrl =
        TextEditingController(text: e?.country ?? 'Vietnam');
    _nameCtrl = TextEditingController(text: e?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: e?.phoneNumber ?? '');
    _label = e?.label ?? 'Home';
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final address = UserAddress(
      id: widget.editing?.id ?? '',
      label: _label,
      fullName: _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      street: _streetCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      isDefault: _isDefault,
    );

    bool ok;
    UserAddress? saved;
    if (widget.editing != null) {
      ok = await UserService.instance
          .updateAddress(widget.userId, address);
      if (ok) saved = address;
    } else {
      saved = await UserService.instance
          .addAddress(widget.userId, address);
      ok = saved != null;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok && saved != null) {
      widget.onSaved(saved);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editing != null
              ? '✅ Address updated!'
              : '✅ Address added!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to save address. Try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.28), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFFFF7043), size: 18),
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFFFF7043), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: _sheetDecoration(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                _sheetTitle(
                    isEdit
                        ? Icons.edit_location_rounded
                        : Icons.add_location_alt_rounded,
                    const Color(0xFFFF7043),
                    isEdit ? 'Edit Address' : 'Add Address'),
                const SizedBox(height: 20),

                // Label selector
                const Text('Address Label',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: ['Home', 'Office', 'Other']
                      .map((l) => Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _label = l),
                              child: Container(
                                margin:
                                    const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: _label == l
                                      ? const Color(0xFFFF7043)
                                          .withValues(alpha: 0.2)
                                      : const Color(0xFF252525),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _label == l
                                        ? const Color(0xFFFF7043)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  l,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _label == l
                                        ? const Color(0xFFFF7043)
                                        : Colors.white54,
                                    fontWeight: _label == l
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Name & Phone
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(
                      'Full Name', Icons.person_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _phoneCtrl,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                      'Phone Number', Icons.phone_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),

                // Street
                TextFormField(
                  controller: _streetCtrl,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(
                      'Street address, building, floor...',
                      Icons.location_on_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),

                // City + Country
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityCtrl,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                        decoration: _inputDecoration(
                            'City', Icons.location_city_rounded),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _countryCtrl,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                        decoration: _inputDecoration(
                            'Country', Icons.flag_rounded),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Default toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Set as default address',
                            style: TextStyle(
                                color: Colors.white, fontSize: 14)),
                      ),
                      Switch(
                        value: _isDefault,
                        onChanged: (v) =>
                            setState(() => _isDefault = v),
                        activeThumbColor: Colors.amber,
                        activeTrackColor: Colors.amber.withValues(alpha: 0.3),
                        inactiveTrackColor: Colors.white12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2))
                        : Icon(
                            isEdit
                                ? Icons.save_rounded
                                : Icons.add_location_alt_rounded,
                            size: 18),
                    label: Text(isEdit ? 'Save Changes' : 'Add Address',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7043),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
