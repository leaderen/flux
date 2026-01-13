/// 远程配置数据模型
/// OSS 配置文件的 Dart 映射

class RemoteConfig {
  final int configVersion;
  final List<String> domains;
  final String? backupSubscription;
  final Announcement? announcement;
  final Maintenance? maintenance;
  final UpdateInfo? update;
  final ContactInfo? contact;
  final FeatureFlags? features;
  final List<String>? recommendedNodes;

  RemoteConfig({
    required this.configVersion,
    required this.domains,
    this.backupSubscription,
    this.announcement,
    this.maintenance,
    this.update,
    this.contact,
    this.features,
    this.recommendedNodes,
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      configVersion: json['config_version'] as int? ?? 1,
      domains: (json['domains'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      backupSubscription: json['backup_subscription'] as String?,
      announcement: json['announcement'] != null
          ? Announcement.fromJson(json['announcement'])
          : null,
      maintenance: json['maintenance'] != null
          ? Maintenance.fromJson(json['maintenance'])
          : null,
      update:
          json['update'] != null ? UpdateInfo.fromJson(json['update']) : null,
      contact: json['contact'] != null
          ? ContactInfo.fromJson(json['contact'])
          : null,
      features: json['features'] != null
          ? FeatureFlags.fromJson(json['features'])
          : null,
      recommendedNodes: (json['recommended_nodes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'config_version': configVersion,
        'domains': domains,
        if (backupSubscription != null)
          'backup_subscription': backupSubscription,
        if (announcement != null) 'announcement': announcement!.toJson(),
        if (maintenance != null) 'maintenance': maintenance!.toJson(),
        if (update != null) 'update': update!.toJson(),
        if (contact != null) 'contact': contact!.toJson(),
        if (features != null) 'features': features!.toJson(),
        if (recommendedNodes != null) 'recommended_nodes': recommendedNodes,
      };
}

class Announcement {
  final bool enabled;
  final String? title;
  final String? content;
  final String type; // info, warning, error

  Announcement({
    required this.enabled,
    this.title,
    this.content,
    this.type = 'info',
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      enabled: json['enabled'] as bool? ?? false,
      title: json['title'] as String?,
      content: json['content'] as String?,
      type: json['type'] as String? ?? 'info',
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        'type': type,
      };
}

class Maintenance {
  final bool enabled;
  final String? message;

  Maintenance({
    required this.enabled,
    this.message,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    return Maintenance(
      enabled: json['enabled'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (message != null) 'message': message,
      };
}

class UpdateInfo {
  final String? minVersion;
  final Map<String, PlatformUpdate> latest;
  final String? changelog;

  UpdateInfo({
    this.minVersion,
    required this.latest,
    this.changelog,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    final latestJson = json['latest'] as Map<String, dynamic>? ?? {};
    final latest = <String, PlatformUpdate>{};
    for (final entry in latestJson.entries) {
      if (entry.value is Map<String, dynamic>) {
        latest[entry.key] = PlatformUpdate.fromJson(entry.value);
      }
    }

    return UpdateInfo(
      minVersion: json['min_version'] as String?,
      latest: latest,
      changelog: json['changelog'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (minVersion != null) 'min_version': minVersion,
        'latest': latest.map((k, v) => MapEntry(k, v.toJson())),
        if (changelog != null) 'changelog': changelog,
      };

  /// 获取当前平台的更新信息
  PlatformUpdate? getForPlatform(String platform) => latest[platform];
}

class PlatformUpdate {
  final String version;
  final String? url;
  final bool force;

  PlatformUpdate({
    required this.version,
    this.url,
    this.force = false,
  });

  factory PlatformUpdate.fromJson(Map<String, dynamic> json) {
    return PlatformUpdate(
      version: json['version'] as String? ?? '0.0.0',
      url: json['url'] as String?,
      force: json['force'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        if (url != null) 'url': url,
        'force': force,
      };
}

class ContactInfo {
  final String? telegram;
  final String? website;
  final String? email;

  ContactInfo({
    this.telegram,
    this.website,
    this.email,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      telegram: json['telegram'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (telegram != null) 'telegram': telegram,
        if (website != null) 'website': website,
        if (email != null) 'email': email,
      };
}

class FeatureFlags {
  final bool inviteEnabled;
  final bool purchaseEnabled;
  final bool ssrEnabled;

  FeatureFlags({
    this.inviteEnabled = true,
    this.purchaseEnabled = true,
    this.ssrEnabled = false,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      inviteEnabled: json['invite_enabled'] as bool? ?? true,
      purchaseEnabled: json['purchase_enabled'] as bool? ?? true,
      ssrEnabled: json['ssr_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'invite_enabled': inviteEnabled,
        'purchase_enabled': purchaseEnabled,
        'ssr_enabled': ssrEnabled,
      };
}
