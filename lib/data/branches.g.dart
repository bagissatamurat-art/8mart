// Сгенерировано tool/import_site_data.dart — НЕ ПРАВИТЬ РУКАМИ, перезапустить скрипт.
// Источник: https://dukenfy-api.8mart.kz/api/v1/public/branches, 2026-10-13. В проде — GET /cities и GET /pickup-points?city (живой статус).
import '../domain/models.dart';

/// Города с филиалами: Астана первой, остальные по алфавиту.
const branchCities = [
  City('astana', 'Астана', 51.1282, 71.4307),
  City('aktobe', 'Актобе', 50.2839, 57.167),
  City('kokshetau', 'Кокшетау', 53.2833, 69.3964),
  City('kostanay', 'Костанай', 53.2144, 63.6246),
  City('uralsk', 'Уральск', 51.2333, 51.3667),
];

/// Филиалы — точки самовывоза. Графика работы в API нет: статус — живые isOpen / acceptingOrders.
const branchPoints = [
  PickupPoint('0ccf7ed8-913a-419a-853f-059a6277e075', 'aktobe', 'пр. Абилкайыр хана, 65', '', 50.29212392252808, 57.161272466182716, isOpen: true, acceptingOrders: true, kaspiIntegrated: false),
  PickupPoint('d45c8fea-de8a-497c-866e-e28e71e4b4a8', 'astana', 'пр. Абылай хана, 32', '', 51.15423903492818, 71.48532271385194, isOpen: true, acceptingOrders: true, kaspiIntegrated: false),
  PickupPoint('ae9a4bb2-32da-4018-a5e1-f67c0bf3ed88', 'astana', 'ул. Сыганак, 13', '', 51.13032326223226, 71.38206303119661, isOpen: true, acceptingOrders: true, kaspiIntegrated: false),
  PickupPoint('730d98ec-f28f-4922-a1a9-17ebf1a73313', 'astana', 'пр. Мангилик Ел, 45кG', '', 51.09926745779235, 71.42763644456865, isOpen: true, acceptingOrders: true, kaspiIntegrated: false, brand: 'ROMANTIC'),
  PickupPoint('731658e3-604d-49f1-93e3-0a2d0e4c24c0', 'kokshetau', 'ул. Сабатаева, 130', '', 53.28001769623048, 69.38920050859453, isOpen: true, acceptingOrders: true, kaspiIntegrated: false),
  PickupPoint('e64539d8-2b4e-4398-8a0f-25846636beb5', 'kostanay', 'ул. Тауелсиздик, 37', '', 53.2120757045302, 63.64054262638093, isOpen: true, acceptingOrders: true, kaspiIntegrated: false),
  PickupPoint('12e15cdf-1678-44ad-a297-6881617a697f', 'uralsk', 'пр. Абулхаир хана, 1/3', '', 51.24495126406298, 51.42003625631333, isOpen: true, acceptingOrders: true, kaspiIntegrated: false),
];
