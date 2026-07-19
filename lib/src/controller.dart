part of '../popper.dart';

class PopperController {
  final web.Element referenceElement;
  final web.Element floatingElement;
  final List<StreamSubscription<web.Event>> _subscriptions =
      <StreamSubscription<web.Event>>[];

  PopperOptions options;

  web.MutationObserver? _mutationObserver;
  bool _disposed = false;
  bool _autoUpdateEnabled = false;
  bool _updateQueued = false;

  /// Captured eagerly: the element must be snapshotted before the first layout
  /// is written, so `dispose()` can hand it back in its pre-Popper state.
  late final _PopperOwnedState _floatingState;

  /// Whether this controller ever wrote the layout onto the floating element.
  /// A custom [PopperOptions.layoutWriter] leaves the element's styles to the
  /// consumer, and `dispose()` must not hand back a state popper never took.
  bool _appliedLayout = false;

  PopperController({
    required this.referenceElement,
    required this.floatingElement,
    this.options = const PopperOptions(),
  }) {
    _floatingState = _PopperOwnedState.capture(
      floatingElement,
      styleProperties: _popperLayoutOwnedStyles,
      attributes: _popperLayoutOwnedAttributes,
    );
  }

  Future<PopperLayout?> update() async {
    if (_disposed) {
      return null;
    }

    final layout = await computePopperLayout(
      referenceElement: referenceElement,
      floatingElement: floatingElement,
      options: options,
    );

    final layoutWriter = options.layoutWriter;
    if (layoutWriter != null) {
      layoutWriter(layout, floatingElement, options.arrowElement);
    } else {
      applyPopperLayout(layout);
    }
    options.onLayout?.call(layout);
    return layout;
  }

  void startAutoUpdate() {
    if (_disposed || _autoUpdateEnabled) {
      return;
    }

    _autoUpdateEnabled = true;

    final scrollParents = <web.Element>{};
    scrollParents.addAll(_collectScrollParents(referenceElement));
    scrollParents.addAll(_collectScrollParents(floatingElement));

    for (final parent in scrollParents) {
      _subscriptions.add(
        web.EventStreamProviders.scrollEvent.forTarget(parent).listen((_) {
          _queueUpdate();
        }),
      );
    }

    _subscriptions.add(
      web.EventStreamProviders.scrollEvent.forTarget(web.window).listen((_) {
        _queueUpdate();
      }),
    );

    _subscriptions.add(
      web.EventStreamProviders.resizeEvent.forTarget(web.window).listen((_) {
        _queueUpdate();
      }),
    );

    if (options.observeMutations) {
      _mutationObserver = web.MutationObserver(
        (JSArray<web.MutationRecord> mutations, web.MutationObserver observer) {
          _queueUpdate();
        }.toJS,
      );

      final observerInit = web.MutationObserverInit(
        childList: true,
        subtree: true,
        characterData: true,
      );

      _mutationObserver!.observe(referenceElement, observerInit);
      _mutationObserver!.observe(floatingElement, observerInit);
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

  /// Disposes the controller and stops auto update.
  ///
  /// By default the floating element is handed back in the state it was in
  /// before this controller wrote its first layout. Pass
  /// [restoreFloatingState] as `false` to leave the last written layout on the
  /// element — useful when it is about to be removed anyway, or when it should
  /// stay frozen where popper put it.
  ///
  /// The element is never touched when this controller did not write the
  /// layout itself (a custom [PopperOptions.layoutWriter] leaves those styles
  /// to the consumer), regardless of [restoreFloatingState].
  void dispose({bool restoreFloatingState = true}) {
    if (_disposed) {
      return;
    }

    stopAutoUpdate();
    if (restoreFloatingState && _appliedLayout) {
      _floatingState.restore();
    }
    _disposed = true;
  }

  void _queueUpdate() {
    if (_disposed || _updateQueued) {
      return;
    }

    _updateQueued = true;
    web.window.requestAnimationFrame(
      (double timestamp) {
        _updateQueued = false;
        if (_disposed) {
          return;
        }
        update();
      }.toJS,
    );
  }

  void applyPopperLayout(PopperLayout layout) {
    _appliedLayout = true;
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
      floatingElement.removeAttribute('data-popper-reference-hidden');
    }

    if (layout.escaped) {
      floatingElement.setAttribute('data-popper-escaped', 'true');
    } else {
      floatingElement.removeAttribute('data-popper-escaped');
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

  void _applyArrow(PopperLayout layout, web.Element arrowElement) {
    final arrowLayoutWriter = options.arrowLayoutWriter;
    if (arrowLayoutWriter != null) {
      arrowLayoutWriter(layout, arrowElement);
      return;
    }

    if (options.arrowWriteMode == PopperArrowWriteMode.none) {
      _clearArrowStyles(arrowElement.style);
      return;
    }

    final parts = _parsePlacement(layout.placement);
    final style = arrowElement.style;
    style.position = 'absolute';
    final arrowData = layout.middlewareData['arrow'] ?? <String, dynamic>{};

    if (parts.basePlacement == 'top' || parts.basePlacement == 'bottom') {
      final arrowRect = _measureRect(arrowElement);
      final arrowX = (arrowData['x'] as num?)?.toDouble() ?? 0;
      style.left = '${arrowX.toStringAsFixed(2)}px';
      style.right = '';
      if (options.arrowWriteMode == PopperArrowWriteMode.full) {
        if (parts.basePlacement == 'top') {
          style.bottom =
              '${(-arrowRect.height.toDouble() / 2).toStringAsFixed(2)}px';
          style.top = '';
        } else {
          style.top =
              '${(-arrowRect.height.toDouble() / 2).toStringAsFixed(2)}px';
          style.bottom = '';
        }
      } else {
        style.top = '';
        style.bottom = '';
      }
      return;
    }

    final arrowRect = _measureRect(arrowElement);
    final arrowY = (arrowData['y'] as num?)?.toDouble() ?? 0;
    style.top = '${arrowY.toStringAsFixed(2)}px';
    style.bottom = '';
    if (options.arrowWriteMode == PopperArrowWriteMode.full) {
      if (parts.basePlacement == 'left') {
        style.right =
            '${(-arrowRect.width.toDouble() / 2).toStringAsFixed(2)}px';
        style.left = '';
      } else {
        style.left =
            '${(-arrowRect.width.toDouble() / 2).toStringAsFixed(2)}px';
        style.right = '';
      }
    } else {
      style.left = '';
      style.right = '';
    }
  }

  void _clearArrowStyles(web.CSSStyleDeclaration style) {
    style.position = '';
    style.left = '';
    style.right = '';
    style.top = '';
    style.bottom = '';
  }

  Set<web.Element> _collectScrollParents(web.Element element) {
    final result = <web.Element>{};
    web.Element? current = element.parentElement;

    while (current != null && current != web.document.body) {
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

      current = current.parentElement;
    }

    return result;
  }
}
