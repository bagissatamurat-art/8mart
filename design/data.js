// 8mart — единый источник данных для макетов. Формы объектов = контракт для API.
export const BRAND = { name: '8mart', phone: '+7 700 133 90 71', phoneRaw: '+77001339071', email: 'mail@8mart.kz', instagram: '8mart_astana', tiktok: '8mart.kz' };

export const CITIES = [
  { id: 'astana', name: 'Астана', lat: 51.1282, lng: 71.4307 },
  { id: 'almaty', name: 'Алматы', lat: 43.2389, lng: 76.8897 },
  { id: 'shymkent', name: 'Шымкент', lat: 42.3417, lng: 69.5901 },
  { id: 'karaganda', name: 'Караганда', lat: 49.8047, lng: 73.1094 },
  { id: 'aktobe', name: 'Актобе', lat: 50.2839, lng: 57.1670 },
  { id: 'pavlodar', name: 'Павлодар', lat: 52.2873, lng: 76.9674 },
  { id: 'oskemen', name: 'Усть-Каменогорск', lat: 49.9483, lng: 82.6275 },
  { id: 'atyrau', name: 'Атырау', lat: 47.0945, lng: 51.9238 },
];
// Точки самовывоза — демо-адреса, заменить на данные из API
export const PICKUP_POINTS = [
  { id: 'ast-1', city: 'astana', name: 'ул. Кабанбай батыра, 11', hours: 'Ежедневно 08:00–23:00', lat: 51.1166, lng: 71.4398 },
  { id: 'ast-2', city: 'astana', name: 'пр. Мангилик Ел, 55', hours: 'Ежедневно 09:00–22:00', lat: 51.0905, lng: 71.4180 },
  { id: 'ast-3', city: 'astana', name: 'ул. Бейбитшилик, 33', hours: 'Пн–Сб 09:00–21:00', lat: 51.1694, lng: 71.4249 },
  { id: 'ast-4', city: 'astana', name: 'пр. Туран, 37', hours: 'Ежедневно 09:00–22:00', lat: 51.1105, lng: 71.4090 },
  { id: 'ast-5', city: 'astana', name: 'ул. Сарайшык, 5', hours: 'Ежедневно 08:00–22:00', lat: 51.1350, lng: 71.4310 },
  { id: 'ast-6', city: 'astana', name: 'пр. Республики, 68', hours: 'Пн–Сб 09:00–20:00', lat: 51.1800, lng: 71.4160 },
  { id: 'ast-7', city: 'astana', name: 'ул. Кенесары, 40', hours: 'Ежедневно 09:00–22:00', lat: 51.1610, lng: 71.4460 },
  { id: 'ast-8', city: 'astana', name: 'ш. Коргалжын, 3', hours: 'Ежедневно 09:00–21:00', lat: 51.1140, lng: 71.3720 },
  { id: 'ast-9', city: 'astana', name: 'ул. Улы Дала, 27', hours: 'Ежедневно 10:00–22:00', lat: 51.0980, lng: 71.4420 },
  { id: 'alm-1', city: 'almaty', name: 'пр. Абая, 150', hours: 'Ежедневно 08:00–23:00', lat: 43.2380, lng: 76.9010 },
  { id: 'alm-2', city: 'almaty', name: 'ул. Розыбакиева, 247', hours: 'Ежедневно 09:00–22:00', lat: 43.2120, lng: 76.8920 },
];

export const DELIVERY = { fee: 1000, freeFrom: 20000, minOrder: 3000, etaMin: 60, etaMax: 90 };

export const PROMO_ERRORS = {
  notFound: 'Промокод не найден',
  expired: 'Срок действия промокода истёк',
  minSum: (sum) => `Промокод действует от ${money(sum)}`,
};

export const FORM_ERRORS = {
  required: 'Обязательное поле',
  phone: 'Введите номер полностью',
  code: 'Неверный код, попробуйте ещё раз',
  codeExpired: 'Код истёк — запросите новый',
};

export const CART_ALERT = { soldOut: 'Часть товаров раскупили. Удалите их, чтобы оформить заказ' };
export const CTA_BLOCKED = { offer: 'Примите условия оферты', soldOut: 'Удалите раскупленные товары', method: 'Выберите способ получения' };

export const CATEGORIES = [
  { slug: 'stroymaterialy', name: 'Стройматериалы', img: './assets/cat-build.png', sub: [
    { slug: 'sukhie-smesi', name: 'Сухие смеси' }, { slug: 'kirpich-i-bloki', name: 'Кирпич и блоки' }, { slug: 'gipsokarton', name: 'Гипсокартон' },
    { slug: 'kraski', name: 'Краски' }, { slug: 'uteplitel', name: 'Утеплитель' }, { slug: 'plitka', name: 'Плитка' }, { slug: 'germetiki', name: 'Герметики и пена' } ] },
  { slug: 'instrumenty', name: 'Инструменты', img: './assets/cat-tools.png', sub: [ { slug: 'ruchnoy', name: 'Ручной инструмент' }, { slug: 'elektro', name: 'Электроинструмент' }, { slug: 'krepezh', name: 'Крепёж' } ] },
  { slug: 'dlya-doma', name: 'Для дома', img: './assets/cat-home.png', sub: [ { slug: 'hoztovary', name: 'Хозтовары' }, { slug: 'svet', name: 'Освещение' }, { slug: 'santehnika', name: 'Сантехника' } ] },
  { slug: 'podarki', name: 'Подарки', img: './assets/cat-goods.png', sub: [ { slug: 'upakovka', name: 'Упаковка' }, { slug: 'otkrytki', name: 'Открытки' }, { slug: 'shary', name: 'Шары' } ] },
  { slug: 'tsvety', name: 'Цветы', img: './assets/cat-flowers.png', sub: [ { slug: 'gortenzii', name: 'Гортензии' }, { slug: 'rozy', name: 'Розы' }, { slug: 'hrizantemy', name: 'Хризантемы' } ] },
];

