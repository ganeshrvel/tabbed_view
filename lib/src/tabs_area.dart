import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:tabbed_view/src/internal/tabbed_view_provider.dart';
import 'package:tabbed_view/src/internal/tabs_area/drop_tab_widget.dart';
import 'package:tabbed_view/src/internal/tabs_area/hidden_tabs.dart';
import 'package:tabbed_view/src/internal/tabs_area/tabs_area_corner.dart';
import 'package:tabbed_view/src/tab_status.dart';
import 'package:tabbed_view/src/tab_widget.dart';
import 'package:tabbed_view/src/tabbed_view_controller.dart';
import 'package:tabbed_view/src/tabs_area_layout.dart';
import 'package:tabbed_view/src/theme/tabbed_view_theme_constants.dart';
import 'package:tabbed_view/src/theme/tabbed_view_theme_data.dart';
import 'package:tabbed_view/src/theme/tabs_area_theme_data.dart';
import 'package:tabbed_view/src/theme/theme_widget.dart';
import 'package:fluent_ui/fluent_ui.dart'
    show FluentTheme, Tooltip, TooltipThemeData;
import 'package:tabbed_view/tabbed_view.dart' show TabData;

/// Widget for the tabs and buttons.
class TabsArea extends StatefulWidget {
  const TabsArea({Key? key, required this.provider}) : super(key: key);

  final TabbedViewProvider provider;

