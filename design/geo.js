// Геосервисы прототипа: Mapbox (карта) + DaData (подсказки и адрес по пину).
// ⚠ Прототип вызывает DaData прямо из браузера — ключ виден в коде. В проде: только через бэкенд
//   GET /geo/suggest?q&city и GET /geo/reverse?lat&lng; DADATA_SECRET_KEY во фронт не кладём никогда.
export const MAPBOX_TOKEN = 'pk.ВСТАВЬТЕ_СВОЙ'; // ключ вырезан из пакета
const DADATA_TOKEN = ''; // ключ вырезан: в проде — только через бэкенд
const DD = 'https://suggestions.dadata.ru/suggestions/api/4_1/rs';

async function dd(path, body) {
  const r = await fetch(`${DD}/${path}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: 'Token ' + DADATA_TOKEN }, body: JSON.stringify(body) });
  if (!r.ok) throw new Error('dadata ' + r.status);
  return (await r.json()).suggestions || [];
}

async function mapboxForward(q, c) {
  const r = await fetch(`https://api.mapbox.com/search/geocode/v6/forward?q=${encodeURIComponent(q)}&country=kz&language=ru&limit=1&proximity=${c.lng},${c.lat}&access_token=${MAPBOX_TOKEN}`);
  const f = ((await r.json()).features || [])[0];
  return f ? { lng: f.geometry.coordinates[0], lat: f.geometry.coordinates[1] } : null;
}

// Подсказки «Улица, дом» в пределах города. → [{title, sub, label, lat, lng, needHouse}]
export async function suggestAddress(q, city) {
  const list = await dd('suggest/address', { query: q, count: 10, locations: [{ country_iso_code: 'KZ', city: city.name }], restrict_value: true, language: 'ru' });
  const out = [], seen = new Set();
  for (const s of list) {
    const d = s.data || {};
    const street = d.street_with_type || d.street || '';
    const house = [d.house, d.block ? (d.block_type || 'корп.') + ' ' + d.block : ''].filter(Boolean).join(' ');
    const title = street ? street + (house ? ', ' + house : '') : (d.settlement_with_type || s.value);
    const sub = [d.city_district_with_type || d.city_district, d.city || city.name].filter(Boolean).join(' · ');
    if (!title || seen.has(title + sub)) continue; seen.add(title + sub);
    let lat = d.geo_lat ? +d.geo_lat : null, lng = d.geo_lon ? +d.geo_lon : null;
    if (lat == null) { const g = await mapboxForward(`${city.name}, ${title}`, city).catch(() => null); if (g) ({ lat, lng } = g); }
    out.push({ title, sub, label: title, lat, lng, needHouse: !!street && !d.house });
    if (out.length === 6) break;
  }
  return out;
}

// Адрес по пину → {street, city}. DaData geolocate; если пусто — обратное геокодирование Mapbox.
export async function reverseGeocode(lat, lng) {
  try {
    const s = (await dd('geolocate/address', { lat, lon: lng, count: 1, radius_meters: 100, language: 'ru' }))[0];
    if (s && s.data && (s.data.street || s.data.house)) {
      const d = s.data;
      return { street: [d.street_with_type || d.street, d.house].filter(Boolean).join(', '), city: d.city || d.settlement || '' };
    }
  } catch (e) { /* падаем на Mapbox */ }
  const r = await fetch(`https://api.mapbox.com/search/geocode/v6/reverse?longitude=${lng}&latitude=${lat}&language=ru&types=address,street&limit=1&access_token=${MAPBOX_TOKEN}`);
  const f = ((await r.json()).features || [])[0];
  if (!f) return { street: '', city: '' };
  const p = f.properties || {}, ctx = p.context || {};
  const street = p.feature_type === 'address' ? [ctx.street && ctx.street.name, ctx.address && ctx.address.address_number].filter(Boolean).join(', ') || p.name : p.name;
  return { street: street || '', city: (ctx.place && ctx.place.name) || '' };
}
