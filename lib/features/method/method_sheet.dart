import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../core/format.dart';
import '../../data/delivery_repository.dart';
import '../../data/geo_repository.dart';
import '../../data/places.dart';
import '../../domain/models.dart';
import '../../domain/shipments.dart';
import '../../domain/store_status.dart';
import '../../state/cart_cubit.dart';
import '../../ui/ui.dart';
import 'address_search.dart';

TextStyle _f(double size, FontWeight w, Color col, {double? h, double? ls}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h, letterSpacing: ls);

/// Выбор способа получения (как на сайте): на весь экран, сверху карта (город слева, × справа, справа снизу — зум «+ / −» и «Моё местоположение»),
/// снизу панель: заголовок, свич Доставка/Самовывоз, поле адреса (поиск — отдельным экраном) или компактный список филиалов со статусом, CTA 56.
/// Доставка: стоимость и время — по зоне доставки 8mart.kz для пина; вне зон — «Доставить сюда» недоступна.
/// Карта — нативный Mapbox Maps SDK (mapbox_maps_flutter), токен ставится в main.dart. Адрес по пину — DaData geolocate / Mapbox reverse (GeoRepository).
/// address + onSaveAddress — режим address-only (кабинет → Адреса): без свича, поле «Название», CTA «Сохранить адрес».
Future<void> openMethodSheet(BuildContext context, {AddressDraft? address, ValueChanged<AddressDraft>? onSaveAddress}) =>
    Navigator.of(context, rootNavigator: true).push<void>(MaterialPageRoute(fullscreenDialog: true,
        builder: (_) => _MethodSheet(address: address, onSaveAddress: onSaveAddress)));

class AddressDraft {
  const AddressDraft({this.title = '', required this.street, required this.city, this.entrance = '', this.flat = ''});
  final String title, street, city, entrance, flat;
}

class _MethodSheet extends StatefulWidget {
  const _MethodSheet({this.address, this.onSaveAddress});
  final AddressDraft? address;
  final ValueChanged<AddressDraft>? onSaveAddress;
  @override
  State<_MethodSheet> createState() => _MethodSheetState();
}

class _MethodSheetState extends State<_MethodSheet> {
  static const _geo = GeoRepository();
  // Карта Mapbox: контроллер появляется в onMapCreated.
  mb.MapboxMap? _mb;
  mb.PointAnnotationManager? _pins;
  mb.Cancelable? _pinTaps;
  final Map<String, String> _annToPoint = {};
  Uint8List? _imgOn, _imgOff;
  int _pinSeq = 0;
  bool _camDirty = false;
  late final mb.CameraViewportState _viewport;
  final _street = TextEditingController();
  final _entrance = TextEditingController(), _flat = TextEditingController(), _title = TextEditingController();
  bool get _addrOnly => widget.onSaveAddress != null;
  late ReceiveMethod _m;
  City _city = Places.cities.first;
  bool _citiesOpen = false;
  String? _point;
  /// Камера летит к дому из поиска — адрес по пину не перезаписываем.
  bool _quiet = false;
  // Пин
  bool _moving = false, _locating = false, _geoBusy = false;
  Timer? _reverseT;
  /// Зона доставки для точки пина (центр карты).
  QuoteResult? _quote;
  /// Точка адреса доставки (где встал пин) — уходит в корзину: по ней сервер проверяет зону и создаёт заказ.
  double? _lat, _lng;
  bool _quoteLoading = false;
  int _quoteReq = 0;
  static const _delivery = DeliveryRepository();

  @override
  void initState() {
    super.initState();
    Places.changes.addListener(_onPlaces);
    Places.refresh();
    final cart = context.read<CartCubit>().state;
    _m = cart.method ?? ReceiveMethod.delivery;
    final d = widget.address;
    if (d != null) {
      _m = ReceiveMethod.delivery;
      _city = Places.cities.firstWhere((c) => c.name == d.city, orElse: () => Places.cities.first);
      _street.text = d.street;
      _title.text = d.title; _entrance.text = d.entrance; _flat.text = d.flat;
      _viewport = mb.CameraViewportState(center: _pt(_city.lat, _city.lng), zoom: 15);
      return;
    }
    final i = cart.address.indexOf(', ');
    if (i > 0) {
      _city = Places.cities.firstWhere((c) => c.name == cart.address.substring(0, i), orElse: () => Places.cities.first);
      if (_m == ReceiveMethod.delivery) { _street.text = cart.address.substring(i + 2); _quote = cart.quote == null ? null : QuoteOk(cart.quote!); _lat = cart.lat; _lng = cart.lng; }
    }
    if (_m == ReceiveMethod.pickup) _point = Places.pickupPoints.where((p) => cart.pointId != null ? p.id == cart.pointId : cart.address.endsWith(p.name)).firstOrNull?.id;
    // Создаём один раз: MapWidget переприменяет viewport, если пришёл новый объект.
    _viewport = mb.CameraViewportState(center: _pt(_city.lat, _city.lng), zoom: _m == ReceiveMethod.delivery ? 15 : 12);
  }

