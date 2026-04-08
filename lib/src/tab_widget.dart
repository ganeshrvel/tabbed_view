import 'package:tabbed_view/src/draggable_config.dart';
import 'package:tabbed_view/src/draggable_data.dart';
import 'package:tabbed_view/src/flow_layout.dart';
import 'package:tabbed_view/src/internal/tabbed_view_provider.dart';
import 'package:tabbed_view/src/internal/tabs_area/drop_tab_widget.dart';
import 'package:tabbed_view/src/internal/tabs_area/tab_drag_feedback_widget.dart';
import 'package:tabbed_view/src/tab_button.dart';
import 'package:tabbed_view/src/tab_button_widget.dart';
import 'package:tabbed_view/src/tab_data.dart';
import 'package:tabbed_view/src/tab_status.dart';
import 'package:tabbed_view/src/theme/tab_status_theme_data.dart';
import 'package:tabbed_view/src/theme/tab_theme_data.dart';
import 'package:tabbed_view/src/theme/tabbed_view_theme_data.dart';
import 'package:tabbed_view/src/theme/theme_widget.dart';
import 'package:fluent_ui/fluent_ui.dart' show Tooltip, TooltipThemeData;
import 'package:flutter/material.dart' hide Tooltip, TooltipThemeData;

/// Listener for the tabs with the mouse over.
typedef UpdateHighlightedIndex = void Function(int? tabIndex);

/// The tab widget. Displays the tab text and its buttons.
class TabWidget extends StatelessWidget {
  const TabWidget(
      {required UniqueKey key,
      required this.index,
      required this.status,
      required this.provider,
      required this.updateHighlightedIndex,
      required this.onClose})
      : super(key: key);

  final int index;
  final TabStatus status;
  final TabbedViewProvider provider;
  final UpdateHighlightedIndex updateHighlightedIndex;
  final Function onClose;

