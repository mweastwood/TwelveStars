import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/widgets/collapsible_selector_bar.dart';

class _TestCollapsibleHost extends StatefulWidget {
  final ScrollController scrollController;
  final void Function(CollapsibleSelectorController controller) onCreated;

  const _TestCollapsibleHost({
    required this.scrollController,
    required this.onCreated,
  });

  @override
  State<_TestCollapsibleHost> createState() => _TestCollapsibleHostState();
}

class _TestCollapsibleHostState extends State<_TestCollapsibleHost>
    with SingleTickerProviderStateMixin {
  late final CollapsibleSelectorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CollapsibleSelectorController(
      vsync: this,
      topSpacerHeight: 80.0,
      activeScrollController: () => widget.scrollController,
      onStatusSettled: () {
        if (mounted) setState(() {});
      },
    );
    widget.onCreated(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListView.builder(
            controller: widget.scrollController,
            itemCount: 50,
            itemBuilder: (context, index) {
              if (index == 0) {
                return SizeTransition(
                  sizeFactor: _controller.animation,
                  alignment: Alignment.topCenter,
                  child: const SizedBox(height: 80.0),
                );
              }
              return SizedBox(height: 50, child: Text('Item $index'));
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CollapsibleSelectorBar(
              animation: _controller.animation,
              padding: const EdgeInsets.all(8.0),
              child: const SizedBox(height: 64, child: Text('Selector Card')),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('CollapsibleSelectorController & CollapsibleSelectorBar', () {
    testWidgets(
      'toggles open and closed and compensates scroll offset when scrolled down',
      (tester) async {
        final scrollController = ScrollController();
        late CollapsibleSelectorController selectorController;

        await tester.pumpWidget(
          MaterialApp(
            home: _TestCollapsibleHost(
              scrollController: scrollController,
              onCreated: (c) => selectorController = c,
            ),
          ),
        );

        expect(selectorController.isExpanded, isFalse);
        expect(selectorController.animation.value, 0.0);

        // Scroll down past threshold (> 5.0)
        scrollController.jumpTo(200.0);
        await tester.pump();
        expect(scrollController.offset, 200.0);

        // Toggle open -> should animate to 1.0 and shift scroll offset by +80.0
        expect(selectorController.toggle(), isTrue);
        await tester.pumpAndSettle();

        expect(selectorController.isExpanded, isTrue);
        expect(selectorController.animation.value, 1.0);
        expect(scrollController.offset, closeTo(280.0, 0.1));

        // Toggle closed -> should animate to 0.0 and shift scroll offset back to 200.0
        expect(selectorController.toggle(), isFalse);
        await tester.pumpAndSettle();

        expect(selectorController.isExpanded, isFalse);
        expect(selectorController.animation.value, 0.0);
        expect(scrollController.offset, closeTo(200.0, 0.1));

        // syncExpanded updates immediately without animation
        selectorController.syncExpanded(true);
        expect(selectorController.isExpanded, isTrue);
        expect(selectorController.animation.value, 1.0);

        scrollController.dispose();
      },
    );
  });
}
