class HealthData {
  final double weight;
  final double height;
  final int age;
  final String gender;
  final String activityLevel;
  final DateTime timestamp;

  HealthData({
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.timestamp,
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

  // Chuyển đổi sang Map để lưu trữ
  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'activityLevel': activityLevel,
      'timestamp': timestamp.millisecondsSinceEpoch,
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
    );
  }
}
