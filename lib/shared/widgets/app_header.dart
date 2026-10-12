import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Global app header: fixed height, safe-area aware, optional leading back
/// button, single-line title, optional trailing actions.
///
/// Shows a 1 px bottom divider only when [scrolled] is true.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.leading,
    this.actions = const [],
    this.scrolled = false,
  });

  /// Plain text title — ignored if [titleWidget] is provided.
  final String title;

  /// Custom title widget (e.g. the Finwise wordmark). Overrides [title].
  final Widget? titleWidget;

  /// Optional leading widget (usually a back button). When null and the
  /// Navigator can pop, a default back button is rendered.
  final Widget? leading;

  /// Trailing icon buttons. Each should be an [_HeaderIconButton] or
  /// [IconButton] with a 48 dp touch target.
  final List<Widget> actions;

  /// Whether content has scrolled under the header (shows bottom divider).
  final bool scrolled;

  static const double _height = 56;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final canPop = Navigator.canPop(context);

    Widget? leadingWidget = leading;
    if (leadingWidget == null && canPop) {
      leadingWidget = AppHeaderBackButton(onPressed: () => Navigator.maybePop(context));
    }

    return Material(
      color: p.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: _height,
              child: Row(
                children: [
                  if (leadingWidget != null) leadingWidget else const SizedBox(width: Sp.lg),
                  Expanded(
                    child: titleWidget ??
                        Text(
                          title,
                          style: t.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                  ...actions,
                  if (actions.isEmpty) const SizedBox(width: Sp.lg),
                ],
              ),
            ),
          ),
          if (scrolled)
            Divider(height: 1, thickness: 1, color: p.outline)
          else
            const SizedBox(height: 1),
        ],
      ),
    );
  }
}

/// Standard 48dp back button for use in AppHeader leading slot.
class AppHeaderBackButton extends StatelessWidget {
  const AppHeaderBackButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Tooltip(
      message: 'Back',
      child: SizedBox(
        width: 48,
        height: 48,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed ?? () => Navigator.maybePop(context),
          child: Icon(Icons.arrow_back, size: 22, color: p.ink),
        ),
      ),
    );
  }
}

/// Standard icon action button for AppHeader trailing slot — 48dp touch target.
class AppHeaderAction extends StatelessWidget {
  const AppHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Center(child: Icon(icon, size: 22, color: p.ink)),
        ),
      ),
    );
  }
}

/// Mixin that adds scroll-based divider visibility to a stateful widget.
///
/// Usage: add [ScrollDividerMixin] to your State, attach [scrollController]
/// to your scroll view, and read [_scrolled] in your build.
mixin ScrollDividerMixin<T extends StatefulWidget> on State<T> {
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