  @override
  void dispose() { Places.changes.removeListener(_onPlaces); _reverseT?.cancel(); _pinTaps?.cancel(); _street.dispose(); _entrance.dispose(); _flat.dispose(); _title.dispose(); super.dispose(); }

  /// С бэкендом: пришли свежие статусы филиалов — обновляем список и пины.
  void _onPlaces() { if (!mounted) return; setState(() {}); _syncPins(); }

  List<PickupPoint> get _points => Places.pickupPoints.where((p) => p.city == _city.id).toList();

  // ── поиск адреса — отдельный экран; выбран дом → карта летит к нему без повторного определения адреса по пину ──
  Future<void> _openSearch() async {
    final r = await openAddressSearch(context, value: _street.text, city: _city);
    if (r == null || !mounted) return;
    if (r.city.id != _city.id) setState(() { _city = r.city; _point = null; });
    final s = r.suggestion;
    setState(() => _street.text = s.title);
    if (s.lat != null) { _quiet = true; _move(s.lat!, s.lng!, 17); _setPos(s.lat!, s.lng!); }
  }

  /// Пин встал на точку: если у адреса есть дом — считаем зону доставки (стоимость и время курьера).
  void _setPos(double lat, double lng) {
    _lat = lat; _lng = lng;
    if (_addrOnly || !RegExp(r'\d').hasMatch(_street.text)) { setState(() { _quote = null; _quoteLoading = false; }); return; }
    final req = ++_quoteReq;
    setState(() => _quoteLoading = true);
    _delivery.quote(lat, lng).then((q) { if (mounted && req == _quoteReq) setState(() { _quote = q; _quoteLoading = false; }); });
  }

  // ── зум и «Моё местоположение» ──
  Future<void> _zoomBy(double d) async {
    final st = await _mb?.getCameraState();
    if (st == null) return;
    await _mb?.easeTo(mb.CameraOptions(zoom: (st.zoom + d).clamp(3, 19)), mb.MapAnimationOptions(duration: 250));
  }

