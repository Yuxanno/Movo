// Условный экспорт: на web — заглушка, на мобильных — реальный AdMob
export 'ad_service_stub.dart'
    if (dart.library.io) 'ad_service_mobile.dart';
