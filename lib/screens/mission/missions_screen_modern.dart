import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:reward_common/services/api_service.dart';
import '../../theme/app_theme.dart';
// import '../../widgets/modern_widgets.dart'; // reward_common으로 이동됨
import 'package:reward_common/reward_common.dart';
import 'package:reward_common/utils/context_extensions.dart';

class Mission {
  final int id;
  final String title;
  final String description;
  final int rewardPoint;
  final String missionUrl;
  final String? category;
  final String? difficulty;
  final int? participantCount;
  final DateTime? endDate;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoint,
    required this.missionUrl,
    this.category,
    this.difficulty,
    this.participantCount,
    this.endDate,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      rewardPoint: json['rewardPoint'] as int,
      missionUrl: json['missionUrl'] as String,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      participantCount: json['participantCount'] as int?,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }
}

class MissionsScreenModern extends StatefulWidget {
  const MissionsScreenModern({super.key});

  @override
  State<MissionsScreenModern> createState() => _MissionsScreenModernState();
}

class _MissionsScreenModernState extends State<MissionsScreenModern>
    with TickerProviderStateMixin {
  List<Mission> missions = [];
  List<Mission> filteredMissions = [];
  int? hoveredMissionId;
  bool isLoading = false;
  String errorMessage = '';
  int currentPage = 0;
  int totalElements = 0;
  bool isLastPage = false;
  final ScrollController _scrollController = ScrollController();
  
  // 필터 관련
  String selectedCategory = '전체';
  String selectedDifficulty = '전체';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // 애니메이션 컨트롤러
  late AnimationController _filterAnimationController;
  bool _showFilters = false;

  final List<String> categories = ['전체', '설문조사', '앱 설치', '영상 시청', '리뷰 작성', '기타'];
  final List<String> difficulties = ['전체', '쉬움', '보통', '어려움'];

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchMissions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!isLoading && !isLastPage) {
        _fetchMissions(page: currentPage + 1);
      }
    }
  }

  Future<void> _fetchMissions({int page = 0}) async {
    if (isLoading) return;

    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = '';
        });
      }

      final api = ApiService();
      final response = await api.get('/api/v1/active-missions', queryParameters: {
        'page': page,
        'size': 20,
      });

      if (response.data != null && response.data['data'] != null) {
        final pageData = response.data['data'];
        final List<dynamic> missionList = pageData['content'];
        final newMissions = missionList.map((json) => Mission.fromJson(json)).toList();
        
        if (mounted) {
          setState(() {
            if (page == 0) {
              missions = newMissions;
            } else {
              missions.addAll(newMissions);
            }
            currentPage = page;
            totalElements = pageData['totalElements'];
            isLastPage = pageData['last'];
            isLoading = false;
            _applyFilters();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = '미션 목록을 불러올 수 없습니다.';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching missions: $e');
      if (mounted) {
        setState(() {
          errorMessage = '미션 목록을 불러오는 중 오류가 발생했습니다.';
          isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    
    setState(() {
      filteredMissions = missions.where((mission) {
        // 검색어 필터
        if (searchQuery.isNotEmpty && 
            !mission.title.toLowerCase().contains(searchQuery.toLowerCase()) &&
            !mission.description.toLowerCase().contains(searchQuery.toLowerCase())) {
          return false;
        }
        
        // 카테고리 필터
        if (selectedCategory != '전체' && mission.category != selectedCategory) {
          return false;
        }
        
        // 난이도 필터
        if (selectedDifficulty != '전체' && mission.difficulty != selectedDifficulty) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.surface,
              context.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 모던 헤더
              _buildModernHeader(),
              
              // 필터 섹션
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showFilters ? 160 : 0,
                child: SingleChildScrollView(
                  child: _buildFilterSection(),
                ),
              ),
              
              // 미션 목록
              Expanded(
                child: _buildMissionList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '미션 챌린지',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.onSurface,
                ),
              ).animate()
                .fadeIn(duration: 500.ms)
                .slideX(begin: -0.2, end: 0),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (!mounted) return;
                  
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                  if (_showFilters) {
                    _filterAnimationController.forward();
                  } else {
                    _filterAnimationController.reverse();
                  }
                },
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _filterAnimationController,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: context.colorScheme.primaryContainer,
                  foregroundColor: context.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 검색바
          ModernSearchBar(
            controller: _searchController,
            hintText: '미션 검색...',
            onChanged: (value) {
              if (!mounted) return;
              
              setState(() {
                searchQuery = value;
                _applyFilters();
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // 통계 카드
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  icon: Icons.task_alt,
                  label: '전체 미션',
                  value: totalElements.toString(),
                  color: context.colorScheme.primary,
                  index: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsCard(
                  icon: Icons.star,
                  label: '평균 포인트',
                  value: missions.isEmpty 
                    ? '0' 
                    : (missions.map((m) => m.rewardPoint).reduce((a, b) => a + b) ~/ missions.length).toString() + 'P',
                  color: context.colorScheme.secondary,
                  index: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsCard(
                  icon: Icons.trending_up,
                  label: '참여율',
                  value: '89%',
                  color: context.colorScheme.tertiary,
                  index: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int index,
  }) {
    return ModernCard(
      useGlassEffect: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 100 * index))
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '카테고리',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (!mounted) return;
                      
                      setState(() {
                        selectedCategory = category;
                        _applyFilters();
                      });
                    },
                    backgroundColor: isSelected 
                      ? context.colorScheme.primaryContainer 
                      : context.colorScheme.surfaceVariant,
                    selectedColor: context.colorScheme.primaryContainer,
                    checkmarkColor: context.colorScheme.onPrimaryContainer,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '난이도',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: difficulties.map((difficulty) {
              final isSelected = selectedDifficulty == difficulty;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(difficulty),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (!mounted) return;
                    
                    setState(() {
                      selectedDifficulty = difficulty;
                      _applyFilters();
                    });
                  },
                  backgroundColor: isSelected 
                    ? context.colorScheme.secondaryContainer 
                    : context.colorScheme.surfaceVariant,
                  selectedColor: context.colorScheme.secondaryContainer,
                  checkmarkColor: context.colorScheme.onSecondaryContainer,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionList() {
    if (isLoading && missions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(color: context.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ModernButton(
              text: '다시 시도',
              onPressed: () => _fetchMissions(page: 0),
              icon: Icons.refresh,
            ),
          ],
        ),
      );
    }

    if (filteredMissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '조건에 맞는 미션이 없습니다',
              style: TextStyle(color: context.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchMissions(page: 0),
      child: AnimationLimiter(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: filteredMissions.length + (isLoading && !isLastPage ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filteredMissions.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final mission = filteredMissions[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildModernMissionCard(mission),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernMissionCard(Mission mission) {
    final difficulty = mission.difficulty ?? '보통';
    final difficultyColor = difficulty == '쉬움' 
      ? Colors.green 
      : difficulty == '어려움' 
        ? Colors.red 
        : Colors.orange;

    return ModernCard(
      onTap: () {
        final locale = Localizations.localeOf(context).languageCode;
        context.go('/$locale/mission/${mission.id}');
      },
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    mission.category ?? '기타',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed,
                        size: 14,
                        color: difficultyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        difficulty,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: difficultyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (mission.endDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colorScheme.errorContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: context.colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'D-${mission.endDate!.difference(DateTime.now()).inDays}',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mission.title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              mission.description,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.colorScheme.primary,
                        context.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${mission.rewardPoint}P',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (mission.participantCount != null)
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${mission.participantCount}명 참여중',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .shimmer(duration: 1500.ms, delay: 500.ms, color: context.colorScheme.primary.withOpacity(0.1));
  }
}

// 모던 검색바 위젯
class ModernSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const ModernSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: -0.1, end: 0);
  }
}