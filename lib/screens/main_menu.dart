import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  int enYuksekSkor = 0;
  AnimationController? _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _enYuksekSkoruYukle();
  }

  void _enYuksekSkoruYukle() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      enYuksekSkor = prefs.getInt('enYuksekSkor') ?? 0;
    });
  }

  @override
  void dispose() {
    _bgController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 680;
          final double horizontalPadding = isWide ? 72 : 24;
          final double verticalPadding = isWide ? 56 : 32;
          final double buttonWidth = isWide ? 320 : double.infinity;

          final controller = _bgController;
          if (controller == null) {
            return const SizedBox.shrink();
          }

          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final double t = controller.value;

              final Alignment begin = Alignment(-0.8 + t * 0.6, -1.0);
              final Alignment end = Alignment(0.8 - t * 0.6, 1.0);
              final double orbSpin = t * 2 * math.pi;

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: const [
                      Color(0xFF05050F),
                      Color(0xFF0B0A20),
                      Color(0xFF130D35),
                      Color(0xFF1C1250),
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                    begin: begin,
                    end: end,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: isWide ? -90 : -140,
                      left: isWide ? -50 : -120,
                      child: Transform.rotate(
                        angle: orbSpin,
                        child: _decorOrb(
                          size: isWide ? 320 : 260,
                          colors: const [Color(0xFF00F5FF), Color(0xFF3B82F6)],
                          opacity: 0.55,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: isWide ? -120 : -160,
                      right: isWide ? -40 : -110,
                      child: Transform.rotate(
                        angle: -orbSpin * 0.8,
                        child: _decorOrb(
                          size: isWide ? 360 : 300,
                          colors: const [Color(0xFFFF00A8), Color(0xFFFF6B6B)],
                          opacity: 0.45,
                        ),
                      ),
                    ),
                    Positioned(
                      top: constraints.maxHeight * 0.45,
                      left: isWide ? constraints.maxWidth * 0.35 : -80,
                      child: Transform.rotate(
                        angle: orbSpin * 0.6,
                        child: _decorRing(size: isWide ? 280 : 240),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                          children: [
                            _logoAndTitle(isWide: isWide),
                            SizedBox(height: isWide ? 40 : 28),
                            Expanded(
                              child: Align(
                                alignment: isWide ? Alignment.centerLeft : Alignment.center,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 520),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: isWide
                                          ? CrossAxisAlignment.start
                                          : CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Neon ritmine kapıl.',
                                          textAlign:
                                              isWide ? TextAlign.left : TextAlign.center,
                                          style: GoogleFonts.orbitron(
                                            fontSize: isWide ? 48 : 40,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Tek dokunuşla ringi döndür, renkleri eşleştir ve kombo patlamalarıyla yüksel. Hızlanan tempo seni bekliyor.',
                                          textAlign:
                                              isWide ? TextAlign.left : TextAlign.center,
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white.withValues(alpha: 0.72),
                                            fontSize: 18,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          alignment: isWide
                                              ? WrapAlignment.start
                                              : WrapAlignment.center,
                                          children: [
                                            _buildFeatureTag(Icons.touch_app,
                                                'Tek dokunuşla döndür'),
                                            _buildFeatureTag(Icons.bolt,
                                                'Kombo patlamaları'),
                                            _buildFeatureTag(Icons.leaderboard,
                                                'Skor tablosu'),
                                          ],
                                        ),
                                        const SizedBox(height: 28),
                                        _buildScoreCard(isWide: isWide),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Align(
                              alignment:
                                  isWide ? Alignment.centerLeft : Alignment.center,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isWide ? 360 : 460,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildMenuButton(
                                      "BAŞLA",
                                      const Color(0xFF00FF9F),
                                      Icons.play_arrow_rounded,
                                      () => Navigator.pushNamed(context, '/game'),
                                      buttonWidth,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildMenuButton(
                                      "LİDERLİK TABLOSU",
                                      const Color(0xFFFFBE0B),
                                      Icons.leaderboard,
                                      () => Navigator.pushNamed(context, '/leaderboard'),
                                      buttonWidth,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildMenuButton(
                                      "AYARLAR",
                                      const Color(0xFF7C3AED),
                                      Icons.tune_rounded,
                                      () => Navigator.pushNamed(context, '/settings'),
                                      buttonWidth,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildMenuButton(
                                      "NASIL OYNANIR",
                                      const Color(0xFF38BDF8),
                                      Icons.help_outline_rounded,
                                      _tutorialGoster,
                                      buttonWidth,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isWide ? 28 : 18),
                            Align(
                              alignment:
                                  isWide ? Alignment.centerLeft : Alignment.center,
                              child: Text(
                                'Geliştiren: Hexa Lab • v1.0.0',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 13,
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
            },
          );
        },
      ),
    );
  }

  Widget _logoAndTitle({required bool isWide}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Container(
          width: isWide ? 72 : 60,
          height: isWide ? 72 : 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                Color(0xFF00F5FF),
                Color(0xFF6D28D9),
                Color(0xFFFF00A8),
                Color(0xFF00F5FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F5FF).withValues(alpha: 0.4),
                blurRadius: 28,
                spreadRadius: 6,
              ),
            ],
          ),
          child: const Icon(Icons.hexagon_outlined,
              color: Colors.white, size: 36),
        ),
        SizedBox(width: isWide ? 20 : 16),
        Column(
          crossAxisAlignment:
              isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Text(
              'HEXA FALL',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: isWide ? 34 : 28,
                letterSpacing: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Refleksini ateşleyen neon döngü oyunu',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: isWide ? 16 : 14,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    String text,
    Color accent,
    IconData icon,
    VoidCallback onPressed,
    double width,
  ) {
    return SizedBox(
      width: width,
      height: 62,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          foregroundColor: Colors.white,
          overlayColor: accent.withValues(alpha: 0.18),
          shadowColor: accent.withValues(alpha: 0.45),
          elevation: 12,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          side: BorderSide(color: accent.withValues(alpha: 0.4), width: 1.2),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: accent),
              const SizedBox(width: 12),
              Text(
                text,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2900F5FF),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
    
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard({required bool isWide}) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: enYuksekSkor),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, child) {
        return Container(
          width: isWide ? 280 : double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            color: Colors.white.withValues(alpha: 0.07),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'En Yüksek Skor',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value.toString().padLeft(3, '0'),
                    style: GoogleFonts.orbitron(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F5FF), Color(0xFF7C3AED)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5FF).withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Kombo Aç',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _decorOrb({required double size, required List<Color> colors, double opacity = 0.5}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.first.withValues(alpha: opacity),
            colors.last.withValues(alpha: opacity * 0.6),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _decorRing({required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 2,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(size),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0x66EBA0FF),
                      Color(0x6600F5FF),
                      Color(0x66FFC857),
                      Color(0x66EBA0FF),
                    ],
                    stops: [0.0, 0.33, 0.66, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _tutorialGoster() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          "Nasıl Oynanır?",
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🎯 AMAÇ:",
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFF00FF41),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Düşen çubuk 12 yön saatinde sadece eşleşen renge değerse skor kazanırsın.",
              style: GoogleFonts.spaceGrotesk(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Text(
              "🎮 KONTROLLER:",
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFF38BDF8),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text("• Dokunmatik: Her dokunuşta ring bir adım döner", style: GoogleFonts.spaceGrotesk(color: Colors.white70)),
            Text("• Klavye: Sağ/Sol ok veya Space = sıradaki renk", style: GoogleFonts.spaceGrotesk(color: Colors.white70)),
            const SizedBox(height: 14),
            Text(
              "💡 İPUÇLARI:",
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFFFFBE0B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text("• Kombo yaparak pulse efektleri tetikle ve bonus puan kap", style: GoogleFonts.spaceGrotesk(color: Colors.white70)),
            Text("• Mükemmel eşleşmeler ardışık olursa hız artar, ritmi yakala!", style: GoogleFonts.spaceGrotesk(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "ANLADIM",
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFF00FF41),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}