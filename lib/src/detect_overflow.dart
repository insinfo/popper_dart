part of '../popper.dart';

class _PopperOverflow {
  final double top;
  final double right;
  final double bottom;
  final double left;

  const _PopperOverflow({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  bool get fits => top <= 0 && right <= 0 && bottom <= 0 && left <= 0;

  double get score =>
      math.max(0.0, top) +
      math.max(0.0, right) +
      math.max(0.0, bottom) +
      math.max(0.0, left);
}

class _PopperVisibilityState {
  final bool referenceHidden;
  final bool escaped;

  const _PopperVisibilityState({
    required this.referenceHidden,
    required this.escaped,
  });
}

PopperInsets detectOverflow(
  PopperMiddlewareState state, [
  PopperDetectOverflowOptions options = const PopperDetectOverflowOptions(),
]) {
  final placement = options.placement ?? state.placement;
  final elementContext = options.elementContext;
  final element = options.altBoundary
      ? (elementContext == 'floating'
          ? state.referenceElement
          : state.floatingElement)
      : (elementContext == 'floating'
          ? state.floatingElement
          : state.referenceElement);

  final clippingRect = _getClippingRect(
    referenceElement:
        elementContext == 'reference' ? element : state.referenceElement,
    floatingElement:
        elementContext == 'floating' ? element : state.floatingElement,
    boundary: options.boundary,
  );

  if (elementContext == 'reference') {
    return _overflowForRect(
      targetRect: state.rects.reference,
      clippingRect: clippingRect,
    );
  }

  final candidatePosition =
      options.placement == null || placement == state.placement
          ? math.Point<double>(state.x, state.y)
          : _computeViewportCoordsForPlacement(
              referenceRect: state.rects.reference,
              floatingRect: state.rects.floating,
              placement: placement,
              offset: state.options.offset,
              rtl: state.rtl,
            );

  return _overflowForRect(
    targetRect: html.Rectangle<num>(
      candidatePosition.x,
      candidatePosition.y,
      state.rects.floating.width,
      state.rects.floating.height,
    ),
    clippingRect: html.Rectangle<num>(
      clippingRect.left + options.padding.left,
      clippingRect.top + options.padding.top,
      math.max(
        0,
        clippingRect.width - options.padding.horizontal,
      ),
      math.max(
        0,
        clippingRect.height - options.padding.vertical,
      ),
    ),
  );
}

_PopperOverflow _detectOverflow({
  required double x,
  required double y,
  required html.Rectangle<num> floatingRect,
  required html.Rectangle<num> clippingRect,
  required PopperInsets padding,
}) {
  final paddedLeft = clippingRect.left.toDouble() + padding.left;
  final paddedTop = clippingRect.top.toDouble() + padding.top;
  final paddedRight = clippingRect.left.toDouble() +
      clippingRect.width.toDouble() -
      padding.right;
  final paddedBottom = clippingRect.top.toDouble() +
      clippingRect.height.toDouble() -
      padding.bottom;

  final targetRight = x + floatingRect.width.toDouble();
  final targetBottom = y + floatingRect.height.toDouble();

  return _PopperOverflow(
    top: paddedTop - y,
    right: targetRight - paddedRight,
    bottom: targetBottom - paddedBottom,
    left: paddedLeft - x,
  );
}

_PopperVisibilityState _computeVisibilityState({
  required html.Rectangle<num> referenceRect,
  required html.Rectangle<num> floatingRect,
  required html.Rectangle<num> clippingRect,
  required double viewportX,
  required double viewportY,
}) {
  final referenceOverflow = _overflowForRect(
    targetRect: referenceRect,
    clippingRect: clippingRect,
  );
  final floatingOverflow = _overflowForRect(
    targetRect: html.Rectangle<num>(
      viewportX,
      viewportY,
      floatingRect.width,
      floatingRect.height,
    ),
    clippingRect: clippingRect,
  );

  return _PopperVisibilityState(
    referenceHidden: _isAnySideFullyClipped(referenceOverflow, referenceRect),
    escaped: _isAnySideFullyClipped(floatingOverflow, floatingRect),
  );
}

PopperInsets _overflowForRect({
  required html.Rectangle<num> targetRect,
  required html.Rectangle<num> clippingRect,
}) {
  final targetLeft = targetRect.left.toDouble();
  final targetTop = targetRect.top.toDouble();
  final targetRight = targetLeft + targetRect.width.toDouble();
  final targetBottom = targetTop + targetRect.height.toDouble();
  final clippingLeft = clippingRect.left.toDouble();
  final clippingTop = clippingRect.top.toDouble();
  final clippingRight = clippingLeft + clippingRect.width.toDouble();
  final clippingBottom = clippingTop + clippingRect.height.toDouble();

  return PopperInsets(
    top: clippingTop - targetTop,
    right: targetRight - clippingRight,
    bottom: targetBottom - clippingBottom,
    left: clippingLeft - targetLeft,
  );
}

bool _isAnySideFullyClipped(
  PopperInsets overflow,
  html.Rectangle<num> rect,
) {
  return overflow.top >= rect.height.toDouble() ||
      overflow.right >= rect.width.toDouble() ||
      overflow.bottom >= rect.height.toDouble() ||
      overflow.left >= rect.width.toDouble();
}
