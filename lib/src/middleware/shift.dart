part of '../../popper.dart';

math.Point<double> _shiftWithinClippingRect({
  required double x,
  required double y,
  required html.Rectangle<num> floatingRect,
  required html.Rectangle<num> clippingRect,
  required String placement,
  required PopperInsets padding,
  required bool shiftCrossAxis,
}) {
  final parts = _parsePlacement(placement);
  final minX = clippingRect.left.toDouble() + padding.left;
  final maxX = clippingRect.left.toDouble() +
      clippingRect.width.toDouble() -
      padding.right -
      floatingRect.width.toDouble();
  final minY = clippingRect.top.toDouble() + padding.top;
  final maxY = clippingRect.top.toDouble() +
      clippingRect.height.toDouble() -
      padding.bottom -
      floatingRect.height.toDouble();

  var nextX = x;
  var nextY = y;

  if (_isVerticalPlacement(parts.basePlacement)) {
    nextY = _clamp(nextY, minY, maxY);
    if (shiftCrossAxis) {
      nextX = _clamp(nextX, minX, maxX);
    }
  } else {
    nextX = _clamp(nextX, minX, maxX);
    if (shiftCrossAxis) {
      nextY = _clamp(nextY, minY, maxY);
    }
  }

  return math.Point<double>(nextX, nextY);
}

PopperMiddleware shiftMiddleware({
  PopperInsets padding = const PopperInsets.all(0),
  bool crossAxis = false,
}) {
  return PopperMiddleware(
    name: 'shift',
    options: <String, dynamic>{
      'padding': padding,
      'crossAxis': crossAxis,
    },
    fn: (state) {
      final shifted = _shiftWithinClippingRect(
        x: state.x,
        y: state.y,
        floatingRect: state.rects.floating,
        clippingRect: state.clippingRect,
        placement: state.placement,
        padding: padding,
        shiftCrossAxis: crossAxis,
      );

      return PopperMiddlewareResult(
        x: shifted.x,
        y: shifted.y,
        data: <String, dynamic>{
          'x': shifted.x - state.x,
          'y': shifted.y - state.y,
          'enabled': <String, bool>{
            'mainAxis': true,
            'crossAxis': crossAxis,
          },
        },
      );
    },
  );
}
