import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../core/env.dart';
import '../../core/format.dart';
import '../../data/geo_repository.dart';
import '../../data/mock_data.dart';
import '../../domain/models.dart';
import '../../domain/shipments.dart';
import '../../state/cart_cubit.dart';
import '../../ui/ui.dart';

TextStyle _f(double size, FontWeight w, Color col, {double? h, double? ls}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h, letterSpacing: ls);

/// Выбор способа получения (MartMethodModal.dc.html, mobile): шторка 92 %, сверху карта 46 % (город слева, × справа),
/// снизу панель: заголовок, свич Доставка/Самовывоз, адрес с подсказками или список точек, CTA 56.
/// Карта — flutter_map + тайлы Mapbox (работает и в браузере). Адрес по пину — DaData geolocate / Mapbox reverse (GeoRepository).
Future<void> openMethodSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true, enableDrag: false, backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(heightFactor: .92, child: const _MethodSheet()),
    );

class _MethodSheet extends StatefulWidget {
  const _MethodSheet();
  @override
  State<_MethodSheet> createState() => _MethodSheetState();
}

class _MethodSheetState extends State<_MethodSheet> {
  static const _geo = GeoRepository();
  final _map = MapController();
  final _street = TextEditingController();
  final _entrance = TextEditingController(), _flat = TextEditingController();
  final _focus = FocusNode();
  late ReceiveMethod _m;
  City _city = MockData.cities.first;
  bool _citiesOpen = false;
  String? _point;
  // Подсказки
  Timer? _debounce;
  List<AddressSuggestion> _sg = const [];
  bool _sgLoading = false, _sgErr = false, _sgOpen = false, _quiet = false;
  int _sgReq = 0;
  // Пин
  bool _moving = false, _locating = false;
  String? _pinLabel;
  Timer? _reverseT;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartCubit>().state;
    _m = cart.method ?? ReceiveMethod.delivery;
    final i = cart.address.indexOf(', ');
    if (i > 0) {
      _city = MockData.cities.firstWhere((c) => c.name == cart.address.substring(0, i), orElse: () => MockData.cities.first);
      if (_m == ReceiveMethod.delivery) { _street.text = cart.address.substring(i + 2); _pinLabel = _street.text; }
    }
    if (_m == ReceiveMethod.pickup) _point = MockData.pickupPoints.where((p) => cart.address.endsWith(p.name)).firstOrNull?.id;
    _focus.addListener(() => setState(() => _sgOpen = _focus.hasFocus && _street.text.trim().length >= 3));
  }

  @override
  void dispose() { _debounce?.cancel(); _reverseT?.cancel(); _street.dispose(); _entrance.dispose(); _flat.dispose(); _focus.dispose(); super.dispose(); }

  List<PickupPoint> get _points => MockData.pickupPoints.where((p) => p.city == _city.id).toList();

  // ── подсказки: с 3 символов, debounce 300 мс, до 6 вариантов ──
  void _onStreet(String v) {
    _debounce?.cancel();
    final q = v.trim();
    if (q.length < 3) { setState(() { _sg = const []; _sgOpen = false; }); return; }
    setState(() { _sgOpen = true; _sgLoading = true; _sgErr = false; });
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final req = ++_sgReq;
      try {
        final r = await _geo.suggest(q, _city);
        if (mounted && req == _sgReq) setState(() { _sg = r; _sgLoading = false; });
      } catch (_) {
        if (mounted && req == _sgReq) setState(() { _sg = const []; _sgLoading = false; _sgErr = true; });
      }
    });
  }

  void _pick(AddressSuggestion s) {
    final text = s.needHouse ? '${s.title}, ' : s.title;
    _street.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    setState(() { _sgOpen = false; _sg = const []; _pinLabel = s.title; });
    if (s.needHouse) { _focus.requestFocus(); } else { _focus.unfocus(); }
    if (s.lat != null) { _quiet = true; _map.move(LatLng(s.lat!, s.lng!), 17); }
  }

  // ── пин: после остановки карты — адрес по координатам ──
  void _onMapEvent(MapEvent e) {
    if (_m != ReceiveMethod.delivery) return;
    if (e is MapEventMoveStart || e is MapEventFlingAnimationStart || e is MapEventDoubleTapZoomStart) {
      if (!_moving) setState(() => _moving = true);
    }
    if (e is MapEventMoveEnd || e is MapEventFlingAnimationEnd || e is MapEventDoubleTapZoomEnd || (e is MapEventMove && e.source == MapEventSource.mapController)) {
      _scheduleReverse();
    }
  }

  void _scheduleReverse() {
      _reverseT?.cancel();
      _reverseT = Timer(const Duration(milliseconds: 250), () async {
        if (!mounted) return;
        setState(() => _moving = false);
        if (_quiet) { _quiet = false; return; }
        final c = _map.camera.center;
        setState(() => _locating = true);
        final a = await _geo.reverse(c.latitude, c.longitude).catchError((_) => '');
        if (!mounted) return;
        setState(() { _locating = false; _pinLabel = a.isEmpty ? null : a; if (a.isNotEmpty && !_focus.hasFocus) _street.text = a; });
      });
  }

  void _setCity(City c) {
    setState(() { _city = c; _citiesOpen = false; _point = null; _street.clear(); _pinLabel = null; });
    if (_m == ReceiveMethod.pickup && _points.isNotEmpty) { _fitPoints(); } else { _map.move(LatLng(c.lat, c.lng), _m == ReceiveMethod.delivery ? 15 : 12); }
  }

  void _fitPoints() {
    final ps = _points;
    if (ps.isEmpty) return;
    _map.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints([for (final p in ps) LatLng(p.lat, p.lng)]), padding: const EdgeInsets.fromLTRB(40, 80, 40, 40)));
  }

  void _setMethod(ReceiveMethod m) {
    setState(() => _m = m);
    if (m == ReceiveMethod.pickup) { _fitPoints(); } else { _map.move(_map.camera.center, 15); }
  }

  void _pickPoint(PickupPoint p, {bool fly = true}) {
    setState(() => _point = p.id);
    if (fly) _map.move(LatLng(p.lat, p.lng), 15);
  }

  void _confirm() {
    final cart = context.read<CartCubit>();
    if (_m == ReceiveMethod.delivery) {
      cart.setMethod(_m, '${_city.name}, ${_street.text.trim().replaceAll(RegExp(r',\s*$'), '')}');
    } else {
      final p = _points.firstWhere((x) => x.id == _point);
      cart.setMethod(_m, '${_city.name}, ${p.name}');
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final isD = _m == ReceiveMethod.delivery;
    final streetOk = RegExp(r'\d').hasMatch(_street.text);
    final ok = isD ? streetOk : _point != null && _points.any((p) => p.id == _point);
    final center = _m == ReceiveMethod.delivery && _street.text.isEmpty ? LatLng(_city.lat, _city.lng) : LatLng(_city.lat, _city.lng);
    const cfg = ShippingConfig();

    final map = Stack(children: [
      FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: center, initialZoom: isD ? 15 : 12,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          onMapEvent: _onMapEvent,
          onMapReady: () { if (!isD) { _fitPoints(); } else if (_street.text.isEmpty) { _scheduleReverse(); } },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token={t}',
            additionalOptions: const {'t': Env.mapboxToken}, tileSize: 512, zoomOffset: -1, maxZoom: 20, userAgentPackageName: 'kz.mart8.app',
          ),
          if (!isD) MarkerLayer(markers: [
            for (final p in _points) Marker(point: LatLng(p.lat, p.lng), width: 44, height: 44,
                child: GestureDetector(onTap: () => _pickPoint(p, fly: false), child: Center(child: _PointMarker(selected: p.id == _point)))),
          ]),
          const Align(alignment: Alignment.bottomRight, child: Padding(padding: EdgeInsets.all(4),
              child: Text('© Mapbox © OpenStreetMap', style: TextStyle(fontFamily: 'Onest', fontSize: 10, color: Color(0xFF6B6873))))),
        ],
      ),
      if (isD) IgnorePointer(child: Center(child: _Pin(lift: _moving, label: _locating ? null : (_pinLabel ?? 'Двигайте карту, чтобы указать дом'), muted: _pinLabel == null && !_locating, loading: _locating || (_moving && !_quiet)))),
      Positioned(left: 16, top: 16, child: _Float(onTap: () => setState(() => _citiesOpen = !_citiesOpen), child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(_city.name, style: _f(15, FontWeight.w600, const Color(0xFF17151A))),
        const SizedBox(width: 8),
        const MartChevron(dir: ChevronDir.down, color: Color(0xFF6B6873), size: 5),
      ]))),
      Positioned(right: 16, top: 16, child: Semantics(button: true, label: 'Закрыть', child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x2617151A), blurRadius: 12, offset: Offset(0, 4))]),
            child: const Center(child: MartCross(size: 14, color: Color(0xFF17151A)))),
      ))),
      if (_citiesOpen) Positioned(left: 16, top: 68, child: Container(
        width: 240, constraints: const BoxConstraints(maxHeight: 320), padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x2917151A), blurRadius: 24, offset: Offset(0, 8))]),
        child: ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: [
          for (final ct in MockData.cities) GestureDetector(onTap: () => _setCity(ct), child: Container(
            height: 44, padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: ct.id == _city.id ? const Color(0xFFFDF0F6) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Expanded(child: Text(ct.name, style: _f(15, ct.id == _city.id ? FontWeight.w600 : FontWeight.w400, const Color(0xFF17151A)))),
              if (ct.id == _city.id) const _Tick(),
            ]),
          )),
        ]),
      )),
    ]);

    Widget tab(String label, ReceiveMethod m) {
      final on = _m == m;
      return Expanded(child: GestureDetector(onTap: () => _setMethod(m), child: AnimatedContainer(
        duration: MartMotion.press, height: 40, alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? c.surface : Colors.transparent, borderRadius: BorderRadius.circular(999),
            boxShadow: on ? const [BoxShadow(color: Color(0x1417151A), blurRadius: 3, offset: Offset(0, 1))] : null),
        child: Text(label, style: _f(15, FontWeight.w600, on ? c.ink1 : c.ink2)),
      )));
    }

    final delivery = ListView(padding: const EdgeInsets.symmetric(horizontal: 4), children: [
      MartInput(label: 'Улица, дом', required: true, controller: _street, focusNode: _focus, onChanged: _onStreet),
      if (_sgOpen) Padding(padding: const EdgeInsets.only(top: 6), child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border),
            boxShadow: const [BoxShadow(color: Color(0x1A17151A), blurRadius: 24, offset: Offset(0, 8))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_sgLoading) SizedBox(height: 44, child: Row(children: [
            const SizedBox(width: 12),
            SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary, backgroundColor: c.border)),
            const SizedBox(width: 10),
            Text('Ищем адрес…', style: _f(14, FontWeight.w400, c.ink2)),
          ]))
          else if (_sg.isEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(
              _sgErr ? 'Подсказки недоступны — укажите дом пином на карте' : 'Не нашли «${_street.text.trim()}» — поставьте пин на карте, адрес подставится',
              style: _f(14, FontWeight.w400, c.ink2, h: 1.4)))
          else for (final s in _sg) InkWell(
            onTap: () => _pick(s), borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 56), child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                const CustomPaint(size: Size(16, 16), painter: _DropPainter(Color(0xFFA9A6B0))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(s.title, style: _f(15, FontWeight.w600, c.ink1, h: 1.3)),
                  if (s.sub.isNotEmpty) ...[const SizedBox(height: 2), Text(s.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: _f(13, FontWeight.w400, c.ink2, h: 1.3))],
                ])),
              ]),
            )),
          ),
        ]),
      )),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: MartInput(label: 'Подъезд', controller: _entrance)),
        const SizedBox(width: 8),
        Expanded(child: MartInput(label: 'Квартира, офис', controller: _flat)),
      ]),
      const SizedBox(height: 12),
      Text('Доставка ${moneyText(cfg.courierFee)}, бесплатно от ${moneyText(cfg.freeFrom)} · 60–90 мин', style: _f(13, FontWeight.w400, c.ink2, h: 1.4)),
    ]);

    final ps = [..._points]..sort((a, b) => a.name.compareTo(b.name));
    final pickup = ps.isEmpty
        ? Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(16)),
            child: Text('В городе ${_city.name} пока нет точек самовывоза — выберите доставку или другой город', style: _f(14, FontWeight.w400, c.ink1, h: 1.4)))
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Row(children: [
              Expanded(child: Text('${ps.length} ${plural(ps.length, 'точка', 'точки', 'точек')}', style: _f(13, FontWeight.w400, c.ink2))),
              Text('по алфавиту', style: _f(13, FontWeight.w400, c.ink2)),
            ])),
            const SizedBox(height: 8),
            Expanded(child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 4), itemCount: ps.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = ps[i], on = p.id == _point;
                return GestureDetector(onTap: () => _pickPoint(p), child: AnimatedContainer(
                  duration: MartMotion.press, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: on ? c.primary50 : c.surface, borderRadius: BorderRadius.circular(MartRadius.field), border: Border.all(color: on ? c.primary : c.border, width: 1.5)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: _f(15, FontWeight.w600, c.ink1)),
                      const SizedBox(height: 2),
                      Text(p.hours, style: _f(13, FontWeight.w400, c.ink2)),
                    ])),
                    const SizedBox(width: 12),
                    Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? c.primary : c.border, width: 2)),
                        child: Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? c.primary : Colors.transparent)))),
                  ]),
                ));
              },
            )),
          ]);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: ColoredBox(color: c.surface, child: LayoutBuilder(builder: (context, cons) => Column(children: [
        SizedBox(height: cons.maxHeight * .46, child: ColoredBox(color: c.surface3, child: map)),
        Expanded(child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Как получить заказ?', style: _f(22, FontWeight.w800, c.ink1, ls: -0.44)),
            const SizedBox(height: 4),
            Text('Цены и наличие зависят от филиала', style: _f(13, FontWeight.w400, c.ink2, h: 1.4)),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
                child: Row(children: [tab('Доставка', ReceiveMethod.delivery), const SizedBox(width: 4), tab('Самовывоз', ReceiveMethod.pickup)])),
            const SizedBox(height: 16),
            Expanded(child: isD ? delivery : pickup),
            const SizedBox(height: 16),
            MartButton(label: isD ? 'Доставить сюда' : 'Заберу здесь', expanded: true,
                disabledReason: ok ? null : (isD ? 'Укажите улицу и дом' : 'Выберите точку на карте или в списке'), onPressed: _confirm),
          ]),
        )),
      ]))),
    );
  }
}