// Стройматериалы — ориентировочные цены (Астана, 2026), фото сгенерированы. Цветы на сайте — 0 тг., помечены price: null.
const IMG = 'https://dukenfy-api.8mart.kz/api/v1/catalog/files/';
export const PRODUCTS = [
  { id: 'b1', name: 'Цемент М400, 50 кг', weight: '50 кг', price: 2890, oldPrice: 3290, badge: 'Товар дня', cat: 'sukhie-smesi', img: './assets/b-cement.png' },
  { id: 'b8', name: 'Цемент М500 Д0, 50 кг', weight: '50 кг', price: 3190, cat: 'sukhie-smesi', img: './assets/b-cement.png' },
  { id: 'b9', name: 'Цемент М400, 25 кг', weight: '25 кг', price: 1590, oldPrice: 1790, cat: 'sukhie-smesi', img: './assets/b-cement.png' },
  { id: 'b10', name: 'Цементно-песчаная смесь М150, 25 кг', weight: '25 кг', price: 1290, cat: 'sukhie-smesi', img: './assets/b-glue.png' },
  { id: 'b11', name: 'Штукатурка гипсовая, 30 кг', weight: '30 кг', price: 2890, cat: 'sukhie-smesi', img: './assets/b-glue.png' },
  { id: 'b12', name: 'Краска фасадная белая, 10 л', weight: '10 л', price: 14900, cat: 'kraski', img: './assets/b-paint.png' },
  { id: 'b2', name: 'Кирпич керамический рядовой М150', weight: '1 шт', price: 145, cat: 'kirpich-i-bloki', img: './assets/b-brick.png' },
  { id: 'b3', name: 'Гипсокартон стеновой 12,5 мм, 2500×1200', weight: '1 лист', price: 3490, oldPrice: 3890, cat: 'gipsokarton', img: './assets/b-drywall.png' },
  { id: 'b4', name: 'Краска интерьерная белая, 10 л', weight: '10 л', price: 12900, oldPrice: 14500, badge: 'Хит', cat: 'kraski', img: './assets/b-paint.png' },
  { id: 'b5', name: 'Утеплитель минеральная вата, 50 мм, рулон', weight: '12 м²', price: 8400, cat: 'uteplitel', img: './assets/b-wool.png' },
  { id: 'b6', name: 'Клей для плитки, 25 кг', weight: '25 кг', price: 2190, oldPrice: 2490, cat: 'sukhie-smesi', img: './assets/b-glue.png' },
  { id: 'b7', name: 'Плитка керамогранит серый 60×60', weight: '1,44 м²', price: 9990, cat: 'plitka', img: './assets/b-tile.png' },
  // Инструменты / Для дома / Подарки — МОК-ассортимент и цены, фото сгенерированы (assets/p-*.png)
  { id: 't1', name: 'Молоток слесарный 500 г', weight: '1 шт', price: 3490, cat: 'ruchnoy', img: './assets/p-t1.png' },
  { id: 't2', name: 'Набор отвёрток, 6 шт', weight: '6 шт', price: 4990, oldPrice: 5890, cat: 'ruchnoy', img: './assets/p-t2.png' },
  { id: 't3', name: 'Рулетка 5 м', weight: '1 шт', price: 1890, cat: 'ruchnoy', img: './assets/p-t3.png' },
  { id: 't4', name: 'Дрель-шуруповёрт аккумуляторная 18 В', weight: '1 шт', price: 32900, oldPrice: 36900, cat: 'elektro', img: './assets/p-t4.png' },
  { id: 't5', name: 'Перфоратор 800 Вт', weight: '1 шт', price: 44900, cat: 'elektro', img: './assets/p-t5.png' },
  { id: 't6', name: 'Саморезы по дереву 3,5×35, 200 шт', weight: '200 шт', price: 1290, cat: 'krepezh', img: './assets/p-t6.png' },
  { id: 't7', name: 'Дюбель-гвоздь 6×40, 100 шт', weight: '100 шт', price: 1590, cat: 'krepezh', img: './assets/p-t7.png' },
  { id: 'h1', name: 'Мешки для строительного мусора, 10 шт', weight: '10 шт', price: 1490, cat: 'hoztovary', img: './assets/p-h1.png' },
  { id: 'h2', name: 'Ведро строительное 12 л', weight: '12 л', price: 990, cat: 'hoztovary', img: './assets/p-h2.png' },
  { id: 'h3', name: 'Лампа светодиодная E27, 12 Вт', weight: '1 шт', price: 690, cat: 'svet', img: './assets/p-h3.png' },
  { id: 'h4', name: 'Удлинитель 5 м, 4 розетки', weight: '1 шт', price: 3990, cat: 'svet', img: './assets/p-h4.png' },
  { id: 'h5', name: 'Смеситель для раковины', weight: '1 шт', price: 12900, oldPrice: 14900, cat: 'santehnika', img: './assets/p-h5.png' },
  { id: 'g1', name: 'Подарочная коробка крафт', weight: '1 шт', price: 1990, cat: 'upakovka', img: './assets/p-g1.png' },
  { id: 'g2', name: 'Лента атласная, 5 м', weight: '5 м', price: 590, cat: 'upakovka', img: './assets/p-g2.png' },
  { id: 'g3', name: 'Открытка «С днём рождения»', weight: '1 шт', price: 490, cat: 'otkrytki', img: './assets/p-g3.png' },
  { id: 'g4', name: 'Шар фольгированный «Сердце»', weight: '1 шт', price: 1490, cat: 'shary', img: './assets/p-g4.png' },
  { id: 'g5', name: 'Набор латексных шаров, 10 шт', weight: '10 шт', price: 2490, cat: 'shary', img: './assets/p-g5.png' },
  { id: 'f1', name: 'Розы Мандала L', weight: 'L', price: null, cat: 'rozy', img: IMG + 'product_921d21b7-a498-4184-970f-350907f58d8d_1783525261145.png' },
  { id: 'f2', name: 'Розы Мандала M', weight: 'M', price: null, cat: 'rozy', img: IMG + 'product_2b70d6aa-a229-427c-8843-4c13d4ab011d_1783525246444.png' },
  { id: 'f3', name: 'Кустовые розы в букете L', weight: 'L', price: null, cat: 'rozy', img: IMG + 'product_c6fa81b7-4989-420b-9435-b9a188a9b3ea_1783525368149.png' },
  { id: 'f4', name: 'Гортензия с хризантемами M', weight: 'M', price: null, cat: 'gortenzii', img: IMG + 'product_7db73bc2-d9a5-4ea4-8f63-09806bd05d3c_1783525655078.png' },
  { id: 'f5', name: 'Французские розы Мандала с гортензией L', weight: 'L', price: null, cat: 'rozy', img: IMG + 'product_1c97985e-0fcf-44cb-94a9-0d679043aaca_1783525461848.png' },
  { id: 'f6', name: 'Роза микс M', weight: 'M', price: null, cat: 'rozy', img: IMG + 'product_47e1639d-b11f-48aa-8bd8-39ef22e972e4_1783524822428.png' },
  { id: 'f7', name: 'Гортензия с кустовыми розами L', weight: 'L', price: null, cat: 'gortenzii', img: IMG + 'product_f13a65fd-3feb-4ea9-96ed-8950106eae87_1783525811054.png' },
  { id: 'f8', name: 'Хризантема Момоко с розами Мандала L', weight: 'L', price: null, cat: 'hrizantemy', img: IMG + 'product_84d1c474-ddda-4f1d-9b42-7b30a1f94f14_1783525892580.png' },
  { id: 'f9', name: 'Хризантема с кустовыми розами M', weight: 'M', price: null, cat: 'hrizantemy', img: IMG + 'product_7faa562f-d421-4653-929d-7502e12fb269_1783525561210.png' },
  { id: 'f10', name: 'Хризантема L', weight: 'L', price: null, cat: 'hrizantemy', img: IMG + 'product_2ecefd47-0667-44ba-b30c-099dd8e8138c_1783525089085.png' },
];

