# Popper

[![pub package](https://img.shields.io/pub/v/popper.svg)](https://pub.dev/packages/popper)
[![Dart CI](https://github.com/insinfo/popper_dart/actions/workflows/dart_ci.yml/badge.svg)](https://github.com/insinfo/popper_dart/actions/workflows/dart_ci.yml)

A powerful and flexible positioning engine for Dart HTML, inspired by Popper.js and Floating UI.

It calculates the absolute or fixed X and Y coordinates needed to position a "floating" element (like a tooltip, popover, or dropdown) next to a "reference" element, while intelligently keeping it in view.

This package targets Dart web applications and uses `package:web` (the modern replacement for `dart:html`), so it is intended for browser environments.

## Installation

```sh
dart pub add popper
```

```yaml
dependencies:
  popper: ^2.0.0
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
import 'package:popper/popper.dart';
import 'package:web/web.dart';

void main() async {
  final reference = document.querySelector('#button')!;
  final floating = document.querySelector('#tooltip') as HTMLElement;

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
import 'package:popper/popper.dart';
import 'package:web/web.dart';

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

  EventStreamProviders.unloadEvent.forTarget(window).listen((_) {
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
- `arrowWriteMode`: Controls whether Popper writes the arrow on both axes (`full`), only on the cross axis (`crossAxisOnly`), or leaves arrow styling to your CSS (`none`).
- `anchorRectBuilder`: Overrides how the reference rectangle is measured, useful when focus/hover states slightly change the anchor geometry.
- `layoutWriter`: Replaces the default DOM writer so you can apply `PopperLayout` with your own CSS policy.
- `arrowLayoutWriter`: Replaces only the arrow writer while preserving the default floating element writer.
- `matchReferenceWidth` and `matchReferenceMinWidth`: Apply the reference width to the floating element.
- `hideWhenDetached`: Hides the floating element when the reference is clipped or the floating element escapes.

For theme-driven arrows such as Bootstrap popovers, prefer `arrowWriteMode: PopperArrowWriteMode.crossAxisOnly` so Popper still centers the arrow without overriding theme-controlled `top`/`right`/`bottom`/`left` values on the main axis.

`computePopperLayout` already exposes the pure layout result. If you want to split compute from apply in controller-driven flows, compute the layout yourself and call `controller.applyPopperLayout(layout)` only when you are ready to write styles.

When the reference element visually shifts between states, pass `anchorRectBuilder` to stabilize the measured anchor independently from the DOM element's current `getBoundingClientRect()`.

When integrating with strong CSS frameworks, pass `layoutWriter` to fully control which inline styles get written to the floating element and arrow.

If you only need to customize arrow styles, prefer `arrowLayoutWriter`. This lets Popper keep applying the floating element layout while you decide exactly how the arrow should be written.

```dart
final controller = PopperController(
  referenceElement: reference,
  floatingElement: floating,
  options: PopperOptions(
    placement: 'bottom',
    arrowElement: arrow,
    arrowLayoutWriter: (layout, arrowElement) {
      final arrowData = layout.middlewareData['arrow'] ?? const <String, dynamic>{};
      arrowElement.style
        ..position = 'absolute'
        ..left = '${(arrowData['x'] as num?)?.toStringAsFixed(2) ?? '0.00'}px'
        ..top = ''
        ..right = ''
        ..bottom = '';
    },
  ),
);
```

## Lifecycle Notes

- Call `startAutoUpdate()` when the floating element is visible and needs to react to scroll, resize, or DOM changes.
- Call `stopAutoUpdate()` if the element stays mounted but no longer needs live positioning.
- Call `dispose()` on `PopperController`, `PopperPortal`, or `PopperAnchoredOverlay` when they are no longer needed.
- `dispose()` hands the floating element back in the state it was in before Popper wrote to it, clearing the inline styles and `data-popper-*` attributes it applied. This matters when the element outlives the controller — a menu returning to its inline parent, for example, would otherwise stay frozen at the last computed viewport coordinates, since inline styles outrank your CSS. Pass `dispose(restoreFloatingState: false)` to leave the last written layout in place.
- Popper only undoes what Popper did: with a custom `layoutWriter` the floating element's styles are yours, so `dispose()` leaves them alone whatever `restoreFloatingState` says.

## Browser Support

This package depends on `package:web` and is meant for browser tests and browser builds. Run the test suite on a browser platform, for example:

```sh
dart test -p chrome
```
