part of '../popper.dart';

enum PopperStrategy {
  fixed,
  absolute,
}

enum PopperBoundary {
  viewport,
  document,
  clippingAncestors,
}

enum PopperVisibility {
  visible,
  referenceHidden,
  escaped,
}

class PopperInsets {
  final double top;
  final double right;
  final double bottom;
  final double left;

  const PopperInsets({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  const PopperInsets.all(double value)
      : top = value,
        right = value,
        bottom = value,
        left = value;

  double get horizontal => left + right;

  double get vertical => top + bottom;
}

class PopperOffset {
  final double mainAxis;
  final double crossAxis;

  const PopperOffset({
    this.mainAxis = 0,
    this.crossAxis = 0,
  });
}

class PopperLayout {
  final double x;
  final double y;
  final double viewportX;
  final double viewportY;
  final String placement;
  final PopperStrategy strategy;
  final html.Rectangle<num> referenceRect;
  final html.Rectangle<num> floatingRect;
  final html.Rectangle<num> clippingRect;
  final double availableWidth;
  final double availableHeight;
  final double overflowTop;
  final double overflowRight;
  final double overflowBottom;
  final double overflowLeft;
  final bool referenceHidden;
  final bool escaped;
  final PopperMiddlewareData middlewareData;

  const PopperLayout({
    required this.x,
    required this.y,
    required this.viewportX,
    required this.viewportY,
    required this.placement,
    required this.strategy,
    required this.referenceRect,
    required this.floatingRect,
    required this.clippingRect,
    required this.availableWidth,
    required this.availableHeight,
    required this.overflowTop,
    required this.overflowRight,
    required this.overflowBottom,
    required this.overflowLeft,
    required this.referenceHidden,
    required this.escaped,
    required this.middlewareData,
  });

  double get overflowScore =>
      math.max(0.0, overflowTop) +
      math.max(0.0, overflowRight) +
      math.max(0.0, overflowBottom) +
      math.max(0.0, overflowLeft);

  PopperVisibility get visibility {
    if (referenceHidden) {
      return PopperVisibility.referenceHidden;
    }
    if (escaped) {
      return PopperVisibility.escaped;
    }
    return PopperVisibility.visible;
  }

  bool get isReferenceHidden => referenceHidden;

  bool get isEscaped => escaped;

  bool get isVisible => !referenceHidden && !escaped;
}

typedef PopperLayoutCallback = void Function(PopperLayout layout);

class PopperComputeResult {
  final double x;
  final double y;
  final String placement;
  final PopperStrategy strategy;
  final PopperMiddlewareData middlewareData;

  const PopperComputeResult({
    required this.x,
    required this.y,
    required this.placement,
    required this.strategy,
    required this.middlewareData,
  });
}

typedef PopperMiddlewareData = Map<String, Map<String, dynamic>>;

typedef PopperMiddlewareExecutor = FutureOr<PopperMiddlewareResult> Function(
  PopperMiddlewareState state,
);

class PopperRects {
  html.Rectangle<num> reference;
  html.Rectangle<num> floating;

  PopperRects({
    required this.reference,
    required this.floating,
  });
}

class PopperMiddlewareReset {
  final String? placement;
  final bool recalculateRects;
  final PopperRects? rects;

  const PopperMiddlewareReset({
    this.placement,
    this.recalculateRects = false,
    this.rects,
  });
}

class PopperMiddlewareResult {
  final double? x;
  final double? y;
  final Map<String, dynamic>? data;
  final PopperMiddlewareReset? reset;

  const PopperMiddlewareResult({
    this.x,
    this.y,
    this.data,
    this.reset,
  });
}

class PopperMiddleware {
  final String name;
  final dynamic options;
  final PopperMiddlewareExecutor fn;

  const PopperMiddleware({
    required this.name,
    required this.fn,
    this.options,
  });
}

class PopperMiddlewareState {
  final html.Element referenceElement;
  final html.Element floatingElement;
  final String initialPlacement;
  final PopperStrategy strategy;
  final PopperOptions options;
  final bool rtl;
  final PopperMiddlewareData middlewareData;

  double x;
  double y;
  String placement;
  PopperRects rects;
  html.Rectangle<num> clippingRect;

  PopperMiddlewareState({
    required this.referenceElement,
    required this.floatingElement,
    required this.initialPlacement,
    required this.strategy,
    required this.options,
    required this.rtl,
    required this.middlewareData,
    required this.x,
    required this.y,
    required this.placement,
    required this.rects,
    required this.clippingRect,
  });
}

class PopperDetectOverflowOptions {
  final PopperBoundary boundary;
  final PopperBoundary rootBoundary;
  final String elementContext;
  final bool altBoundary;
  final PopperInsets padding;
  final String? placement;

  const PopperDetectOverflowOptions({
    this.boundary = PopperBoundary.clippingAncestors,
    this.rootBoundary = PopperBoundary.viewport,
    this.elementContext = 'floating',
    this.altBoundary = false,
    this.padding = const PopperInsets.all(0),
    this.placement,
  });
}

class PopperOptions {
  final String placement;
  final List<String> fallbackPlacements;
  final List<String> allowedAutoPlacements;
  final PopperStrategy strategy;
  final PopperBoundary boundary;
  final PopperInsets padding;
  final PopperOffset offset;
  final bool flip;
  final bool shift;
  final bool shiftCrossAxis;
  final bool matchReferenceWidth;
  final bool matchReferenceMinWidth;
  final bool hideWhenDetached;
  final bool roundByDevicePixelRatio;
  final bool observeMutations;
  final html.Element? arrowElement;
  final PopperInsets arrowPadding;
  final bool inline;
  final List<PopperMiddleware> middleware;
  final PopperLayoutCallback? onLayout;

  const PopperOptions({
    this.placement = 'bottom-start',
    this.fallbackPlacements = const <String>[
      'top-start',
      'bottom-end',
      'top-end',
    ],
    this.allowedAutoPlacements = _allPlacements,
    this.strategy = PopperStrategy.fixed,
    this.boundary = PopperBoundary.clippingAncestors,
    this.padding = const PopperInsets.all(8),
    this.offset = const PopperOffset(),
    this.flip = true,
    this.shift = true,
    this.shiftCrossAxis = true,
    this.matchReferenceWidth = false,
    this.matchReferenceMinWidth = false,
    this.hideWhenDetached = false,
    this.roundByDevicePixelRatio = true,
    this.observeMutations = true,
    this.arrowElement,
    this.arrowPadding = const PopperInsets.all(8),
    this.inline = false,
    this.middleware = const <PopperMiddleware>[],
    this.onLayout,
  });
}

class PopperPortalOptions {
  final String hostClassName;
  final String hostZIndex;
  final String floatingZIndex;
  final bool restoreOnDispose;

  const PopperPortalOptions({
    this.hostClassName = 'popper-portal-host',
    this.hostZIndex = '10000',
    this.floatingZIndex = '1000',
    this.restoreOnDispose = false,
  });
}

class _PlacementParts {
  final String basePlacement;
  final String? alignment;

  const _PlacementParts(this.basePlacement, this.alignment);
}
