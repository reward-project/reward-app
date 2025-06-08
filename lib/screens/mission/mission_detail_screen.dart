import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:reward_common/services/api_service.dart';
import 'package:reward_common/reward_common.dart';
import 'package:reward_common/utils/context_extensions.dart';
import '../../providers/auth_provider_extended.dart';

class MissionDetailScreen extends StatefulWidget {
  final String missionId;

  const MissionDetailScreen({
    super.key,
    required this.missionId,
  });

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? mission;
  bool isLoading = true;
  String errorMessage = '';
  bool isCompleting = false;
  bool isCompleted = false;
  
  late AnimationController _confettiController;
  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchMissionDetail();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _fetchMissionDetail() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final api = ApiService();
      final response = await api.get('/api/v1/missions/${widget.missionId}');

      if (response.data != null && response.data['data'] != null) {
        setState(() {
          mission = response.data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = '미션 정보를 불러올 수 없습니다.';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching mission detail: $e');
      setState(() {
        errorMessage = '미션 정보를 불러오는 중 오류가 발생했습니다.';
        isLoading = false;
      });
    }
  }

  Future<void> _completeMission() async {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      GlobalErrorHandler.showError(context, '로그인이 필요합니다.');
      return;
    }

    setState(() {
      isCompleting = true;
    });

    _buttonController.forward();

    final api = ApiService();
    final response = await api.postWrapped<Map<String, dynamic>>(
      '/api/v1/missions/${widget.missionId}/complete',
      data: {
        'completedAt': DateTime.now().toIso8601String(),
      },
      context: context,
      showLoading: true,
      loadingMessage: '미션을 완료하는 중...',
    );

    if (response.success) {
      setState(() {
        isCompleted = true;
        isCompleting = false;
      });

      // 축하 애니메이션 실행
      _confettiController.forward();
      
      // 성공 피드백
      HapticFeedback.lightImpact();
      
      _showSuccessDialog();
      
      // 성공 메시지 표시
      if (context.mounted) {
        GlobalErrorHandler.showSuccess(context, '미션이 성공적으로 완료되었습니다!');
      }
    } else {
      setState(() {
        isCompleting = false;
      });
      _buttonController.reverse();
      // 에러는 ApiService에서 자동으로 처리됨
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              size: 64,
              color: context.colorScheme.primary,
            ).animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              '미션 완료!',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${mission?['rewardPoint'] ?? 0}P를 획득하셨습니다!',
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: '포인트 내역 보기',
                    onPressed: () {
                      Navigator.of(context).pop();
                      final locale = Localizations.localeOf(context).languageCode;
                      context.go('/$locale/cash-history');
                    },
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ModernButton(
                    text: '다른 미션 보기',
                    onPressed: () {
                      Navigator.of(context).pop();
                      final locale = Localizations.localeOf(context).languageCode;
                      context.go('/$locale/missions');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openMissionUrl() async {
    final url = mission?['missionUrl'] as String?;
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showMessage('링크를 열 수 없습니다.');
        }
      } catch (e) {
        _showMessage('링크를 열 수 없습니다.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 미션 공유 기능
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.share,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colorScheme.primaryContainer.withOpacity(0.3),
              context.colorScheme.surface,
            ],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
              onPressed: _fetchMissionDetail,
              icon: Icons.refresh,
            ),
          ],
        ),
      );
    }

    if (mission == null) {
      return const Center(
        child: Text('미션 정보가 없습니다.'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 헤더 이미지 영역 (임시)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colorScheme.primary,
                  context.colorScheme.secondary,
                ],
              ),
            ),
            child: Stack(
              children: [
                // 배경 패턴
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // 중앙 아이콘
                Center(
                  child: Icon(
                    Icons.task_alt,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ).animate()
                    .scale(duration: 800.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 1500.ms),
                ),
              ],
            ),
          ),
          
          // 컨텐츠 영역
          Transform.translate(
            offset: const Offset(0, -30),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 미션 제목과 카테고리
                    _buildMissionHeader(),
                    const SizedBox(height: 24),
                    
                    // 미션 정보 카드들
                    _buildInfoCards(),
                    const SizedBox(height: 24),
                    
                    // 미션 설명
                    _buildDescription(),
                    const SizedBox(height: 24),
                    
                    // 미션 수행 방법
                    _buildInstructions(),
                    const SizedBox(height: 32),
                    
                    // 완료 버튼
                    _buildCompleteButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionHeader() {
    final category = mission?['category'] as String? ?? '기타';
    final difficulty = mission?['difficulty'] as String? ?? '보통';
    final difficultyColor = difficulty == '쉬움' 
      ? Colors.green 
      : difficulty == '어려움' 
        ? Colors.red 
        : Colors.orange;

    return Column(
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
                category,
                style: context.textTheme.labelMedium?.copyWith(
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
                    size: 16,
                    color: difficultyColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    difficulty,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: difficultyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          mission?['title'] as String? ?? '',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colorScheme.onSurface,
          ),
        ).animate()
          .fadeIn(duration: 600.ms)
          .slideX(begin: -0.3, end: 0),
      ],
    );
  }

  Widget _buildInfoCards() {
    final rewardPoint = mission?['rewardPoint'] as int? ?? 0;
    final participantCount = mission?['participantCount'] as int? ?? 0;
    final endDate = mission?['endDate'] as String?;
    
    DateTime? deadline;
    if (endDate != null) {
      try {
        deadline = DateTime.parse(endDate);
      } catch (e) {
        // 파싱 실패 시 null 유지
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.monetization_on,
            label: '리워드',
            value: '${rewardPoint}P',
            color: context.colorScheme.primary,
            index: 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.people,
            label: '참여자',
            value: '${participantCount}명',
            color: context.colorScheme.secondary,
            index: 1,
          ),
        ),
        if (deadline != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: Icons.timer,
              label: '마감',
              value: 'D-${deadline.difference(DateTime.now()).inDays}',
              color: context.colorScheme.error,
              index: 2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
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
          Icon(icon, color: color, size: 28),
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
      .fadeIn(delay: Duration(milliseconds: 200 + (index * 100)))
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  Widget _buildDescription() {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '미션 설명',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            mission?['description'] as String? ?? '',
            style: context.textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 400.ms)
      .slideY(begin: 0.3, end: 0);
  }

  Widget _buildInstructions() {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt,
                color: context.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                '수행 방법',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStep(1, '아래 "미션 시작" 버튼을 눌러주세요'),
          _buildStep(2, '링크로 이동하여 미션을 완료해주세요'),
          _buildStep(3, '"미션 완료" 버튼을 눌러 포인트를 획득하세요'),
          if (mission?['missionUrl'] != null) ...[
            const SizedBox(height: 16),
            ModernButton(
              text: '미션 시작',
              onPressed: _openMissionUrl,
              icon: Icons.launch,
              outlined: true,
            ),
          ],
        ],
      ),
    ).animate()
      .fadeIn(delay: 600.ms)
      .slideY(begin: 0.3, end: 0);
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    if (isCompleted) {
      return ModernButton(
        text: '완료됨',
        onPressed: null,
        icon: Icons.check_circle,
        filled: true,
      ).animate()
        .scale(duration: 300.ms, curve: Curves.bounceOut);
    }

    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_buttonController.value * 0.05),
          child: ModernButton(
            text: isCompleting ? '완료 처리 중...' : '미션 완료',
            onPressed: isCompleting ? null : _completeMission,
            icon: isCompleting ? null : Icons.task_alt,
            isLoading: isCompleting,
          ),
        );
      },
    );
  }
}