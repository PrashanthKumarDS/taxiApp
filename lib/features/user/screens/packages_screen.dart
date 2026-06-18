import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxi_app/core/services/package_firestore_service.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/models/tour_package.dart';
import 'package:taxi_app/shared/widgets/primary_button.dart';

const _bookingPhone = '7829975777';

const _backgroundImage =
    'https://images.unsplash.com/photo-1642516864138-5fd999e09dfb?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8bXVydWRlc2h3YXJhfGVufDB8fDB8fHww';

/// Preferred section order; unknown starting points are appended alphabetically.
const _order = ['murudeshwar', 'honnavar', 'gokarna', 'udupi', 'kollur'];

/// Per-destination tagline shown under each section heading.
const _subtitles = <String, String>{
  'murudeshwar': 'Explore the best of Murudeshwar & nearby attractions',
  'honnavar': 'Discover waterfalls, backwaters & hidden gems',
  'gokarna': 'Beaches, temples & coastal adventures',
  'udupi': 'Temples, beaches & coastal cuisine',
  'kollur': 'A temple town nestled in the Western Ghats',
};

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<PackageFirestoreService>();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              child: Image.asset(
                'assets/images/logo.png',
                height: 50,
                width: 50,
                fit: BoxFit.contain,
              ),
            ),

            const Text(
              'MyTown Cabs Packages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            )
          ],
        ),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.network(
                _backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          StreamBuilder<List<TourPackage>>(
            stream: service.watchActivePackages(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Could not load packages.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.accent.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final packages = snap.data ?? const <TourPackage>[];
              if (packages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.card_travel,
                          size: 56,
                          color: AppTheme.accent.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Packages Coming Soon',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We\'re putting together exciting tour packages.\nCheck back shortly!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.accent.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Group by starting point, then order sections.
              final groups = <String, List<TourPackage>>{};
              for (final p in packages) {
                final key = p.startingPoint.isEmpty ? 'Other' : p.startingPoint;
                groups.putIfAbsent(key, () => []).add(p);
              }
              final sections = groups.keys.toList()
                ..sort((a, b) {
                  final ia = _order.indexOf(a.toLowerCase());
                  final ib = _order.indexOf(b.toLowerCase());
                  if (ia != -1 && ib != -1) return ia.compareTo(ib);
                  if (ia != -1) return -1;
                  if (ib != -1) return 1;
                  return a.compareTo(b);
                });

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  for (final sp in sections)
                    _PackageSection(startingPoint: sp, packages: groups[sp]!),
                  const _MorePackagesFooter(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PackageSection extends StatelessWidget {
  const _PackageSection({required this.startingPoint, required this.packages});

  final String startingPoint;
  final List<TourPackage> packages;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        _subtitles[startingPoint.toLowerCase()] ??
        'Explore $startingPoint & nearby attractions';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            '$startingPoint Packages',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: AppTheme.accent,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.accent.withValues(alpha: 0.6),
            ),
          ),
        ),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: _PackageCard(package: packages[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MorePackagesFooter extends StatelessWidget {
  const _MorePackagesFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.more_horiz,
              size: 18, color: AppTheme.accent.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(
            'More packages coming soon',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.accent.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package});

  final TourPackage package;

  @override
  Widget build(BuildContext context) {
    final img = package.image;
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context, package),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: (img != null && img.isNotEmpty)
                  ? Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _priceLine(package),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _IconLine(icon: Icons.place, text: package.startingPoint),
                    if (package.duration.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _IconLine(icon: Icons.schedule, text: package.duration),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: FilledButton(
                        onPressed: () => _showDetail(context, package),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'View Details →',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _imageFallback() => Container(
    color: AppTheme.accent.withValues(alpha: 0.08),
    child: Icon(
      Icons.image_not_supported_outlined,
      color: AppTheme.accent.withValues(alpha: 0.3),
    ),
  );
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.accent.withValues(alpha: 0.6)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.accent.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

String _priceLine(TourPackage p) {
  final parts = <String>[];
  if (p.sedanMiniPrice > 0) parts.add('Sedan ${_inr(p.sedanMiniPrice)}');
  if (p.suvPrice > 0) parts.add('SUV ${_inr(p.suvPrice)}');
  return parts.join('  •  ');
}

/// ₹3,600 style formatting.
String _inr(double value) {
  final s = value.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '₹$buf';
}

void _showDetail(BuildContext context, TourPackage package) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (package.image != null && package.image!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    package.image!,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                package.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (package.startingPoint.isNotEmpty) ...[
                    const Icon(Icons.place, size: 15, color: AppTheme.accent),
                    const SizedBox(width: 4),
                    Text(
                      package.startingPoint,
                      style: TextStyle(
                        color: AppTheme.accent.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (package.duration.isNotEmpty) ...[
                    const Icon(
                      Icons.schedule,
                      size: 15,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      package.duration,
                      style: TextStyle(
                        color: AppTheme.accent.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              if (package.places.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Places covered',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ...package.places.map(
                  (place) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            place,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Pricing',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              if (package.sedanMiniPrice > 0)
                _PriceRow(label: 'Sedan / Mini', price: package.sedanMiniPrice),
              if (package.suvPrice > 0)
                _PriceRow(label: 'SUV', price: package.suvPrice),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Call to Book',
                onPressed: () => launchUrl(
                  Uri.parse('tel:$_bookingPhone'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'For bookings & details: $_bookingPhone',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.accent.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.price});

  final String label;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            _inr(price),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}
