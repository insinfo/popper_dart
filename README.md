# Popper

[![Dart CI](https://github.com/insinfo/popper_dart/actions/workflows/dart_ci.yml/badge.svg)](https://github.com/insinfo/popper_dart/actions/workflows/dart_ci.yml)

A powerful and flexible positioning engine for Dart HTML, inspired by Popper.js and Floating UI.

It calculates the absolute or fixed X and Y coordinates needed to position a "floating" element (like a tooltip, popover, or dropdown) next to a "reference" element, while intelligently keeping it in view.

This package targets Dart web applications and uses `dart:html`, so it is intended for browser environments.

## Installation

```sh
dart pub add popper
```

```yaml
dependencies:
  popper: ^1.0.0
```

## Features
- **Smart Positioning**: Automatically flips or shifts the floating element when it hits the edge of the clipping boundaries.
- **Middleware System**: Highly customizable pipeline (includes `flip`, `shift`, `offset`, `size`, `arrow`, `hide`, `inline`, and `autoPlacement`).
- **Auto Update**: Includes built-in `PopperController` and `PopperAnchoredOverlay` to automatically update positions on scroll, resize, or DOM mutations.
- **Advanced Boundary Detection**: Automatically finds visual viewports and scroll ancestors to prevent the floating element from being clipped.

## Handling Layouts

The exact layout computation is provided by `computePopperLayout`, and low-level absolute coordinates can be extracted using `computePosition`.

Use `computePosition` when you only need coordinates and middleware data. Use `computePopperLayout` when you also need the resolved placement, clipping rect, overflow information, visibility state, or available size.

## Basic Usage

```dart
import 'dart:html';
import 'package:popper/popper.dart';

void main() async {
  final reference = document.querySelector('#button')!;
  final floating = document.querySelector('#tooltip')!;

  // Low-level computation
  final result = await computePosition(
    referenceElement: reference,
    floatingElement: floating,
    placement: 'bottom',
    middleware: [
      offsetMiddleware(const PopperOffset(mainAxis: 8)),
      flipMiddleware(
        fallbackPlacements: ['top'],
        allowedAutoPlacements: ['top', 'bottom'],
      ),
      shiftMiddleware(padding: const PopperInsets.all(5)),
    ],
  );

  floating.style.position = 'absolute';
  floating.style.left = '${result.x}px';
  floating.style.top = '${result.y}px';
  
  // Or use the complete PopperController to handle styles + auto-updating
  final controller = PopperController(
    referenceElement: reference,
    floatingElement: floating,
    options: const PopperOptions(
      placement: 'bottom-start',
      strategy: PopperStrategy.absolute,
      flip: true,
      shift: true,
    ),
  );
  
  controller.startAutoUpdate();
}
```

## Anchored Overlay Example

If your floating element should be rendered in a portal attached to `document.body`, use `PopperAnchoredOverlay`.

```dart
import 'dart:html';
import 'package:popper/popper.dart';

void main() {
  final button = document.querySelector('#button')!;
  final menu = document.querySelector('#menu')!;

  final overlay = PopperAnchoredOverlay.attach(
    referenceElement: button,
    floatingElement: menu,
    popperOptions: const PopperOptions(
      placement: 'bottom-start',
      strategy: PopperStrategy.fixed,
      shift: true,
      flip: true,
      hideWhenDetached: true,
    ),
    portalOptions: const PopperPortalOptions(
      restoreOnDispose: true,
    ),
  );

  overlay.startAutoUpdate();

  window.onUnload.listen((_) {
    overlay.dispose();
  });
}
```

## Common Options

`PopperOptions` lets you enable the built-in middleware pipeline without wiring each middleware manually.

- `placement`: Initial placement such as `bottom-start`, `top`, or `auto`.
- `strategy`: `PopperStrategy.fixed` or `PopperStrategy.absolute`.
- `offset`: Adds distance between reference and floating elements.
- `flip`: Enables fallback placement selection when the preferred side overflows.
- `allowedAutoPlacements`: Restricts which placements may be chosen when using `placement: 'auto'`.
- `shift`: Keeps the floating element inside the clipping area.
- `inline`: Uses the union of client rects for multi-line inline references.
- `arrowElement`: Enables arrow positioning and exposes arrow data in `middlewareData['arrow']`.
- `matchReferenceWidth` and `matchReferenceMinWidth`: Apply the reference width to the floating element.
- `hideWhenDetached`: Hides the floating element when the reference is clipped or the floating element escapes.

## Lifecycle Notes

- Call `startAutoUpdate()` when the floating element is visible and needs to react to scroll, resize, or DOM changes.
- Call `stopAutoUpdate()` if the element stays mounted but no longer needs live positioning.
- Call `dispose()` on `PopperController`, `PopperPortal`, or `PopperAnchoredOverlay` when they are no longer needed.

## Browser Support

This package depends on `dart:html` and is meant for browser tests and browser builds. Run the test suite on a browser platform, for example:

```sh
dart test -p chrome
```
