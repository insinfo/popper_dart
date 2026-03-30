part of '../../popper.dart';

PopperMiddleware inlineMiddleware() {
  return PopperMiddleware(
    name: 'inline',
    fn: (state) {
      final clientRects = state.referenceElement.getClientRects();
      if (clientRects.length <= 1) {
        return const PopperMiddlewareResult();
      }

      var left = double.infinity;
      var top = double.infinity;
      var right = double.negativeInfinity;
      var bottom = double.negativeInfinity;

      for (final rect in clientRects) {
        left = math.min(left, rect.left.toDouble());
        top = math.min(top, rect.top.toDouble());
        right = math.max(right, rect.right.toDouble());
        bottom = math.max(bottom, rect.bottom.toDouble());
      }

      final nextRects = PopperRects(
        reference: html.Rectangle<num>(left, top, right - left, bottom - top),
        floating: _cloneRect(state.rects.floating),
      );

      if (nextRects.reference.left != state.rects.reference.left ||
          nextRects.reference.top != state.rects.reference.top ||
          nextRects.reference.width != state.rects.reference.width ||
          nextRects.reference.height != state.rects.reference.height) {
        return PopperMiddlewareResult(
          reset: PopperMiddlewareReset(
            rects: nextRects,
          ),
        );
      }

      return const PopperMiddlewareResult();
    },
  );
}
