// Иконка приложения 8mart (выбран вариант 5: «8MART» белым на фирменном розовом), вектор из настоящего логотипа.
// Генерирует все размеры iOS (AppIcon.appiconset) и Android (mipmap + адаптивная иконка API 26+, монохромная для Android 13).
// Запуск: node design/app-icon/build.mjs
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
const sharp = createRequire('/Users/atamuratbagisov/8mart/package.json')('sharp');

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '../..');
const PINK = '#EE1D74';
// Логотип 8MART (public/assets/logo.svg сайта), viewBox 126×30
const LOGO = fs.readFileSync('/Users/atamuratbagisov/8mart/public/assets/logo.svg', 'utf8')
  .replace(/<metadata>.*<\/metadata>/s, '').match(/<path[^>]*\/?>(<\/path>)?/g).map(p => p.replace(/fill="[^"]*"/, 'fill="#fff"')).join('');
const LW = 125.5, LH = 29.12;
/** Логотип шириной w по центру квадрата side. */
const mark = (side, w) => { const k = w / LW; return `<g transform="translate(${(side - w) / 2} ${(side - LH * k) / 2}) scale(${k})">${LOGO}</g>`; };
const svg = (side, body) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${side} ${side}" width="${side}" height="${side}">${body}</svg>`;

// Мастер 1024: фон на весь квадрат (скругление делает система), надпись — 74 % ширины.
const MASTER = svg(1024, `<rect width="1024" height="1024" fill="${PINK}"/>${mark(1024, 760)}`);
fs.writeFileSync(path.join(ROOT, 'design/app-icon/app-icon.svg'), MASTER);
const png = (s, px) => sharp(Buffer.from(s), { density: 72 * px / 1024 * 4 }).resize(px, px).flatten({ background: PINK }).png();
await png(MASTER, 1024).toFile(path.join(ROOT, 'design/app-icon/app-icon-1024.png'));

// iOS: все файлы из Contents.json (размер × масштаб), без прозрачности.
const ios = path.join(ROOT, 'ios/Runner/Assets.xcassets/AppIcon.appiconset');
for (const im of JSON.parse(fs.readFileSync(path.join(ios, 'Contents.json'), 'utf8')).images) {
  if (!im.filename) continue;
  const px = Math.round(parseFloat(im.size) * parseInt(im.scale));
  await png(MASTER, px).toFile(path.join(ios, im.filename));
}

// Android: обычная иконка (квадрат), адаптивная — фон цветом + надпись на прозрачном (надпись в безопасной зоне 66 из 108 dp).
const res = path.join(ROOT, 'android/app/src/main/res');
const dens = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
const FG = svg(1080, mark(1080, 540)); // ~54 dp из 108: в круге (безопасная зона 66 dp) остаются поля
for (const [d, k] of Object.entries(dens)) {
  await png(MASTER, Math.round(48 * k)).toFile(path.join(res, `mipmap-${d}/ic_launcher.png`));
  await sharp(Buffer.from(FG), { density: 72 * 108 * k / 1080 * 4 }).resize(Math.round(108 * k), Math.round(108 * k)).png().toFile(path.join(res, `mipmap-${d}/ic_launcher_foreground.png`));
}
fs.mkdirSync(path.join(res, 'mipmap-anydpi-v26'), { recursive: true });
fs.writeFileSync(path.join(res, 'mipmap-anydpi-v26/ic_launcher.xml'), `<?xml version="1.0" encoding="utf-8"?>
<!-- Адаптивная иконка (Android 8+): фон — фирменный розовый, надпись 8MART — design/app-icon/build.mjs. monochrome — тематические иконки Android 13. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
`);
fs.writeFileSync(path.join(res, 'values/ic_launcher_background.xml'), `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">${PINK}</color>
</resources>
`);
console.log('icons ok');
