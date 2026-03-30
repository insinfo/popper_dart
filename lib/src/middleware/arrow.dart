part of '../../popper.dart';

PopperMiddleware arrowMiddleware({
  required html.Element element,
  PopperInsets padding = const PopperInsets.all(8),
}) {
  return PopperMiddleware(
    name: 'arrow',
    options: <String, dynamic>{
      'padding': padding,
    },
    fn: (state) {
      final arrowRect = _measureRect(element);
      final parts = _parsePlacement(state.placement);
      final floatingRect = state.rects.floating;
      final referenceRect = state.rects.reference;

      if (_isVerticalPlacement(parts.basePlacement)) {
        final desiredX = referenceRect.left.toDouble() +
            referenceRect.width.toDouble() / 2 -
            state.x -
            arrowRect.width.toDouble() / 2;
        final minX = padding.left;
        final maxX = math.max(
          minX,
          floatingRect.width.toDouble() -
              arrowRect.width.toDouble() -
              padding.right,
        );

        return PopperMiddlewareResult(
          data: <String, dynamic>{
            'x': _clamp(desiredX, minX, maxX),
          },
        );
      }

      final desiredY = referenceRect.top.toDouble() +
          referenceRect.height.toDouble() / 2 -
          state.y -
          arrowRect.height.toDouble() / 2;
      final minY = padding.top;
      final maxY = math.max(
        minY,
        floatingRect.height.toDouble() -
            arrowRect.height.toDouble() -
            padding.bottom,
      );

      return PopperMiddlewareResult(
        data: <String, dynamic>{
          'y': _clamp(desiredY, minY, maxY),
        },
      );
    },
  );
}
