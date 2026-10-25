import 'package:flutter/material.dart';
import '../theme/finwise_spacing.dart';
import '../theme/finwise_tokens.dart';

/// Standardized Finwise app header:
/// - Safe-area aware
/// - Single-line title with proper typography
/// - Optional leading back button and trailing actions
/// - Smooth scroll divider
class FinwiseHeader extends StatelessWidget implements PreferredSizeWidget {
  const FinwiseHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.leading,
    this.actions = const [],
    this.scrolled = false,
  });

  final String title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget> actions;
  final bool scrolled;

  static const double height = 56;

  @override
  Size get preferredSize => const Size.fromHeight(height + 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final t = theme.textTheme;
    final canPop = Navigator.canPop(context);

    Widget? leadingWidget = leading;
    if (leadingWidget == null && canPop) {
      leadingWidget = FinwiseHeaderBackButton(
        onPressed: () => Navigator.maybePop(context),
      );
    }

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: height,
              child: Row(
                children: [
                  if (leadingWidget != null)
                    leadingWidget
                  else
                    const SizedBox(width: FinwiseSpacing.lg),
                  Expanded(
                    child: titleWidget ??
                        Text(
                          title,
                          style: t.titleLarge?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                  ...actions,
                  if (actions.isEmpty) const SizedBox(width: FinwiseSpacing.lg),
                ],
              ),
            ),
          ),
          if (scrolled)
            Divider(height: 1, thickness: 1, color: tokens.outline)
          else
            const SizedBox(height: 1),
        ],
      ),
    );
  }
}

/// Standard 48dp back button for use in FinwiseHeader leading slot.
class FinwiseHeaderBackButton extends StatelessWidget {
  const FinwiseHeaderBackButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Tooltip(
      message: 'Back',
      child: SizedBox(
        width: 48,
        height: 48,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed ?? () => Navigator.maybePop(context),
          child: Icon(Icons.arrow_back, size: 22, color: onSurface),
        ),
      ),
    );
  }
}

/// Standard icon action button for FinwiseHeader trailing slot — 48dp touch target.
class FinwiseHeaderAction extends StatelessWidget {
  const FinwiseHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: color ?? tokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mixin that adds scroll-based divider visibility to a stateful widget.
mixin FinwiseScrollDividerMixin<T extends StatefulWidget> on State<T> {
  final scrollController = ScrollController();
  bool scrolled = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final now = scrollController.offset > 2;
    if (now != scrolled) setState(() => scrolled = now);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
