part of '../../popper.dart';

html.Rectangle<num> _measureRect(html.Element element) {
  final rect = element.getBoundingClientRect();
  if (rect.width.toDouble() > 0 || rect.height.toDouble() > 0) {
    return rect;
  }

  if (element is! html.HtmlElement) {
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

  final measured = element.getBoundingClientRect();

  element.style.display = previousDisplay;
  element.style.visibility = previousVisibility;
  element.style.position = previousPosition;

  return measured;
}

html.Rectangle<num> _cloneRect(html.Rectangle<num> rect) {
  return html.Rectangle<num>(
    rect.left,
    rect.top,
    rect.width,
    rect.height,
  );
}

double _asDouble(num? value) {
  return value?.toDouble() ?? 0.0;
}

bool _isRTL(html.Element element) {
  return element.getComputedStyle().direction.toLowerCase() == 'rtl';
}

double _scaleX(html.Element element) {
  if (element is! html.HtmlElement || element.offsetWidth == 0) {
    return 1.0;
  }

  final rect = element.getBoundingClientRect();
  final width = rect.width.toDouble();
  return width == 0 ? 1.0 : width / element.offsetWidth.toDouble();
}

double _scaleY(html.Element element) {
  if (element is! html.HtmlElement || element.offsetHeight == 0) {
    return 1.0;
  }

  final rect = element.getBoundingClientRect();
  final height = rect.height.toDouble();
  return height == 0 ? 1.0 : height / element.offsetHeight.toDouble();
}

html.Rectangle<num> _getViewportRect() {
  final visualViewport = _getVisualViewport();
  final viewportWidth =
      visualViewport?['width'] ?? _asDouble(html.window.innerWidth);
  final viewportHeight =
      visualViewport?['height'] ?? _asDouble(html.window.innerHeight);
  final offsetLeft = visualViewport?['offsetLeft'] ?? 0.0;
  final offsetTop = visualViewport?['offsetTop'] ?? 0.0;
  return html.Rectangle<num>(
    offsetLeft,
    offsetTop,
    viewportWidth,
    viewportHeight,
  );
}

html.Rectangle<num> _getDocumentRectInViewportCoords() {
  final documentElement = html.document.documentElement;
  final body = html.document.body;

  final documentWidth = math.max(
    _asDouble(documentElement?.scrollWidth),
    _asDouble(body?.scrollWidth),
  );
  final documentHeight = math.max(
    _asDouble(documentElement?.scrollHeight),
    _asDouble(body?.scrollHeight),
  );

  return html.Rectangle<num>(
    -_asDouble(html.window.pageXOffset),
    -_asDouble(html.window.pageYOffset),
    documentWidth,
    documentHeight,
  );
}

html.Rectangle<num> _getClippingRect({
  required html.Element referenceElement,
  required html.Element floatingElement,
  required PopperBoundary boundary,
}) {
  switch (boundary) {
    case PopperBoundary.viewport:
      return _getViewportRect();
    case PopperBoundary.document:
      return _getDocumentRectInViewportCoords();
    case PopperBoundary.clippingAncestors:
      var rect = _getViewportRect();
      final ancestors = <html.Element>{}
        ..addAll(_collectClippingAncestors(referenceElement))
        ..addAll(_collectClippingAncestors(floatingElement));

      for (final ancestor in ancestors) {
        rect = _intersectRects(rect, _getInnerClientRect(ancestor));
      }
      return rect;
  }
}

Set<html.Element> _collectClippingAncestors(html.Element element) {
  final result = <html.Element>{};
  html.Element? current = element.parent;

  while (current != null && current != html.document.body) {
    if (_isClippingElement(current)) {
      result.add(current);
    }
    current = current.parent;
  }

  return result;
}

bool _isClippingElement(html.Element element) {
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

html.Rectangle<num> _getInnerClientRect(html.Element element) {
  final rect = element.getBoundingClientRect();

  if (element is! html.HtmlElement) {
    return rect;
  }

  final left = rect.left.toDouble() + _asDouble(element.clientLeft);
  final top = rect.top.toDouble() + _asDouble(element.clientTop);
  final width = _asDouble(element.clientWidth);
  final height = _asDouble(element.clientHeight);

  return html.Rectangle<num>(left, top, width, height);
}

html.Rectangle<num> _intersectRects(
  html.Rectangle<num> first,
  html.Rectangle<num> second,
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

  return html.Rectangle<num>(
    left,
    top,
    math.max(0.0, right - left),
    math.max(0.0, bottom - top),
  );
}

html.Element? _getOffsetParent(html.Element element) {
  final computedStyle = element.getComputedStyle();

  if (computedStyle.position == 'fixed') {
    return null;
  }

  if (element is html.HtmlElement && element.offsetParent != null) {
    final offsetParent = element.offsetParent;
    if (offsetParent != null &&
        offsetParent != html.document.documentElement &&
        offsetParent != html.document.body) {
      return offsetParent;
    }
  }

  html.Element? current = element.parent;
  while (current != null &&
      current != html.document.body &&
      current != html.document.documentElement) {
    final currentStyle = current.getComputedStyle();
    if (currentStyle.position != 'static' || _createsContainingBlock(current)) {
      return current;
    }
    current = current.parent;
  }

  return html.document.body;
}

bool _createsContainingBlock(html.Element element) {
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
  required html.Element floatingElement,
  required PopperStrategy strategy,
}) {
  if (strategy == PopperStrategy.fixed) {
    return math.Point<double>(viewportX, viewportY);
  }

  final offsetParent = _getOffsetParent(floatingElement);
  if (offsetParent == null || offsetParent == html.document.body) {
    return math.Point<double>(
      viewportX + _asDouble(html.window.pageXOffset),
      viewportY + _asDouble(html.window.pageYOffset),
    );
  }

  final offsetParentRect = offsetParent.getBoundingClientRect();
  final scaleX = _scaleX(offsetParent);
  final scaleY = _scaleY(offsetParent);
  final scrollLeft = offsetParent == html.document.body
      ? _asDouble(html.window.pageXOffset)
      : _asDouble(offsetParent.scrollLeft);
  final scrollTop = offsetParent == html.document.body
      ? _asDouble(html.window.pageYOffset)
      : _asDouble(offsetParent.scrollTop);
  final clientLeft = offsetParent is html.HtmlElement
      ? _asDouble(offsetParent.clientLeft)
      : 0.0;
  final clientTop = offsetParent is html.HtmlElement
      ? _asDouble(offsetParent.clientTop)
      : 0.0;

  return math.Point<double>(
    (viewportX - offsetParentRect.left.toDouble() - clientLeft + scrollLeft) /
        scaleX,
    (viewportY - offsetParentRect.top.toDouble() - clientTop + scrollTop) /
        scaleY,
  );
}

Map<String, double>? _getVisualViewport() {
  if (js_util.hasProperty(html.window, '__popperTestVisualViewport')) {
    final testViewport =
        js_util.getProperty<Object?>(html.window, '__popperTestVisualViewport');
    if (testViewport != null) {
      return <String, double>{
        'width': _asDouble(
          js_util.getProperty<Object?>(testViewport, 'width') as num?,
        ),
        'height': _asDouble(
          js_util.getProperty<Object?>(testViewport, 'height') as num?,
        ),
        'offsetLeft': _asDouble(
          js_util.getProperty<Object?>(testViewport, 'offsetLeft') as num?,
        ),
        'offsetTop': _asDouble(
          js_util.getProperty<Object?>(testViewport, 'offsetTop') as num?,
        ),
      };
    }
  }

  if (!js_util.hasProperty(html.window, 'visualViewport')) {
    return null;
  }

  final viewport = js_util.getProperty<Object?>(html.window, 'visualViewport');
  if (viewport == null) {
    return null;
  }

  double getNumber(String name) {
    if (!js_util.hasProperty(viewport, name)) {
      return 0.0;
    }
    return _asDouble(js_util.getProperty<Object?>(viewport, name) as num?);
  }

  final width = getNumber('width');
  final height = getNumber('height');
  if (width <= 0 || height <= 0) {
    return null;
  }

  return <String, double>{
    'width': width,
    'height': height,
    'offsetLeft': getNumber('offsetLeft'),
    'offsetTop': getNumber('offsetTop'),
  };
}

double _roundByDevicePixelRatio(double value) {
  final devicePixelRatio = _asDouble(html.window.devicePixelRatio);
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
