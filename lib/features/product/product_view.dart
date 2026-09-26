import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/mock_data.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/cart_cubit.dart';
import '../../ui/ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/product_details.dart';
import '../../state/favorites_cubit.dart';
import '../method/method_sheet.dart';

Future<void> openProductSheet(BuildContext context, Product p) {
  final sel = ProductSelection(p);
  return showMartSheet(context, bodyPadding: EdgeInsets.zero, closeOverlay: true,
      builder: (_) => ProductView(product: p, selection: sel), footer: ProductCta(product: p, selection: sel)).whenComplete(sel.dispose);
}

/// Выбор размера и цвета у цветов — общий для шторки и закреплённой кнопки. Первый размер и первый цвет по умолчанию.
class ProductSelection extends ChangeNotifier {
  ProductSelection(this.product);
  final Product product;
  int variant = 0, color = 0;
  ProductVariant? get v => product.hasVariants ? product.variants![variant] : null;
  String? get colorName => (product.colors?.isNotEmpty ?? false) ? product.colors![color] : null;
  String get cartKey => v == null ? product.id : MockData.cartKey(v!, colorName);
  int? get price => v?.price ?? product.price;
  void setVariant(int i) { variant = i; notifyListeners(); }
  void setColor(int i) { color = i; notifyListeners(); }
}

TextStyle _f(double size, FontWeight w, Color col, {double? h, double? ls}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h, letterSpacing: ls);

/// Карточка товара mobile (MartProductView.dc.html, isM): галерея во всю ширину 1:1 с точками → категория · метка →
/// название 20/800 + сердце 44 → цена 24/800, старая, −N%, «за 50 кг» → бонусы → «Поделиться» →
/// «Доставка / Самовывоз» (ваш способ первым) → описание (свёрнуто до 120) → характеристики (первые 6).
class ProductView extends StatefulWidget {
  const ProductView({super.key, required this.product, this.selection});
  final Product product;
  final ProductSelection? selection;
  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  late final ProductSelection _sel = widget.selection ?? ProductSelection(widget.product);
  final _pager = PageController();
  int _page = 0;
  @override
  void initState() { super.initState(); _sel.addListener(_onSel); }
  @override
  void dispose() { _sel.removeListener(_onSel); if (widget.selection == null) _sel.dispose(); _pager.dispose(); super.dispose(); }
  void _onSel() {
    final i = ProductDetailsMock.of(widget.product).images.indexOf(_sel.v?.image ?? '');
    if (i >= 0 && _pager.hasClients) _pager.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    setState(() {});
  }
  bool _descOpen = false, _specsOpen = false;
  static const _specN = 6;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final p = widget.product;
    final det = ProductDetailsMock.of(p);
    final ph = ProductDetailsMock.placeholders(p);
    final fav = context.watch<FavoritesCubit>().state.contains(p.id);
    final method = context.watch<CartCubit>().state.method;
    final cat = [MockData.category(p.categoryId)?.name, if (p.subId.isNotEmpty) MockData.subName(p.subId)].whereType<String>().where((x) => x.isNotEmpty).join(' · ');
    final disc = p.oldPrice != null && p.price != null ? ((1 - p.price! / p.oldPrice!) * 100).round() : 0;
    final descLong = det.desc.join(' ').length > 240;
    final specs = _specsOpen ? det.specs : det.specs.take(_specN).toList();
    final ways = [
      (id: ReceiveMethod.delivery, title: t.delivery, info: det.conditions.delivery),
      (id: ReceiveMethod.pickup, title: t.pickup, info: det.conditions.pickup),
    ]..sort((a, b) => (b.id == method ? 1 : 0) - (a.id == method ? 1 : 0));

