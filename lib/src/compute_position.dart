part of '../popper.dart';

const int _maxResetCount = 50;

Future<PopperComputeResult> computePosition({
  required html.Element referenceElement,
  required html.Element floatingElement,
  String placement = 'bottom',
  PopperStrategy strategy = PopperStrategy.absolute,
  List<PopperMiddleware> middleware = const <PopperMiddleware>[],
  PopperOptions options = const PopperOptions(),
}) async {
  final state = await _runMiddlewarePipeline(
    referenceElement: referenceElement,
    floatingElement: floatingElement,
    placement: placement,
    strategy: strategy,
    options: options,
    middleware: middleware,
  );

  return PopperComputeResult(
    x: state.x,
    y: state.y,
    placement: state.placement,
    strategy: strategy,
    middlewareData: state.middlewareData,
  );
}

Future<PopperLayout> computePopperLayout({
  required html.Element referenceElement,
  required html.Element floatingElement,
  PopperOptions options = const PopperOptions(),
}) async {
  final middleware = _buildMiddleware(options);
  final state = await _runMiddlewarePipeline(
    referenceElement: referenceElement,
    floatingElement: floatingElement,
    placement: options.placement,
    strategy: options.strategy,
    options: options,
    middleware: middleware,
  );

  final overflow = _detectOverflow(
    x: state.x,
    y: state.y,
    floatingRect: state.rects.floating,
    clippingRect: state.clippingRect,
    padding: options.padding,
  );

  final visibilityState = _computeVisibilityState(
    referenceRect: state.rects.reference,
    floatingRect: state.rects.floating,
    clippingRect: state.clippingRect,
    viewportX: state.x,
    viewportY: state.y,
  );

  final cssCoords = _convertViewportCoordsToCssCoords(
    viewportX: state.x,
    viewportY: state.y,
    floatingElement: floatingElement,
    strategy: options.strategy,
  );

  final availableWidth =
      state.middlewareData['size']?['availableWidth']?.toDouble() ??
          _computeAvailableWidth(
            viewportX: state.x,
            floatingRect: state.rects.floating,
            clippingRect: state.clippingRect,
            padding: options.padding,
          );
  final availableHeight =
      state.middlewareData['size']?['availableHeight']?.toDouble() ??
          _computeAvailableHeight(
            viewportY: state.y,
            floatingRect: state.rects.floating,
            clippingRect: state.clippingRect,
            padding: options.padding,
          );

  return PopperLayout(
    x: options.roundByDevicePixelRatio
        ? _roundByDevicePixelRatio(cssCoords.x)
        : cssCoords.x,
    y: options.roundByDevicePixelRatio
        ? _roundByDevicePixelRatio(cssCoords.y)
        : cssCoords.y,
    viewportX: state.x,
    viewportY: state.y,
    placement: state.placement,
    strategy: options.strategy,
    referenceRect: state.rects.reference,
    floatingRect: state.rects.floating,
    clippingRect: state.clippingRect,
    availableWidth: availableWidth,
    availableHeight: availableHeight,
    overflowTop: overflow.top,
    overflowRight: overflow.right,
    overflowBottom: overflow.bottom,
    overflowLeft: overflow.left,
    referenceHidden:
        state.middlewareData['hide']?['referenceHidden'] as bool? ??
            visibilityState.referenceHidden,
    escaped: state.middlewareData['hide']?['escaped'] as bool? ??
        visibilityState.escaped,
    middlewareData: state.middlewareData,
  );
}