  @override
  State<StatefulWidget> createState() => _TabsAreaState();
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.left});

  final bool left;

  static const String _tooltipMessage = 'Scroll horizontally to browse tabs.\n'
      'Use ‹ › arrows to navigate between them.\n'
      'Drag a tab to reorder within a pane or\n'
      'move it to another. To create a new split\n'
      'pane, drag a tab and drop it onto the\n'
      'right side content area, if one doesn\'t exist yet.';

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltipMessage,
      style: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
        preferBelow: true,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: left
              ? TabbedViewThemeConstants.arrowLeftPaddingStart
              : TabbedViewThemeConstants.arrowRightPaddingStart,
          right: left
              ? TabbedViewThemeConstants.arrowLeftPaddingEnd
              : TabbedViewThemeConstants.arrowRightPaddingEnd,
        ),
        child: SizedBox(
          width: TabbedViewThemeConstants.arrowCircleSize,
          height: TabbedViewThemeConstants.arrowCircleSize,
          child: Icon(
            CupertinoIcons.info,
            size: TabbedViewThemeConstants.infoIconSize,
            color: TabbedViewTheme.of(context).tabsArea.navIconColor,
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({
    required this.left,
    required this.onTap,
    required this.normalColor,
    required this.hoverColor,
  });

  final bool left;
  final VoidCallback onTap;
  final Color normalColor;
  final Color hoverColor;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = _hover ? widget.hoverColor : widget.normalColor;

    return Tooltip(
      message: widget.left ? 'Scroll left' : 'Scroll right',
      style: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
        preferBelow: true,
      ),
      child: MouseRegion(
        cursor: MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.left
                  ? TabbedViewThemeConstants.arrowLeftPaddingStart
                  : TabbedViewThemeConstants.arrowRightPaddingStart,
              right: widget.left
                  ? TabbedViewThemeConstants.arrowLeftPaddingEnd
                  : TabbedViewThemeConstants.arrowRightPaddingEnd,
            ),
            child: SizedBox(
              width: TabbedViewThemeConstants.arrowCircleSize,
              height: TabbedViewThemeConstants.arrowCircleSize,
              child: Center(
                child: Container(
                  width: TabbedViewThemeConstants.arrowCircleSize - 4,
                  height: TabbedViewThemeConstants.arrowCircleSize - 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.normalColor.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    widget.left ? Icons.chevron_left : Icons.chevron_right,
                    size: TabbedViewThemeConstants.arrowIconSize,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The [TabsArea] state.
class _TabsAreaState extends State<TabsArea> {
  int? _highlightedIndex;
  final HiddenTabs _hiddenTabs = HiddenTabs();
  final ScrollController _scrollController = ScrollController();
  int _lastTabCount = 0;
  TabData? _lastSelectedTab;

  @override
  void initState() {
    super.initState();
    _lastTabCount = widget.provider.controller.tabs.length;
    _lastSelectedTab = widget.provider.controller.selectedTab;
    widget.provider.anyDragActive?.addListener(_onAnyDragActiveChanged);
  }

  @override
  void dispose() {
    widget.provider.anyDragActive?.removeListener(_onAnyDragActiveChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TabsArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.anyDragActive != widget.provider.anyDragActive) {
      oldWidget.provider.anyDragActive?.removeListener(_onAnyDragActiveChanged);
      widget.provider.anyDragActive?.addListener(_onAnyDragActiveChanged);
    }
    final controller = widget.provider.controller;
    final int tabCount = controller.tabs.length;
    final TabData? selectedTab = controller.selectedTab;

    if (tabCount > _lastTabCount || !identical(selectedTab, _lastSelectedTab)) {
      _lastTabCount = tabCount;
      _lastSelectedTab = selectedTab;
      _scrollToSelected();
    } else {
      _lastTabCount = tabCount;
      _lastSelectedTab = selectedTab;
    }
  }

  void _onAnyDragActiveChanged() {
    if (mounted) setState(() {});
  }

  // void _scrollToEnd() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!mounted) return;
  //     if (!_scrollController.hasClients) return;
  //     if (!_scrollController.position.hasContentDimensions) return;
  //     _scrollController.animateTo(
  //       _scrollController.position.maxScrollExtent,
  //       duration: const Duration(milliseconds: 200),
  //       curve: Curves.easeOut,
  //     );
  //   });
  // }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = widget.provider.controller;
      final int? selectedIndex = controller.selectedIndex;
      if (selectedIndex == null) return;
      if (!_scrollController.hasClients) return;
      if (!_scrollController.position.hasContentDimensions) return;

      final key = controller.tabs[selectedIndex].scrollKey;
      final ctx = key.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) return;

      final scrollBox = _scrollController.position.context.storageContext
          .findRenderObject() as RenderBox?;
      if (scrollBox == null) return;

      final tabOffset = box.localToGlobal(Offset.zero, ancestor: scrollBox);
      final double tabLeft = tabOffset.dx + _scrollController.offset;
      final double tabRight = tabLeft + box.size.width;
      final double viewportWidth = _scrollController.position.viewportDimension;
      final double currentScroll = _scrollController.offset;
      final double maxScroll = _scrollController.position.maxScrollExtent;

      if (tabLeft < currentScroll) {
        _scrollController.animateTo(
          tabLeft.clamp(0.0, maxScroll),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else if (tabRight > currentScroll + viewportWidth) {
        _scrollController.animateTo(
          (tabRight - viewportWidth).clamp(0.0, maxScroll),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    if (!_scrollController.position.hasContentDimensions) return;
    _scrollController.animateTo(
      (_scrollController.offset + delta)
          .clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Widget _buildArrow({required bool left, required bool dragging}) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        bool visible = false;
        if (!dragging &&
            _scrollController.hasClients &&
            _scrollController.positions.length == 1 &&
            _scrollController.position.hasContentDimensions) {
          final double offset = _scrollController.offset;
          final double maxExtent = _scrollController.position.maxScrollExtent;
          if (left) {
            visible = offset > 0;
          } else {
            visible = maxExtent > 0 && offset < maxExtent;
          }
        }

        // left arrow space: show info icon when no scroll needed
        if (left && !visible && !dragging) {
          return _InfoButton(left: left);
        }

        return Opacity(
          opacity: visible ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !visible,
            child: _ArrowButton(
              left: left,
              onTap: () => _scrollBy(left
                  ? -TabbedViewThemeConstants.arrowScrollDelta
                  : TabbedViewThemeConstants.arrowScrollDelta),
              normalColor: TabbedViewTheme.of(context).tabsArea.navIconColor,
              hoverColor: FluentTheme.of(context).accentColor.lighter,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    TabbedViewController controller = widget.provider.controller;
    TabbedViewThemeData theme = TabbedViewTheme.of(context);
    TabsAreaThemeData tabsAreaTheme = theme.tabsArea;
    final bool dragging = (widget.provider.draggingTabIndex != null) ||
        (widget.provider.anyDragActive?.value == true);

    List<Widget> tabWidgets = [];
    for (int index = 0; index < controller.tabs.length; index++) {
      TabStatus status = _getStatusFor(index);
      tabWidgets.add(KeyedSubtree(
          key: controller.tabs[index].scrollKey,
          child: TabWidget(
              key: controller.tabs[index].uniqueKey,
              index: index,
              status: status,
              provider: widget.provider,
              updateHighlightedIndex: _updateHighlightedIndex,
              onClose: _onTabClose)));
    }

    // during drag add last drop zone inside the scrollable strip
    // so it appears right after the last tab not after the > arrow
    if (dragging && controller.reorderEnable) {
      tabWidgets.add(DropTabWidget(
          provider: widget.provider,
          newIndex: controller.length,
          child: const SizedBox(width: DropTabWidget.dropWidth)));
    }

    Widget tabsAreaLayout = TabsAreaLayout(
        children: tabWidgets,
        theme: theme,
        hiddenTabs: _hiddenTabs,
        selectedTabIndex: controller.selectedIndex);

    Widget scrollableStrip = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.trackpad,
          },
        ),
        child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final double delta = event.scrollDelta.dy != 0
                    ? event.scrollDelta.dy
                    : event.scrollDelta.dx;
                if (_scrollController.hasClients &&
                    _scrollController.position.hasContentDimensions) {
                  final newOffset = (_scrollController.offset + delta)
                      .clamp(0.0, _scrollController.position.maxScrollExtent);
                  _scrollController.jumpTo(newOffset);
                }
              }
            },
            child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: tabsAreaLayout)));

    Widget corner =
        TabsAreaCorner(provider: widget.provider, hiddenTabs: _hiddenTabs);

    Widget tabsRow =
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      _buildArrow(left: true, dragging: dragging),
      Expanded(child: ClipRect(child: scrollableStrip)),
      _buildArrow(left: false, dragging: dragging),
      corner,
    ]);

    Decoration? decoration;
    if (tabsAreaTheme.color != null || tabsAreaTheme.border != null) {
      decoration = BoxDecoration(
          color: tabsAreaTheme.color, border: tabsAreaTheme.border);
    }
    return Container(child: tabsRow, decoration: decoration);
  }

  /// Gets the status of the tab for a given index.
  TabStatus _getStatusFor(int tabIndex) {
    TabbedViewController controller = widget.provider.controller;
    if (controller.tabs.isEmpty || tabIndex >= controller.tabs.length) {
      throw Exception('Invalid tab index: $tabIndex');
    }

    if (controller.selectedIndex != null &&
        controller.selectedIndex == tabIndex) {
      return TabStatus.selected;
    } else if (_highlightedIndex != null && _highlightedIndex == tabIndex) {
      return TabStatus.highlighted;
    }
    return TabStatus.normal;
  }

  void _updateHighlightedIndex(int? tabIndex) {
    if (_highlightedIndex != tabIndex) {
      setState(() {
        _highlightedIndex = tabIndex;
      });
    }
  }

  void _onTabClose() {
    setState(() {
      _highlightedIndex = null;
    });
  }
}
