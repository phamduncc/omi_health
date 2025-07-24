import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';
import 'custom_input_field.dart';
import 'custom_dropdown.dart';

class EditProfileBottomSheet extends StatefulWidget {
  final HealthData? currentData;
  final VoidCallback onProfileUpdated;

  const EditProfileBottomSheet({
    super.key,
    required this.currentData,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedActivityLevel;
  bool _isLoading = false;

  final List<String> _genders = ['Nam', 'Nữ'];
  final List<String> _activityLevels = [
    'Ít vận động',
    'Vận động nhẹ',
    'Vận động vừa',
    'Vận động nhiều',
    'Vận động rất nhiều',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentData != null) {
      _weightController.text = widget.currentData!.weight.toString();
      _heightController.text = widget.currentData!.height.toString();
      _ageController.text = widget.currentData!.age.toString();
      _selectedGender = widget.currentData!.gender;
      _selectedActivityLevel = widget.currentData!.activityLevel;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null || _selectedActivityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ thông tin'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedData = HealthData(
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        age: int.parse(_ageController.text),
        gender: _selectedGender!,
        activityLevel: _selectedActivityLevel!,
        timestamp: DateTime.now(),
      );

      await StorageService.saveLatestData(updatedData);
      await StorageService.saveToHistory(updatedData);

      widget.onProfileUpdated();
      Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin cá nhân'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi cập nhật'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chỉnh sửa thông tin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CustomInputField(
                        label: 'Cân nặng',
                        hint: 'Nhập cân nặng của bạn',
                        controller: _weightController,
                        suffix: 'kg',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.monitor_weight,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập cân nặng';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0 || weight > 300) {
                            return 'Cân nặng không hợp lệ (1-300 kg)';
                          }
                          return null;
                        },
                      ),

                      CustomInputField(
                        label: 'Chiều cao',
                        hint: 'Nhập chiều cao của bạn',
                        controller: _heightController,
                        suffix: 'cm',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.height,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập chiều cao';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height <= 0 || height > 250) {
                            return 'Chiều cao không hợp lệ (1-250 cm)';
                          }
                          return null;
                        },
                      ),

                      CustomInputField(
                        label: 'Tuổi',
                        hint: 'Nhập tuổi của bạn',
                        controller: _ageController,
                        suffix: 'tuổi',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.cake,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tuổi';
                          }
                          final age = int.tryParse(value);
                          if (age == null || age <= 0 || age > 120) {
                            return 'Tuổi không hợp lệ (1-120)';
                          }
                          return null;
                        },
                      ),

                      CustomDropdown(
                        label: 'Giới tính',
                        value: _selectedGender,
                        items: _genders,
                        prefixIcon: Icons.person,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),

                      CustomDropdown(
                        label: 'Mức độ vận động',
                        value: _selectedActivityLevel,
                        items: _activityLevels,
                        prefixIcon: Icons.fitness_center,
                        onChanged: (value) {
                          setState(() {
                            _selectedActivityLevel = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Cập nhật thông tin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
