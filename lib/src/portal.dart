part of '../popper.dart';

class PopperPortal {
  final html.DivElement hostElement;
  final html.Element floatingElement;
  final html.Element? _originalParent;
  final bool _restoreOnDispose;
  bool _disposed = false;

  PopperPortal._({
    required this.hostElement,
    required this.floatingElement,
    required html.Element? originalParent,
    required bool restoreOnDispose,
  })  : _originalParent = originalParent,
        _restoreOnDispose = restoreOnDispose;

  factory PopperPortal.attach({
    required html.Element floatingElement,
    PopperPortalOptions options = const PopperPortalOptions(),
  }) {
    final hostElement = html.DivElement()..classes.add(options.hostClassName);
    hostElement.style.position = 'fixed';
    hostElement.style.left = '0';
    hostElement.style.top = '0';
    hostElement.style.width = '100%';
    hostElement.style.height = '100%';
    hostElement.style.pointerEvents = 'none';
    hostElement.style.zIndex = options.hostZIndex;

    final originalParent = floatingElement.parent;
    html.document.body?.append(hostElement);

    floatingElement.style.position = 'fixed';
    floatingElement.style.pointerEvents = 'auto';
    floatingElement.style.zIndex = options.floatingZIndex;
    hostElement.append(floatingElement);

    return PopperPortal._(
      hostElement: hostElement,
      floatingElement: floatingElement,
      originalParent: originalParent,
      restoreOnDispose: options.restoreOnDispose,
    );
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    if (_restoreOnDispose && _originalParent != null) {
      _originalParent.append(floatingElement);
    }

    hostElement.remove();
    _disposed = true;
  }
}

class PopperAnchoredOverlay {
  final PopperPortal portal;
  final PopperController controller;

  PopperAnchoredOverlay._({
    required this.portal,
    required this.controller,
  });

  factory PopperAnchoredOverlay.attach({
    required html.Element referenceElement,
    required html.Element floatingElement,
    PopperOptions popperOptions = const PopperOptions(),
    PopperPortalOptions portalOptions = const PopperPortalOptions(),
  }) {
    final portal = PopperPortal.attach(
      floatingElement: floatingElement,
      options: portalOptions,
    );

    final controller = PopperController(
      referenceElement: referenceElement,
      floatingElement: floatingElement,
      options: popperOptions,
    );

    return PopperAnchoredOverlay._(
      portal: portal,
      controller: controller,
    );
  }

  Future<PopperLayout?> update() => controller.update();

  void startAutoUpdate() => controller.startAutoUpdate();

  void stopAutoUpdate() => controller.stopAutoUpdate();

  void dispose() {
    controller.dispose();
    portal.dispose();
  }
}
