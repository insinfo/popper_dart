part of '../../popper.dart';

/// `dart:html` exposed `style` and `getComputedStyle()` on every element;
/// `package:web` only declares them on `HTMLElement`/`SVGElement` and on
/// `window`. The casts are safe on the JS backends: every element shares the
/// same underlying JS object, which always carries an inline `style`.
extension _PopperElementHelpers on web.Element {
  web.CSSStyleDeclaration get style => (this as web.HTMLElement).style;

  web.CSSStyleDeclaration getComputedStyle() =>
      web.window.getComputedStyle(this);
}

/// Inline styles `PopperPortal.attach` takes over on the floating element.
const List<String> _popperPortalOwnedStyles = <String>[
  'position',
  'pointer-events',
  'z-index',
];

/// Inline styles `PopperController.applyPopperLayout` takes over on the
/// floating element.
const List<String> _popperLayoutOwnedStyles = <String>[
  'position',
  'left',
  'top',
  'right',
  'bottom',
  'margin',
  'transform',
  'width',
  'min-width',
  'visibility',
  'pointer-events',
  '--popper-available-width',
  '--popper-available-height',
];

/// Attributes `PopperController.applyPopperLayout` takes over on the floating
/// element.
const List<String> _popperLayoutOwnedAttributes = <String>[
  'data-popper-placement',
  'data-popper-reference-hidden',
  'data-popper-escaped',
];

/// Snapshot of the element state Popper takes ownership of, so `dispose()` can
/// hand the element back exactly as it was found.
///
/// Popper positions by writing inline styles, which outrank any stylesheet. An
/// element handed back still carrying them (`position: fixed` plus a stale
/// `transform`) keeps rendering at the last computed viewport coordinates
/// instead of falling back to its own CSS.
///
/// Restoring the captured values rather than blanket-clearing preserves inline
/// styles the consumer had set before Popper attached.
class _PopperOwnedState {
  _PopperOwnedState._(this._element, this._styles, this._attributes);

  final web.Element _element;
  final Map<String, String> _styles;
  final Map<String, String?> _attributes;

  factory _PopperOwnedState.capture(
    web.Element element, {
    List<String> styleProperties = const <String>[],
    List<String> attributes = const <String>[],
  }) {
    final styles = <String, String>{};
    for (final property in styleProperties) {
      styles[property] = element.style.getPropertyValue(property);
    }

    final capturedAttributes = <String, String?>{};
    for (final attribute in attributes) {
      capturedAttributes[attribute] = element.getAttribute(attribute);
    }

    return _PopperOwnedState._(element, styles, capturedAttributes);
  }

  void restore() {
    for (final entry in _styles.entries) {
      if (entry.value.isEmpty) {
        _element.style.removeProperty(entry.key);
      } else {
        _element.style.setProperty(entry.key, entry.value);
      }
    }

    for (final entry in _attributes.entries) {
      final value = entry.value;
      if (value == null) {
        _element.removeAttribute(entry.key);
      } else {
        _element.setAttribute(entry.key, value);
      }
    }
  }
}

math.Rectangle<num> _rectFromDomRect(web.DOMRect rect) {
  return math.Rectangle<num>(
    rect.left,
    rect.top,
    rect.width,
    rect.height,
  );
}

math.Rectangle<num> _measureRect(web.Element element) {
  final rect = _rectFromDomRect(element.getBoundingClientRect());
  if (rect.width.toDouble() > 0 || rect.height.toDouble() > 0) {
    return rect;
  }

  if (!element.isA<web.HTMLElement>()) {
    return rect;
  }

  final previousDisplay = element.style.display;
  final previousVisibility = element.style.visibility;
  final previousPosition = element.style.position;
  final computedStyle = element.getComputedStyle();

  if (computedStyle.display == 'none') {
    element.style.display = 'block';
  }
  element.style.visibility = 'hidden';
  if (computedStyle.position == 'static' || computedStyle.position.isEmpty) {
    element.style.position = 'absolute';
  }

  final measured = _rectFromDomRect(element.getBoundingClientRect());

  element.style.display = previousDisplay;
  element.style.visibility = previousVisibility;
  element.style.position = previousPosition;

  return measured;
}

math.Rectangle<num> _cloneRect(math.Rectangle<num> rect) {
  return math.Rectangle<num>(
    rect.left,
    rect.top,
    rect.width,
    rect.height,
  );
}

double _asDouble(num? value) {
  return value?.toDouble() ?? 0.0;
}

bool _isRTL(web.Element element) {
  return element.getComputedStyle().direction.toLowerCase() == 'rtl';
}