  Future<void> _locate() async {
    if (_geoBusy) return;
    setState(() => _geoBusy = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) showMartToast(context, 'Нет доступа к геопозиции — разрешите его в настройках телефона');
        return;
      }
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)));
      await _move(p.latitude, p.longitude, _m == ReceiveMethod.delivery ? 17 : 13);
    } catch (_) {
      if (mounted) showMartToast(context, 'Не удалось определить местоположение');
    } finally {
      if (mounted) setState(() => _geoBusy = false);
    }
  }

  // ── карта Mapbox ──
  static mb.Point _pt(double lat, double lng) => mb.Point(coordinates: mb.Position(lng, lat));

  Future<void> _move(double lat, double lng, double zoom) async {
    await _mb?.flyTo(mb.CameraOptions(center: _pt(lat, lng), zoom: zoom), mb.MapAnimationOptions(duration: 600));
  }

  Future<void> _onMapCreated(mb.MapboxMap m) async {
    _mb = m;
    await m.gestures.updateSettings(mb.GesturesSettings(rotateEnabled: false, pitchEnabled: false));
    await m.scaleBar.updateSettings(mb.ScaleBarSettings(enabled: false));
    final pins = await m.annotations.createPointAnnotationManager();
    if (!mounted) return;
    _pins = pins;
    _pinTaps = pins.tapEvents(onTap: _onPinTap);
    await _syncPins();
  }

  void _onStyleLoaded(mb.StyleLoadedEventData _) {
    _mb?.style.localizeLabels('ru', null).catchError((_) {});
    if (_m == ReceiveMethod.pickup) { _fitPoints(); } else if (_street.text.isEmpty) { _scheduleReverse(); }
  }

  // ── пин: пока камера движется — поднят, после остановки (idle) — адрес по координатам ──
  void _onCamera(mb.CameraChangedEventData _) {
    _camDirty = true;
    if (_m == ReceiveMethod.delivery && !_moving) setState(() => _moving = true);
  }

  void _onIdle(mb.MapIdleEventData _) {
    if (!_camDirty) return;
    _camDirty = false;
    if (_m == ReceiveMethod.delivery) _scheduleReverse();
  }

  // ── точки самовывоза: нативные аннотации с картинкой-кружком, тап выбирает точку ──
  void _onPinTap(mb.PointAnnotation a) {
    final id = _annToPoint[a.id];
    final p = _points.where((x) => x.id == id).firstOrNull;
    if (p != null) _pickPoint(p, fly: false);
  }

  Future<void> _syncPins() async {
    final mgr = _pins;
    if (mgr == null) return;
    final seq = ++_pinSeq;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    _imgOn ??= await _markerPng(true, dpr);
    _imgOff ??= await _markerPng(false, dpr);
    await mgr.deleteAll();
    if (seq != _pinSeq) return;
    _annToPoint.clear();
    if (_m != ReceiveMethod.pickup) return;
    final ps = _points;
    // iOS читает PNG в 1×, Android — с плотностью экрана: на iOS уменьшаем, чтобы маркер был 36 pt.
    final size = defaultTargetPlatform == TargetPlatform.iOS ? 1 / dpr : 1.0;
    final anns = await mgr.createMulti([
      for (final p in ps) mb.PointAnnotationOptions(geometry: _pt(p.lat, p.lng), image: p.id == _point ? _imgOn : _imgOff, iconSize: size),
    ]);
    if (seq != _pinSeq) return;
    for (var i = 0; i < anns.length && i < ps.length; i++) {
      final a = anns[i];
      if (a != null) _annToPoint[a.id] = ps[i].id;
    }
  }

  void _scheduleReverse() {
      _reverseT?.cancel();
      _reverseT = Timer(const Duration(milliseconds: 250), () async {
        if (!mounted) return;
        setState(() => _moving = false);
        if (_quiet) { _quiet = false; return; }
        final st = await _mb?.getCameraState();
        if (st == null || !mounted) return;
        final c = st.center.coordinates;
        final lat = c.lat.toDouble(), lng = c.lng.toDouble();
        setState(() => _locating = true);
        final a = await _geo.reverse(lat, lng).catchError((_) => '');
        if (!mounted) return;
        setState(() { _locating = false; if (a.isNotEmpty) _street.text = a; });
        _setPos(lat, lng);
      });
  }

  void _setCity(City c) {
    setState(() { _city = c; _citiesOpen = false; _point = null; _street.clear(); _quote = null; _lat = null; _lng = null; });
    if (_m == ReceiveMethod.pickup && _points.isNotEmpty) { _fitPoints(); } else { _move(c.lat, c.lng, _m == ReceiveMethod.delivery ? 15 : 12); }
    _syncPins();
  }

  Future<void> _fitPoints() async {
    final m = _mb, ps = _points;
    if (m == null || ps.isEmpty) return;
    final cam = await m.cameraForCoordinatesPadding([for (final p in ps) _pt(p.lat, p.lng)], mb.CameraOptions(),
        mb.MbxEdgeInsets(top: 80, left: 40, bottom: 40, right: 40), 15, null);
    await m.flyTo(cam, mb.MapAnimationOptions(duration: 600));
  }

  void _setMethod(ReceiveMethod m) {
    setState(() => _m = m);
    if (m == ReceiveMethod.pickup) { _fitPoints(); } else { _mb?.easeTo(mb.CameraOptions(zoom: 15), mb.MapAnimationOptions(duration: 400)); }
    _syncPins();
  }

  void _pickPoint(PickupPoint p, {bool fly = true}) {
    setState(() => _point = p.id);
    if (fly) _move(p.lat, p.lng, 15);
    _syncPins();
  }

  void _confirm() {
    if (_addrOnly) {
      widget.onSaveAddress!(AddressDraft(title: _title.text, street: _street.text.trim().replaceAll(RegExp(r',\s*$'), ''), city: _city.name, entrance: _entrance.text, flat: _flat.text));
      Navigator.of(context).pop();
      return;
    }
    final cart = context.read<CartCubit>();
    if (_m == ReceiveMethod.delivery) {
      cart.setMethod(_m, '${_city.name}, ${_street.text.trim().replaceAll(RegExp(r',\s*$'), '')}', quote: switch (_quote) { QuoteOk(:final quote) => quote, _ => null },
          cityId: _city.id, lat: _lat, lng: _lng);
    } else {
      final p = _points.firstWhere((x) => x.id == _point);
      cart.setMethod(_m, '${_city.name}, ${p.name}', pickupKaspi: p.kaspiIntegrated, cityId: _city.id, pointId: p.id);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final isD = _m == ReceiveMethod.delivery;
    final streetOk = RegExp(r'\d').hasMatch(_street.text);
    /// Вне зон доставки — заказать сюда нельзя (адрес в кабинет сохранить можно).
    final outside = isD && !_addrOnly && _quote is QuoteOutside;
    final ok = isD ? streetOk && !outside : _point != null && _points.any((p) => p.id == _point);
    final cfg = ShippingConfig.current;
    // Порог бесплатной доставки показываем, только если он есть (с бэкендом его задаёт сервер).
    final free = cfg.hasFreeDelivery ? ', бесплатно от ${moneyText(cfg.freeFrom)}' : '';
    final top = MediaQuery.paddingOf(context).top;

    final map = Stack(children: [
      mb.MapWidget(
        key: const ValueKey('method-map'),
        styleUri: mb.MapboxStyles.MAPBOX_STREETS,
        viewport: _viewport,
        // Жесты по карте забирает карта, а не шторка/список под ней.
        gestureRecognizers: {Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())},
        onMapCreated: _onMapCreated,
        onStyleLoadedListener: _onStyleLoaded,
        onCameraChangeListener: _onCamera,
        onMapIdleListener: _onIdle,
      ),
      // Пин без подписи (адрес — в поле ниже); пока определяется адрес — лоадер вокруг головки пина.
      if (isD) IgnorePointer(child: Center(child: _Pin(lift: _moving, loading: _locating || (_moving && !_quiet)))),
      // Зум «+ / −» и «Моё местоположение» — справа снизу.
      Positioned(right: 16, bottom: 16, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x2617151A), blurRadius: 12, offset: Offset(0, 4))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _MapBtn(label: 'Приблизить', onTap: () => _zoomBy(1), child: const MartPlusMinus(plus: true, color: Color(0xFF17151A), size: 14)),
            Container(width: 24, height: 1, color: const Color(0xFFEEEDF1)),
            _MapBtn(label: 'Отдалить', onTap: () => _zoomBy(-1), child: const MartPlusMinus(plus: false, color: Color(0xFF17151A), size: 14)),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x2617151A), blurRadius: 12, offset: Offset(0, 4))]),
          child: _MapBtn(label: 'Моё местоположение', onTap: _locate, child: _geoBusy
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEE1D74)))
              : const CustomPaint(size: Size(18, 18), painter: _LocatePainter(Color(0xFF17151A)))),
        ),
      ])),
      Positioned(left: 16, top: 16 + top, child: _Float(onTap: () => setState(() => _citiesOpen = !_citiesOpen), child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(_city.name, style: _f(15, FontWeight.w600, const Color(0xFF17151A))),
        const SizedBox(width: 8),
        const MartChevron(dir: ChevronDir.down, color: Color(0xFF6B6873), size: 5),
      ]))),
      Positioned(right: 16, top: 16 + top, child: Semantics(button: true, label: 'Закрыть', child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x2617151A), blurRadius: 12, offset: Offset(0, 4))]),
            child: const Center(child: MartCross(size: 14, color: Color(0xFF17151A)))),
      ))),
      if (_citiesOpen) Positioned(left: 16, top: 68 + top, child: Container(
        width: 240, constraints: const BoxConstraints(maxHeight: 320), padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x2917151A), blurRadius: 24, offset: Offset(0, 8))]),
        child: ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: [
          for (final ct in Places.cities) GestureDetector(onTap: () => _setCity(ct), child: Container(
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

    // Строка о доставке под адресом: нет дома / вне зон — подсказка на её месте (высота панели не меняется, карта не прыгает).
    final needHouse = isD && _street.text.trim().length > 2 && !streetOk && !_locating;
    final q = _quote;
    final feeLine = needHouse ? ('Укажите номер дома — найдите адрес или сдвиньте пин к дому', true)
        : outside ? ('Сюда пока не доставляем — выберите другой адрес или самовывоз', true)
        : _quoteLoading ? ('Считаем стоимость доставки…', false)
        : q is QuoteOk ? ('Доставка ${moneyText(q.quote.fee)}$free · ~${q.quote.eta} мин', false)
        : ('Доставка от ${moneyText(cfg.courierFee)}$free · ${cfg.etaMin}–${cfg.etaMax} мин', false);
    final delivery = ListView(padding: const EdgeInsets.symmetric(horizontal: 4), children: [
      MartTapField(label: 'Улица, дом', required: true, value: _street.text, busy: _locating, error: needHouse || outside, onTap: _openSearch),
      // Подъезд и квартира — только в адресной книге кабинета; при заказе — на оформлении.
      if (_addrOnly) ...[
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: MartInput(label: 'Подъезд', controller: _entrance)),
          const SizedBox(width: 8),
          Expanded(child: MartInput(label: 'Квартира, офис', controller: _flat)),
        ]),
      ],
      const SizedBox(height: 12),
      Text(feeLine.$1, style: _f(13, feeLine.$2 ? FontWeight.w500 : FontWeight.w400, feeLine.$2 ? c.error : c.ink2, h: 1.4)),
    ]);

    final ps = [..._points]..sort((a, b) => a.name.compareTo(b.name));
    // Статус филиала цветом: открыт — зелёный, не принимает заказы — жёлтый, закрыт — серый.
    (String, Color) status(PickupPoint p) => switch (storeTone(p)) {
          StoreTone.open => ('Открыто · принимает заказы', c.success),
          StoreTone.soon => ('Сейчас не принимает заказы', c.warning),
          StoreTone.closed => ('Сейчас закрыто', c.ink3),
        };
    final pickup = ps.isEmpty
        ? Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: c.warningBg, borderRadius: BorderRadius.circular(16)),
            child: Text('В городе ${_city.name} пока нет точек самовывоза — выберите доставку или другой город', style: _f(14, FontWeight.w400, c.ink1, h: 1.4)))
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text('${ps.length} ${plural(ps.length, 'точка', 'точки', 'точек')} в городе ${_city.name}', style: _f(13, FontWeight.w400, c.ink2))),
            const SizedBox(height: 4),
            Expanded(child: ListView.separated(
              padding: EdgeInsets.zero, itemCount: ps.length, separatorBuilder: (_, __) => Divider(height: 1, indent: 52, color: c.divider),
              itemBuilder: (_, i) {
                final p = ps[i], on = p.id == _point;
                final (st, tone) = status(p);
                return Semantics(button: true, selected: on, label: '${p.brand ?? '8MART'}, ${p.name}. $st', child: GestureDetector(
                  behavior: HitTestBehavior.opaque, onTap: () => _pickPoint(p),
                  child: AnimatedContainer(
                    duration: MartMotion.press, constraints: const BoxConstraints(minHeight: 60), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(color: on ? c.primary50 : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                    child: ExcludeSemantics(child: Row(children: [
                      Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? c.primary : tone.withValues(alpha: .14)),
                          child: Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? Colors.white : tone)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Flexible(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _f(15, FontWeight.w600, c.ink1))),
                          if (p.brand != null) ...[
                            const SizedBox(width: 6),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(6)),
                                child: Text(p.brand!, style: _f(11, FontWeight.w600, c.ink2))),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text(st, style: _f(13, FontWeight.w500, tone == c.ink3 ? c.ink2 : tone)),
                      ])),
                    ])),
                  ),
                ));
              },
            )),
          ]);

    return Scaffold(
      backgroundColor: c.surface, resizeToAvoidBottomInset: false,
      body: LayoutBuilder(builder: (context, cons) => Column(children: [
        // Карта одной высоты в доставке и самовывозе — переключение не двигает пин.
        SizedBox(height: cons.maxHeight * .46, child: ColoredBox(color: c.surface3, child: map)),
        Expanded(child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12 + MediaQuery.paddingOf(context).bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(_addrOnly ? (widget.address!.street.isEmpty ? 'Новый адрес' : 'Изменить адрес') : 'Как получить заказ?', style: _f(22, FontWeight.w800, c.ink1, ls: -0.44)),
            if (_addrOnly) ...[const SizedBox(height: 4), Text('Двигайте карту или введите адрес', style: _f(13, FontWeight.w400, c.ink2, h: 1.4))],
            const SizedBox(height: 16),
            if (_addrOnly) MartInput(label: 'Название', controller: _title)
            else Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
                child: Row(children: [tab('Доставка', ReceiveMethod.delivery), const SizedBox(width: 4), tab('Самовывоз', ReceiveMethod.pickup)])),
            const SizedBox(height: 16),
            Expanded(child: isD ? delivery : pickup),
            const SizedBox(height: 16),
            MartButton(label: _addrOnly ? 'Сохранить адрес' : isD ? 'Доставить сюда' : 'Заберу здесь', expanded: true,
                disabledReason: ok ? null : (isD ? (outside ? 'Сюда пока не доставляем' : 'Укажите улицу и дом') : 'Выберите точку на карте или в списке'), onPressed: _confirm),
          ]),
        )),
      ])),
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

