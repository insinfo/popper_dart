part of '../popper.dart';

class PopperPortal {
  final html.DivElement hostElement;
  final html.Element floatingElement;
  final html.Element? _originalParent;
  final bool _restoreOnDispose;
  final _PopperOwnedState _floatingState;
  bool _disposed = false;

  PopperPortal._({
    required this.hostElement,
    required this.floatingElement,
    required html.Element? originalParent,
    required bool restoreOnDispose,
    required _PopperOwnedState floatingState,
  })  : _originalParent = originalParent,
        _restoreOnDispose = restoreOnDispose,
        _floatingState = floatingState;

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
    final floatingState = _PopperOwnedState.capture(
      floatingElement,
      styleProperties: _popperPortalOwnedStyles,
    );
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
      floatingState: floatingState,
    );
  }

  /// Tears the portal down, moving the floating element back to its original
  /// parent when `restoreOnDispose` was set.
  ///
  /// By default the styles this portal applied to the floating element
  /// (`position`, `pointer-events`, `z-index`) are handed back as they were.
  /// Pass [restoreFloatingState] as `false` to leave them in place.
  void dispose({bool restoreFloatingState = true}) {
    if (_disposed) {
      return;
    }

    if (_restoreOnDispose && _originalParent != null) {
      _originalParent.append(floatingElement);
    }
    if (restoreFloatingState) {
      _floatingState.restore();
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

  /// Disposes the controller and the portal.
  ///
  /// See [PopperController.dispose] and [PopperPortal.dispose] for what
  /// [restoreFloatingState] controls. The controller is disposed first so the
  /// portal's pre-attach snapshot of `position` is the one that lands.
  void dispose({bool restoreFloatingState = true}) {
    controller.dispose(restoreFloatingState: restoreFloatingState);
    portal.dispose(restoreFloatingState: restoreFloatingState);
  }
}