/// Белая кнопка поверх карты (город): 40, тень.
class _Float extends StatelessWidget {
  const _Float({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
        height: 40, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x2617151A), blurRadius: 12, offset: Offset(0, 4))]),
        child: child,
      ));
}

/// Пин доставки (map.html #pin): голова 28 (розовая, белая рамка 3, точка 6) + ножка 16; при движении поднимается на 8. Над ним — подсказка с адресом.
class _Pin extends StatelessWidget {
  const _Pin({required this.lift, this.label, this.muted = false, this.loading = false});
  final bool lift, muted, loading;
  final String? label;
  @override
  Widget build(BuildContext context) {
    // Коробка 140 по центру карты → сдвиг на −70, чтобы кончик ножки пришёлся ровно в центр.
    return Transform.translate(offset: const Offset(0, -70), child: AnimatedSlide(
      duration: const Duration(milliseconds: 150), offset: Offset(0, lift ? -8 / 140 : 0),
      child: SizedBox(height: 140, child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 260), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x2617151A), blurRadius: 12, offset: Offset(0, 4))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (loading) ...[const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEE1D74))), const SizedBox(width: 8)],
            Flexible(child: Text(loading ? 'Определяем адрес…' : (label ?? ''), textAlign: TextAlign.center,
                style: _f(13, muted ? FontWeight.w500 : FontWeight.w600, muted ? const Color(0xFF6B6873) : const Color(0xFF17151A), h: 1.35))),
          ]),
        ),
        const SizedBox(height: 6),
        Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFFEE1D74), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x59EE1D74), blurRadius: 12, offset: Offset(0, 4))]),
            child: Center(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))),
        Container(width: 2.5, height: 16, decoration: BoxDecoration(color: const Color(0xFF17151A).withValues(alpha: .75), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)))),
      ])),
    ));
  }
}