/// Пин доставки: головка 34 (розовая, белое кольцо, точка) + ножка 14; при движении карты поднимается на 8.
/// Адрес над пином не пишем — он в поле ниже; пока определяется — вращающееся кольцо вокруг головки.
class _Pin extends StatelessWidget {
  const _Pin({required this.lift, this.loading = false});
  final bool lift, loading;
  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFEE1D74);
    // Коробка 60 по центру карты → сдвиг на −30, чтобы кончик ножки пришёлся ровно в центр.
    return Transform.translate(offset: const Offset(0, -30), child: AnimatedSlide(
      duration: const Duration(milliseconds: 150), offset: Offset(0, lift ? -8 / 60 : 0),
      child: SizedBox(height: 60, child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        SizedBox.square(dimension: 46, child: Stack(alignment: Alignment.center, children: [
          if (loading) const SizedBox.square(dimension: 46, child: CircularProgressIndicator(strokeWidth: 2.5, color: pink, backgroundColor: Color(0x33EE1D74))),
          Container(width: 34, height: 34, decoration: BoxDecoration(color: pink, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x59EE1D74), blurRadius: 12, offset: Offset(0, 4))]),
              child: Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))),
        ])),
        Container(width: 2.5, height: 14, decoration: BoxDecoration(color: const Color(0xFF17151A).withValues(alpha: .75), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)))),
      ])),
    ));
  }
}