export function money(n) { return n == null ? 'Цена уточняется' : `${Math.round(n).toLocaleString('ru-RU').replace(/\u00a0/g, ' ')} тг.`; }
export function plural(n, one, few, many) { const a = Math.abs(n) % 100, b = a % 10; if (a > 10 && a < 20) return many; if (b > 1 && b < 5) return few; if (b === 1) return one; return many; }
export function itemsTitle(n) { return `${n} ${plural(n, 'товар', 'товара', 'товаров')}`; }

// Маска +7 (999) 999-99-99; ведущая 8 → +7; иной код после + — свободный формат.
// Форматируем только по цифрам: удаление любого символа маски удаляет соседнюю цифру, пусто → ''.
export function formatPhone(raw, prev) {
  let s = String(raw || '');
  // Удалили символ маски (скобку, пробел, дефис) — цифры не изменились: стираем ближайшую цифру слева
  if (prev && s.length < prev.length && s.replace(/\D/g, '') === prev.replace(/\D/g, '')) {
    let i = 0; while (i < s.length && s[i] === prev[i]) i++;
    const h = s.slice(0, i), pre = h.startsWith('+7') ? 2 : 0;
    const head = h.slice(0, pre) + h.slice(pre).replace(/\d(?=\D*$)/, '');
    s = head + s.slice(i);
  }
  if (!s.trim()) return '';
  const intl = s.startsWith('+') && !/^\+7/.test(s) && !/^\+$/.test(s);
  if (intl) return s.replace(/[^\d+ ]/g, '').slice(0, 16);
  let digits = s.replace(/\D/g, '');
  if (digits.startsWith('8')) digits = '7' + digits.slice(1);
  if (digits.startsWith('7')) digits = digits.slice(1);
  digits = digits.slice(0, 10);
  if (!digits.length) return (s.startsWith('+') || /\d/.test(s)) && !(prev && s.length < prev.length) ? '+7' : '';
  let out = '+7 (' + digits.slice(0, 3);
  if (digits.length > 3) out += ') ' + digits.slice(3, 6);
  if (digits.length > 6) out += '-' + digits.slice(6, 8);
  if (digits.length > 8) out += '-' + digits.slice(8, 10);
  return out;
}
export function phoneComplete(v) { return /^\+7 \(\d{3}\) \d{3}-\d{2}-\d{2}$/.test(v); }

