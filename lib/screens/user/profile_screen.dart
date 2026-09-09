import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_locale.dart';
import '../../providers/auth_provider.dart';
import '../../services/naql_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = NaqlApi();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    final token = context.read<AuthProvider>().token;
    _statsFuture = _api.userStats(token!);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = LocaleController.of(context, listen: false);
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayName = user.username ?? user.email ?? 'Naql customer';
    final phone = user.phoneNumber;

    final menuItems = <_MenuItem>[
      _MenuItem(icon: '💳', label: s.paymentMethods, sub: s.paymentMethodsSub, onTap: () {}),
      _MenuItem(icon: '📍', label: s.savedAddresses, sub: s.savedAddressesSub, onTap: () {}),
      _MenuItem(
        icon: '📱',
        label: phone == null ? s.addPhone : s.editPhone,
        sub: phone ?? s.contactInfo,
        onTap: () => _openPhoneEdit(s),
      ),
      _MenuItem(
        icon: '🌐',
        label: s.language,
        sub: locale.lang.label,
        onTap: () => _openLanguagePicker(locale),
      ),
      _MenuItem(icon: '🛡', label: s.privacy, sub: '', onTap: () {}),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _statsFuture = _api.userStats(context.read<AuthProvider>().token!));
        await _statsFuture;
      },
      child: SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kRedLight,
              shape: BoxShape.circle,
              border: Border.all(color: kRedBorder, width: 3),
            ),
            child: Center(
              child: Text(
                'MS',
                style: outfitStyle(
                    size: 26, weight: FontWeight.w800, color: kRed),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(displayName,
              style: outfitStyle(size: 20, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          // Contact phone (for reaching the customer).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, color: kRed, size: 16),
              const SizedBox(width: 6),
              Text(
                phone ?? s.contactInfo,
                style: interStyle(size: 14, color: phone == null ? kUserMuted : kUserText),
              ),
              if (phone != null) ...[
                const SizedBox(width: 6),
                Text(
                  s.t('Service: 01555444333', 'خدمه عملاد 01555444333'),
                  style: interStyle(size: 11, color: kUserMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final trips = snapshot.data?['trips'] ?? '0';
              final rating = snapshot.data?['rating'] ?? '0.0';
              final saved = snapshot.data?['savedEGP'] ?? '0';
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stat('$trips', s.trips),
                  _divider(),
                  _stat('$rating ⭐', s.rating),
                  _divider(),
                  _stat('$saved ${s.egp}', s.saved),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: menuItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.circular(0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: kUserSubtle,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(item.icon,
                                    style: const TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.label,
                                      style: interStyle(
                                          size: 14, weight: FontWeight.w500)),
                                  if (item.sub.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(item.sub,
                                        style: interStyle(
                                            size: 12, color: kUserMuted)),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Color(0xFFD1D5DB), size: 20),
                          ],
                        ),
                      ),
                    ),
                    if (i < menuItems.length - 1)
                      const Divider(height: 1, indent: 64, color: Color(0xFFF9FAFB)),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Color(0xFFFFE2E2)),
                backgroundColor: const Color(0xFFFFF1F2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(s.signOut,
                  style: outfitStyle(
                      size: 15, weight: FontWeight.w600, color: Colors.red)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
      ),
    );
  }

  void _openPhoneEdit(S s) async {
    final phone = context.read<AuthProvider>().user?.phoneNumber ?? '';
    final controller = TextEditingController(text: phone);
    final ok = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.editPhone,
            style: outfitStyle(size: 18, weight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: s.yourPhone,
              hintText: s.phoneHint,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancelBtn)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );

    if (ok == null || ok.isEmpty) return;

    final normalized = _normalizePhone(ok);
    final updated = await context.read<AuthProvider>().updatePhone(normalized);
    if (!mounted) return;
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('Phone updated.', 'تم تحديث الهاتف.'))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('Could not update phone. Try a +20… number.', 'تعذر تحديث الهاتف. جرّب رقم بصيغة +20….'))),
      );
    }
  }

  String _normalizePhone(String raw) {
    var v = raw.replaceAll(RegExp(r'\s+'), '');
    if (v.startsWith('00')) v = '+${v.substring(2)}';
    if (!v.startsWith('+')) v = '+$v';
    return v;
  }

  void _openLanguagePicker(LocaleController locale) async {
    final picked = await showDialog<AppLang>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(S.of(context).language),
        children: AppLang.values.map((l) {
          return SimpleDialogOption(
            child: Row(
              children: [
                Text(l.label,
                    style: interStyle(
                        size: 14,
                        weight: l == locale.lang ? FontWeight.w700 : FontWeight.normal)),
                const SizedBox(width: 8),
                if (l == locale.lang)
                  Icon(Icons.check, color: kRed, size: 18),
              ],
            ),
            onPressed: () => Navigator.pop(context, l),
          );
        }).toList(),
      ),
    );
    if (picked != null) {
      await locale.setLang(picked);
    }
  }

  Widget _stat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(value, style: outfitStyle(size: 15, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: interStyle(size: 12, color: kUserMuted)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 28, color: kUserBorder);
  }
}

class _MenuItem {
  final String icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });
}
