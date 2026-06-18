import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openEdit(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ProfileForm(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ValueListenableBuilder<AppUser?>(
              valueListenable: UserService.instance.notifier,
              builder: (_, user, __) {
                if (user == null) return const SizedBox.shrink();
                return _buildProfile(context, user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: kCream,
          border: Border(bottom: BorderSide(color: kRed.withOpacity(0.4))),
        ),
        child: const Row(
          children: [
            Text('JDMDex', style: TextStyle(fontFamily: 'GozaruDemo', color: kBg, fontSize: 30)),
          ],
        ),
      );

  Widget _buildProfile(BuildContext context, AppUser user) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + nom
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kRed, width: 2),
                        color: kBgElevated,
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: user.profilImgUrl != null
                          ? CachedNetworkImage(imageUrl: user.profilImgUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.person_outline, color: kTextMuted, size: 44),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(user.username, style: const TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w800)),
                if (user.socialMedia != null)
                  Text(user.socialMedia!, style: const TextStyle(color: kTextDim, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Infos
          _infoCard([
            _InfoRow(icon: Icons.alternate_email, label: 'Pseudo', value: user.username),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
            if (user.socialMedia != null)
              _InfoRow(icon: Icons.link, label: 'Réseau social', value: user.socialMedia!),
          ]),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openEdit(context, user),

            style: ElevatedButton.styleFrom(
              backgroundColor: kRed, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Modifier le profil', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      );

  Widget _infoCard(List<Widget> rows) => Container(
        decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
        child: Column(
          children: rows.map((r) {
            final isLast = r == rows.last;
            return Column(
              children: [
                r,
                if (!isLast) const Divider(height: 1, color: kBorder, indent: 16, endIndent: 16),
              ],
            );
          }).toList(),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: kTextMuted, size: 18),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: kTextDim, fontSize: 13)),
            const Spacer(),
            Text(value, style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ─── Form ───

class _ProfileForm extends StatefulWidget {
  final AppUser user;
  const _ProfileForm({required this.user});

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _socialCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameCtrl.text = widget.user.username;
    _emailCtrl.text = widget.user.email;
    _socialCtrl.text = widget.user.socialMedia ?? '';
    _imgCtrl.text = widget.user.profilImgUrl ?? '';
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _socialCtrl.dispose();
    _imgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_usernameCtrl.text.trim().isEmpty) return;
    final user = AppUser(
      userId: widget.user.userId ?? DateTime.now().millisecondsSinceEpoch,
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      socialMedia: _socialCtrl.text.trim().isEmpty ? null : _socialCtrl.text.trim(),
      profilImgUrl: _imgCtrl.text.trim().isEmpty ? null : _imgCtrl.text.trim(),
    );
    await UserService.instance.save(user);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Modifier le profil',
                    style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: kTextDim)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameCtrl,
              style: const TextStyle(color: kBg),
              decoration: const InputDecoration(labelText: 'Pseudo *', prefixIcon: Icon(Icons.person_outline, color: kRed, size: 18)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailCtrl,
              style: const TextStyle(color: kBg),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined, color: kRed, size: 18)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _socialCtrl,
              style: const TextStyle(color: kBg),
              decoration: const InputDecoration(labelText: 'Réseau social (ex: @pseudo)', prefixIcon: Icon(Icons.link, color: kRed, size: 18)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _imgCtrl,
              style: const TextStyle(color: kBg),
              decoration: const InputDecoration(labelText: 'URL photo de profil', prefixIcon: Icon(Icons.image_outlined, color: kRed, size: 18)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
