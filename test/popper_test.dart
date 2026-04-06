@TestOn('browser')
library;

// para executar use dart test -p chrome test/popper_test.dart
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:popper/popper.dart';
import 'package:test/test.dart';

void main() {
  final mounted = <html.Element>[];

  setUp(() {
    html.document.body!.style.margin = '0';
    html.document.body!.style.padding = '0';
  });

  tearDown(() {
    for (final element in mounted.reversed) {
      element.remove();
    }
    mounted.clear();
    js_util.setProperty(html.window, '__popperTestVisualViewport', null);
  });

  html.DivElement mountBox({
    required double left,
    required double top,
    required double width,
    required double height,
    String position = 'fixed',
    String? extraStyle,
  }) {
    final element = html.DivElement()
      ..style.position = position
      ..style.left = '${left}px'
      ..style.top = '${top}px'
      ..style.width = '${width}px'
      ..style.height = '${height}px';

    if (extraStyle != null && extraStyle.isNotEmpty) {
      element.setAttribute(
          'style', '${element.getAttribute('style')};$extraStyle');
    }

    html.document.body!.append(element);
    mounted.add(element);
    return element;
  }

  html.DivElement mountChild(
    html.Element parent, {
    required double left,
    required double top,
    required double width,
    required double height,
    String position = 'absolute',
    String? extraStyle,
  }) {
    final element = html.DivElement()
      ..style.position = position
      ..style.left = '${left}px'
      ..style.top = '${top}px'
      ..style.width = '${width}px'
      ..style.height = '${height}px';

    if (extraStyle != null && extraStyle.isNotEmpty) {
      element.setAttribute(
          'style', '${element.getAttribute('style')};$extraStyle');
    }

    parent.append(element);
    mounted.add(element);
    return element;
  }

  Future<void> nextFrame() async {
    final completer = Completer<void>();
    html.window.requestAnimationFrame((_) => completer.complete());
    await completer.future;
  }

  void expectClose(num actual, num expected, [double delta = 1.5]) {
    expect((actual - expected).abs(), lessThanOrEqualTo(delta));
  }

  test('alinha start corretamente em RTL', () async {
    final container = mountBox(
      left: 0,
      top: 0,
      width: 400,
      height: 300,
      extraStyle: 'direction: rtl;',
    );
    final reference = mountChild(
      container,
      left: 120,
      top: 40,
      width: 100,
      height: 30,
    );
    final floating = mountChild(
      container,
      left: 0,
      top: 0,
      width: 60,
      height: 20,
    );

    final layout = await computePopperLayout(
      referenceElement: reference,
      floatingElement: floating,
      options: const PopperOptions(
        placement: 'bottom-start',
        strategy: PopperStrategy.fixed,
      ),
    );

    final expectedLeft = layout.referenceRect.left +
        layout.referenceRect.width -
        layout.floatingRect.width;
    expectClose(layout.viewportX, expectedLeft.toDouble());
  });

  test('retorna middlewareData customizado e coordenadas alteradas', () async {
    final reference = mountBox(
      left: 0,
      top: 0,
      width: 100,
      height: 100,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 50,
      height: 50,
    );

    final result = await computePosition(
      referenceElement: reference,
      floatingElement: floating,
      placement: 'top',
      strategy: PopperStrategy.fixed,
      middleware: <PopperMiddleware>[
        PopperMiddleware(
          name: 'custom',
          fn: (state) => PopperMiddlewareResult(
            x: state.x + 1,
            y: state.y + 2,
            data: <String, dynamic>{
              'property': true,
            },
          ),
        ),
      ],
    );

    expect(result.placement, equals('top'));
    expectClose(result.x, 26);
    expectClose(result.y, -48);
    expect(result.middlewareData['custom'], containsPair('property', true));
  });

  test('computePosition aplica middleware simples sobre x/y', () async {
    final reference = mountBox(
      left: 0,
      top: 0,
      width: 100,
      height: 100,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 50,
      height: 50,
    );

    final base = await computePosition(
      referenceElement: reference,
      floatingElement: floating,
    );
    final shifted = await computePosition(
      referenceElement: reference,
      floatingElement: floating,
      middleware: <PopperMiddleware>[
        PopperMiddleware(
          name: 'shiftOne',
          fn: (state) => PopperMiddlewareResult(
            x: state.x + 1,
            y: state.y + 1,
          ),
        ),
      ],
    );

    expectClose(shifted.x, base.x + 1);
    expectClose(shifted.y, base.y + 1);
  });

  test('middleware consegue resetar placement', () async {
    final reference = mountBox(
      left: 0,
      top: 0,
      width: 100,
      height: 100,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 50,
      height: 50,
    );

    final result = await computePosition(
      referenceElement: reference,
      floatingElement: floating,
      placement: 'bottom',
      strategy: PopperStrategy.fixed,
      middleware: <PopperMiddleware>[
        PopperMiddleware(
          name: 'forceTop',
          fn: (_) => const PopperMiddlewareResult(
            reset: PopperMiddlewareReset(
              placement: 'top',
            ),
          ),
        ),
      ],
    );

    expect(result.placement, equals('top'));
    expectClose(result.y, -50);
  });

  test('corrige coordenadas em offset parent com transform scale', () async {
    final container = mountBox(
      left: 40,
      top: 60,
      width: 300,
      height: 300,
      position: 'absolute',
      extraStyle: 'transform: scale(1.5); transform-origin: top left;',
    );
    final reference = mountChild(
      container,
      left: 50,
      top: 40,
      width: 90,
      height: 30,
    );
    final floating = mountChild(
      container,
      left: 0,
      top: 0,
      width: 120,
      height: 50,
    );

    final controller = PopperController(
      referenceElement: reference,
      floatingElement: floating,
      options: const PopperOptions(
        placement: 'bottom-start',
        strategy: PopperStrategy.absolute,
      ),
    );

    await controller.update();
    await nextFrame();

    final referenceRect = reference.getBoundingClientRect();
    final floatingRect = floating.getBoundingClientRect();

    expectClose(floatingRect.left, referenceRect.left);
    expectClose(floatingRect.top, referenceRect.bottom);
  });

  test('faz flip dentro de scroll containers aninhados', () async {
    final scroller = mountBox(
      left: 0,
      top: 0,
      width: 240,
      height: 180,
      extraStyle: 'overflow: auto; border: 0;',
    );
    final inner = mountChild(
      scroller,
      left: 0,
      top: 0,
      width: 220,
      height: 600,
      extraStyle: 'position: relative;',
    );
    final reference = mountChild(
      inner,
      left: 20,
      top: 520,
      width: 80,
      height: 30,
    );
    final floating = mountChild(
      inner,
      left: 0,
      top: 0,
      width: 120,
      height: 100,
    );

    scroller.scrollTop = 380;
    await nextFrame();

    final layout = await computePopperLayout(
      referenceElement: reference,
      floatingElement: floating,
      options: const PopperOptions(
        placement: 'bottom-start',
        strategy: PopperStrategy.fixed,
        boundary: PopperBoundary.clippingAncestors,
      ),
    );

    expect(layout.placement, equals('top-start'));
    expect(
      layout.viewportY + layout.floatingRect.height.toDouble(),
      lessThanOrEqualTo(
        layout.clippingRect.top.toDouble() +
            layout.clippingRect.height.toDouble() +
            1,
      ),
    );
  });

  test('inline middleware usa uniao de client rects em referencia multilinha',
      () async {
    final container = mountBox(
      left: 0,
      top: 0,
      width: 120,
      height: 200,
      extraStyle: 'font-size: 16px; line-height: 16px;',
    );

    final paragraph = html.DivElement()
      ..style.width = '120px'
      ..style.whiteSpace = 'normal'
      ..text = 'texto longo para quebrar em mais de uma linha no inline';
    container.append(paragraph);
    mounted.add(paragraph);

    final reference = html.SpanElement()
      ..text = 'referencia inline muito longa para quebrar linha'
      ..style.backgroundColor = 'rgb(255, 255, 0)';
    paragraph.append(reference);
    mounted.add(reference);

    final floating = mountBox(
      left: 0,
      top: 0,
      width: 90,
      height: 30,
    );

    await nextFrame();
    expect(reference.getClientRects().length, greaterThan(1));

    final layout = await computePopperLayout(
      referenceElement: reference,
      floatingElement: floating,
      options: const PopperOptions(
        placement: 'bottom-start',
        strategy: PopperStrategy.fixed,
        inline: true,
      ),
    );

    final firstRect = reference.getClientRects().first;
    expect(layout.referenceRect.height, greaterThan(firstRect.height));
  });

  test('respeita visual viewport override ao calcular clipping e shift',
      () async {
    js_util.setProperty(
      html.window,
      '__popperTestVisualViewport',
      js_util.jsify(<String, double>{
        'width': 200,
        'height': 150,
        'offsetLeft': 10,
        'offsetTop': 20,
      }),
    );

    final reference = mountBox(
      left: 170,
      top: 120,
      width: 40,
      height: 20,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 80,
      height: 40,
    );

    final layout = await computePopperLayout(
      referenceElement: reference,
      floatingElement: floating,
      options: const PopperOptions(
        placement: 'bottom-start',
        strategy: PopperStrategy.fixed,
        boundary: PopperBoundary.viewport,
        shift: true,
      ),
    );

    expectClose(layout.clippingRect.left, 10);
    expectClose(layout.clippingRect.top, 20);
    expectClose(layout.clippingRect.width, 200);
    expectClose(layout.clippingRect.height, 150);
    expect(
      layout.viewportX + layout.floatingRect.width.toDouble(),
      lessThanOrEqualTo(210),
    );
    expect(
      layout.viewportY + layout.floatingRect.height.toDouble(),
      lessThanOrEqualTo(170),
    );
  });

  test('auto placement escolhe uma colocacao permitida com menor overflow',
      () async {
    final reference = mountBox(
      left: 90,
      top: 130,
      width: 30,
      height: 20,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 80,
      height: 50,
    );

    js_util.setProperty(
      html.window,
      '__popperTestVisualViewport',
      js_util.jsify(<String, double>{
        'width': 220,
        'height': 180,
        'offsetLeft': 0,
        'offsetTop': 0,
      }),
    );

    final layout = await computePopperLayout(
      referenceElement: reference,
      floatingElement: floating,
      options: const PopperOptions(
        placement: 'auto',
        strategy: PopperStrategy.fixed,
        boundary: PopperBoundary.viewport,
        allowedAutoPlacements: <String>['top', 'bottom'],
      ),
    );

    expect(layout.placement, equals('top'));
  });

  test('arrow middleware produz dados e controller posiciona o elemento seta',
      () async {
    final reference = mountBox(
      left: 120,
      top: 80,
      width: 100,
      height: 30,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 120,
      height: 60,
    );
    final arrow = mountChild(
      floating,
      left: 0,
      top: 0,
      width: 12,
      height: 12,
    );

    final layout = await computePopperLayout(
      referenceElement: reference,
      floatingElement: floating,
      options: PopperOptions(
        placement: 'bottom',
        strategy: PopperStrategy.fixed,
        arrowElement: arrow,
      ),
    );

    expect(layout.middlewareData['arrow'], contains('x'));

    final controller = PopperController(
      referenceElement: reference,
      floatingElement: floating,
      options: PopperOptions(
        placement: 'bottom',
        strategy: PopperStrategy.fixed,
        arrowElement: arrow,
      ),
    );

    await controller.update();

    expect(arrow.style.left, isNotEmpty);
    expect(arrow.style.top, isNotEmpty);
  });

  test('arrowWriteMode crossAxisOnly nao escreve o eixo principal da seta',
      () async {
    final reference = mountBox(
      left: 120,
      top: 80,
      width: 100,
      height: 30,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 120,
      height: 60,
    );
    final arrow = mountChild(
      floating,
      left: 0,
      top: 0,
      width: 12,
      height: 12,
    );

    final controller = PopperController(
      referenceElement: reference,
      floatingElement: floating,
      options: PopperOptions(
        placement: 'bottom',
        strategy: PopperStrategy.fixed,
        arrowElement: arrow,
        arrowWriteMode: PopperArrowWriteMode.crossAxisOnly,
      ),
    );

    await controller.update();

    expect(arrow.style.left, isNotEmpty);
    expect(arrow.style.top, isEmpty);
    expect(arrow.style.bottom, isEmpty);
  });

  test('arrowWriteMode none nao escreve estilos inline na seta', () async {
    final reference = mountBox(
      left: 120,
      top: 80,
      width: 100,
      height: 30,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 120,
      height: 60,
    );
    final arrow = mountChild(
      floating,
      left: 0,
      top: 0,
      width: 12,
      height: 12,
    );

    final controller = PopperController(
      referenceElement: reference,
      floatingElement: floating,
      options: PopperOptions(
        placement: 'bottom',
        strategy: PopperStrategy.fixed,
        arrowElement: arrow,
        arrowWriteMode: PopperArrowWriteMode.none,
      ),
    );

    await controller.update();

    expect(arrow.style.position, isEmpty);
    expect(arrow.style.left, isEmpty);
    expect(arrow.style.top, isEmpty);
    expect(arrow.style.right, isEmpty);
    expect(arrow.style.bottom, isEmpty);
  });

  test('applyPopperLayout permite separar compute de apply', () async {
    final reference = mountBox(
      left: 120,
      top: 80,
      width: 100,
      height: 30,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 120,
      height: 60,
    );

    final controller = PopperController(
      referenceElement: reference,
      floatingElement: floating,
      options: const PopperOptions(
        placement: 'bottom',
        strategy: PopperStrategy.fixed,
      ),
    );
    final layout = await computePopperLayout(
      referenceElement: reference,
      floatingElement: floating,
      options: controller.options,
    );

    controller.applyPopperLayout(layout);

    expect(floating.style.position, 'fixed');
    expect(floating.style.transform, contains('translate('));
  });

  test('anchorRectBuilder permite estabilizar o retangulo de referencia',
      () async {
    final reference = mountBox(
      left: 150,
      top: 100,
      width: 50,
      height: 20,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 80,
      height: 40,
    );

    final layout = await computePopperLayout(
      referenceElement: reference,
      floatingElement: floating,
      options: PopperOptions(
        placement: 'bottom',
        strategy: PopperStrategy.fixed,
        anchorRectBuilder: (_, __) => html.Rectangle<num>(20, 30, 100, 10),
      ),
    );

    expectClose(layout.referenceRect.left, 20);
    expectClose(layout.referenceRect.top, 30);
    expectClose(layout.referenceRect.width, 100);
    expectClose(layout.referenceRect.height, 10);
    expectClose(layout.viewportX, 30);
    expectClose(layout.viewportY, 40);
  });

  test('layoutWriter substitui a escrita padrao do controller', () async {
    final reference = mountBox(
      left: 120,
      top: 80,
      width: 100,
      height: 30,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 120,
      height: 60,
    );
    final arrow = mountChild(
      floating,
      left: 0,
      top: 0,
      width: 12,
      height: 12,
    );

    var writerCalled = false;
    final controller = PopperController(
      referenceElement: reference,
      floatingElement: floating,
      options: PopperOptions(
        placement: 'bottom',
        strategy: PopperStrategy.fixed,
        arrowElement: arrow,
        layoutWriter: (layout, floatingElement, arrowElement) {
          writerCalled = true;
          floatingElement.style.transform =
              'translateX(${layout.x.toStringAsFixed(0)}px)';
          arrowElement?.setAttribute('data-writer', layout.placement);
        },
      ),
    );

    await controller.update();

    expect(writerCalled, isTrue);
    expect(floating.style.transform, startsWith('translateX('));
    expect(floating.getAttribute('data-popper-placement'), isNull);
    expect(arrow.getAttribute('data-writer'), 'bottom');
  });

  test('arrowLayoutWriter substitui apenas a escrita da seta', () async {
    final reference = mountBox(
      left: 120,
      top: 80,
      width: 100,
      height: 30,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 120,
      height: 60,
    );
    final arrow = mountChild(
      floating,
      left: 0,
      top: 0,
      width: 12,
      height: 12,
    );

    var writerCalled = false;
    final controller = PopperController(
      referenceElement: reference,
      floatingElement: floating,
      options: PopperOptions(
        placement: 'bottom',
        strategy: PopperStrategy.fixed,
        arrowElement: arrow,
        arrowLayoutWriter: (layout, arrowElement) {
          writerCalled = true;
          arrowElement.style
            ..position = 'absolute'
            ..left = '7px'
            ..top = ''
            ..right = ''
            ..bottom = '';
          arrowElement.setAttribute('data-arrow-writer', layout.placement);
        },
      ),
    );

    await controller.update();

    expect(writerCalled, isTrue);
    expect(floating.style.transform, contains('translate('));
    expect(floating.getAttribute('data-popper-placement'), 'bottom');
    expect(arrow.style.left, '7px');
    expect(arrow.getAttribute('data-arrow-writer'), 'bottom');
  });

  test('copyWith permite ajustar opcoes sem reconstruir manualmente', () {
    final base = const PopperOptions(
      placement: 'bottom',
      strategy: PopperStrategy.fixed,
      shift: true,
    );

    final next = base.copyWith(
      placement: 'top',
      arrowWriteMode: PopperArrowWriteMode.crossAxisOnly,
      shift: false,
    );

    expect(next.placement, 'top');
    expect(next.strategy, PopperStrategy.fixed);
    expect(next.shift, isFalse);
    expect(next.arrowWriteMode, PopperArrowWriteMode.crossAxisOnly);
    expect(base.placement, 'bottom');
    expect(base.shift, isTrue);
  });

  test('controller aplica largura, minWidth e oculta quando destacado',
      () async {
    final reference = mountBox(
      left: -240,
      top: -180,
      width: 90,
      height: 24,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 40,
      height: 20,
    );

    final controller = PopperController(
      referenceElement: reference,
      floatingElement: floating,
      options: const PopperOptions(
        placement: 'bottom-start',
        strategy: PopperStrategy.fixed,
        boundary: PopperBoundary.viewport,
        matchReferenceWidth: true,
        matchReferenceMinWidth: true,
        hideWhenDetached: true,
      ),
    );

    final layout = await controller.update();

    expect(layout, isNotNull);
    expect(floating.style.width, '90px');
    expect(floating.style.minWidth, '90px');
    expect(floating.style.visibility, 'hidden');
    expect(floating.style.pointerEvents, 'none');
    expect(floating.attributes, contains('data-popper-reference-hidden'));
  });

  test('controller inicia auto update, observa mutacoes e para corretamente',
      () async {
    final reference = mountBox(
      left: 40,
      top: 40,
      width: 80,
      height: 24,
    );
    final floating = mountBox(
      left: 0,
      top: 0,
      width: 50,
      height: 20,
    );

    var layoutCalls = 0;
    final controller = PopperController(
      referenceElement: reference,
      floatingElement: floating,
      options: PopperOptions(
        placement: 'bottom',
        strategy: PopperStrategy.fixed,
        onLayout: (_) {
          layoutCalls++;
        },
      ),
    );

    controller.startAutoUpdate();
    await nextFrame();
    expect(layoutCalls, greaterThan(0));

    final callsAfterStart = layoutCalls;
    reference.append(html.SpanElement()..text = 'mutation');
    await nextFrame();
    await nextFrame();
    expect(layoutCalls, greaterThan(callsAfterStart));

    controller.stopAutoUpdate();
    final callsAfterStop = layoutCalls;
    reference.append(html.SpanElement()..text = 'ignored');
    await nextFrame();
    await nextFrame();
    expect(layoutCalls, equals(callsAfterStop));

    controller.dispose();
    final layout = await controller.update();
    expect(layout, isNull);
  });

  test('portal e anchored overlay ancoram e descartam corretamente', () async {
    final originalParent = mountBox(
      left: 0,
      top: 0,
      width: 300,
      height: 200,
      position: 'absolute',
    );
    final reference = mountChild(
      originalParent,
      left: 30,
      top: 20,
      width: 60,
      height: 20,
    );
    final floating = mountChild(
      originalParent,
      left: 0,
      top: 0,
      width: 80,
      height: 40,
    );

    final portal = PopperPortal.attach(
      floatingElement: floating,
      options: const PopperPortalOptions(
        hostClassName: 'test-portal-host',
        restoreOnDispose: true,
      ),
    );

    expect(portal.hostElement.classes.contains('test-portal-host'), isTrue);
    expect(floating.parent, same(portal.hostElement));

    portal.dispose();

    expect(floating.parent, same(originalParent));
    expect(portal.hostElement.isConnected, isFalse);

    final overlay = PopperAnchoredOverlay.attach(
      referenceElement: reference,
      floatingElement: floating,
      popperOptions: const PopperOptions(
        placement: 'bottom-start',
        strategy: PopperStrategy.fixed,
      ),
      portalOptions: const PopperPortalOptions(
        restoreOnDispose: true,
      ),
    );

    expect(floating.parent, same(overlay.portal.hostElement));

    final layout = await overlay.update();
    expect(layout, isNotNull);

    overlay.startAutoUpdate();
    await nextFrame();
    overlay.stopAutoUpdate();
    overlay.dispose();

    expect(floating.parent, same(originalParent));
    expect(overlay.portal.hostElement.isConnected, isFalse);
  });

  test(
      'anchored overlay alinha bottom-start corretamente ao abrir elemento inicialmente oculto',
      () async {
    final originalParent = mountBox(
      left: 0,
      top: 0,
      width: 500,
      height: 400,
      position: 'absolute',
    );
    final reference = mountChild(
      originalParent,
      left: 140,
      top: 120,
      width: 180,
      height: 38,
    );
    final floating = mountChild(
      originalParent,
      left: 0,
      top: 0,
      width: 120,
      height: 160,
      extraStyle:
          'display: none; padding: 5px 0; border: 1px solid rgba(0,0,0,.15); '
          'background: white; box-sizing: border-box;',
    );

    final search = html.DivElement()
      ..style.margin = '8px'
      ..style.height = '40px';
    floating.append(search);
    mounted.add(search);

    final overlay = PopperAnchoredOverlay.attach(
      referenceElement: reference,
      floatingElement: floating,
      popperOptions: const PopperOptions(
        placement: 'bottom-start',
        strategy: PopperStrategy.fixed,
        matchReferenceWidth: true,
      ),
      portalOptions: const PopperPortalOptions(
        restoreOnDispose: true,
      ),
    );

    overlay.startAutoUpdate();
    floating.style.display = 'block';
    await nextFrame();
    await overlay.update();
    await nextFrame();

    final referenceRect = reference.getBoundingClientRect();
    final floatingRect = floating.getBoundingClientRect();

    expectClose(floatingRect.left, referenceRect.left);
    expectClose(floatingRect.top, referenceRect.bottom);
    expectClose(floatingRect.width, referenceRect.width);

    overlay.dispose();
  });
}
