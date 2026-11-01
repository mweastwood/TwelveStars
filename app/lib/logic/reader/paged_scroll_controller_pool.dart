import 'package:flutter/widgets.dart';

/// Manages a bounded LRU pool of [ScrollController] instances for paged reader
/// views (such as `BibleTab`), deferring disposal of evicted controllers that
/// are still mounted or attached to a scroll position.
class PagedScrollControllerPool {
  final int maxCachedControllers;
  final int Function()? activePageIndex;

  final Map<int, ScrollController> _cachedControllers = {};
  final Map<int, ScrollController> _evictedControllersByIndex = {};
  final Set<ScrollController> _evictedControllers = {};
  final Map<ScrollController, int> _controllerMountCounts = {};
  final ValueNotifier<int> keepAliveRevision = ValueNotifier<int>(0);

  bool _keepAliveUpdateScheduled = false;
  bool _disposed = false;

  PagedScrollControllerPool({
    this.maxCachedControllers = 10,
    this.activePageIndex,
  });

  /// Read-only view of the currently cached (active) controllers by page index.
  Map<int, ScrollController> get cachedControllers => _cachedControllers;

  /// Returns the cached controller for [index] without affecting LRU order,
  /// or `null` if [index] is not currently in the active cache.
  ScrollController? operator [](int index) => _cachedControllers[index];

  /// Whether the page at [index] is currently retained in the active LRU cache.
  bool isKeptAlive(int index) => _cachedControllers.containsKey(index);

  @visibleForTesting
  Set<ScrollController> get evictedControllers => _evictedControllers;

  @visibleForTesting
  int mountCountFor(ScrollController controller) =>
      _controllerMountCounts[controller] ?? 0;

  /// Increments the mount reference count for [controller].
  void onControllerMounted(ScrollController controller) {
    if (_disposed) return;
    _controllerMountCounts[controller] =
        (_controllerMountCounts[controller] ?? 0) + 1;
  }

  /// Decrements the mount reference count for [controller] and disposes it
  /// immediately if it was previously evicted and no longer has clients.
  void onControllerUnmounted(ScrollController controller) {
    if (_disposed) return;
    final count = (_controllerMountCounts[controller] ?? 0) - 1;
    if (count <= 0) {
      _controllerMountCounts.remove(controller);
      if (_evictedControllers.remove(controller)) {
        _evictedControllersByIndex.removeWhere((_, v) => v == controller);
        if (!controller.hasClients) {
          controller.dispose();
        }
      }
    } else {
      _controllerMountCounts[controller] = count;
    }
  }

  /// Returns the [ScrollController] for [index], promoting it in the LRU cache,
  /// reviving it if it was recently evicted while still mounted, or creating a
  /// new instance after evicting the oldest non-active entries.
  ScrollController getController(int index, {int? activePage}) {
    if (_cachedControllers.containsKey(index)) {
      final controller = _cachedControllers.remove(index)!;
      _cachedControllers[index] = controller;
      return controller;
    }
    final revived = _evictedControllersByIndex.remove(index);
    if (revived != null) {
      _evictedControllers.remove(revived);
      _evictOldestControllersIfNeeded(activePage);
      _cachedControllers[index] = revived;
      return revived;
    }
    _evictOldestControllersIfNeeded(activePage);
    final newController = ScrollController();
    _cachedControllers[index] = newController;
    return newController;
  }

  void _evictOldestControllersIfNeeded(int? activePageOverride) {
    if (_cachedControllers.length < maxCachedControllers) return;
    final protectedPage = activePageOverride ?? activePageIndex?.call();
    final evictKeys = _cachedControllers.keys
        .where((key) => key != protectedPage)
        .take(_cachedControllers.length - maxCachedControllers + 1)
        .toList();
    for (final key in evictKeys) {
      final controller = _cachedControllers.remove(key);
      if (controller == null) continue;
      if ((_controllerMountCounts[controller] ?? 0) > 0 ||
          controller.hasClients) {
        final previousEvicted = _evictedControllersByIndex[key];
        if (previousEvicted != null &&
            previousEvicted != controller &&
            (_controllerMountCounts[previousEvicted] ?? 0) <= 0 &&
            !previousEvicted.hasClients) {
          _evictedControllers.remove(previousEvicted);
          previousEvicted.dispose();
        }
        _evictedControllersByIndex[key] = controller;
        _evictedControllers.add(controller);
        _scheduleKeepAliveUpdate();
      } else {
        controller.dispose();
      }
    }
  }

  void _scheduleKeepAliveUpdate() {
    if (_keepAliveUpdateScheduled || _disposed) return;
    _keepAliveUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keepAliveUpdateScheduled = false;
      if (_disposed) return;
      keepAliveRevision.value++;
      final unmountedControllers = _evictedControllers
          .where((c) => (_controllerMountCounts[c] ?? 0) <= 0 && !c.hasClients)
          .toList();
      for (final controller in unmountedControllers) {
        _evictedControllers.remove(controller);
        _evictedControllersByIndex.removeWhere((_, v) => v == controller);
        controller.dispose();
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Disposes all cached and evicted controllers and the [keepAliveRevision]
  /// notifier.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final allControllers = <ScrollController>{
      ..._cachedControllers.values,
      ..._evictedControllers,
    };
    _cachedControllers.clear();
    _evictedControllers.clear();
    _evictedControllersByIndex.clear();
    _controllerMountCounts.clear();
    for (final controller in allControllers) {
      controller.dispose();
    }
    keepAliveRevision.dispose();
  }
}
