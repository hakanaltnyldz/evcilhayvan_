// lib/features/auth/domain/user_model.dart

class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'user', 'admin', 'seller'
  final String? city; // ? -> null olabilir
  
  // --- GÜNCELLEME: BU İKİSİNİ EKLE ---
  // (EditProfileScreen'in hata vermemesi için)
  final String? avatarUrl;
  final String? about;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.city,
    this.avatarUrl, // Eklendi
    this.about,      // Eklendi
  });

  // --- GÜNCELLEME: ÇÖKMEYİ ENGELLEYEN YER ---
  // Bu factory, backend'den gelen JSON'ı bir User nesnesine çevirir
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Backend'de _id olarak geliyor, biz id olarak alıyoruz
      // ID null gelirse boş string ata (hiçbir şeyin çökmemesi için)
      id: json['_id'] ?? json['id'] ?? '', 
      
      // 'name', 'email', 'role' null gelirse varsayılan değer ata
      name: json['name'] ?? 'Bilinmeyen Kullanıcı',
      email: json['email'] ?? 'eposta-yok@bilinmiyor.com',
      role: json['role'] ?? 'user',
      
      city: json['city'],
      avatarUrl: json['avatarUrl'], // Eklendi
      about: json['about'],        // Eklendi
    );
  }
  // --- GÜNCELLEME BİTTİ ---
}