    Widget pink(String text, VoidCallback onTap, bool open) => GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: onTap,
          child: SizedBox(height: 44, child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(text, style: _f(15, FontWeight.w600, c.primary)),
            const SizedBox(width: 8),
            MartChevron(dir: open ? ChevronDir.up : ChevronDir.down, color: c.primary, size: 5),
          ])),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AspectRatio(aspectRatio: 1, child: Stack(children: [
        PageView.builder(controller: _pager, itemCount: det.images.length, onPageChanged: (i) => setState(() => _page = i), itemBuilder: (_, i) => det.images[i].isEmpty
            ? Stack(children: [const MartStripes(step: 12, radius: 0), Center(child: Text(ph[i], style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFF9E9BA6))))])
            : ColoredBox(color: c.surface2, child: MartImage(det.images[i], radius: 0, fit: BoxFit.cover))),
        if (det.images.length > 1) Positioned(bottom: 12, left: 0, right: 0, child: IgnorePointer(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < det.images.length; i++) AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _page ? 18 : 6, height: 6, decoration: BoxDecoration(color: i == _page ? c.primary : const Color(0x4017151A), borderRadius: BorderRadius.circular(3))),
        ]))),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (cat.isNotEmpty) Text(cat, style: _f(13, FontWeight.w400, c.ink3)),
          if (det.conditions.tag != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(999)),
            child: Text(det.conditions.tag!, style: _f(12, FontWeight.w600, const Color(0xFF8A5A00)))),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(p.name, style: _f(20, FontWeight.w800, c.ink1, h: 1.2, ls: -0.4))),
          const SizedBox(width: 12),
          Semantics(button: true, label: fav ? 'Убрать из избранного' : 'В избранное', child: GestureDetector(
            onTap: () => context.read<FavoritesCubit>().toggle(p.id),
            child: Container(width: 44, height: 44, decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
              child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 22, color: fav ? MartColors.favorite : MartColors.favoriteOutline)),
          )),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(_sel.price == null ? 'Цена уточняется' : money(_sel.price!), style: _f(_sel.price == null ? 20 : 24, FontWeight.w800, c.ink1, ls: -0.24)),
          if (disc > 0) ...[
            Text(money(p.oldPrice!), style: _f(16, FontWeight.w400, c.ink3).copyWith(decoration: TextDecoration.lineThrough, decorationColor: c.ink3)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(999)),
              child: Text('−$disc%', style: _f(12, FontWeight.w600, Colors.white))),
          ],
          if (!p.hasVariants && p.pack.isNotEmpty && p.pack != '1 шт') Text(t.perUnit(p.pack), style: _f(14, FontWeight.w400, c.ink2)),
        ]),
        if (p.bonus > 0) ...[
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Container(
            padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
            decoration: BoxDecoration(color: c.successBg, borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
                child: const Text('Б', style: TextStyle(fontFamily: 'Onest', fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, height: 1))),
              const SizedBox(width: 6),
              Text(t.bonusCount(p.bonus), style: _f(13, FontWeight.w600, c.successText)),
            ]),
          )),
        ],
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: () => Share.share('https://8mart.kz/p/${p.id}'),
          child: SizedBox(height: 36, child: Row(mainAxisSize: MainAxisSize.min, children: [
            CustomPaint(size: const Size.square(14), painter: _SharePainter(c.ink2)),
            const SizedBox(width: 8),
            Text(t.share, style: _f(14, FontWeight.w600, c.ink2)),
          ])),
        )),
        if (p.hasVariants) ...[
          const SizedBox(height: 20),
          Row(children: [Text('Размер', style: _f(15, FontWeight.w700, c.ink1)), const SizedBox(width: 6), Text(MockData.flowerSizeHint[_sel.v!.size] ?? '', style: _f(15, FontWeight.w400, c.ink2))]),
          const SizedBox(height: 10),
          Row(children: [
            for (var i = 0; i < p.variants!.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: GestureDetector(onTap: () => _sel.setVariant(i), child: AnimatedContainer(
                duration: MartMotion.press, height: 56,
                decoration: BoxDecoration(color: i == _sel.variant ? c.primary50 : c.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: i == _sel.variant ? c.primary : c.border, width: 1.5)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(p.variants![i].size, style: _f(16, i == _sel.variant ? FontWeight.w700 : FontWeight.w500, c.ink1)),
                  const SizedBox(height: 2),
                  Text(money(p.variants![i].price), style: _f(12, FontWeight.w400, c.ink2)),
                ]),
              ))),
            ],
          ]),
        ],
        if (p.colors?.isNotEmpty ?? false) ...[
          const SizedBox(height: 20),
          Row(children: [Text('Цвет', style: _f(15, FontWeight.w700, c.ink1)), const SizedBox(width: 6), Text(_sel.colorName ?? '', style: _f(15, FontWeight.w400, c.ink2))]),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (var i = 0; i < p.colors!.length; i++) Semantics(button: true, selected: i == _sel.color, label: p.colors![i], child: GestureDetector(
              onTap: () => _sel.setColor(i),
              child: Container(width: 40, height: 40, alignment: Alignment.center,
                decoration: i == _sel.color ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.primary, width: 2)) : null,
                child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: i == _sel.color ? Colors.white : c.border, width: i == _sel.color ? 2 : 1)),
                  child: ClipOval(child: _Swatch(p.colors![i])))),
            )),
          ]),
        ],
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(border: Border.all(color: c.divider), borderRadius: BorderRadius.circular(MartRadius.field)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < ways.length; i++) Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.divider))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(ways[i].title, style: _f(15, FontWeight.w600, c.ink1))),
                  if (ways[i].id == method) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(999)),
                    child: Text(t.yourWay, style: _f(12, FontWeight.w600, c.primary))),
                ]),
                const SizedBox(height: 4),
                Text(ways[i].info.when, style: _f(14, FontWeight.w400, c.ink1, h: 1.4)),
                const SizedBox(height: 4),
                Text(ways[i].info.sub, style: _f(13, FontWeight.w400, c.ink2, h: 1.4)),
                if (ways[i].info.note != null) ...[const SizedBox(height: 4), Text(ways[i].info.note!, style: _f(13, FontWeight.w400, c.ink2, h: 1.4))],
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Text(t.descTitle, style: _f(17, FontWeight.w700, c.ink1)),
        const SizedBox(height: 10),
        ClipRect(child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: descLong && !_descOpen ? 120 : double.infinity),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: const [Colors.black, Colors.black, Colors.transparent], stops: descLong && !_descOpen ? [0, (r.height - 48) / r.height, 1] : [0, 1, 1]).createShader(r),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < det.desc.length; i++) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                child: Text(det.desc[i], style: _f(15, FontWeight.w400, const Color(0xFF3A3740), h: 1.55))),
            ]),
          ),
        )),
        if (descLong) Align(alignment: Alignment.centerLeft, child: pink(_descOpen ? t.collapse : t.readMore, () => setState(() => _descOpen = !_descOpen), _descOpen)),
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(t.specsTitle, style: _f(17, FontWeight.w700, c.ink1))),
        for (final (k, v) in specs) Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.divider))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 10, child: Text(k, style: _f(14, FontWeight.w400, c.ink2, h: 1.4))),
            const SizedBox(width: 12),
            Expanded(flex: 12, child: Text(v, style: _f(14, FontWeight.w400, c.ink1, h: 1.4))),
          ]),
        ),
        if (det.specs.length > _specN) Align(alignment: Alignment.centerLeft,
            child: pink(_specsOpen ? t.collapse : t.allSpecs(det.specs.length), () => setState(() => _specsOpen = !_specsOpen), _specsOpen)),
      ])),
    ]);
  }
}