// Telegram-бот авторизации (мок — заменить на реальный). Ссылка с одноразовым токеном сессии от бэкенда.
export const TG_BOT = { username: 'mart8_auth_bot', link: (token) => 'https://t.me/mart8_auth_bot?start=' + token };
// Поддержка в WhatsApp (мок номера)
export const SUPPORT_WA = '77000000000';
// Промокод (мок): код, скидка %, минимальная сумма товаров
export const PROMO = { code: 'MART10', pct: 10, minSum: 15000 };

// ── Личный кабинет (мок; формы объектов = контракт API) ──
export const USER = { id: 'u1', name: 'Айгерим', phone: '+7 (700) 133-90-71', since: 'март 2025' };
// status: accepted | assembling | onway | ready | done | cancelled
export const ORDERS = [
  { id: '8M-10482', date: '26 сентября, 14:05', method: 'delivery', status: 'onway', address: 'Астана, Кабанбай батыра, 11', eta: '15:20–15:35', payment: 'kaspi', promo: 'MART10', items: [{ id: 'b1', qty: 2 }, { id: 'b6', qty: 1 }, { id: 'b4', qty: 1 }] },
  { id: '8M-10311', date: '12 сентября, 10:42', method: 'pickup', status: 'done', address: 'пр. Мангилик Ел, 55', payment: 'card', items: [{ id: 'b3', qty: 6 }, { id: 'b11', qty: 2 }] },
  { id: '8M-10107', date: '28 августа, 18:10', method: 'delivery', status: 'done', address: 'Астана, Кабанбай батыра, 11', payment: 'kaspi', items: [{ id: 'b12', qty: 1 }, { id: 'b5', qty: 3 }, { id: 'b2', qty: 200 }, { id: 'b9', qty: 4 }] },
  { id: '8M-09984', date: '14 августа, 12:30', method: 'delivery', status: 'cancelled', address: 'Астана, ул. Сарайшык, 5', payment: 'card', items: [{ id: 'b8', qty: 10 }] },
];
export const ORDER_STATUS = {
  accepted: { label: 'Принят', tone: 'active' }, assembling: { label: 'Собираем', tone: 'active' }, onway: { label: 'Курьер в пути', tone: 'active' },
  ready: { label: 'Готов к выдаче', tone: 'active' }, done: { label: 'Доставлен', labelPickup: 'Выдан', tone: 'ok' }, cancelled: { label: 'Отменён', tone: 'bad' },
};
export const ADDRESSES = [
  { id: 'a1', title: 'Дом', street: 'Кабанбай батыра, 11', city: 'Астана', entrance: '2', floor: '7', flat: '48', isDefault: true },
  { id: 'a2', title: 'Объект', street: 'ул. Сарайшык, 5', city: 'Астана', entrance: '', floor: '', flat: '', isDefault: false },
];
// Карты сохраняет платёжный шлюз при оплате; фронт получает только маску
export const CARDS = [ { id: 'c1', brand: 'Visa', last4: '4821', exp: '09/28', isDefault: true }, { id: 'c2', brand: 'Mastercard', last4: '1097', exp: '03/27', isDefault: false } ];
export const FAVORITES = ['b4', 'b1', 'b3', 'b5', 'b12', 'b6'];
// status: active | used | expired
export const USER_PROMOS = [
  { code: 'MART10', title: '−10% на заказ', cond: 'от 15 000 тг', until: 'до 31 октября', status: 'active' },
  { code: 'FREEDEL', title: 'Бесплатная доставка', cond: 'на любой заказ', until: 'до 15 октября', status: 'active' },
  { code: 'SPRING', title: '−15% на краски', cond: 'от 10 000 тг', until: 'истёк 31 мая', status: 'expired' },
];
// Бонусы — МОК, уточнить у бизнеса. 1 бонус = 1 тг; начисление — у каждого товара своё (product.bonus, за 1 шт),
// приходят после получения заказа; списать можно до maxPart% суммы товаров.
export const BONUS = { balance: 1240, maxPart: 30, history: [
  { id: 'h1', title: 'Начислено за заказ №8M-10311', date: '12 сентября', amount: 890 },
  { id: 'h2', title: 'Списано в заказе №8M-10107', date: '28 августа', amount: -500 },
  { id: 'h3', title: 'Начислено за заказ №8M-10107', date: '28 августа', amount: 850 },
] };

