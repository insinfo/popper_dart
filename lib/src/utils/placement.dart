part of '../../popper.dart';

_PlacementParts _parsePlacement(String placement) {
  final normalized = placement.trim().toLowerCase();
  if (normalized.isEmpty) {
    return const _PlacementParts(_placementBottom, _alignmentStart);
  }

  final segments = normalized.split('-');
  final basePlacement = segments.first;
  final alignment = segments.length > 1 ? segments[1] : null;

  if (basePlacement == _placementAuto) {
    return _PlacementParts(
      _placementAuto,
      alignment == _alignmentStart || alignment == _alignmentEnd
          ? alignment
          : _alignmentStart,
    );
  }

  final safeBasePlacement = _basePlacements.contains(basePlacement)
      ? basePlacement
      : _placementBottom;
  final safeAlignment =
      alignment == _alignmentStart || alignment == _alignmentEnd
          ? alignment
          : null;

  return _PlacementParts(safeBasePlacement, safeAlignment);
}

bool _isVerticalPlacement(String basePlacement) {
  return basePlacement == _placementTop || basePlacement == _placementBottom;
}

String _composePlacement(String basePlacement, String? alignment) {
  if (alignment == null || alignment.isEmpty) {
    return basePlacement;
  }
  return '$basePlacement-$alignment';
}

math.Point<double> _computeCoordsFromPlacement({
  required html.Rectangle<num> referenceRect,
  required html.Rectangle<num> floatingRect,
  required String placement,
  bool rtl = false,
}) {
  final parts = _parsePlacement(placement);
  final referenceLeft = referenceRect.left.toDouble();
  final referenceTop = referenceRect.top.toDouble();
  final referenceWidth = referenceRect.width.toDouble();
  final referenceHeight = referenceRect.height.toDouble();
  final floatingWidth = floatingRect.width.toDouble();
  final floatingHeight = floatingRect.height.toDouble();

  double x = referenceLeft;
  double y = referenceTop;

  switch (parts.basePlacement) {
    case _placementTop:
      x = referenceLeft + (referenceWidth - floatingWidth) / 2;
      y = referenceTop - floatingHeight;
      break;
    case _placementBottom:
      x = referenceLeft + (referenceWidth - floatingWidth) / 2;
      y = referenceTop + referenceHeight;
      break;
    case _placementLeft:
      x = referenceLeft - floatingWidth;
      y = referenceTop + (referenceHeight - floatingHeight) / 2;
      break;
    case _placementRight:
      x = referenceLeft + referenceWidth;
      y = referenceTop + (referenceHeight - floatingHeight) / 2;
      break;
    default:
      x = referenceLeft + (referenceWidth - floatingWidth) / 2;
      y = referenceTop + referenceHeight;
      break;
  }

  if (_isVerticalPlacement(parts.basePlacement)) {
    if (parts.alignment == _alignmentStart) {
      x = rtl ? referenceLeft + referenceWidth - floatingWidth : referenceLeft;
    } else if (parts.alignment == _alignmentEnd) {
      x = rtl ? referenceLeft : referenceLeft + referenceWidth - floatingWidth;
    }
  } else {
    if (parts.alignment == _alignmentStart) {
      y = referenceTop;
    } else if (parts.alignment == _alignmentEnd) {
      y = referenceTop + referenceHeight - floatingHeight;
    }
  }

  return math.Point<double>(x, y);
}

math.Point<double> _computeViewportCoordsForPlacement({
  required html.Rectangle<num> referenceRect,
  required html.Rectangle<num> floatingRect,
  required String placement,
  required PopperOffset offset,
  bool rtl = false,
}) {
  final baseCoords = _computeCoordsFromPlacement(
    referenceRect: referenceRect,
    floatingRect: floatingRect,
    placement: placement,
    rtl: rtl,
  );

  return _applyOffsetToViewportPosition(
    x: baseCoords.x,
    y: baseCoords.y,
    placement: placement,
    offset: offset,
    rtl: rtl,
  );
}