/// Свотч цвета; «Микс» — четыре сектора (розовый, белый, голубой, жёлтый).
class _Swatch extends StatelessWidget {
  const _Swatch(this.name);
  final String name;
  @override
  Widget build(BuildContext context) {
    if (name == 'Микс') return CustomPaint(painter: _MixPainter(), child: const SizedBox.expand());
    return ColoredBox(color: Color(MockData.colorSwatch[name] ?? 0xFFEEEDF1), child: const SizedBox.expand());
  }
}

class _MixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    const cols = [Color(0xFFF4A6C0), Color(0xFFFFFFFF), Color(0xFF9EC5F0), Color(0xFFF7D774)];
    final r = Offset.zero & s;
    for (var i = 0; i < 4; i++) { canvas.drawArc(r, -1.5708 + i * 1.5708, 1.5708, true, Paint()..color = cols[i]); }
  }
  @override
  bool shouldRepaint(_MixPainter o) => false;
}

/// «Поделиться» геометрией: стрелка вверх + лоток.
class _SharePainter extends CustomPainter {
  _SharePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawLine(Offset(s.width / 2, 1), Offset(s.width / 2, s.height * .65), p);
    canvas.drawPath(Path()..moveTo(s.width * .25, s.height * .28)..lineTo(s.width / 2, 1)..lineTo(s.width * .75, s.height * .28), p);
    canvas.drawPath(Path()..moveTo(1, s.height * .6)..lineTo(1, s.height - 1)..lineTo(s.width - 1, s.height - 1)..lineTo(s.width - 1, s.height * .6), p);
  }
  @override
  bool shouldRepaint(_SharePainter o) => o.color != color;
}

/// CTA снизу: «В корзину · цена» 56 → в корзине: розовый степпер 140×44 + «В корзине · сумма» (secondary 44).
class ProductCta extends StatelessWidget {
  const ProductCta({super.key, required this.product, this.selection});
  final Product product;
  final ProductSelection? selection;
  @override
  Widget build(BuildContext context) {
    final sel = selection;
    if (sel == null) return _cta(context, product.id, product.price);
    return ListenableBuilder(listenable: sel, builder: (context, _) => _cta(context, sel.cartKey, sel.price));
  }

  Widget _cta(BuildContext context, String key, int? price) {
    final t = L10n.of(context);
    final qty = context.select<CartCubit, int>((c) => c.state.qtyOf(key));
    final cart = context.read<CartCubit>();
    void set(int q) { if (!cart.setQty(key, q)) openMethodSheet(context); }
    if (price == null) return MartButton(label: 'Цена уточняется', expanded: true, disabledReason: 'Цена пока не указана');
    if (qty == 0) return MartButton(label: t.toCart, amount: money(price), expanded: true, onPressed: () => set(1));
    return Row(children: [
      MartStepper(qty: qty, onChanged: set, width: 140, size: 44, tone: MartStepperTone.primary),
      const SizedBox(width: 8),
      Expanded(child: MartButton(label: t.inCartBtn, amount: money(price * qty), variant: MartButtonVariant.secondary, size: MartButtonSize.m44, expanded: true,
          onPressed: () { Navigator.of(context).maybePop(); context.go('/cart'); })),
    ]);
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, required this.id});
  final String id;
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late final Product? _p = MockData.byId(widget.id);
  late final ProductSelection? _sel = _p == null ? null : ProductSelection(_p);
  @override
  void dispose() { _sel?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final p = _p;
    if (p == null) return const Scaffold(body: Center(child: Text('Товар не найден')));
    return Scaffold(
      backgroundColor: context.mc.surface,
      body: Stack(children: [
        ListView(padding: EdgeInsets.zero, children: [ProductView(product: p, selection: _sel)]),
        Positioned(left: 12, top: MediaQuery.paddingOf(context).top + 8, child: const MartBackButton()),
      ]),
      bottomNavigationBar: MartBottomBar(child: ProductCta(product: p, selection: _sel)),
    );
  }
}
