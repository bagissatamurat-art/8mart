import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import '../domain/models.dart';
import '../domain/shipments.dart';
import '../state/cart_cubit.dart' show PromoRules;
import 'mock_data.dart';

/// Сторис главной — как на сайте: настоящие сторис 8mart.kz (сейчас — видео) первыми, затем свои о букетах, промокоде и доставке.
/// С API_URL — GET /stories бэкенда (форма Story сайта: {id, title, cover, slides:[{img, title, text, video?, duration?, cta?:{label, href?, copy?}}]}),
/// имя для API_MOCK — «stories». Без бэкенда:
/// TEMP-ADAPTER — живые сторис из публичного API 8mart.kz (GET /api/v1/public/stories) + свои (_local). С бэкендом — удалить _live.
class StoryRepository {
  const StoryRepository();
  static const _origin = 'https://dukenfy-api.8mart.kz';

  Future<List<Story>> stories() async {
    if (!ApiClient.isMocked('stories')) {
      try {
        return [for (final s in await ApiClient.instance.get<List<dynamic>>('/stories')) storyFromJson(s as Map<String, dynamic>)];
      } catch (_) {
        // Свои слайды собраны на товарах и промокоде мока — с настоящим каталогом они вели бы в никуда.
        return const [];
      }
    }
    return [...await _live(), ..._local()];
  }

  /// Сторис в форме сайта. cta.href — путь сайта (/product/f1, /catalog?cat=…): в приложении — ctaPath для go_router.
  static Story storyFromJson(Map<String, dynamic> j) => Story(
        id: '${j['id']}', title: '${j['title'] ?? ''}', cover: '${j['cover'] ?? ''}',
        slides: [
          for (final s in (j['slides'] as List? ?? const []).cast<Map<String, dynamic>>())
            StorySlide(
              img: '${s['img'] ?? ''}', title: '${s['title'] ?? ''}', text: '${s['text'] ?? ''}',
              video: s['video'] as String?, duration: (s['duration'] as num?)?.round(),
              ctaLabel: (s['cta'] as Map?)?['label'] as String?, ctaPath: (s['cta'] as Map?)?['href'] as String?, ctaCopy: (s['cta'] as Map?)?['copy'] as String?,
            ),
        ],
      );

  Future<List<Story>> _live() async {
    try {
      final r = await http.get(Uri.parse('$_origin/api/v1/public/stories')).timeout(const Duration(seconds: 5));
      if (r.statusCode != 200) return const [];
      final list = (jsonDecode(utf8.decode(r.bodyBytes)) as List).cast<Map<String, dynamic>>();
      return [
        for (final s in list)
          if (s['isActive'] != false && s['url'] != null && (s['type'] == 'video' || s['type'] == 'image'))
            () {
              final media = '$_origin${s['url']}', cover = s['thumbnail'] == null ? media : '$_origin${s['thumbnail']}';
              // Заголовка в API нет — подпись кружка «8mart»; текст и цена уже в самом видео.
              return Story(id: 'live-${s['id']}', title: '8mart', cover: cover, slides: [
                s['type'] == 'video' ? StorySlide(img: cover, video: media, duration: (s['duration'] as num?)?.round()) : StorySlide(img: media),
              ]);
            }(),
      ];
    } catch (_) {
      return const [];
    }
  }

  static const _i = 'assets/images/';

  static StorySlide _bouquet(String id) {
    final p = MockData.byId(id)!;
    return StorySlide(img: p.image, title: p.name, text: 'от ${_grp(p.price ?? 0)} тг · размеры ${p.pack.replaceAll(' · ', ', ')}', ctaLabel: 'Выбрать размер', ctaPath: '/p/${p.id}');
  }

  static String _grp(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

  List<Story> _local() {
    const cfg = ShippingConfig();
    final eta = '${cfg.etaMin}–${cfg.etaMax}';
    return [
      Story(id: 's-bouquets', title: 'Букеты', cover: '${_i}st-flowers.jpg', slides: [
        StorySlide(img: '${_i}st-flowers.jpg', title: 'Букет за $eta минут', text: 'Розы, гортензии и хризантемы — соберём сегодня и привезём', ctaLabel: 'Выбрать букет', ctaPath: '/catalog/tsvety'),
      ]),
      Story(id: 's-roses', title: 'Розы', cover: MockData.byId('f1')!.image, slides: [_bouquet('f1'), _bouquet('f6'), _bouquet('f3')]),
      Story(id: 's-hydrangeas', title: 'Гортензии', cover: MockData.byId('f4')!.image, slides: [_bouquet('f4'), _bouquet('f7')]),
      Story(id: 's-chrysanthemums', title: 'Хризантемы', cover: MockData.byId('f8')!.image, slides: [_bouquet('f8'), _bouquet('f10')]),
      Story(id: 's-promo', title: 'Промокод', cover: '${_i}st-gifts.jpg', slides: [
        StorySlide(img: '${_i}st-gifts.jpg', title: '−${PromoRules.pct}% по коду ${PromoRules.code}', text: 'На заказ от ${_grp(PromoRules.minSum)} тг. Введите код в корзине',
            ctaLabel: 'Скопировать код', ctaCopy: PromoRules.code),
      ]),
      Story(id: 's-delivery', title: 'Доставка', cover: '${_i}st-delivery.jpg', slides: [
        StorySlide(img: '${_i}st-delivery.jpg', title: 'Бесплатно от ${_grp(cfg.freeFrom)} тг', text: 'Привезём букет за $eta минут. Иначе от ${_grp(cfg.courierFee)} тг',
            ctaLabel: 'Выбрать букет', ctaPath: '/catalog/tsvety'),
      ]),
    ];
  }
}