// Бонусы за товар (за 1 шт). В API — поле product.bonus; у товара без бонусов поле отсутствует.
const BONUS_BY_ID = { b1: 87, b8: 64, b4: 390, b12: 450, b5: 250, b3: 70, b6: 45, b11: 58 };
for (const p of PRODUCTS) if (p.bonus == null && BONUS_BY_ID[p.id]) p.bonus = BONUS_BY_ID[p.id];
export function bonusFor(lines) { return lines.reduce((s, l) => s + ((l.p || l).bonus || 0) * (l.qty || 1), 0); }
export function bonusText(n) { return '+' + String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ' ') + ' ' + plural(n, 'бонус', 'бонуса', 'бонусов'); }

// Избранное — общий стор на все экраны (прототип: localStorage + событие; в проде — API /favorites)
const FAV_KEY = '8mart.favorites';
export function getFavorites() { try { const v = JSON.parse(localStorage.getItem(FAV_KEY)); if (Array.isArray(v)) return v; } catch (e) {} return FAVORITES.slice(); }
export function setFavorite(id, on) { const cur = getFavorites().filter(x => x !== id); const next = on ? [id, ...cur] : cur; try { localStorage.setItem(FAV_KEY, JSON.stringify(next)); } catch (e) {} window.dispatchEvent(new CustomEvent('8mart:favorites', { detail: next })); return next; }
export function onFavorites(fn) { const h = (e) => fn(e.detail || getFavorites()); const s = (e) => { if (e.key === FAV_KEY) fn(getFavorites()); }; window.addEventListener('8mart:favorites', h); window.addEventListener('storage', s); return () => { window.removeEventListener('8mart:favorites', h); window.removeEventListener('storage', s); }; }

// ── Каталог ──
// Цветы: один товар с вариантами размера S/M/L (variants[].id + цена) и выбором цвета (colors). Позиция корзины = '<variantId>|<цвет>'.
// Цены и цвета — МОК (на сайте цветы 0 тг.), заменить данными из API.
const FLOWER_COLORS = { f1: ['Розовый', 'Красный', 'Белый'], f3: ['Розовый', 'Белый'], f4: ['Микс', 'Голубой'], f5: ['Белый', 'Розовый'], f6: ['Микс'], f7: ['Белый', 'Голубой'], f8: ['Микс', 'Жёлтый'], f9: ['Белый'], f10: ['Белый', 'Жёлтый'] };
(function groupFlowers() {
  const fl = PRODUCTS.filter(p => /^f\d+$/.test(p.id)), groups = {};
  for (const p of fl) { const m = p.name.match(/^(.*)\s([SML])$/); const base = m ? m[1] : p.name, size = m ? m[2] : p.weight;
    (groups[base] = groups[base] || []).push({ id: p.id, size, img: p.img, cat: p.cat }); }
  for (const i of fl.map(p => PRODUCTS.indexOf(p)).sort((a, b) => b - a)) PRODUCTS.splice(i, 1);
  // МОК-цены: базовая цена букета × множитель размера (S 1, M 1,45, L 2)
  const BASE = [9900, 11900, 12900, 10900, 14900, 8900, 13900];
  const MULT = { S: 1, M: 1.45, L: 2 };
  Object.entries(groups).forEach(([name, vs], gi) => {
    const first = vs[0], base = BASE[gi % BASE.length];
    const variants = ['S', 'M', 'L'].map(size => { const own = vs.find(v => v.size === size); const img = (own || vs.find(v => v.size === 'M') || vs[vs.length - 1]).img;
      return { id: own ? own.id : first.id + '-' + size.toLowerCase(), size, price: Math.round(base * MULT[size] / 100) * 100, img }; });
    PRODUCTS.push({ id: first.id, name, weight: 'S · M · L', price: variants[0].price, cat: first.cat, img: (vs.find(v => v.size === 'L') || first).img, colors: FLOWER_COLORS[first.id] || ['Микс'], variants });
  });
})();
for (const p of PRODUCTS) if (!p.variants && !p.pack) p.pack = p.weight;
// Фильтры по корневой категории: attr — поле товара (строка или массив). Цена от–до есть всегда.
export const CAT_FILTERS = {
  stroymaterialy: [{ key: 'packs', title: 'Фасовка', attr: 'pack' }],
  tsvety: [{ key: 'colors', title: 'Цвет', attr: 'colors' }],
  instrumenty: [], 'dlya-doma': [], podarki: [],
};
for (const p of PRODUCTS) if (p.variants) p.sizes = p.variants.map(v => v.size);
export const SORTS = [['popular', 'Сначала популярные'], ['cheap', 'Сначала дешевле'], ['expensive', 'Сначала дороже'], ['sale', 'Со скидкой'], ['bonus', 'С бонусами']];
export const PAGE_SIZE = 8;

// Разбор позиции корзины '<id>|<цвет>' → товар с размером/цветом
export function cartItem(key) {
  const [id, color] = String(key).split('|'); const x = PRODUCTS.find(q => q.id === id && !q.variants); if (x) return color ? { ...x, id: key, name: x.name + ', ' + color.toLowerCase(), color } : x;
  for (const g of PRODUCTS) if (g.variants) { const v = g.variants.find(v => v.id === id); if (v) return { ...g, id: key, name: g.name + ', ' + v.size + (color ? ', ' + color.toLowerCase() : ''), price: v.price, img: v.img, variant: v.size, color }; }
  return null;
}

