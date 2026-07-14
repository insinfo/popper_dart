## 1.3.0

- Fixed the 1.2.0 dispose restore reaching elements popper never wrote to. `PopperController.dispose()` restored the floating element unconditionally, but with a custom `PopperOptions.layoutWriter` the consumer owns those styles — popper only computes the layout and never applies it. Disposing therefore wiped the consumer's own inline styles and `data-popper-placement`, which broke consumers that dispose and recreate a controller on every reposition: the floating element was left unpositioned. `dispose()` now restores only when this controller actually applied a layout itself, so popper undoes just what popper did.
- Added a `restoreFloatingState` named argument (default `true`) to `PopperController.dispose(...)`, `PopperPortal.dispose(...)` and `PopperAnchoredOverlay.dispose(...)`. Pass `false` to leave the last written layout on the floating element instead of handing it back — useful when the element is about to be removed anyway, or when it should stay frozen where popper put it. It can only turn the restore off: an element popper never wrote to is still left untouched.

## 1.2.0

- Fixed `PopperPortal.dispose()` and `PopperController.dispose()` leaving behind the inline styles and `data-popper-*` attributes they had written on the floating element. Popper positions by writing inline styles (`position: fixed`, `transform: translate(...)`, `left`/`top`/`margin`, `z-index`, ...), which outrank any stylesheet, so an element handed back still carrying them kept rendering at the last computed viewport coordinates instead of falling back to its own CSS. This was most visible with `restoreOnDispose: true`, where the element is reused after the portal is torn down: a menu restored to its inline parent stayed frozen at the position computed before teardown.
- Changed both `dispose()` methods to hand the floating element back in its pre-attach state. The state Popper takes ownership of is captured on attach and restored on dispose, rather than blanket-cleared, so inline styles and a `data-popper-placement` the consumer had set before attaching survive the attach/dispose cycle untouched.

## 1.1.0

- Added `arrowWriteMode` with `full`, `crossAxisOnly`, and `none` to control how arrow inline styles are written.
- Added `PopperController.applyPopperLayout(...)` to separate layout computation from DOM application.
- Added `anchorRectBuilder` to stabilize or override reference measurement.
- Added `layoutWriter` and `arrowLayoutWriter` so consumers can replace the default layout writing policy.
- Added `PopperOptions.copyWith(...)` for easier option composition.

## 1.0.0

- Initial version.
