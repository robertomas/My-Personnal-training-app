// Bottom-sheet scaffold matching .sheet / .sheet-handle / backdrop blur.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required AppTokens t,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (ctx) {
      return Stack(
        children: [
          // blurred tinted backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(color: t.backdrop),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AppSheet(t: t, child: builder(ctx)),
            ),
          ),
        ],
      );
    },
  );
}

class AppSheet extends StatelessWidget {
  final AppTokens t;
  final Widget child;
  const AppSheet({super.key, required this.t, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: t.border)),
      ),
      padding: EdgeInsets.fromLTRB(22, 16, 22, 32 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: t.borderStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Themed text field used inside sheets / settings.
class AppField extends StatelessWidget {
  final AppTokens t;
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  const AppField({
    super.key,
    required this.t,
    this.controller,
    this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.autofocus = false,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(),
              style: t.label(11, color: t.textMuted, spacing: 0.6)),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          obscureText: obscureText,
          autofocus: autofocus,
          textInputAction: textInputAction,
          cursorColor: t.accent,
          style: t.body(16, color: t.text),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: t.body(16, color: t.textFaint),
            filled: true,
            fillColor: t.surface2,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusSm),
              borderSide: BorderSide(color: t.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusSm),
              borderSide: BorderSide(color: t.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusSm),
              borderSide: BorderSide(color: t.accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
