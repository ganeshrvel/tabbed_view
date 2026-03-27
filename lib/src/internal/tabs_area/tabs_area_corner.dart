import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:tabbed_view/src/internal/tabbed_view_provider.dart';
import 'package:tabbed_view/src/internal/tabs_area/drop_tab_widget.dart';
import 'package:tabbed_view/src/internal/tabs_area/hidden_tabs.dart';
import 'package:tabbed_view/src/internal/tabs_area/tabs_area_buttons_widget.dart';

@internal
class TabsAreaCorner extends StatefulWidget {
  final TabbedViewProvider provider;
  final HiddenTabs hiddenTabs;

  const TabsAreaCorner(
      {super.key, required this.provider, required this.hiddenTabs});

  @override
  State<TabsAreaCorner> createState() => _TabsAreaCornerState();
}

class _TabsAreaCornerState extends State<TabsAreaCorner> {
  @override
  void initState() {
    super.initState();
    widget.hiddenTabs.addListener(_onChanged);
    widget.provider.anyDragActive?.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant TabsAreaCorner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hiddenTabs != widget.hiddenTabs) {
      oldWidget.hiddenTabs.removeListener(_onChanged);
      widget.hiddenTabs.addListener(_onChanged);
    }
    if (oldWidget.provider.anyDragActive != widget.provider.anyDragActive) {
      oldWidget.provider.anyDragActive?.removeListener(_onChanged);
      widget.provider.anyDragActive?.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.hiddenTabs.removeListener(_onChanged);
    widget.provider.anyDragActive?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool dragging = (widget.provider.draggingTabIndex != null) ||
        (widget.provider.anyDragActive?.value == true);

    Widget corner = Container(
        padding: const EdgeInsets.only(left: 0),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TabsAreaButtonsWidget(
                  provider: widget.provider, hiddenTabs: widget.hiddenTabs)
            ]));

    if (widget.provider.controller.reorderEnable) {
      corner = DropTabWidget(
          provider: widget.provider,
          newIndex: widget.provider.controller.length,
          child: corner);
    }

    return Opacity(
      opacity: dragging ? 0.0 : 1.0,
      child: IgnorePointer(
        ignoring: dragging,
        child: corner,
      ),
    );
  }
}