double _scaleX(web.Element element) {
  if (!element.isA<web.HTMLElement>()) {
    return 1.0;
  }
  final offsetWidth = (element as web.HTMLElement).offsetWidth;
  if (offsetWidth == 0) {
    return 1.0;
  }

  final rect = element.getBoundingClientRect();
  final width = rect.width.toDouble();
  return width == 0 ? 1.0 : width / offsetWidth.toDouble();
}

double _scaleY(web.Element element) {
  if (!element.isA<web.HTMLElement>()) {
    return 1.0;
  }
  final offsetHeight = (element as web.HTMLElement).offsetHeight;
  if (offsetHeight == 0) {
    return 1.0;
  }

  final rect = element.getBoundingClientRect();
  final height = rect.height.toDouble();
  return height == 0 ? 1.0 : height / offsetHeight.toDouble();
}

math.Rectangle<num> _getViewportRect() {
  final visualViewport = _getVisualViewport();
  final viewportWidth =
      visualViewport?['width'] ?? _asDouble(web.window.innerWidth);
  final viewportHeight =
      visualViewport?['height'] ?? _asDouble(web.window.innerHeight);
  final offsetLeft = visualViewport?['offsetLeft'] ?? 0.0;
  final offsetTop = visualViewport?['offsetTop'] ?? 0.0;
  return math.Rectangle<num>(
    offsetLeft,
    offsetTop,
    viewportWidth,
    viewportHeight,
  );
}

math.Rectangle<num> _getDocumentRectInViewportCoords() {
  final documentElement = web.document.documentElement;
  final body = web.document.body;

  final documentWidth = math.max(
    _asDouble(documentElement?.scrollWidth),
    _asDouble(body?.scrollWidth),
  );
  final documentHeight = math.max(
    _asDouble(documentElement?.scrollHeight),
    _asDouble(body?.scrollHeight),
  );

  return math.Rectangle<num>(
    -_asDouble(web.window.scrollX),
    -_asDouble(web.window.scrollY),
    documentWidth,
    documentHeight,
  );
}

math.Rectangle<num> _getClippingRect({
  required web.Element referenceElement,
  required web.Element floatingElement,
  required PopperBoundary boundary,
}) {
  switch (boundary) {
    case PopperBoundary.viewport:
      return _getViewportRect();
    case PopperBoundary.document:
      return _getDocumentRectInViewportCoords();
    case PopperBoundary.clippingAncestors:
      var rect = _getViewportRect();
      final ancestors = <web.Element>{}
        ..addAll(_collectClippingAncestors(referenceElement))
        ..addAll(_collectClippingAncestors(floatingElement));

      for (final ancestor in ancestors) {
        rect = _intersectRects(rect, _getInnerClientRect(ancestor));
      }
      return rect;
  }
}

Set<web.Element> _collectClippingAncestors(web.Element element) {
  final result = <web.Element>{};
  web.Element? current = element.parentElement;

  while (current != null && current != web.document.body) {
    if (_isClippingElement(current)) {
      result.add(current);
    }
    current = current.parentElement;
  }

  return result;
}

bool _isClippingElement(web.Element element) {
  final computedStyle = element.getComputedStyle();
  final overflow =
      '${computedStyle.overflow}${computedStyle.overflowX}${computedStyle.overflowY}'
          .toLowerCase();

  return overflow.contains('hidden') ||
      overflow.contains('clip') ||
      overflow.contains('auto') ||
      overflow.contains('scroll') ||
      overflow.contains('overlay');
}

math.Rectangle<num> _getInnerClientRect(web.Element element) {
  final rect = _rectFromDomRect(element.getBoundingClientRect());

  if (!element.isA<web.HTMLElement>()) {
    return rect;
  }

  final left = rect.left.toDouble() + _asDouble(element.clientLeft);
  final top = rect.top.toDouble() + _asDouble(element.clientTop);
  final width = _asDouble(element.clientWidth);
  final height = _asDouble(element.clientHeight);

  return math.Rectangle<num>(left, top, width, height);
}

math.Rectangle<num> _intersectRects(
  math.Rectangle<num> first,
  math.Rectangle<num> second,
) {
  final left = math.max(first.left.toDouble(), second.left.toDouble());
  final top = math.max(first.top.toDouble(), second.top.toDouble());
  final right = math.min(
    first.left.toDouble() + first.width.toDouble(),
    second.left.toDouble() + second.width.toDouble(),
  );
  final bottom = math.min(
    first.top.toDouble() + first.height.toDouble(),
    second.top.toDouble() + second.height.toDouble(),
  );

  return math.Rectangle<num>(
    left,
    top,
    math.max(0.0, right - left),
    math.max(0.0, bottom - top),
  );
}

