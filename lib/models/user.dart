class AppUser {
  final int? userId;
  final String username;
  final String email;
  final String? socialMedia;
  final String? profilImgUrl;

  const AppUser({
    this.userId,
    required this.username,
    required this.email,
    this.socialMedia,
    this.profilImgUrl,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'email': email,
        'social_media': socialMedia,
        'profil_img_url': profilImgUrl,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        userId: j['user_id'] as int?,
        username: j['username'] as String? ?? '',
        email: j['email'] as String? ?? '',
        socialMedia: j['social_media'] as String?,
        profilImgUrl: j['profil_img_url'] as String?,
      );

  AppUser copyWith({String? username, String? email, String? socialMedia, String? profilImgUrl}) => AppUser(
        userId: userId,
        username: username ?? this.username,
        email: email ?? this.email,
        socialMedia: socialMedia ?? this.socialMedia,
        profilImgUrl: profilImgUrl ?? this.profilImgUrl,
      );
}
