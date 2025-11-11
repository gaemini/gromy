class Advertisement {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String targetUrl;
  final String advertiser;
  final bool isActive;
  final int priority; // 우선순위 (높을수록 먼저 표시)

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.targetUrl,
    required this.advertiser,
    this.isActive = true,
    this.priority = 0,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'advertiser': advertiser,
      'isActive': isActive,
      'priority': priority,
    };
  }

  // JSON에서 객체 생성
  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      targetUrl: json['targetUrl'] ?? '',
      advertiser: json['advertiser'] ?? '',
      isActive: json['isActive'] ?? true,
      priority: json['priority'] ?? 0,
    );
  }

  // 기본 광고 목록 (하드코딩)
  static List<Advertisement> get defaultAds => [
    Advertisement(
      id: 'ad_1',
      title: '한양대 ERICA SW중심대학 인턴십',
      description: '2025년 여름방학 SW 인턴십 프로그램 신청 안내',
      imageUrl: 'https://www.hanyang.ac.kr/documents/20182/0/emblem_01.png',
      targetUrl: 'https://computer.hanyang.ac.kr/news/job.php',
      advertiser: '한양대학교 ERICA',
      priority: 1,
    ),
    Advertisement(
      id: 'ad_2',
      title: '서울 공원 탐방',
      description: '도심 속 자연, 서울의 아름다운 공원을 만나보세요',
      imageUrl: 'https://parks.seoul.go.kr/template/default/images/common/logo.png',
      targetUrl: 'https://parks.seoul.go.kr/',
      advertiser: '서울특별시',
      priority: 2,
    ),
    Advertisement(
      id: 'ad_3',
      title: '스타벅스 안산점',
      description: '새로운 시즌 메뉴를 만나보세요',
      imageUrl: 'https://www.starbucks.co.kr/common/img/common/logo.png',
      targetUrl: 'https://map.naver.com/p/entry/place/13491652',
      advertiser: '스타벅스',
      priority: 3,
    ),
  ];
}
