import 'package:flutter/material.dart';
import '../models/health_tip.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> with TickerProviderStateMixin {
  List<HealthTip> _tips = [];
  List<HealthTip> _filteredTips = [];
  HealthData? _currentData;
  TipCategory? _selectedCategory;
  bool _isLoading = true;
  late TabController _tabController;

  final List<TipCategory> _categories = TipCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length + 1, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final currentData = await StorageService.getLatestData();
    final tips = _getSampleTips();
    
    setState(() {
      _currentData = currentData;
      _tips = tips;
      _filteredTips = tips;
      _isLoading = false;
    });
  }

  List<HealthTip> _getSampleTips() {
    return [
      HealthTip(
        id: '1',
        title: '10 thực phẩm giúp giảm cân hiệu quả',
        content: '''Dưới đây là 10 thực phẩm tự nhiên giúp bạn giảm cân một cách khoa học:

1. **Trứng**: Giàu protein, giúp no lâu và tăng cường trao đổi chất
2. **Cá hồi**: Omega-3 giúp đốt cháy mỡ thừa
3. **Rau xanh**: Ít calo, nhiều chất xơ
4. **Quả bơ**: Chất béo tốt giúp kiểm soát cảm giác đói
5. **Yến mạch**: Chất xơ hòa tan giúp no lâu
6. **Ớt**: Capsaicin tăng tốc độ trao đổi chất
7. **Táo**: Pectin giúp giảm hấp thụ đường
8. **Sữa chua Hy Lạp**: Protein cao, probiotic tốt
9. **Hạt chia**: Chất xơ và protein thực vật
10. **Trà xanh**: Catechin giúp đốt cháy mỡ

**Lưu ý**: Kết hợp với chế độ ăn cân bằng và vận động đều đặn.''',
        category: TipCategory.nutrition,
        tags: ['giảm cân', 'dinh dưỡng', 'thực phẩm'],
        readTime: 3,
      ),
      
      HealthTip(
        id: '2',
        title: 'Bài tập cardio 15 phút tại nhà',
        content: '''Bài tập cardio đơn giản không cần dụng cụ:

**Khởi động (2 phút):**
- Đi bộ tại chỗ: 30 giây
- Xoay vai và cánh tay: 30 giây
- Gập người chạm chân: 30 giây
- Nhảy nhẹ: 30 giây

**Bài tập chính (10 phút):**
Mỗi động tác 45 giây, nghỉ 15 giây:
1. Jumping Jacks
2. High Knees (chạy tại chỗ nâng cao đầu gối)
3. Burpees (đơn giản)
4. Mountain Climbers
5. Squat Jumps
6. Plank Jacks
7. Butt Kicks
8. Push-up (có thể quỳ gối)
9. Star Jumps
10. Running in Place

**Thư giãn (3 giây):**
- Đi bộ chậm và thở sâu
- Giãn cơ chân và tay

**Lợi ích**: Đốt cháy 100-150 calories, tăng cường sức khỏe tim mạch.''',
        category: TipCategory.exercise,
        tags: ['cardio', 'tại nhà', 'giảm cân'],
        readTime: 4,
      ),

      HealthTip(
        id: '3',
        title: 'Cách tính lượng nước cần uống mỗi ngày',
        content: '''Công thức tính lượng nước cần thiết:

**Công thức cơ bản:**
- Cân nặng (kg) × 35ml = Lượng nước tối thiểu/ngày

**Ví dụ:** 
- Cân nặng 60kg: 60 × 35 = 2.1 lít/ngày
- Cân nặng 70kg: 70 × 35 = 2.45 lít/ngày

**Điều chỉnh theo hoạt động:**
- Vận động nhẹ: +500ml
- Vận động vừa: +750ml  
- Vận động nặng: +1000ml
- Thời tiết nóng: +500ml
- Bị ốm/sốt: +500-1000ml

**Dấu hiệu đủ nước:**
✅ Nước tiểu màu vàng nhạt
✅ Không cảm thấy khát
✅ Da không khô
✅ Năng lượng tốt

**Mẹo uống nước:**
- Uống 1-2 ly khi thức dậy
- Uống trước mỗi bữa ăn 30 phút
- Mang theo chai nước
- Ăn nhiều trái cây, rau quả''',
        category: TipCategory.lifestyle,
        tags: ['nước', 'sức khỏe', 'hàng ngày'],
        readTime: 3,
      ),

      HealthTip(
        id: '4',
        title: 'Kỹ thuật thở giảm stress trong 5 phút',
        content: '''Kỹ thuật thở 4-7-8 giúp giảm stress nhanh chóng:

**Cách thực hiện:**
1. **Ngồi thẳng** hoặc nằm thoải mái
2. **Thở ra hoàn toàn** qua miệng
3. **Đóng miệng**, thở vào qua mũi đếm 4
4. **Nín thở** đếm 7
5. **Thở ra** qua miệng đếm 8 (có tiếng "whoosh")
6. **Lặp lại** 3-4 chu kỳ

**Lợi ích:**
- Giảm cortisol (hormone stress)
- Làm chậm nhịp tim
- Thư giãn hệ thần kinh
- Cải thiện tập trung
- Giúp ngủ ngon hơn

**Khi nào sử dụng:**
- Trước khi ngủ
- Khi cảm thấy lo âu
- Trước cuộc họp quan trọng
- Khi tức giận
- Trong lúc tắc đường

**Lưu ý:** 
- Không nên làm quá 4 chu kỳ lúc đầu
- Tập luyện đều đặn để có hiệu quả tốt nhất''',
        category: TipCategory.mental,
        tags: ['stress', 'thở', 'thư giãn'],
        readTime: 2,
      ),

      HealthTip(
        id: '5',
        title: 'Tối ưu giấc ngủ cho sức khỏe tốt nhất',
        content: '''Hướng dẫn chi tiết để có giấc ngủ chất lượng:

**Thời gian ngủ lý tưởng:**
- Người trưởng thành: 7-9 tiếng/đêm
- Đi ngủ: 22:00-23:00
- Thức dậy: 6:00-7:00

**Chuẩn bị trước khi ngủ (1-2 tiếng):**
- Tắt điện thoại, TV, máy tính
- Đọc sách hoặc nghe nhạc nhẹ
- Tắm nước ấm
- Uống trà thảo mộc (cam thảo, hoa cúc)
- Viết nhật ký hoặc suy nghĩ tích cực

**Môi trường ngủ:**
- Nhiệt độ: 18-22°C
- Tối đen hoặc dùng mặt nạ ngủ
- Yên tĩnh hoặc tiếng ồn trắng
- Nệm và gối thoải mái
- Thông gió tốt

**Tránh trước khi ngủ:**
- Caffeine sau 14:00
- Bữa ăn nặng (3 tiếng trước)
- Vận động mạnh (2 tiếng trước)
- Ánh sáng xanh từ màn hình
- Căng thẳng, lo âu

**Lợi ích của giấc ngủ tốt:**
- Tăng cường miễn dịch
- Cải thiện trí nhớ
- Kiểm soát cân nặng
- Giảm nguy cơ bệnh tim
- Tâm trạng tích cực''',
        category: TipCategory.sleep,
        tags: ['ngủ', 'sức khỏe', 'chất lượng'],
        readTime: 4,
      ),
    ];
  }

  void _filterTips(TipCategory? category) {
    setState(() {
      _selectedCategory = category;
      if (category == null) {
        _filteredTips = _tips;
      } else {
        _filteredTips = _tips.where((tip) => tip.category == category).toList();
      }
    });
  }

  Color _getCategoryColor(TipCategory category) {
    switch (category) {
      case TipCategory.nutrition:
        return const Color(0xFF2ECC71);
      case TipCategory.exercise:
        return const Color(0xFFE74C3C);
      case TipCategory.lifestyle:
        return const Color(0xFF3498DB);
      case TipCategory.mental:
        return const Color(0xFF9B59B6);
      case TipCategory.sleep:
        return const Color(0xFF34495E);
    }
  }

  IconData _getCategoryIcon(TipCategory category) {
    switch (category) {
      case TipCategory.nutrition:
        return Icons.restaurant;
      case TipCategory.exercise:
        return Icons.fitness_center;
      case TipCategory.lifestyle:
        return Icons.eco;
      case TipCategory.mental:
        return Icons.psychology;
      case TipCategory.sleep:
        return Icons.bedtime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời khuyên sức khỏe'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            if (index == 0) {
              _filterTips(null);
            } else {
              _filterTips(_categories[index - 1]);
            }
          },
          tabs: [
            const Tab(text: 'Tất cả'),
            ..._categories.map((category) => Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(category.name.split('.').last),
                ],
              ),
            )),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTipsList(),
    );
  }

  Widget _buildTipsList() {
    if (_filteredTips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không có lời khuyên nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _filteredTips.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildPersonalizedSection();
          }
          
          final tip = _filteredTips[index - 1];
          return _buildTipCard(tip);
        },
      ),
    );
  }

  Widget _buildPersonalizedSection() {
    if (_currentData == null) return const SizedBox.shrink();
    
    String personalizedTip = '';
    Color tipColor = const Color(0xFF3498DB);
    IconData tipIcon = Icons.lightbulb;
    
    final bmi = _currentData!.bmi;
    if (bmi < 18.5) {
      personalizedTip = 'BMI của bạn thấp. Hãy tập trung vào dinh dưỡng và tăng cân lành mạnh.';
      tipColor = const Color(0xFF3498DB);
      tipIcon = Icons.trending_up;
    } else if (bmi < 25) {
      personalizedTip = 'BMI của bạn ở mức lý tưởng. Hãy duy trì lối sống lành mạnh!';
      tipColor = const Color(0xFF2ECC71);
      tipIcon = Icons.favorite;
    } else if (bmi < 30) {
      personalizedTip = 'BMI của bạn hơi cao. Hãy tập trung vào việc giảm cân an toàn.';
      tipColor = const Color(0xFFF39C12);
      tipIcon = Icons.trending_down;
    } else {
      personalizedTip = 'BMI của bạn cao. Nên tham khảo ý kiến bác sĩ và có kế hoạch giảm cân.';
      tipColor = const Color(0xFFE74C3C);
      tipIcon = Icons.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tipColor, tipColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tipIcon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Lời khuyên dành riêng cho bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            personalizedTip,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(HealthTip tip) {
    final color = _getCategoryColor(tip.category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTipDetail(tip),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(tip.category),
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          tip.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${tip.readTime} phút',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tip.content.length > 150 
                    ? '${tip.content.substring(0, 150)}...'
                    : tip.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              if (tip.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: tip.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTipDetail(HealthTip tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TipDetailBottomSheet(tip: tip),
    );
  }
}

class _TipDetailBottomSheet extends StatelessWidget {
  final HealthTip tip;

  const _TipDetailBottomSheet({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          color: _getCategoryColor(tip.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        tip.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                tip.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(TipCategory category) {
    switch (category) {
      case TipCategory.nutrition:
        return const Color(0xFF2ECC71);
      case TipCategory.exercise:
        return const Color(0xFFE74C3C);
      case TipCategory.lifestyle:
        return const Color(0xFF3498DB);
      case TipCategory.mental:
        return const Color(0xFF9B59B6);
      case TipCategory.sleep:
        return const Color(0xFF34495E);
    }
  }
}
