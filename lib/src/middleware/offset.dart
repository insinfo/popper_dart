part of '../../popper.dart';

math.Point<double> _applyOffsetToViewportPosition({
  required double x,
  required double y,
  required String placement,
  required PopperOffset offset,
  bool rtl = false,
}) {
  final parts = _parsePlacement(placement);
  var nextX = x;
  var nextY = y;
  final crossAxisMultiplier =
      rtl && _isVerticalPlacement(parts.basePlacement) ? -1.0 : 1.0;

  switch (parts.basePlacement) {
    case _placementTop:
      nextY -= offset.mainAxis;
      nextX += offset.crossAxis * crossAxisMultiplier;
      break;
    case _placementBottom:
      nextY += offset.mainAxis;
      nextX += offset.crossAxis * crossAxisMultiplier;
      break;
    case _placementLeft:
      nextX -= offset.mainAxis;
      nextY += offset.crossAxis;
      break;
    case _placementRight:
      nextX += offset.mainAxis;
      nextY += offset.crossAxis;
      break;
  }

  return math.Point<double>(nextX, nextY);
}

PopperMiddleware offsetMiddleware(
    [PopperOffset offset = const PopperOffset()]) {
  return PopperMiddleware(
    name: 'offset',
    options: offset,
    fn: (state) {
      final delta = _applyOffsetToViewportPosition(
        x: 0,
        y: 0,
        placement: state.placement,
        offset: offset,
        rtl: state.rtl,
      );

      return PopperMiddlewareResult(
        x: state.x + delta.x,
        y: state.y + delta.y,
        data: <String, dynamic>{
          'x': delta.x,
          'y': delta.y,
        },
      );
    },
  );
}
