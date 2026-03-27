import 'package:fluent_ui/fluent_ui.dart' hide TabData;
import 'package:flutter/material.dart'
    show Scaffold, TextField, InputDecoration, OutlineInputBorder, Icons;
import 'package:tabbed_view/tabbed_view.dart';

void main() {
  runApp(const TabbedViewExample());
}

class TabbedViewExample extends StatelessWidget {
  const TabbedViewExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      home: const TabbedViewExamplePage(),
    );
  }
}

class TabbedViewExamplePage extends StatefulWidget {
  const TabbedViewExamplePage({Key? key}) : super(key: key);

  @override
  TabbedViewExamplePageState createState() => TabbedViewExamplePageState();
}

class TabbedViewExamplePageState extends State<TabbedViewExamplePage> {
  late TabbedViewController _controller;

  @override
  void initState() {
    super.initState();
    List<TabData> tabs = [];

    tabs.add(TabData(
        text: 'Tab 1',
        leading: (context, status) => const Icon(Icons.star, size: 16),
        content:
            const Padding(padding: EdgeInsets.all(8), child: Text('Hello'))));
    tabs.add(TabData(
        text: 'Tab 2',
        content: const Padding(
            padding: EdgeInsets.all(8), child: Text('Hello again'))));
    tabs.add(TabData(
        closable: false,
        text: 'TextField',
        content: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
                decoration: const InputDecoration(
                    isDense: true, border: OutlineInputBorder()))),
        keepAlive: true));

    _controller = TabbedViewController(tabs);
  }

  @override
  Widget build(BuildContext context) {
    final TabbedView tabbedView = TabbedView(controller: _controller);
    final Widget w =
        TabbedViewTheme(data: TabbedViewThemeData.mobile(), child: tabbedView);
    return Scaffold(
        body: Container(padding: const EdgeInsets.all(32), child: w));
  }
}
