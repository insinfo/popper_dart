part of '../../popper.dart';

PopperMiddleware hideMiddleware({
  PopperInsets padding = const PopperInsets.all(0),
}) {
  return PopperMiddleware(
    name: 'hide',
    options: <String, dynamic>{
      'padding': padding,
    },
    fn: (state) {
      final referenceOverflow = detectOverflow(
        state,
        PopperDetectOverflowOptions(
          elementContext: 'reference',
          padding: padding,
        ),
      );
      final floatingOverflow = detectOverflow(
        state,
        PopperDetectOverflowOptions(
          elementContext: 'floating',
          altBoundary: true,
          padding: padding,
        ),
      );

      final referenceHidden = referenceOverflow.top >=
              state.rects.reference.height.toDouble() ||
          referenceOverflow.right >= state.rects.reference.width.toDouble() ||
          referenceOverflow.bottom >= state.rects.reference.height.toDouble() ||
          referenceOverflow.left >= state.rects.reference.width.toDouble();

      final escaped = floatingOverflow.top >=
              state.rects.floating.height.toDouble() ||
          floatingOverflow.right >= state.rects.floating.width.toDouble() ||
          floatingOverflow.bottom >= state.rects.floating.height.toDouble() ||
          floatingOverflow.left >= state.rects.floating.width.toDouble();

      return PopperMiddlewareResult(
        data: <String, dynamic>{
          'referenceHidden': referenceHidden,
          'escaped': escaped,
          'referenceHiddenOffsets': <String, double>{
            'top': referenceOverflow.top,
            'right': referenceOverflow.right,
            'bottom': referenceOverflow.bottom,
            'left': referenceOverflow.left,
          },
          'escapedOffsets': <String, double>{
            'top': floatingOverflow.top,
            'right': floatingOverflow.right,
            'bottom': floatingOverflow.bottom,
            'left': floatingOverflow.left,
          },
        },
      );
    },
  );
}
