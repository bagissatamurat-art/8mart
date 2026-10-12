// Баннеры-скриншоты для App Store и Google Play: настоящие экраны (design/store/raw, снимает integration_test/store_screenshots_test.dart)
// в рамке телефона + заголовок Onest. Рендер — headless Chrome (точный шрифт и тени), выход — design/store/out.
// Запуск: node design/store/build.mjs
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const HERE = path.dirname(new URL(import.meta.url).pathname);
const ROOT = path.resolve(HERE, '../..');
const RAW = path.join(HERE, 'raw'), OUT = path.join(HERE, 'out'), TMP = path.join(HERE, '.tmp');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const FONT = 'file://' + path.join(ROOT, 'assets/fonts/Onest-Variable.ttf');
const LOGO = fs.readFileSync('/Users/atamuratbagisov/8mart/public/assets/logo.svg', 'utf8').replace(/<metadata>.*<\/metadata>/s, '');
fs.mkdirSync(TMP, { recursive: true });

// Заголовок — о пользе, подзаголовок — коротко. Фон чередуем: фирменный розовый / пудровый.
const FRAMES = [
  ['01-home', 'Букеты с доставкой<br>за 30–70 минут', 'Розы, гортензии и хризантемы — сегодня'],
  ['02-product', 'Свежие цветы<br>каждый день', 'Собираем букет в день заказа'],
  ['03-sizes', 'Размеры S, M и L', 'Состав и цена каждого — сразу'],
  ['04-method', 'Доставка или<br>самовывоз', 'Точная цена доставки по адресу'],
  ['05-checkout', 'Оформление<br>за минуту', 'Телефон и адрес — из профиля'],
  ['06-delivery-time', 'Удобное время<br>доставки', 'Ближайшее или интервал на любой день'],
  ['07-order', 'Статус заказа<br>в реальном времени', 'Видно, когда букет в пути'],
  ['08-bonus', 'Бонусы за<br>каждый букет', '1 бонус = 1 тенге, не сгорают'],
];

const css = (W, H) => `
@font-face { font-family: Onest; src: url('${FONT}'); font-weight: 100 900; }
* { margin: 0; box-sizing: border-box; }
html, body { width: ${W}px; height: ${H}px; overflow: hidden; }
body { font-family: Onest, sans-serif; position: relative; }
.pink { background: radial-gradient(120% 70% at 50% 0%, #FF4F95 0%, #EE1D74 45%, #C80F5F 100%); color: #fff; }
.blush { background: radial-gradient(120% 70% at 50% 0%, #FFFFFF 0%, #FDF0F6 50%, #FBDCEA 100%); color: #17151A; }
.blush h1 em { color: #EE1D74; }
.top { position: absolute; left: 0; right: 0; top: ${H * .045}px; text-align: center; padding: 0 ${W * .07}px; }
.logo { height: ${W * .045}px; margin-bottom: ${H * .018}px; }
.pink .logo path { fill: #fff; }
h1 { font-weight: 800; font-size: ${W * .082}px; line-height: 1.08; letter-spacing: -0.025em; }
h1 em { font-style: normal; }
p { margin-top: ${H * .014}px; font-size: ${W * .036}px; font-weight: 500; opacity: .85; }
.phone { position: absolute; left: 50%; transform: translateX(-50%); width: ${W * .82}px; top: ${H * .235}px;
  border-radius: ${W * .085}px; padding: ${W * .016}px; background: #17151A;
  box-shadow: 0 ${W * .03}px ${W * .08}px rgba(60, 0, 25, .35), 0 0 0 ${W * .004}px rgba(255,255,255,.15) inset; }
.phone img { display: block; width: 100%; border-radius: ${W * .07}px; }
`;

const page = (W, H, [name, title, sub], i) => `<!doctype html><html><head><meta charset="utf-8"><style>${css(W, H)}</style></head>
<body class="${i % 2 ? 'blush' : 'pink'}"><div class="top"><div class="logo">${LOGO.replace('<svg', '<svg height="100%"')}</div>
<h1>${title.replace(/(\d[\d–,]*\s*минут|S, M и L|30–70)/, '<em>$1</em>')}</h1><p>${sub}</p></div>
<div class="phone"><img src="file://${path.join(RAW, name + '.png')}"></div></body></html>`;

function render(html, W, H, out) {
  const f = path.join(TMP, path.basename(out) + '.html');
  fs.writeFileSync(f, html);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  execFileSync(CHROME, ['--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1', '--allow-file-access-from-files',
    `--window-size=${W},${H}`, `--screenshot=${out}`, 'file://' + f], { stdio: 'ignore' });
}

const SIZES = { 'ios-6.9': [1320, 2868], 'ios-6.5': [1284, 2778], android: [1080, 2160] };
for (const [dir, [W, H]] of Object.entries(SIZES)) {
  FRAMES.forEach((fr, i) => { if (fs.existsSync(path.join(RAW, fr[0] + '.png'))) render(page(W, H, fr, i), W, H, path.join(OUT, dir, `${fr[0]}.png`)); });
}

// Google Play: баннер 1024×500 — логотип, слоган и два настоящих букета.
const B1 = 'https://dukenfy-api.8mart.kz/api/v1/catalog/files/product_921d21b7-a498-4184-970f-350907f58d8d_1783525261145.png';
const B2 = 'https://dukenfy-api.8mart.kz/api/v1/catalog/files/product_f13a65fd-3feb-4ea9-96ed-8950106eae87_1783525811054.png';
render(`<!doctype html><html><head><meta charset="utf-8"><style>${css(1024, 500)}
.wrap { position: absolute; inset: 0; display: flex; align-items: center; padding: 0 56px; gap: 24px; }
.txt { flex: 1; } .txt .logo { height: 40px; margin-bottom: 26px; } .txt h1 { font-size: 46px; white-space: nowrap; } .txt p { font-size: 20px; margin-top: 16px; white-space: nowrap; }
.pics { display: flex; gap: 16px; } .pics img { width: 190px; height: 290px; object-fit: cover; border-radius: 28px; box-shadow: 0 18px 40px rgba(60,0,25,.35); background: #fff; }
.pics img:first-child { margin-top: -40px; } .pics img:last-child { margin-top: 40px; }</style></head>
<body class="pink"><div class="wrap"><div class="txt"><div class="logo">${LOGO.replace('<svg', '<svg height="100%"')}</div>
<h1>Букеты с доставкой<br>за 30–70 минут</h1><p>Самовывоз из филиалов · Kaspi Pay · бонусы</p></div>
<div class="pics"><img src="${B1}"><img src="${B2}"></div></div></body></html>`, 1024, 500, path.join(OUT, 'android/feature-graphic.png'));

fs.rmSync(TMP, { recursive: true, force: true });
console.log('store frames ok');
