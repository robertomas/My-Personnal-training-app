// Shared UI primitives, ported from skins.css component classes.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// .card
class AppCard extends StatelessWidget {
  final AppTokens t;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool clip;

  const AppCard({
    super.key,
    required this.t,
    required this.child,
    this.padding,
    this.margin,
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    final deco = BoxDecoration(
      color: t.cardGradient == null ? t.surface : null,
      gradient: t.cardGradient,
      borderRadius: BorderRadius.circular(t.radius),
      border: Border.all(color: t.border),
      boxShadow: t.cardShadow,
    );
    return Container(
      margin: margin,
      padding: padding,
      decoration: deco,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: child,
    );
  }
}

/// .phase-pill
class PhasePill extends StatelessWidget {
  final AppTokens t;
  final int number;
  final String text;
  const PhasePill(
      {super.key, required this.t, required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = t.phaseColor(number);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c),
      ),
      child: Text(text,
          style: t.label(10, color: c, spacing: 0.6).copyWith(height: 1.1)),
    );
  }
}

/// .tag
class AppTag extends StatelessWidget {
  final AppTokens t;
  final String text;
  final Color? color;
  final Color? bg;
  final Color? borderColor;
  const AppTag(
      {super.key,
      required this.t,
      required this.text,
      this.color,
      this.bg,
      this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? t.surface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor ?? t.border),
      ),
      child: Text(text,
          style: t.label(10, color: color ?? t.textMuted, spacing: 0.6)),
    );
  }
}

/// group-marker (superset / circuit)
class GroupMarker extends StatelessWidget {
  final AppTokens t;
  final String text;
  final bool circuit;
  const GroupMarker(
      {super.key, required this.t, required this.text, this.circuit = false});

  @override
  Widget build(BuildContext context) {
    final bg = circuit ? t.phase3 : t.phase2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        style: t
            .mono(9, weight: FontWeight.w700, color: t.accentText)
            .copyWith(letterSpacing: 1.0),
      ),
    );
  }
}

/// .btn-primary
class PrimaryButton extends StatelessWidget {
  final AppTokens t;
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool full;
  const PrimaryButton({
    super.key,
    required this.t,
    required this.label,
    this.icon,
    this.onPressed,
    this.full = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: t.accentText),
          const SizedBox(width: 8),
        ],
        Text(label.toUpperCase(),
            style: t
                .body(14, weight: FontWeight.w700, color: t.accentText)
                .copyWith(letterSpacing: 0.4)),
      ],
    );
    return _Pressable(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: t.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      ),
    );
  }
}

/// .btn-ghost
class GhostButton extends StatelessWidget {
  final AppTokens t;
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final bool full;
  final Alignment alignment;
  final double fontSize;
  const GhostButton({
    super.key,
    required this.t,
    this.label,
    this.icon,
    this.onPressed,
    this.padding,
    this.full = false,
    this.alignment = Alignment.center,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment:
          alignment == Alignment.centerLeft ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: t.text),
          if (label != null) const SizedBox(width: 6),
        ],
        if (label != null)
          Flexible(
            child: Text(label!.toUpperCase(),
                style: t
                    .body(fontSize, weight: FontWeight.w600, color: t.text)
                    .copyWith(letterSpacing: 0.4)),
          ),
      ],
    );
    return _Pressable(
      onPressed: onPressed,
      child: Container(
        width: full ? double.infinity : null,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        alignment: alignment,
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: content,
      ),
    );
  }
}

/// header-action chip (pill button used in headers)
class HeaderAction extends StatelessWidget {
  final AppTokens t;
  final String? label;
  final IconData icon;
  final VoidCallback? onPressed;
  const HeaderAction(
      {super.key,
      required this.t,
      required this.icon,
      this.label,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onPressed: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: label == null ? 10 : 14, vertical: 8),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: t.textMuted),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(label!, style: t.body(13, color: t.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// square icon button (.icon-btn)
class IconBtn extends StatelessWidget {
  final AppTokens t;
  final IconData icon;
  final VoidCallback? onPressed;
  const IconBtn(
      {super.key, required this.t, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onPressed: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: t.border),
        ),
        child: Icon(icon, size: 16, color: t.textMuted),
      ),
    );
  }
}

/// Tap with subtle scale-on-press (matches active:scale(.98)).
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const _Pressable({required this.child, this.onPressed});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// section label (.section-label)
class SectionLabel extends StatelessWidget {
  final AppTokens t;
  final String text;
  const SectionLabel({super.key, required this.t, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(text.toUpperCase(),
            style: t.label(11, color: t.textMuted, spacing: 0.8)),
      );
}
