import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';

/// Animated, image-free splash visuals: a letter-by-letter wordmark, a typed
/// tagline, drifting glows and a pulsing loader on the brand colour.
///
/// The very first frame is a flat [launchColor] – exactly what the native
/// launch screens (iOS storyboard, Android launch theme) show – so the hand-off
/// from native to Flutter is seamless. Everything else fades/animates in.
///
/// Pure presentation: navigation lives in `SplashScreen`.
class SplashView extends StatefulWidget {
  /// Must match the native launch background
  /// (`ios/Runner/Base.lproj/LaunchScreen.storyboard`,
  /// `android/app/src/main/res/values/colors.xml`).
  static const Color launchColor = AppColors.primary;

  final String title;
  final String tagline;

  /// 0 → 1 while the splash is leaving; fades and lifts the content out.
  final Animation<double> exit;

  const SplashView({
    super.key,
    required this.title,
    required this.tagline,
    this.exit = const AlwaysStoppedAnimation<double>(0),
  });

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 1800);
  static const _loopDuration = Duration(milliseconds: 2600);

  late final AnimationController _intro;
  late final AnimationController _loop;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: _introDuration);
    _loop = AnimationController(vsync: this, duration: _loopDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      // Respect "reduce motion": show the finished state, keep it still.
      _intro.value = 1;
      _loop.value = 0.5;
    } else {
      _intro.forward();
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Progress of [t] through [begin]…[end], eased and clamped to 0…1.
  static double _phase(double t, double begin, double end,
      [Curve curve = Curves.easeOutCubic]) {
    final raw = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS (dark bar = light icons)
        systemNavigationBarColor: SplashView.launchColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Semantics(
        container: true,
        label: '${widget.title}. ${widget.tagline}',
        child: ExcludeSemantics(
          child: ColoredBox(
            color: SplashView.launchColor,
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _loop, widget.exit]),
              builder: (context, _) => _buildFrame(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrame(BuildContext context) {
    final t = _intro.value;
    final loop = _loop.value;
    final exit = Curves.easeIn.transform(widget.exit.value);

    final glow = _phase(t, 0.0, 0.6, Curves.easeOut);
    final contentOpacity = 1 - exit;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Drifting glows.
        Opacity(
          opacity: (1 - exit * 0.6).clamp(0.0, 1.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Glow(
                alignment: Alignment(
                  0.95 + 0.06 * math.sin(loop * 2 * math.pi),
                  -0.85 + 0.05 * math.cos(loop * 2 * math.pi),
                ),
                size: 420,
                color: Colors.white,
                alpha: 0.16 * glow,
                scale: 0.8 + 0.2 * glow,
              ),
              _Glow(
                alignment: Alignment(
                  -1.0 + 0.05 * math.cos(loop * 2 * math.pi),
                  0.95 + 0.04 * math.sin(loop * 2 * math.pi),
                ),
                size: 460,
                color: AppColors.primaryLight,
                alpha: 0.42 * glow,
                scale: 0.8 + 0.2 * glow,
              ),
              _Glow(
                alignment: Alignment(
                  0.9 + 0.04 * math.sin(loop * 2 * math.pi + 1),
                  0.75,
                ),
                size: 260,
                color: AppColors.accent,
                alpha: 0.20 * glow,
                scale: 0.8 + 0.2 * glow,
              ),
            ],
          ),
        ),

        // Content.
        SafeArea(
          child: Center(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Opacity(
                opacity: contentOpacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -14 * exit),
                  child: Transform.scale(
                    scale: 1 + 0.04 * exit,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildWordmark(t, loop),
                        const SizedBox(height: 14),
                        _buildUnderline(t),
                        const SizedBox(height: 18),
                        _buildTagline(t),
                        const SizedBox(height: 56),
                        _buildDots(t, loop),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── wordmark ───────────────────────────────────────────────────────────────

  Widget _buildWordmark(double t, double loop) {
    final letters = widget.title.characters.toList();

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < letters.length; i++)
          _buildLetter(letters[i], i, t),
      ],
    );

    // After the reveal, a soft highlight sweeps across the wordmark.
    final sweepActive = t > 0.7;
    if (!sweepActive) return row;

    final sweep = -0.6 + loop * 2.2;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: const Alignment(-1, -0.25),
        end: const Alignment(1, 0.25),
        colors: [
          Colors.white.withValues(alpha: 0.9),
          Colors.white,
          Colors.white.withValues(alpha: 0.9),
        ],
        stops: [
          (sweep - 0.28).clamp(0.0, 1.0),
          sweep.clamp(0.0, 1.0),
          (sweep + 0.28).clamp(0.0, 1.0),
        ],
      ).createShader(bounds),
      child: row,
    );
  }

  Widget _buildLetter(String letter, int index, double t) {
    final begin = 0.06 + index * 0.05;
    final end = begin + 0.34;
    final fade = _phase(t, begin, end, Curves.easeOut);
    final rise = _phase(t, begin, end, Curves.easeOutBack);

    return Opacity(
      opacity: fade,
      child: Transform.translate(
        offset: Offset(0, (1 - rise) * 30),
        child: Text(
          letter,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 46,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: 1.6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── underline ──────────────────────────────────────────────────────────────

  Widget _buildUnderline(double t) {
    final p = _phase(t, 0.50, 0.70);
    return Opacity(
      opacity: p,
      child: Container(
        width: 12 + 60 * p,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }

  // ── tagline (typed, per-character fade) ────────────────────────────────────

  Widget _buildTagline(double t) {
    final text = widget.tagline;
    final chars = text.characters.toList();
    final progress = _phase(t, 0.58, 0.92, Curves.easeOut) * chars.length;

    const style = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.4,
    );

    // Every character is laid out from the start (transparent until typed), so
    // the line never jitters horizontally while it types.
    // One line, shrunk to fit if needed (avoids a lonely last word on narrow
    // screens or with large system text).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              for (var i = 0; i < chars.length; i++)
                TextSpan(
                  text: chars[i],
                  style: style.copyWith(
                    color: Colors.white.withValues(
                      alpha: 0.86 * (progress - i).clamp(0.0, 1.0),
                    ),
                  ),
                ),
            ],
          ),
          textAlign: TextAlign.center,
          softWrap: false,
        ),
      ),
    );
  }

  // ── loader dots ────────────────────────────────────────────────────────────

  Widget _buildDots(double t, double loop) {
    final visible = _phase(t, 0.80, 1.0);
    return Opacity(
      opacity: visible,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _dot(0.5 + 0.5 * math.sin((loop - i * 0.14) * 2 * math.pi)),
          ],
        ],
      ),
    );
  }

  Widget _dot(double v) {
    return Transform.scale(
      scale: 0.65 + 0.35 * v,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.4 + 0.6 * v),
        ),
      ),
    );
  }
}

/// Soft radial glow anchored to a corner of the screen.
class _Glow extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;
  final double alpha;
  final double scale;

  const _Glow({
    required this.alignment,
    required this.size,
    required this.color,
    required this.alpha,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: alpha),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