// ── Карточка товара (быстрый просмотр). Всё ниже — МОК, в API: product.images[], description, specs[], delivery, group ──
export const COLOR_SWATCH = { 'Розовый': '#F4A6C0', 'Красный': '#D7263D', 'Белый': '#FFFFFF', 'Голубой': '#9EC5F0', 'Жёлтый': '#F7D774', 'Микс': 'conic-gradient(#F4A6C0 0 25%,#FFFFFF 0 50%,#9EC5F0 0 75%,#F7D774 0)', 'Слоновая кость': '#F3EBD8', 'Светло-серый': '#D9DADC', 'Бежевый': '#E6D3B3' };
// Способ доставки зависит от товара: express — курьер за 60–90 мин; cargo — тяжёлое/габаритное, грузовой машиной на следующий день; flowers — курьер, букет в коробке с водой.
export const DELIVERY_TYPES = {
  express: { tag: '', delivery: { when: 'Сегодня, за 60–90 минут', price: money(DELIVERY.fee).replace('тг.', 'тг') + ', бесплатно от ' + money(DELIVERY.freeFrom).replace('тг.', 'тг'), note: '' },
    pickup: { when: 'Через 30 минут', where: 'В наличии в 6 из 8 точек', note: 'Храним заказ 24 часа' } },
  cargo: { tag: 'Тяжёлый товар', delivery: { when: 'Завтра, интервал 9:00–21:00', price: 'от 3 000 тг — зависит от веса заказа', note: 'Привезём грузовой машиной. Разгрузка у подъезда, подъём на этаж — 200 тг за единицу за этаж' },
    pickup: { when: 'Завтра с 9:00', where: 'Только со склада: ш. Коргалжын, 3', note: 'Погрузим в машину. Храним заказ 3 дня' } },
  flowers: { tag: '', delivery: { when: 'Сегодня, за 60–90 минут', price: money(DELIVERY.fee).replace('тг.', 'тг') + ', бесплатно от ' + money(DELIVERY.freeFrom).replace('тг.', 'тг'), note: 'Привезём в коробке с водой, приложим открытку' },
    pickup: { when: 'Соберём за 40 минут', where: 'В 4 из 8 точек', note: 'Храним букет в холодильнике до конца дня' } },
};
const HEAVY = ['b1', 'b8', 'b11', 'b2', 'b3', 'b5', 'b7'];
for (const p of PRODUCTS) p.delivery = HEAVY.includes(p.id) ? 'cargo' : p.variants ? 'flowers' : 'express';
// Разные фасовки одного товара — отдельные товары одной группы (переключаются в карточке)
for (const [id, g] of [['b1', 'm400'], ['b9', 'm400']]) { const p = PRODUCTS.find(x => x.id === id); if (p) p.group = g; }
for (const [id, cs] of [['b4', ['Белый', 'Слоновая кость', 'Светло-серый', 'Бежевый']], ['b12', ['Белый', 'Светло-серый']]]) { const p = PRODUCTS.find(x => x.id === id); if (p) { p.colors = cs; p.colorNote = 'Колеровка бесплатно, 15 минут'; } }
const CEMENT_DESC = 'Портландцемент М400 Д20 — универсальный цемент для большинства строительных работ: приготовления бетона и кладочных растворов, заливки фундаментов, стяжки пола и штукатурки.\nДобавка 20% минеральных компонентов повышает водостойкость и снижает риск появления трещин. Подходит для работы при температуре от +5 °C.\nДля бетона М200 смешивайте 1 часть цемента, 2,8 части песка и 4,8 части щебня. Готовый раствор используйте в течение 2 часов. Храните мешки в сухом помещении на поддоне, не дольше 60 дней с даты производства.';
const DETAILS = {
  b1: { desc: CEMENT_DESC, specs: [['Марка', 'М400 Д20'], ['Фасовка', '50 кг'], ['Тип', 'Портландцемент ЦЕМ II/А-Ш 32,5Н'], ['Прочность на сжатие', '40 МПа'], ['Расход на 1 м³ бетона М200', '≈ 290 кг'], ['Время схватывания', 'от 2 часов'], ['Температура применения', 'от +5 до +30 °C'], ['Морозостойкость', 'F100'], ['Водонепроницаемость', 'W6'], ['Срок хранения', '60 дней'], ['Упаковка', 'Бумажный мешок'], ['Производитель', 'Standart Cement'], ['Страна', 'Казахстан'], ['Мешков на поддоне', '40 шт']] },
  b9: { desc: CEMENT_DESC, specs: [['Марка', 'М400 Д20'], ['Фасовка', '25 кг'], ['Тип', 'Портландцемент ЦЕМ II/А-Ш 32,5Н'], ['Прочность на сжатие', '40 МПа'], ['Время схватывания', 'от 2 часов'], ['Температура применения', 'от +5 до +30 °C'], ['Морозостойкость', 'F100'], ['Срок хранения', '60 дней'], ['Производитель', 'Standart Cement'], ['Страна', 'Казахстан']] },
  b4: { desc: 'Матовая интерьерная краска для стен и потолков в жилых помещениях. Скрывает мелкие неровности, не имеет резкого запаха, выдерживает влажную уборку.\nНаносится валиком, кистью или краскопультом в 2 слоя, второй — через 2 часа. 10 литров хватает на 60–70 м² в один слой.\nБазовый цвет — белый. Колеруем в любой оттенок из каталога бесплатно, прямо в магазине.', specs: [['Объём', '10 л'], ['Тип', 'Водно-дисперсионная, акриловая'], ['Степень блеска', 'Глубокоматовая'], ['Расход', '140–160 мл/м² на слой'], ['Высыхание между слоями', '2 часа'], ['Стойкость к мытью', '2 класс'], ['Помещения', 'Жилые, сухие'], ['Колеровка', 'Да, бесплатно'], ['Производитель', 'Alina Paint'], ['Страна', 'Казахстан']] },
  t4: { desc: 'Компактная аккумуляторная дрель-шуруповёрт для сборки мебели, монтажа и сверления дерева и металла. 21 режим момента, 2 скорости, подсветка рабочей зоны.\nВ комплекте 2 аккумулятора 2 А·ч, зарядное устройство и кейс. Зарядка — 60 минут.', specs: [['Напряжение', '18 В'], ['Аккумулятор', 'Li-Ion, 2 А·ч × 2'], ['Крутящий момент', '45 Н·м'], ['Скорость', '0–400 / 0–1500 об/мин'], ['Патрон', 'Быстрозажимной, до 13 мм'], ['Вес', '1,4 кг'], ['Гарантия', '12 месяцев']] },
};
const FLOWER_SPECS = [['S', '35 см, 9–11 цветков'], ['M', '45 см, 15–19 цветков'], ['L', '55 см, 25–29 цветков'], ['Упаковка', 'Крафт, атласная лента'], ['Стойкость', '5–7 дней'], ['Уход', 'Подрезать стебли, менять воду каждый день']];
export function productDetails(p) {
  const det = DETAILS[p.id] || {};
  let images;
  if (p.variants) { const seen = new Set(); images = [p.img, ...p.variants.map(v => v.img)].filter(s => s && !seen.has(s) && seen.add(s)).map(src => ({ src })); images.push({ ph: 'букет в интерьере' }); }
  else if (p.img) images = [{ src: p.img }, { ph: 'фото упаковки' }, { ph: p.delivery === 'cargo' ? 'на поддоне' : 'в работе' }];
  else images = [{ ph: 'фото товара' }, { ph: 'фото упаковки' }];
  const desc = det.desc || (p.variants ? 'Букет собираем в день заказа из свежих цветов. Состав может немного отличаться от фото — сохраним стиль и цветовую гамму.\nК каждому букету бесплатно прикладываем открытку и подкормку для цветов.' : 'Описание товара появится позже. Уточните детали у поддержки в WhatsApp.');
  const specs = det.specs || (p.variants ? FLOWER_SPECS : [['Фасовка', p.pack || p.weight], ['Производитель', 'Уточняется']].filter(r => r[1]));
  return { images, desc: desc.split('\n'), specs: specs.map(([k, v]) => ({ k, v })), type: mergeConditions(DELIVERY_TYPES[p.delivery] || DELIVERY_TYPES.express, p.conditions) };
}

