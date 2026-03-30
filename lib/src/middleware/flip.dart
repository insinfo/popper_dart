part of '../../popper.dart';

List<String> _expandAutoPlacement({
  required _PlacementParts requestedPlacement,
  required html.Rectangle<num> referenceRect,
  required html.Rectangle<num> clippingRect,
  required List<String> allowedPlacements,
}) {
  if (requestedPlacement.basePlacement != _placementAuto) {
    return <String>[
      _composePlacement(
        requestedPlacement.basePlacement,
        requestedPlacement.alignment,
      ),
    ];
  }

  final candidates = <String>[];
  for (final placement in allowedPlacements) {
    final parsed = _parsePlacement(placement);
    if (!_basePlacements.contains(parsed.basePlacement)) {
      continue;
    }

    if (requestedPlacement.alignment != null &&
        parsed.alignment != requestedPlacement.alignment) {
      continue;
    }

    candidates.add(_composePlacement(
      parsed.basePlacement,
      parsed.alignment ?? requestedPlacement.alignment,
    ));
  }

  final normalizedCandidates =
      candidates.isEmpty ? _allPlacements : candidates.toSet().toList();

  normalizedCandidates.sort((left, right) {
    final leftScore = _scoreAutoPlacement(
      placement: left,
      referenceRect: referenceRect,
      clippingRect: clippingRect,
    );
    final rightScore = _scoreAutoPlacement(
      placement: right,
      referenceRect: referenceRect,
      clippingRect: clippingRect,
    );
    return rightScore.compareTo(leftScore);
  });

  return normalizedCandidates;
}

double _scoreAutoPlacement({
  required String placement,
  required html.Rectangle<num> referenceRect,
  required html.Rectangle<num> clippingRect,
}) {
  final parts = _parsePlacement(placement);
  final clippingLeft = clippingRect.left.toDouble();
  final clippingTop = clippingRect.top.toDouble();
  final clippingRight = clippingLeft + clippingRect.width.toDouble();
  final clippingBottom = clippingTop + clippingRect.height.toDouble();
  final referenceLeft = referenceRect.left.toDouble();
  final referenceTop = referenceRect.top.toDouble();
  final referenceRight = referenceLeft + referenceRect.width.toDouble();
  final referenceBottom = referenceTop + referenceRect.height.toDouble();

  double mainSpace;
  switch (parts.basePlacement) {
    case _placementTop:
      mainSpace = referenceTop - clippingTop;
      break;
    case _placementBottom:
      mainSpace = clippingBottom - referenceBottom;
      break;
    case _placementLeft:
      mainSpace = referenceLeft - clippingLeft;
      break;
    case _placementRight:
      mainSpace = clippingRight - referenceRight;
      break;
    default:
      mainSpace = 0;
  }

  double crossSpace;
  if (_isVerticalPlacement(parts.basePlacement)) {
    final startSpace = referenceRight - clippingLeft;
    final endSpace = clippingRight - referenceLeft;
    if (parts.alignment == _alignmentStart) {
      crossSpace = startSpace;
    } else if (parts.alignment == _alignmentEnd) {
      crossSpace = endSpace;
    } else {
      crossSpace = math.min(startSpace, endSpace);
    }
  } else {
    final startSpace = referenceBottom - clippingTop;
    final endSpace = clippingBottom - referenceTop;
    if (parts.alignment == _alignmentStart) {
      crossSpace = startSpace;
    } else if (parts.alignment == _alignmentEnd) {
      crossSpace = endSpace;
    } else {
      crossSpace = math.min(startSpace, endSpace);
    }
  }

  return mainSpace + crossSpace * 0.25;
}

PopperMiddleware flipMiddleware({
  required List<String> fallbackPlacements,
  required List<String> allowedAutoPlacements,
  PopperInsets padding = const PopperInsets.all(0),
}) {
  return PopperMiddleware(
    name: 'flip',
    options: <String, dynamic>{
      'fallbackPlacements': fallbackPlacements,
      'allowedAutoPlacements': allowedAutoPlacements,
      'padding': padding,
    },
    fn: (state) {
      final placements = <String>[
        state.initialPlacement,
        ...fallbackPlacements,
      ];

      final expanded = <String>[];
      for (final placement in placements) {
        final parsed = _parsePlacement(placement);
        expanded.addAll(_expandAutoPlacement(
          requestedPlacement: parsed,
          referenceRect: state.rects.reference,
          clippingRect: state.clippingRect,
          allowedPlacements: allowedAutoPlacements,
        ));
      }

      final unique = <String>[];
      for (final placement in expanded) {
        if (!unique.contains(placement)) {
          unique.add(placement);
        }
      }

      var bestPlacement = state.placement;
      var bestScore = double.infinity;
      final overflowsData = <Map<String, dynamic>>[];

      for (final placement in unique) {
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
          if (score <= 0) {
            break;
          }
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
