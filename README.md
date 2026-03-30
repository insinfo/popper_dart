# Popper

A powerful and flexible positioning engine for Dart HTML, inspired by Popper.js and Floating UI.

It calculates the absolute or fixed X and Y coordinates needed to position a "floating" element (like a tooltip, popover, or dropdown) next to a "reference" element, while intelligently keeping it in view.

## Features
- **Smart Positioning**: Automatically flips or shifts the floating element when it hits the edge of the clipping boundaries.
- **Middleware System**: Highly customizable pipeline (includes `flip`, `shift`, `offset`, `size`, `arrow`, `hide`, `inline`, and `autoPlacement`).
- **Auto Update**: Includes built-in `PopperController` and `PopperAnchoredOverlay` to automatically update positions on scroll, resize, or DOM mutations.
- **Advanced Boundary Detection**: Automatically finds visual viewports and scroll ancestors to prevent the floating element from being clipped.

## Handling Layouts

The exact layout computation is provided by `computePopperLayout`, and low-level absolute coordinates can be extracted using `computePosition`.

## Usage

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
