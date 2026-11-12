import 'package:flutter/material.dart';
import 'package:melody/core/widgets/frosted.dart';

/// Scrolling page with a big bold title that turns into a small one in a
/// frosted app bar once it scrolls away.
///
/// With [header] the big title is replaced by a custom header (e.g. an album
/// cover) and the small title appears once the header is scrolled past.
class LargeTitlePage extends StatefulWidget {
  /// Creates the page.
  const LargeTitlePage({
    required this.title,
    required this.slivers,
    this.actions = const [],
    this.header,
    this.onRefresh,
    this.onNearEnd,
    this.automaticallyImplyLeading = true,
    super.key,
  });

  /// Page title.
  final String title;

  /// Page content.
  final List<Widget> slivers;

  /// App bar actions.
  final List<Widget> actions;

  /// Replaces the big title.
  final Widget? header;

  /// Enables pull to refresh.
  final Future<void> Function()? onRefresh;

  /// Called when the user scrolls close to the end (endless lists).
  final VoidCallback? onNearEnd;

  /// Shows a back button when the page was pushed.
  final bool automaticallyImplyLeading;

  @override
  State<LargeTitlePage> createState() => _LargeTitlePageState();
}

class _LargeTitlePageState extends State<LargeTitlePage> {
  final ScrollController _controller = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final headerHeight = _headerKey.currentContext?.size?.height ?? 56;
    final collapsed = _controller.offset > headerHeight - 24;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    final near = widget.onNearEnd;
    if (near != null && _controller.position.extentAfter < 800) near();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final view = CustomScrollView(
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          backgroundColor: Colors.transparent,
          flexibleSpace: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _collapsed ? 1 : 0,
            child: const Frosted(child: SizedBox.expand()),
          ),
          title: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _collapsed ? 1 : 0,
            child: Text(widget.title),
          ),
          actions: widget.actions,
        ),
        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: _headerKey,
            child:
                widget.header ??
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.title,
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                ),
          ),
        ),
        ...widget.slivers,
        SliverPadding(padding: EdgeInsets.only(bottom: bottom + 24)),
      ],
    );
    final refresh = widget.onRefresh;
    return refresh == null
        ? view
        : RefreshIndicator(
            onRefresh: refresh,
            edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
            child: view,
          );
  }
}
