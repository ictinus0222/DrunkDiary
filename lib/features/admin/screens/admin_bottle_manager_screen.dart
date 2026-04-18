import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/repositories/alcohol_repository.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../repositories/admin_repository.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository());
final alcoholRepositoryProvider = Provider((ref) => AlcoholRepository());

class AdminBottleManagerScreen extends ConsumerStatefulWidget {
  const AdminBottleManagerScreen({super.key});

  @override
  ConsumerState<AdminBottleManagerScreen> createState() => _AdminBottleManagerScreenState();
}

class _AdminBottleManagerScreenState extends ConsumerState<AdminBottleManagerScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final subTypeController = TextEditingController();
  final countryController = TextEditingController();
  final abvController = TextEditingController();
  final volumeController = TextEditingController();
  final descriptionController = TextEditingController();
  final tagsController = TextEditingController();

  String selectedType = 'Whiskey';
  final List<String> alcoholTypes = [
    'Whiskey',
    'Vodka',
    'Rum',
    'Gin',
    'Tequila',
    'Beer',
    'Wine',
    'Brandy',
    'Liqueur',
    'Other'
  ];

  File? selectedImage;
  bool isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  List<String> _generateKeywords() {
    final name = nameController.text.toLowerCase();
    final brand = brandController.text.toLowerCase();
    final type = selectedType.toLowerCase();
    
    final Set<String> keywords = {};
    
    void addTerms(String text) {
      final words = text.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
      for (final word in words) {
        for (int i = 2; i <= word.length; i++) {
          keywords.add(word.substring(0, i));
        }
      }
      keywords.addAll(words);
    }

    addTerms(name);
    addTerms(brand);
    addTerms(type);
    
    return keywords.toList();
  }

  Future<void> _saveBottle() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a bottle image')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      final alcoholRepo = ref.read(alcoholRepositoryProvider);
      final user = FirebaseAuth.instance.currentUser;

      // 1. Upload Image
      final fileName = '${brandController.text}_${nameController.text}_${DateTime.now().millisecondsSinceEpoch}.jpg'
          .replaceAll(' ', '_');
      final imageUrl = await adminRepo.uploadBottleImage(selectedImage!, fileName);

      // 2. Prepare Model
      final alcohol = AlcoholModel(
        id: '', // Firestore will generate
        name: nameController.text.trim(),
        brand: brandController.text.trim(),
        type: selectedType,
        subType: subTypeController.text.trim().isNotEmpty ? subTypeController.text.trim() : null,
        abv: double.parse(abvController.text),
        origin: countryController.text.trim(),
        volumeMl: int.tryParse(volumeController.text),
        description: descriptionController.text.trim(),
        imageUrl: imageUrl,
        tags: tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        searchKeywords: _generateKeywords(),
        createdBy: user?.uid,
        createdAt: DateTime.now(),
        isVerified: true,
        isActive: true,
      );

      // 3. Save
      await alcoholRepo.createAlcohol(alcohol);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bottle added successfully!')),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _resetForm() {
    nameController.clear();
    brandController.clear();
    subTypeController.clear();
    countryController.clear();
    abvController.clear();
    volumeController.clear();
    descriptionController.clear();
    tagsController.clear();
    setState(() {
      selectedImage = null;
      selectedType = 'Whiskey';
    });
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Bottle Manager',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: customColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: customColors.borderDark),
                    image: selectedImage != null
                        ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.contain)
                        : null,
                  ),
                  child: selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Add Bottle Photo', style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField('Bottle Name', nameController, 'Enter name', customColors),
              _buildTextField('Brand', brandController, 'Enter brand', customColors),
              
              _buildDropdown('Type', customColors),
              
              _buildTextField('Subtype', subTypeController, 'e.g. Single Malt, IPA', customColors, isRequired: false),
              _buildTextField('Country', countryController, 'e.g. Scotland, USA', customColors),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('ABV %', abvController, 'e.g. 40.0', customColors, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Volume (ml)', volumeController, 'e.g. 750', customColors, keyboardType: TextInputType.number)),
                ],
              ),

              _buildTextField('Description', descriptionController, 'Enter description', customColors, maxLines: 4),
              _buildTextField('Tags', tagsController, 'smoke, peat, oak (comma separated)', customColors, isRequired: false),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveBottle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('SAVE BOTTLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    String hint, 
    AppCustomColors colors, {
    TextInputType keyboardType = TextInputType.text, 
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              if (!isRequired) 
                Text(' (OPTIONAL)', style: AppTextStyles.caption.copyWith(color: Colors.white24, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppTextStyles.body.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body.copyWith(color: Colors.white24),
              filled: true,
              fillColor: colors.cardBackground,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.amber, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'Required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, AppCustomColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderDark),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                dropdownColor: colors.cardBackground,
                style: AppTextStyles.body.copyWith(color: Colors.white),
                items: alcoholTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => selectedType = val!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