/// Кнопка поверх карты 44 (зум, «Моё местоположение»).
class _MapBtn extends StatelessWidget {
  const _MapBtn({required this.label, required this.onTap, required this.child});
  final String label;
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) => Semantics(button: true, label: label, child: GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onTap, child: SizedBox.square(dimension: MartHeight.hit, child: Center(child: child))));
}

/// Стрелка «Моё местоположение» (навигационный треугольник) геометрией.
class _LocatePainter extends CustomPainter {
  const _LocatePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..moveTo(s.width * .92, s.height * .08)..lineTo(s.width * .08, s.height * .45)..lineTo(s.width * .5, s.height * .5)
      ..lineTo(s.width * .55, s.height * .92)..close(), p);
  }
  @override
  bool shouldRepaint(_LocatePainter o) => o.color != color;
}

/// Точка самовывоза (map.html .pp) для аннотации Mapbox: 36, белая с розовой рамкой 2.5 и точкой 12; выбранная — розовая, ×1.15. PNG в [dpr].
Future<Uint8List> _markerPng(bool selected, double dpr) async {
  const pink = Color(0xFFEE1D74);
  final k = dpr * (selected ? 1.15 : 1);
  final side = (52 * dpr).ceil();
  final rec = ui.PictureRecorder();
  final cv = Canvas(rec);
  final c = Offset(side / 2, side / 2);
  cv.drawCircle(c + Offset(0, 4 * dpr), 18 * k, Paint()..color = const Color(0x2E17151A)..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * dpr));
  cv.drawCircle(c, 18 * k, Paint()..color = selected ? pink : Colors.white);
  cv.drawCircle(c, (18 - 1.25) * k, Paint()..color = pink..style = PaintingStyle.stroke..strokeWidth = 2.5 * k);
  cv.drawCircle(c, 6 * k, Paint()..color = selected ? Colors.white : pink);
  final img = await rec.endRecording().toImage(side, side);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return bytes!.buffer.asUint8List();
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
