part of '../../popper.dart';

typedef PopperDebugCleanup = void Function();

PopperDebugCleanup paintPopperDebugRects({
  required math.Rectangle<num> referenceRect,
  required math.Rectangle<num> floatingRect,
  required math.Rectangle<num> clippingRect,
}) {
  final host = web.document.createElement('div') as web.HTMLDivElement;
  host.style.position = 'fixed';
  host.style.left = '0';
  host.style.top = '0';
  host.style.width = '0';
  host.style.height = '0';
  host.style.pointerEvents = 'none';
  host.style.zIndex = '2147483647';

  host.appendChild(
      _buildDebugRect(referenceRect, 'rgba(27, 94, 32, 0.14)', '#1b5e20'));
  host.appendChild(
      _buildDebugRect(floatingRect, 'rgba(13, 71, 161, 0.14)', '#0d47a1'));
  host.appendChild(
      _buildDebugRect(clippingRect, 'rgba(183, 28, 28, 0.08)', '#b71c1c'));

  web.document.body?.appendChild(host);

  return () {
    host.remove();
  };
}

web.HTMLDivElement _buildDebugRect(
  math.Rectangle<num> rect,
  String backgroundColor,
  String borderColor,
) {
  final element = web.document.createElement('div') as web.HTMLDivElement;
  element.style.position = 'fixed';
  element.style.left = '${rect.left.toDouble()}px';
  element.style.top = '${rect.top.toDouble()}px';
  element.style.width = '${rect.width.toDouble()}px';
  element.style.height = '${rect.height.toDouble()}px';
  element.style.background = backgroundColor;
  element.style.border = '1px dashed $borderColor';
  element.style.boxSizing = 'border-box';
  return element;
}
