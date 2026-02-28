import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/prise.dart';
import '../../../data/repositories/prise_repository.dart';
import '../../widgets/main_scaffold.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late int _annee;
  late int _mois;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _annee = now.year;
    _mois = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PriseRepository>().chargerMois(_annee, _mois);
    });
  }

  void _changerMois(int delta) {
    setState(() {
      _mois += delta;
      if (_mois > 12) {
        _mois = 1;
        _annee++;
      }
      if (_mois < 1) {
        _mois = 12;
        _annee--;
      }
    });
    context.read<PriseRepository>().chargerMois(_annee, _mois);
  }

  Map<String, List<Prise>> _grouperParJour(List<Prise> prises) {
    final Map<String, List<Prise>> grouped = {};
    for (final p in prises) {
      final key = DateFormat('yyyy-MM-dd').format(p.datePrevue);
      grouped.putIfAbsent(key, () => []).add(p);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PriseRepository>();
    final grouped = _grouperParJour(repo.prisesDuMois);
    final moisLabel =
        DateFormat('MMMM yyyy', 'fr_FR').format(DateTime(_annee, _mois));

    return MainScaffold(
      currentIndex: 2,
      child: Column(
        children: [
          _buildHeader(moisLabel),
          Expanded(
            child: repo.prisesDuMois.isEmpty
                ? const _EmptyJournal()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      // ── Carte observance ────────────────────────
                      _ObservanceSummary(
                        observance: repo.observance,
                        prises: repo.prisesDuMois,
                      ),
                      const SizedBox(height: 24),

                      // ── Groupes par jour ────────────────────────
                      ...grouped.entries.map((entry) {
                        final date = DateTime.parse(entry.key);
                        final prises = entry.value;
                        final prisesOk = prises
                            .where((p) => p.statut == StatutPrise.prise)
                            .length;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DayHeader(
                                date: date,
                                prisesOk: prisesOk,
                                total: prises.length,
                              ),
                              const SizedBox(height: 8),
                              // Cartes prises du jour dans un container
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    for (int i = 0; i < prises.length; i++) ...[
                                      _PriseTile(prise: prises[i]),
                                      if (i < prises.length - 1)
                                        const Divider(
                                          height: 1,
                                          indent: 56,
                                          endIndent: 16,
                                          color: Color(0xFFF3F4F6),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String moisLabel) {
    final label = moisLabel[0].toUpperCase() + moisLabel.substring(1);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2952), Color(0xFF1A4480)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Journal de Bord',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              // Navigation mois
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _changerMois(-1),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white54, size: 20),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () => _changerMois(1),
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white54, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Carte observance — style maquette avec cercle + message
// ════════════════════════════════════════════════════════════════════════════

class _ObservanceSummary extends StatelessWidget {
  final double observance;
  final List<Prise> prises;

  const _ObservanceSummary({required this.observance, required this.prises});

  String get _message {
    if (observance >= 90) return 'Excellente observance 🎯';
    if (observance >= 75) return 'Très bonne observance 🎯';
    if (observance >= 50) return 'Observance à améliorer';
    return 'Pensez à prendre vos médicaments';
  }

  String get _sousTitre {
    final ok = prises.where((p) => p.statut == StatutPrise.prise).length;
    return '$ok prises effectuées sur ${prises.length} ce mois-ci. Continuez comme ça !';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2952), Color(0xFF1A4480)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Cercle de progression
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: observance / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF22C55E)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      observance.toStringAsFixed(0),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      '%',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _sousTitre,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
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

// ════════════════════════════════════════════════════════════════════════════
// En-tête de jour — "AUJOURD'HUI · 23 FÉV." avec badge "1/3"
// ════════════════════════════════════════════════════════════════════════════

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final int prisesOk;
  final int total;

  const _DayHeader(
      {required this.date, required this.prisesOk, required this.total});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    // Label du jour
    String prefixe;
    if (dateKey == today) {
      prefixe = "AUJOURD'HUI";
    } else if (dateKey == yesterday) {
      prefixe = 'HIER';
    } else {
      final j = DateFormat('EEEE', 'fr_FR').format(date).toUpperCase();
      prefixe = j;
    }
    final dateFmt = DateFormat('d MMM.', 'fr_FR').format(date).toUpperCase();
    final label = '$prefixe · $dateFmt';

    // Couleur du badge
    Color badgeColor;
    if (prisesOk == total) {
      badgeColor = const Color(0xFF22C55E); // vert
    } else if (prisesOk == 0) {
      badgeColor = const Color(0xFFEF4444); // rouge
    } else {
      badgeColor = const Color(0xFFF59E0B); // orange
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.8,
          ),
        ),
        Row(
          children: [
            Text(
              '$prisesOk/$total',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
            if (prisesOk == total) ...[
              const SizedBox(width: 3),
              Text(
                '✓',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Tile d'une prise — avec icône statut + dosage + snooze info
// ════════════════════════════════════════════════════════════════════════════

class _PriseTile extends StatelessWidget {
  final Prise prise;
  const _PriseTile({required this.prise});

  @override
  Widget build(BuildContext context) {
    // Icône statut
    final (Color iconBg, Color iconColor, IconData icon) =
        switch (prise.statut) {
      StatutPrise.prise => (
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
          Icons.check_rounded,
        ),
      StatutPrise.ignoree => (
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          Icons.close_rounded,
        ),
      StatutPrise.snoozee => (
          const Color(0xFFFEF9C3),
          const Color(0xFFCA8A04),
          Icons.alarm_rounded,
        ),
    };

    // Sous-titre : dosage + info snooze si applicable
    final String sousTitre;
    if (prise.statut == StatutPrise.snoozee && prise.snoozeMinutes != null) {
      sousTitre =
          '${prise.medicamentIcone.isNotEmpty ? '' : ''}${prise.medicamentNom} · Snoozé ${prise.snoozeMinutes}min';
    } else {
      sousTitre = prise.medicamentNom;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Icône statut
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),

          // Nom + sous-titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prise.medicamentNom,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sousTitre == prise.medicamentNom
                      ? _buildDosage(prise)
                      : sousTitre,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Heure
          Text(
            DateFormat('HH:mm').format(prise.datePrise ?? prise.datePrevue),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _buildDosage(Prise prise) {
    // Affiche le dosage si disponible dans le nom (ex: "Metformine 500mg")
    // Sinon juste le nom du médicament
    return prise.medicamentIcone.isNotEmpty
        ? prise.medicamentIcone
        : prise.medicamentNom;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// État vide
// ════════════════════════════════════════════════════════════════════════════

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('📋', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune prise ce mois-ci',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Les prises confirmées apparaîtront ici',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