web.Element? _getOffsetParent(web.Element element) {
  final computedStyle = element.getComputedStyle();

  if (computedStyle.position == 'fixed') {
    return null;
  }

  if (element.isA<web.HTMLElement>()) {
    final offsetParent = (element as web.HTMLElement).offsetParent;
    if (offsetParent != null &&
        offsetParent != web.document.documentElement &&
        offsetParent != web.document.body) {
      return offsetParent;
    }
  }

  web.Element? current = element.parentElement;
  while (current != null &&
      current != web.document.body &&
      current != web.document.documentElement) {
    final currentStyle = current.getComputedStyle();
    if (currentStyle.position != 'static' || _createsContainingBlock(current)) {
      return current;
    }
    current = current.parentElement;
  }

  return web.document.body;
}

bool _createsContainingBlock(web.Element element) {
  final style = element.getComputedStyle();
  final transform = style.getPropertyValue('transform');
  final perspective = style.getPropertyValue('perspective');
  final contain = style.getPropertyValue('contain');
  final willChange = style.getPropertyValue('will-change');
  final filter = style.getPropertyValue('filter');

  return transform != 'none' ||
      perspective != 'none' ||
      contain.contains('paint') ||
      willChange.contains('transform') ||
      willChange.contains('perspective') ||
      willChange.contains('filter') ||
      filter != 'none';
}

math.Point<double> _convertViewportCoordsToCssCoords({
  required double viewportX,
  required double viewportY,
  required web.Element floatingElement,
  required PopperStrategy strategy,
}) {
  if (strategy == PopperStrategy.fixed) {
    return math.Point<double>(viewportX, viewportY);
  }

  final offsetParent = _getOffsetParent(floatingElement);
  if (offsetParent == null || offsetParent == web.document.body) {
    return math.Point<double>(
      viewportX + _asDouble(web.window.scrollX),
      viewportY + _asDouble(web.window.scrollY),
    );
  }

  final offsetParentRect = offsetParent.getBoundingClientRect();
  final scaleX = _scaleX(offsetParent);
  final scaleY = _scaleY(offsetParent);
  final scrollLeft = offsetParent == web.document.body
      ? _asDouble(web.window.scrollX)
      : _asDouble(offsetParent.scrollLeft);
  final scrollTop = offsetParent == web.document.body
      ? _asDouble(web.window.scrollY)
      : _asDouble(offsetParent.scrollTop);
  final clientLeft = offsetParent.isA<web.HTMLElement>()
      ? _asDouble(offsetParent.clientLeft)
      : 0.0;
  final clientTop = offsetParent.isA<web.HTMLElement>()
      ? _asDouble(offsetParent.clientTop)
      : 0.0;

  return math.Point<double>(
    (viewportX - offsetParentRect.left.toDouble() - clientLeft + scrollLeft) /
        scaleX,
    (viewportY - offsetParentRect.top.toDouble() - clientTop + scrollTop) /
        scaleY,
  );
}

double? _numPropertyOf(JSObject target, String name) {
  if (!target.hasProperty(name.toJS).toDart) {
    return null;
  }
  final value = target.getProperty(name.toJS);
  return value.isA<JSNumber>() ? (value as JSNumber).toDartDouble : null;
}

Map<String, double>? _getVisualViewport() {
  final testViewport =
      web.window.getProperty('__popperTestVisualViewport'.toJS);
  if (testViewport.isA<JSObject>()) {
    final target = testViewport as JSObject;
    return <String, double>{
      'width': _numPropertyOf(target, 'width') ?? 0.0,
      'height': _numPropertyOf(target, 'height') ?? 0.0,
      'offsetLeft': _numPropertyOf(target, 'offsetLeft') ?? 0.0,
      'offsetTop': _numPropertyOf(target, 'offsetTop') ?? 0.0,
    };
  }

  final viewport = web.window.visualViewport;
  if (viewport == null) {
    return null;
  }

  final width = viewport.width;
  final height = viewport.height;
  if (width <= 0 || height <= 0) {
    return null;
  }

  return <String, double>{
    'width': width,
    'height': height,
    'offsetLeft': viewport.offsetLeft,
    'offsetTop': viewport.offsetTop,
  };
}

double _roundByDevicePixelRatio(double value) {
  final devicePixelRatio = _asDouble(web.window.devicePixelRatio);
  if (devicePixelRatio <= 0) {
    return value;
  }
  return (value * devicePixelRatio).roundToDouble() / devicePixelRatio;
}

double _clamp(double value, double minimum, double maximum) {
  if (maximum < minimum) {
    return minimum;
  }
  return math.max(minimum, math.min(maximum, value));
}