/// Точка самовывоза (map.html .pp): 36, белая с розовой рамкой 2.5 и точкой 12; выбранная — розовая, ×1.15.
class _PointMarker extends StatelessWidget {
  const _PointMarker({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: selected ? 1.15 : 1, duration: const Duration(milliseconds: 150),
        child: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: selected ? const Color(0xFFEE1D74) : Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEE1D74), width: 2.5),
              boxShadow: const [BoxShadow(color: Color(0x2E17151A), blurRadius: 12, offset: Offset(0, 4))]),
          child: Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(color: selected ? Colors.white : const Color(0xFFEE1D74), shape: BoxShape.circle)))),
      );
}

class _Tick extends StatelessWidget {
  const _Tick();
  @override
  Widget build(BuildContext context) => const CustomPaint(size: Size(12, 9), painter: _TickPainter());
}

class _TickPainter extends CustomPainter {
  const _TickPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = const Color(0xFFEE1D74)..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(1, s.height * .5)..lineTo(s.width * .38, s.height - 1)..lineTo(s.width - 1, 1), p);
  }
  @override
  bool shouldRepaint(_TickPainter o) => false;
}

/// Метка-капля в подсказке адреса.
class _DropPainter extends CustomPainter {
  const _DropPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(s.width / 2, s.height - 1)
      ..quadraticBezierTo(1, s.height * .55, 1, s.height * .38)
      ..arcToPoint(Offset(s.width - 1, s.height * .38), radius: Radius.circular(s.width / 2 - 1))
      ..quadraticBezierTo(s.width - 1, s.height * .55, s.width / 2, s.height - 1);
    canvas.drawPath(path, p);
    canvas.drawCircle(Offset(s.width / 2, s.height * .38), 2.5, Paint()..color = color);
  }
  @override
  bool shouldRepaint(_DropPainter o) => o.color != color;
}