  @override
  Widget build(BuildContext context) {
    TabData tab = provider.controller.tabs[index];
    TabbedViewThemeData theme = TabbedViewTheme.of(context);
    TabThemeData tabTheme = theme.tab;
    TabStatusThemeData statusTheme = tabTheme.getTabThemeFor(status);

    List<Widget> textAndButtons = _textAndButtons(context, tabTheme);

    Widget textAndButtonsContainer = ClipRect(
        child: FlowLayout(
            children: textAndButtons,
            firstChildFlex: true,
            verticalAlignment: tabTheme.verticalAlignment));

    BorderSide innerBottomBorder = statusTheme.innerBottomBorder ??
        tabTheme.innerBottomBorder ??
        BorderSide.none;
    BorderSide innerTopBorder = statusTheme.innerTopBorder ??
        tabTheme.innerTopBorder ??
        BorderSide.none;
    BoxDecoration? decoration = statusTheme.decoration ?? tabTheme.decoration;

    EdgeInsetsGeometry? padding;
    if (textAndButtons.length == 1) {
      padding =
          statusTheme.paddingWithoutButton ?? tabTheme.paddingWithoutButton;
    }
    if (padding == null) {
      padding = statusTheme.padding ?? tabTheme.padding;
    }

    EdgeInsetsGeometry? margin = tabTheme.margin;
    if (statusTheme.margin != null) {
      margin = statusTheme.margin;
    }

    Widget tabWidget = Container(
        child: Container(
            child: textAndButtonsContainer,
            padding: padding,
            decoration: BoxDecoration(
                border:
                    Border(top: innerTopBorder, bottom: innerBottomBorder))),
        decoration: decoration);

    MouseCursor cursor = MouseCursor.defer;

    tabWidget = Tooltip(
      message: tab.text,
      style: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 700),
        preferBelow: true,
      ),
      child: MouseRegion(
          cursor: cursor,
          onEnter: (event) => updateHighlightedIndex(index),
          onExit: (event) => updateHighlightedIndex(null),
          child: provider.draggingTabIndex == null
              ? GestureDetector(
                  onTap: () => _onSelect(context, index), child: tabWidget)
              : tabWidget),
    );

    if (tab.draggable) {
      DraggableConfig draggableConfig = DraggableConfig.defaultConfig;
      if (provider.onDraggableBuild != null) {
        draggableConfig =
            provider.onDraggableBuild!(provider.controller, index, tab);
      }

      if (draggableConfig.canDrag) {
        Widget feedback = draggableConfig.feedback != null
            ? draggableConfig.feedback!
            : TabDragFeedbackWidget(tab: tab, tabTheme: tabTheme);

        tabWidget = Draggable<DraggableData>(
            child: tabWidget,
            feedback: Material(
              color: Colors.transparent,
              child: feedback,
            ),
            data: DraggableData(provider.controller, tab),
            feedbackOffset: draggableConfig.feedbackOffset,
            dragAnchorStrategy: draggableConfig.dragAnchorStrategy,
            onDragStarted: () {
              provider.onTabDrag(index);
              // shift focus and selection to the dragged tab immediately
              // so the focused highlight follows the drag from the start
              if (provider.onTabTap != null) {
                provider.onTabTap!(index);
              }
              provider.controller.selectedIndex = index;
              if (draggableConfig.onDragStarted != null) {
                draggableConfig.onDragStarted!();
              }
            },
            onDragUpdate: (details) {
              if (draggableConfig.onDragUpdate != null) {
                draggableConfig.onDragUpdate!(details);
              }
            },
            onDraggableCanceled: (velocity, offset) {
              provider.onTabDrag(null);
              if (draggableConfig.onDraggableCanceled != null) {
                draggableConfig.onDraggableCanceled!(velocity, offset);
              }
            },
            onDragEnd: (details) {
              if (draggableConfig.onDragEnd != null) {
                draggableConfig.onDragEnd!(details);
              }
            },
            onDragCompleted: () {
              provider.onTabDrag(null);
              if (draggableConfig.onDragCompleted != null) {
                draggableConfig.onDragCompleted!();
              }
            });

        tabWidget = Opacity(
            child: tabWidget,
            opacity: provider.draggingTabIndex != index
                ? 1
                : tabTheme.draggingOpacity);
      }
    }

    // apply margin outside Draggable so transparent margin area
    // does not capture drag events
    tabWidget = Padding(padding: margin ?? EdgeInsets.zero, child: tabWidget);

    if (provider.controller.reorderEnable &&
        provider.draggingTabIndex != tab.index) {
      return DropTabWidget(
          provider: provider, newIndex: tab.index, child: tabWidget);
    }
    return tabWidget;
  }

  /// Builds a list with title text and buttons.
  List<Widget> _textAndButtons(BuildContext context, TabThemeData tabTheme) {
    List<Widget> textAndButtons = [];

    TabData tab = provider.controller.tabs[index];
    TabStatusThemeData statusTheme = tabTheme.getTabThemeFor(status);

    Color normalColor = statusTheme.normalButtonColor != null
        ? statusTheme.normalButtonColor!
        : tabTheme.normalButtonColor;
    Color hoverColor = statusTheme.hoverButtonColor != null
        ? statusTheme.hoverButtonColor!
        : tabTheme.hoverButtonColor;
    Color disabledColor = statusTheme.disabledButtonColor != null
        ? statusTheme.disabledButtonColor!
        : tabTheme.disabledButtonColor;

    BoxDecoration? normalBackground = statusTheme.normalButtonBackground != null
        ? statusTheme.normalButtonBackground
        : tabTheme.normalButtonBackground;
    BoxDecoration? hoverBackground = statusTheme.hoverButtonBackground != null
        ? statusTheme.hoverButtonBackground
        : tabTheme.hoverButtonBackground;
    BoxDecoration? disabledBackground =
        statusTheme.disabledButtonBackground != null
            ? statusTheme.disabledButtonBackground
            : tabTheme.disabledButtonBackground;

    TextStyle? textStyle = tabTheme.textStyle;
    if (statusTheme.fontColor != null) {
      if (textStyle != null) {
        textStyle = textStyle.copyWith(color: statusTheme.fontColor);
      } else {
        textStyle = TextStyle(color: statusTheme.fontColor);
      }
    }

    final bool buttonsEnabled = provider.draggingTabIndex == null &&
        (provider.selectToEnableButtons == false ||
            (provider.selectToEnableButtons && status == TabStatus.selected));
    bool hasButtons = tab.buttons != null && tab.buttons!.length > 0;
    EdgeInsets? padding;
    if (tab.closable || hasButtons && tabTheme.buttonsOffset > 0) {
      padding = EdgeInsets.only(right: tabTheme.buttonsOffset);
    }

    Widget textWidget = Container(
        child:
            Text(tab.text, style: textStyle, overflow: TextOverflow.ellipsis),
        padding: padding);

    if (tab.leading != null) {
      Widget? leading = tab.leading!(context, status);
      if (leading != null) {
        textWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [leading, Flexible(child: textWidget)],
        );
      }
    }

    textAndButtons.add(textWidget);

    if (hasButtons) {
      for (int i = 0; i < tab.buttons!.length; i++) {
        EdgeInsets? padding;
        if (i > 0 && i < tab.buttons!.length && tabTheme.buttonsGap > 0) {
          padding = EdgeInsets.only(left: tabTheme.buttonsGap);
        }
        TabButton button = tab.buttons![i];
        textAndButtons.add(Container(
            child: TabButtonWidget(
                provider: provider,
                button: button,
                enabled: buttonsEnabled,
                normalColor: normalColor,
                hoverColor: hoverColor,
                disabledColor: disabledColor,
                normalBackground: normalBackground,
                hoverBackground: hoverBackground,
                disabledBackground: disabledBackground,
                iconSize: button.iconSize != null
                    ? button.iconSize!
                    : tabTheme.buttonIconSize,
                themePadding: tabTheme.buttonPadding),
            padding: padding));
      }
    }

    // always render close slot — visible only when closable
    EdgeInsets? closePadding;
    if (hasButtons && tabTheme.buttonsGap > 0) {
      closePadding = EdgeInsets.only(left: tabTheme.buttonsGap);
    }
    TabButton closeButton = TabButton(
        icon: tabTheme.closeIcon,
        onPressed: tab.closable ? () => _onClose(context, index) : null,
        toolTip: tab.closable ? provider.closeButtonTooltip : null);
    textAndButtons.add(Container(
        child: TabButtonWidget(
            provider: provider,
            button: closeButton,
            enabled: buttonsEnabled && tab.closable,
            normalColor: normalColor,
            hoverColor: hoverColor,
            disabledColor: disabledColor,
            normalBackground: normalBackground,
            hoverBackground: hoverBackground,
            disabledBackground: disabledBackground,
            iconSize: tabTheme.buttonIconSize,
            themePadding: tabTheme.buttonPadding),
        padding: closePadding));

    return textAndButtons;
  }

  void _onClose(BuildContext context, int index) {
    if (provider.tabCloseInterceptor == null ||
        provider.tabCloseInterceptor!(index)) {
      onClose();
      TabData tabData = provider.controller.removeTab(index);
      if (provider.onTabClose != null) {
        provider.onTabClose!(index, tabData);
      }
    }
  }

  void _onSelect(BuildContext context, int newTabIndex) {
    // fires unconditionally on every tap — used for global focus
    if (provider.onTabTap != null) {
      provider.onTabTap!(newTabIndex);
    }
    if (provider.tabSelectInterceptor == null ||
        provider.tabSelectInterceptor!(newTabIndex)) {
      provider.controller.selectedIndex = newTabIndex;
    }
  }
}
