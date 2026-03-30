part of '../../popper.dart';

PopperMiddleware autoPlacementMiddleware({
  required List<String> allowedPlacements,
  PopperInsets padding = const PopperInsets.all(0),
}) {
  return PopperMiddleware(
    name: 'autoPlacement',
    options: <String, dynamic>{
      'allowedPlacements': allowedPlacements,
      'padding': padding,
    },
    fn: (state) {
      final candidates =
          allowedPlacements.isEmpty ? _allPlacements : allowedPlacements;

      var bestPlacement = state.placement;
      var bestScore = double.infinity;
      final overflowsData = <Map<String, dynamic>>[];

      for (final placement in candidates) {
        final overflow = detectOverflow(
          state,
          PopperDetectOverflowOptions(
            placement: placement,
            padding: padding,
          ),
        );

        final score = math.max(overflow.top, 0.0).toDouble() +
            math.max(overflow.right, 0.0).toDouble() +
            math.max(overflow.bottom, 0.0).toDouble() +
            math.max(overflow.left, 0.0).toDouble();

        overflowsData.add(<String, dynamic>{
          'placement': placement,
          'overflows': <double>[
            overflow.top,
            overflow.right,
            overflow.bottom,
            overflow.left,
          ],
        });

        if (score < bestScore) {
          bestScore = score;
          bestPlacement = placement;
        }
      }

      if (bestPlacement != state.placement) {
        return PopperMiddlewareResult(
          data: <String, dynamic>{
            'overflows': overflowsData,
          },
          reset: PopperMiddlewareReset(
            placement: bestPlacement,
          ),
        );
      }

      return PopperMiddlewareResult(
        data: <String, dynamic>{
          'overflows': overflowsData,
        },
      );
    },
  );
}
