part of '../popper.dart';

class PopperController {
  final html.Element referenceElement;
  final html.Element floatingElement;
  final List<StreamSubscription<html.Event>> _subscriptions =
      <StreamSubscription<html.Event>>[];

  PopperOptions options;

  html.MutationObserver? _mutationObserver;
  bool _disposed = false;
  bool _autoUpdateEnabled = false;
  bool _updateQueued = false;

  PopperController({
    required this.referenceElement,
    required this.floatingElement,
    this.options = const PopperOptions(),
  });

  Future<PopperLayout?> update() async {
    if (_disposed) {
      return null;
    }

    final layout = await computePopperLayout(
      referenceElement: referenceElement,
      floatingElement: floatingElement,
      options: options,
    );

    _applyLayout(layout);
    options.onLayout?.call(layout);
    return layout;
  }

  void startAutoUpdate() {
    if (_disposed || _autoUpdateEnabled) {
      return;
    }

    _autoUpdateEnabled = true;

    final scrollParents = <html.Element>{};
    scrollParents.addAll(_collectScrollParents(referenceElement));
    scrollParents.addAll(_collectScrollParents(floatingElement));

    for (final parent in scrollParents) {
      _subscriptions.add(parent.onScroll.listen((_) {
        _queueUpdate();
      }));
    }

    _subscriptions.add(html.window.onScroll.listen((_) {
      _queueUpdate();
    }));

    _subscriptions.add(html.window.onResize.listen((_) {
      _queueUpdate();
    }));

    if (options.observeMutations) {
      _mutationObserver = html.MutationObserver((_, __) {
        _queueUpdate();
      });

      _mutationObserver!.observe(
        referenceElement,
        childList: true,
        subtree: true,
        characterData: true,
      );

      _mutationObserver!.observe(
        floatingElement,
        childList: true,
        subtree: true,
        characterData: true,
      );
    }

    update();
  }

  void stopAutoUpdate() {
    _autoUpdateEnabled = false;

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _mutationObserver?.disconnect();
    _mutationObserver = null;
    _updateQueued = false;
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    stopAutoUpdate();
    _disposed = true;
  }

  void _queueUpdate() {
    if (_disposed || _updateQueued) {
      return;
    }

    _updateQueued = true;
    html.window.requestAnimationFrame((_) {
      _updateQueued = false;
      if (_disposed) {
        return;
      }
      update();
    });
  }

  void _applyLayout(PopperLayout layout) {
    final style = floatingElement.style;

    style.position =
        layout.strategy == PopperStrategy.fixed ? 'fixed' : 'absolute';
    style.left = '0';
    style.top = '0';
    style.right = 'auto';
    style.bottom = 'auto';
    style.margin = '0';
    style.transform =
        'translate(${layout.x.toStringAsFixed(2)}px, ${layout.y.toStringAsFixed(2)}px)';

    if (options.matchReferenceWidth) {
      style.width = '${layout.referenceRect.width.toDouble()}px';
    } else {
      style.width = '';
    }

    if (options.matchReferenceMinWidth) {
      style.minWidth = '${layout.referenceRect.width.toDouble()}px';
    } else {
      style.minWidth = '';
    }

    style.setProperty(
      '--popper-available-width',
      '${layout.availableWidth.toStringAsFixed(2)}px',
    );
    style.setProperty(
      '--popper-available-height',
      '${layout.availableHeight.toStringAsFixed(2)}px',
    );

    floatingElement.setAttribute('data-popper-placement', layout.placement);

    if (layout.referenceHidden) {
      floatingElement.setAttribute('data-popper-reference-hidden', 'true');
    } else {
      floatingElement.attributes.remove('data-popper-reference-hidden');
    }

    if (layout.escaped) {
      floatingElement.setAttribute('data-popper-escaped', 'true');
    } else {
      floatingElement.attributes.remove('data-popper-escaped');
    }

    if (options.hideWhenDetached &&
        (layout.referenceHidden || layout.escaped)) {
      style.visibility = 'hidden';
      style.pointerEvents = 'none';
    } else {
      style.visibility = 'visible';
      if (style.pointerEvents == 'none') {
        style.pointerEvents = '';
      }
    }

    if (options.arrowElement != null) {
      _applyArrow(layout, options.arrowElement!);
    }
  }

  void _applyArrow(PopperLayout layout, html.Element arrowElement) {
    final parts = _parsePlacement(layout.placement);
    final style = arrowElement.style;
    style.position = 'absolute';
    style.left = 'auto';
    style.right = 'auto';
    style.top = 'auto';
    style.bottom = 'auto';
    final arrowData = layout.middlewareData['arrow'] ?? <String, dynamic>{};

    if (parts.basePlacement == 'top' || parts.basePlacement == 'bottom') {
      final arrowRect = _measureRect(arrowElement);
      final arrowX = (arrowData['x'] as num?)?.toDouble() ?? 0;
      style.left = '${arrowX.toStringAsFixed(2)}px';
      if (parts.basePlacement == 'top') {
        style.bottom =
            '${(-arrowRect.height.toDouble() / 2).toStringAsFixed(2)}px';
      } else {
        style.top =
            '${(-arrowRect.height.toDouble() / 2).toStringAsFixed(2)}px';
      }
      return;
    }

    final arrowRect = _measureRect(arrowElement);
    final arrowY = (arrowData['y'] as num?)?.toDouble() ?? 0;
    style.top = '${arrowY.toStringAsFixed(2)}px';
    if (parts.basePlacement == 'left') {
      style.right = '${(-arrowRect.width.toDouble() / 2).toStringAsFixed(2)}px';
    } else {
      style.left = '${(-arrowRect.width.toDouble() / 2).toStringAsFixed(2)}px';
    }
  }

  Set<html.Element> _collectScrollParents(html.Element element) {
    final result = <html.Element>{};
    html.Element? current = element.parent;

    while (current != null && current != html.document.body) {
      final computed = current.getComputedStyle();
      final overflow =
          '${computed.overflow}${computed.overflowX}${computed.overflowY}'
              .toLowerCase();

      final isScrollable = overflow.contains('auto') ||
          overflow.contains('scroll') ||
          overflow.contains('overlay');

      if (isScrollable) {
        result.add(current);
      }

      current = current.parent;
    }

    return result;
  }
}
