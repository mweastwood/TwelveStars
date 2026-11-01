import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/reader/paged_scroll_controller_pool.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PagedScrollControllerPool', () {
    test(
      'caches up to maxCachedControllers and evicts oldest non-active entries',
      () {
        int activePage = 0;
        final pool = PagedScrollControllerPool(
          maxCachedControllers: 3,
          activePageIndex: () => activePage,
        );

        final c0 = pool.getController(0);
        final c1 = pool.getController(1);
        final c2 = pool.getController(2);

        expect(pool.cachedControllers.keys.toList(), [0, 1, 2]);
        expect(pool.isKeptAlive(0), isTrue);
        expect(pool.isKeptAlive(1), isTrue);
        expect(pool.isKeptAlive(2), isTrue);

        // Re-requesting 1 promotes 1 to most-recently-used: order is now [0, 2, 1]
        expect(pool.getController(1), same(c1));
        expect(pool.cachedControllers.keys.toList(), [0, 2, 1]);

        // Requesting 3 while activePage == 0 protects page 0 and evicts oldest non-active (2)
        final c3 = pool.getController(3);
        expect(pool.cachedControllers.keys.toList(), [0, 1, 3]);
        expect(pool.isKeptAlive(2), isFalse);
        expect(pool.isKeptAlive(0), isTrue);
        expect(pool[3], same(c3));

        // Because c2 was unmounted and had no clients, it was disposed immediately
        expect(() => c2.addListener(() {}), throwsFlutterError);
        expect(() => c0.addListener(() {}), returnsNormally);

        pool.dispose();
      },
    );

    testWidgets(
      'keeps mounted loading controllers alive until unmounted and increments keepAliveRevision',
      (tester) async {
        int activePage = 0;
        final pool = PagedScrollControllerPool(
          maxCachedControllers: 2,
          activePageIndex: () => activePage,
        );

        final c0 = pool.getController(0);
        pool.onControllerMounted(c0);
        expect(pool.mountCountFor(c0), 1);

        activePage = 1;
        final c1 = pool.getController(1);
        pool.onControllerMounted(c1);

        activePage = 2;
        final initialRevision = pool.keepAliveRevision.value;
        // Evicts c0 while c0 is still mounted (loading state, hasClients == false)
        final c2 = pool.getController(2);
        pool.onControllerMounted(c2);

        expect(pool.isKeptAlive(0), isFalse);
        expect(pool.evictedControllers.contains(c0), isTrue);
        // c0 must NOT be disposed yet because it is still mounted
        expect(() => c0.addListener(() {}), returnsNormally);

        // Post-frame callback increments keepAliveRevision and retains c0 while mounted
        await tester.pump();
        expect(pool.keepAliveRevision.value, greaterThan(initialRevision));
        expect(pool.evictedControllers.contains(c0), isTrue);
        expect(() => c0.addListener(() {}), returnsNormally);

        // Once unmounted, c0 is disposed and removed from evictedControllers
        pool.onControllerUnmounted(c0);
        expect(pool.mountCountFor(c0), 0);
        expect(pool.evictedControllers.contains(c0), isFalse);
        expect(() => c0.addListener(() {}), throwsFlutterError);

        pool.dispose();
      },
    );

    testWidgets(
      'revives evicted controller when re-requested while still mounted',
      (tester) async {
        int activePage = 0;
        final pool = PagedScrollControllerPool(
          maxCachedControllers: 2,
          activePageIndex: () => activePage,
        );

        final c0 = pool.getController(0);
        pool.onControllerMounted(c0);

        activePage = 1;
        final c1 = pool.getController(1);
        pool.onControllerMounted(c1);

        activePage = 2;
        final c2 = pool.getController(2);
        pool.onControllerMounted(c2);

        // c0 is now evicted but still mounted
        expect(pool.isKeptAlive(0), isFalse);
        expect(pool.evictedControllers.contains(c0), isTrue);

        // Re-requesting page 0 revives c0 into the active cache and evicts c1
        activePage = 0;
        final revived0 = pool.getController(0);
        expect(revived0, same(c0));
        expect(pool.isKeptAlive(0), isTrue);
        expect(pool.evictedControllers.contains(c0), isFalse);
        expect(pool.evictedControllers.contains(c1), isTrue);

        await tester.pump();
        pool.dispose();
      },
    );

    test(
      'dispose() disposes all cached and evicted controllers and is idempotent',
      () {
        int activePage = 0;
        final pool = PagedScrollControllerPool(
          maxCachedControllers: 1,
          activePageIndex: () => activePage,
        );

        final c0 = pool.getController(0);
        pool.onControllerMounted(c0);

        activePage = 1;
        final c1 = pool.getController(1);

        expect(pool.evictedControllers.contains(c0), isTrue);
        expect(pool.cachedControllers.containsValue(c1), isTrue);

        pool.dispose();
        // Calling dispose() a second time is a safe no-op
        pool.dispose();

        expect(pool.cachedControllers, isEmpty);
        expect(pool.evictedControllers, isEmpty);
        expect(() => c0.addListener(() {}), throwsFlutterError);
        expect(() => c1.addListener(() {}), throwsFlutterError);
        expect(
          () => pool.keepAliveRevision.addListener(() {}),
          throwsFlutterError,
        );
      },
    );
  });
}
