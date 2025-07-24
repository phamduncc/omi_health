class HealthData {
  final double weight;
  final double height;
  final int age;
  final String gender;
  final String activityLevel;
  final DateTime timestamp;
  final double? waist; // Vòng eo (cm) - tùy chọn
  final double? hip;   // Vòng mông (cm) - tùy chọn

  HealthData({
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.timestamp,
    this.waist,
    this.hip,
  });

  // Tính BMI
  double get bmi => weight / ((height / 100) * (height / 100));

  // Phân loại BMI
  String get bmiCategory {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  // Màu sắc cho từng loại BMI
  String get bmiCategoryColor {
    if (bmi < 18.5) return '#3498db'; // Xanh dương
    if (bmi < 25) return '#2ecc71'; // Xanh lá
    if (bmi < 30) return '#f39c12'; // Cam
    return '#e74c3c'; // Đỏ
  }

  // Tính BMR (Basal Metabolic Rate)
  double get bmr {
    if (gender.toLowerCase() == 'nam') {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  // Tính TDEE (Total Daily Energy Expenditure)
  double get tdee {
    double multiplier;
    switch (activityLevel.toLowerCase()) {
      case 'ít vận động':
        multiplier = 1.2;
        break;
      case 'vận động nhẹ':
        multiplier = 1.375;
        break;
      case 'vận động vừa':
        multiplier = 1.55;
        break;
      case 'vận động nhiều':
        multiplier = 1.725;
        break;
      case 'vận động rất nhiều':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.2;
    }
    return bmr * multiplier;
  }

  // Cân nặng lý tưởng
  double get idealWeight {
    if (gender.toLowerCase() == 'nam') {
      return 50 + 2.3 * ((height - 152.4) / 2.54);
    } else {
      return 45.5 + 2.3 * ((height - 152.4) / 2.54);
    }
  }

  // Khoảng cân nặng lý tưởng (BMI 18.5-24.9)
  Map<String, double> get idealWeightRange {
    final heightInM = height / 100;
    final minWeight = 18.5 * heightInM * heightInM;
    final maxWeight = 24.9 * heightInM * heightInM;
    return {
      'min': minWeight,
      'max': maxWeight,
    };
  }

  // Tính WHR (Waist-to-Hip Ratio)
  double? get whr {
    if (waist == null || hip == null) return null;
    return waist! / hip!;
  }

  // Phân loại WHR
  String? get whrCategory {
    final whrValue = whr;
    if (whrValue == null) return null;

    if (gender.toLowerCase() == 'nam') {
      if (whrValue < 0.9) return 'Thấp';
      if (whrValue <= 1.0) return 'Trung bình';
      return 'Cao';
    } else {
      if (whrValue < 0.8) return 'Thấp';
      if (whrValue <= 0.85) return 'Trung bình';
      return 'Cao';
    }
  }

  // Màu sắc cho WHR
  String? get whrCategoryColor {
    final category = whrCategory;
    if (category == null) return null;

    switch (category) {
      case 'Thấp':
        return '#2ecc71'; // Xanh lá
      case 'Trung bình':
        return '#f39c12'; // Cam
      case 'Cao':
        return '#e74c3c'; // Đỏ
      default:
        return '#95a5a6'; // Xám
    }
  }

  // Tính phần trăm mỡ cơ thể (Body Fat Percentage) - công thức Navy
  double? get bodyFatPercentage {
    if (waist == null) return null;

    if (gender.toLowerCase() == 'nam') {
      // Công thức cho nam: 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450
      // Vì không có neck measurement, sử dụng công thức đơn giản hóa
      return 1.20 * bmi + 0.23 * age - 16.2;
    } else {
      // Công thức cho nữ
      if (hip == null) return null;
      return 1.20 * bmi + 0.23 * age - 5.4;
    }
  }

  // Phân loại phần trăm mỡ cơ thể
  String? get bodyFatCategory {
    final bodyFat = bodyFatPercentage;
    if (bodyFat == null) return null;

    if (gender.toLowerCase() == 'nam') {
      if (bodyFat < 6) return 'Thiết yếu';
      if (bodyFat < 14) return 'Vận động viên';
      if (bodyFat < 18) return 'Khỏe mạnh';
      if (bodyFat < 25) return 'Chấp nhận được';
      return 'Béo phì';
    } else {
      if (bodyFat < 16) return 'Thiết yếu';
      if (bodyFat < 21) return 'Vận động viên';
      if (bodyFat < 25) return 'Khỏe mạnh';
      if (bodyFat < 32) return 'Chấp nhận được';
      return 'Béo phì';
    }
  }

  // Màu sắc cho phần trăm mỡ cơ thể
  String? get bodyFatCategoryColor {
    final category = bodyFatCategory;
    if (category == null) return null;

    switch (category) {
      case 'Thiết yếu':
      case 'Vận động viên':
        return '#3498db'; // Xanh dương
      case 'Khỏe mạnh':
        return '#2ecc71'; // Xanh lá
      case 'Chấp nhận được':
        return '#f39c12'; // Cam
      case 'Béo phì':
        return '#e74c3c'; // Đỏ
      default:
        return '#95a5a6'; // Xám
    }
  }

  // Chuyển đổi sang Map để lưu trữ
  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'activityLevel': activityLevel,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'waist': waist,
      'hip': hip,
    };
  }

  // Tạo từ Map
  factory HealthData.fromMap(Map<String, dynamic> map) {
    return HealthData(
      weight: map['weight']?.toDouble() ?? 0.0,
      height: map['height']?.toDouble() ?? 0.0,
      age: map['age']?.toInt() ?? 0,
      gender: map['gender'] ?? '',
      activityLevel: map['activityLevel'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      waist: map['waist']?.toDouble(),
      hip: map['hip']?.toDouble(),
    );
  }
}
