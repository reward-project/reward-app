import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MissionListScreen extends StatelessWidget {
  const MissionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    
    final socialApps = [
      {
        'name': '네이버',
        'icon': 'N',
        'unread': 216,
        'onTap': () => context.go('/$currentLocale/missions'),
      },
      // 필요한 경우 다른 앱들 추가
      // {'name': '유튜브', 'icon': '▶', 'unread': 5},
      // {'name': '인스타그램', 'icon': '📷', 'unread': 26},
      // {'name': '카카오', 'icon': '💬', 'unread': 209},
      // {'name': '페이스북', 'icon': 'f', 'unread': 0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('미션'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // 알림 기능 구현
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: socialApps.length,
          itemBuilder: (context, index) {
            final app = socialApps[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Card(
                child: InkWell(
                  onTap: app['onTap'] as void Function()?,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // 앱 아이콘
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            app['icon'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // 앱 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app['name'] as String,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                '미션하기',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 남은 미션 수
                        Text(
                          '남은 미션: ${app['unread']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 