// Условия получения задаются на товаре (админка): product.conditions = { tag?, delivery?: {when, price, note}, pickup?: {when, where, note} }.
// Незаполненные поля берутся из шаблона типа (DELIVERY_TYPES[product.delivery]).
function mergeConditions(base, own) { if (!own) return base; return { tag: own.tag ?? base.tag, delivery: { ...base.delivery, ...(own.delivery || {}) }, pickup: { ...base.pickup, ...(own.pickup || {}) } }; }
{ const b5 = PRODUCTS.find(x => x.id === 'b5'); if (b5) b5.conditions = { tag: 'Габаритный товар', delivery: { note: 'Рулоны объёмные — до 10 шт помещаются в легковую машину, больше — грузовой' } }; }

// ── Отправления: один заказ может приехать несколькими доставками ──
// Товар с delivery 'cargo' (тяжёлый/габаритный) едет Газелью на следующий день; остальные (express, flowers) — курьером сегодня.
// Если в корзине есть оба типа — клиент выбирает: двумя доставками (быстрое сегодня, тяжёлое завтра) или всё вместе завтра Газелью.
// Тарифы, окна и вес — МОК, уточнить у бизнеса. В API: product.weightKg, order.shipments[].
export const SHIPPING = {
  courier: { name: 'Курьер', when: 'Сегодня, за 60–90 минут', pickupWhen: 'Сегодня, через 30 минут' },
  cargo: { name: 'Газель', when: 'Завтра, 9:00–21:00', pickupWhen: 'Завтра с 9:00', pickupWhere: 'Склад, ш. Коргалжын, 3',
    tiers: [{ upTo: 300, fee: 3000 }, { upTo: 1000, fee: 5000 }, { upTo: 1500, fee: 7000 }], liftFee: 200,
    days: ['Завтра, 27 сентября', 'Пн, 28 сентября', 'Вт, 29 сентября'], intervals: ['9:00–13:00', '13:00–17:00', '17:00–21:00'] },
};
const KG = { b2: 2.5, b3: 25, b5: 10, b7: 32, b4: 14, b12: 14 };
for (const p of PRODUCTS) if (p.weightKg == null) { const m = String(p.weight || '').match(/([\d.,]+)\s*кг/); p.weightKg = KG[p.id] ?? (m ? parseFloat(m[1].replace(',', '.')) : 1); }
export function cargoFee(kg) { const t = SHIPPING.cargo.tiers; return (t.find(x => kg <= x.upTo) || t[t.length - 1]).fee; }
const fmtKg = (kg) => (kg >= 1000 ? (Math.round(kg / 100) / 10).toString().replace('.', ',') + ' т' : Math.round(kg) + ' кг');
// lines: [{p, qty, soldOut}] · opts: { method, together, goodsTotal (после скидки, для порога бесплатной доставки), pickupPoint, floor, lift }
export function planShipments(lines, opts = {}) {
  const method = opts.method || 'delivery', pk = method === 'pickup';
  const isCargo = (l) => l.p.delivery === 'cargo';
  const heavy = lines.filter(isCargo), light = lines.filter(l => !isCargo(l));
  const act = (ls) => ls.filter(l => !l.soldOut);
  const canSplit = act(heavy).length > 0 && act(light).length > 0;
  const together = canSplit && !!opts.together;
  const groups = !act(heavy).length ? [['courier', lines]] : !act(light).length ? [['cargo', lines]] : together ? [['cargo', lines]] : [['courier', light], ['cargo', heavy]];
  const n = groups.length, gt = opts.goodsTotal ?? act(lines).reduce((s, l) => s + (l.p.price || 0) * l.qty, 0);
  const list = groups.map(([kind, ls], i) => {
    const a = act(ls), kg = a.reduce((s, l) => s + (l.p.weightKg || 1) * l.qty, 0), qty = a.reduce((s, l) => s + l.qty, 0);
    const cargoUnits = a.filter(isCargo).reduce((s, l) => s + l.qty, 0);
    const base = pk ? 0 : kind === 'cargo' ? cargoFee(kg) : gt >= DELIVERY.freeFrom ? 0 : DELIVERY.fee;
    const floor = parseInt(opts.floor, 10) || 0, lift = !pk && kind === 'cargo' && opts.lift && floor > 1 ? SHIPPING.cargo.liftFee * cargoUnits * (floor - 1) : 0;
    const K = SHIPPING[kind];
    const label = pk ? (n > 1 ? 'Самовывоз ' + (i + 1) + ' из ' + n : 'Самовывоз') : (n > 1 ? 'Доставка ' + (i + 1) + ' из ' + n : 'Доставка');
    const when = pk ? K.pickupWhen : K.when;
    const where = pk ? (kind === 'cargo' ? K.pickupWhere : (opts.pickupPoint || '')) : '';
    const meta = pk ? [where, kind === 'cargo' ? 'поможем погрузить' : 'храним 24 часа'].filter(Boolean).join(' · ')
      : kind === 'cargo' ? 'Газель · ' + fmtKg(kg) + ' · разгрузка у подъезда' : 'Курьер · ' + itemsTitle(qty);
    return { id: kind, kind, index: i + 1, lines: ls, qty, kg: Math.round(kg), cargoUnits, fee: base, lift, total: base + lift, label, when, meta, where,
      feeLabel: pk ? 'Самовывоз' : kind === 'cargo' ? (n > 1 ? 'Доставка завтра, Газель' : 'Доставка Газелью') : (n > 1 ? 'Доставка сегодня, курьер' : 'Доставка'),
      feeText: base === 0 ? 'Бесплатно' : money(base), feeColor: base === 0 ? '#1DA765' : '#17151A', isCargo: kind === 'cargo', isCourier: kind === 'courier' };
  });
  return { canSplit, together, multi: n > 1, list, fee: list.reduce((s, x) => s + x.fee, 0), lift: list.reduce((s, x) => s + x.lift, 0), hasCourierFee: list.some(x => x.isCourier && x.fee > 0) };
}
// Варианты для выбора «как привезти» (показываются, только если plan.canSplit)
export function splitOptions(lines, opts = {}) {
  const pk = opts.method === 'pickup';
  const a = planShipments(lines, { ...opts, together: false }), b = planShipments(lines, { ...opts, together: true });
  const [c, g] = a.list;
  const f = (pl) => pl.fee === 0 ? 'Бесплатно' : pl.list.map(x => x.fee).filter(Boolean).map(money).join(' + ').replace(/ тг\.(?= \+)/g, '');
  return [
    { id: 'split', together: false, title: pk ? 'Забрать в два приёма' : 'Двумя доставками', sub: pk ? 'Сегодня — ' + itemsTitle(c.qty) + ' в выбранной точке, завтра — ' + itemsTitle(g.qty) + ' со склада' : 'Сегодня — ' + itemsTitle(c.qty) + ' курьером, завтра — ' + itemsTitle(g.qty) + ' Газелью', feeText: f(a), sel: !opts.together },
    { id: 'together', together: true, title: pk ? 'Всё завтра со склада' : 'Всё вместе завтра', sub: pk ? SHIPPING.cargo.pickupWhere + ', с 9:00' : 'Одной Газелью, 9:00–21:00', feeText: f(b), sel: !!opts.together },
  ];
}