Future<PopperMiddlewareState> _runMiddlewarePipeline({
  required html.Element referenceElement,
  required html.Element floatingElement,
  required String placement,
  required PopperStrategy strategy,
  required PopperOptions options,
  required List<PopperMiddleware> middleware,
}) async {
  final rtl = _isRTL(floatingElement);
  final initialPlacement = placement;

  final state = PopperMiddlewareState(
    referenceElement: referenceElement,
    floatingElement: floatingElement,
    initialPlacement: initialPlacement,
    strategy: strategy,
    options: options,
    rtl: rtl,
    middlewareData: <String, Map<String, dynamic>>{},
    x: 0,
    y: 0,
    placement: placement,
    rects: PopperRects(
      reference: _measureRect(referenceElement),
      floating: _measureRect(floatingElement),
    ),
    clippingRect: _getClippingRect(
      referenceElement: referenceElement,
      floatingElement: floatingElement,
      boundary: options.boundary,
    ),
  );

  void recomputeBaseCoords() {
    final coords = _computeCoordsFromPlacement(
      referenceRect: state.rects.reference,
      floatingRect: state.rects.floating,
      placement: state.placement,
      rtl: rtl,
    );
    state.x = coords.x;
    state.y = coords.y;
  }

  recomputeBaseCoords();

  var resetCount = 0;
  for (var i = 0; i < middleware.length; i++) {
    final current = middleware[i];
    final result = await current.fn(state);

    if (result.x != null) {
      state.x = result.x!;
    }
    if (result.y != null) {
      state.y = result.y!;
    }
    if (result.data != null) {
      state.middlewareData[current.name] = <String, dynamic>{
        ...state.middlewareData[current.name] ?? <String, dynamic>{},
        ...result.data!,
      };
    }

    final reset = result.reset;
    if (reset == null) {
      continue;
    }

    resetCount++;
    if (resetCount > _maxResetCount) {
      break;
    }

    if (reset.placement != null) {
      state.placement = reset.placement!;
    }

    if (reset.rects != null) {
      state.rects = reset.rects!;
    } else if (reset.recalculateRects) {
      state.rects = PopperRects(
        reference: _measureRect(referenceElement),
        floating: _measureRect(floatingElement),
      );
    }

    state.clippingRect = _getClippingRect(
      referenceElement: referenceElement,
      floatingElement: floatingElement,
      boundary: options.boundary,
    );

    recomputeBaseCoords();
    i = -1;
  }

  return state;
}

List<PopperMiddleware> _buildMiddleware(PopperOptions options) {
  final middleware = <PopperMiddleware>[];

  if (options.inline) {
    middleware.add(inlineMiddleware());
  }

  if (_parsePlacement(options.placement).basePlacement == _placementAuto) {
    middleware.add(autoPlacementMiddleware(
      allowedPlacements: options.allowedAutoPlacements,
      padding: options.padding,
    ));
  } else if (options.flip) {
    middleware.add(flipMiddleware(
      fallbackPlacements: options.fallbackPlacements,
      allowedAutoPlacements: options.allowedAutoPlacements,
      padding: options.padding,
    ));
  }

  if (options.offset.mainAxis != 0 || options.offset.crossAxis != 0) {
    middleware.add(offsetMiddleware(options.offset));
  }

  if (options.shift) {
    middleware.add(shiftMiddleware(
      padding: options.padding,
      crossAxis: options.shiftCrossAxis,
    ));
  }

  middleware.add(sizeMiddleware());
  middleware.add(hideMiddleware(padding: options.padding));

  if (options.arrowElement != null) {
    middleware.add(arrowMiddleware(
      element: options.arrowElement!,
      padding: options.arrowPadding,
    ));
  }

  middleware.addAll(options.middleware);
  return middleware;
}

double _computeAvailableWidth({
  required double viewportX,
  required html.Rectangle<num> floatingRect,
  required html.Rectangle<num> clippingRect,
  required PopperInsets padding,
}) {
  final minX = clippingRect.left.toDouble() + padding.left;
  final maxX = clippingRect.left.toDouble() +
      clippingRect.width.toDouble() -
      padding.right;
  final visibleLeft = math.max(viewportX, minX);
  final visibleRight =
      math.min(viewportX + floatingRect.width.toDouble(), maxX);
  return math.max(0.0, visibleRight - visibleLeft);
}

double _computeAvailableHeight({
  required double viewportY,
  required html.Rectangle<num> floatingRect,
  required html.Rectangle<num> clippingRect,
  required PopperInsets padding,
}) {
  final minY = clippingRect.top.toDouble() + padding.top;
  final maxY = clippingRect.top.toDouble() +
      clippingRect.height.toDouble() -
      padding.bottom;
  final visibleTop = math.max(viewportY, minY);
  final visibleBottom =
      math.min(viewportY + floatingRect.height.toDouble(), maxY);
  return math.max(0.0, visibleBottom - visibleTop);
}
