/// Egypt cities (name EN / name AR / lat / lng) used for the address picker.
class EgyptCity {
  final String name;
  final String nameAr;
  final double lat;
  final double lng;

  const EgyptCity(this.name, this.nameAr, this.lat, this.lng);
}

const egyptCities = <EgyptCity>[
  EgyptCity('Cairo', 'القاهرة', 30.0444, 31.2357),
  EgyptCity('Giza', 'الجيزة', 30.0131, 31.2089),
  EgyptCity('Alexandria', 'الإسكندرية', 31.2001, 29.9187),
  EgyptCity('Port Said', 'بورسعيد', 31.2653, 32.3019),
  EgyptCity('Port Fouad', 'بورفؤاد', 29.9724, 32.3775),
  EgyptCity('Suez', 'السويس', 29.9668, 32.5473),
  EgyptCity('Damietta', 'دمياط', 31.4133, 31.8132),
  EgyptCity('Mansoura', 'المنصورة', 31.0406, 31.3817),
  EgyptCity('Tanta', 'طنطا', 30.7916, 30.9704),
  EgyptCity('Zagazig', 'الزقازيق', 30.8180, 31.5049),
  EgyptCity('Ismailia', 'الإسماعيلية', 30.5900, 32.2640),
  EgyptCity('Minya', 'المنيا', 28.0745, 30.7688),
  EgyptCity('Assiut', 'أسيوط', 27.1758, 31.1811),
  EgyptCity('Sohag', 'سوهاج', 26.5573, 31.8724),
  EgyptCity('Luxor', 'الأقصر', 25.6872, 32.6396),
  EgyptCity('Aswan', 'أسوان', 24.0889, 32.8998),
  EgyptCity('Hurghada', 'الغردقة', 27.2506, 33.8257),
  EgyptCity('Sharm El Sheikh', 'شرم الحمراء', 28.3420, 34.3283),
  EgyptCity('Beni Suef', 'بني سويف', 29.0667, 31.0948),
  EgyptCity('Faiyum', 'الفيوم', 29.2817, 30.8368),
  EgyptCity('Damanhur', 'دمنهور', 31.0333, 30.4786),
];
