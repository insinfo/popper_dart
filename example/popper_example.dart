import 'dart:html' as html;
import 'package:popper/popper.dart';

void main() {
  // Styles for the example viewport
  html.document.body!.style
    ..margin = '0'
    ..fontFamily = 'sans-serif'
    ..height = '200vh' // Force scrolling to demonstrate auto update behavior
    ..display = 'flex'
    ..justifyContent = 'center'
    ..alignItems = 'center';

  // Create Reference Element (Button)
  final button = html.ButtonElement()
    ..text = 'Click or Hover Me'
    ..style.padding = '16px 24px'
    ..style.fontSize = '16px'
    ..style.cursor = 'pointer'
    ..style.backgroundColor = '#6200ee'
    ..style.color = 'white'
    ..style.border = 'none'
    ..style.borderRadius = '8px'
    ..style.boxShadow = '0 2px 5px rgba(0,0,0,0.2)';

  html.document.body!.append(button);

  // Create Floating Element (Tooltip)
  final tooltip = html.DivElement()
    ..text = 'I am a Popper tooltip!'
    ..style.backgroundColor = '#222'
    ..style.color = '#fff'
    ..style.padding = '8px 12px'
    ..style.borderRadius = '4px'
    ..style.fontSize = '14px'
    ..style.fontWeight = 'bold'
    ..style.boxShadow = '0 4px 10px rgba(0,0,0,0.15)'
    ..style.zIndex = '9999';

  html.document.body!.append(tooltip);

  // Initialize Popper controller
  final popper = PopperController(
    referenceElement: button,
    floatingElement: tooltip,
    options: const PopperOptions(
      placement: 'top', // Start at the top
      strategy: PopperStrategy.fixed,
      offset: PopperOffset(mainAxis: 10), // Adding some space
      flip: true, // Will flip to bottom if scrolled past top
      shift: true, // Will shift left/right if hitting side bounds
    ),
  );

  // Bind the controller to continuously auto update on scroll & resize
  popper.startAutoUpdate();
  
  // Example interaction: Swap base placement on click
  button.onClick.listen((_) {
    final currentOpts = popper.options;
    popper.options = PopperOptions(
      placement: currentOpts.placement.startsWith('top') ? 'bottom' : 'top',
      strategy: currentOpts.strategy,
      offset: currentOpts.offset,
      flip: currentOpts.flip,
      shift: currentOpts.shift,
    );
    
    // Instantly update the layout frame based on the new options
    popper.update();
  });
}
