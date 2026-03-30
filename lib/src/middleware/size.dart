part of '../../popper.dart';

PopperMiddleware sizeMiddleware() {
  return PopperMiddleware(
    name: 'size',
    fn: (state) {
      final overflow = detectOverflow(
        state,
        PopperDetectOverflowOptions(
          padding: state.options.padding,
        ),
      );

      final availableWidth = math.max(
        0,
        state.rects.floating.width.toDouble() -
            math.max(overflow.left, 0) -
            math.max(overflow.right, 0),
      );
      final availableHeight = math.max(
        0,
        state.rects.floating.height.toDouble() -
            math.max(overflow.top, 0) -
            math.max(overflow.bottom, 0),
      );

      return PopperMiddlewareResult(
        data: <String, dynamic>{
          'availableWidth': availableWidth,
          'availableHeight': availableHeight,
        },
      );
    },
  );
}
