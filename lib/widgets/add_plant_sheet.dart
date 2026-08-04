import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_colors.dart';
import '../providers/garden_provider.dart';
import '../services/image_service.dart';
import '../core/utils/error_utils.dart';
import 'app_card.dart';

class AddPlantSheet extends StatefulWidget {
  final GardenProvider provider;

  const AddPlantSheet({super.key, required this.provider});

  @override
  State<AddPlantSheet> createState() => _AddPlantSheetState();
}

class _AddPlantSheetState extends State<AddPlantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();
  final _scientificNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _waterFreq = 7;
  int _fertFreq = 30;
  int _initialHealth = 100;
  XFile? _pickedImageFile;
  String _currentImagePath = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _speciesCtrl.dispose();
    _scientificNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
    );
  }

  Widget _buildImageSourceOption(BuildContext context, IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurface, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AppCard(
        borderRadius: 30,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Add New Plant',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
  
                // Image Picker Box
                GestureDetector(
                  onTap: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: context,
                      backgroundColor: AppColors.surfaceElevated,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (context) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildImageSourceOption(context, Icons.camera_alt_rounded, 'Camera', ImageSource.camera),
                            _buildImageSourceOption(context, Icons.photo_library_rounded, 'Gallery', ImageSource.gallery),
                          ],
                        ),
                      ),
                    );
  
                    if (source != null) {
                      final picker = ImagePicker();
                      final img = await picker.pickImage(source: source);
                      if (img != null) {
                        setState(() {
                          _pickedImageFile = img;
                          _currentImagePath = img.path;
                        });
                      }
                    }
                  },
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                    ),
                    child: _currentImagePath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: kIsWeb
                                ? Image.network(_currentImagePath, fit: BoxFit.cover)
                                : Image.file(File(_currentImagePath), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGreen.withValues(alpha: 0.5), size: 36),
                              const SizedBox(height: 8),
                              Text('Upload Plant Photo', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
  
                // Nickname
                const Text('Nickname', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a nickname.';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(context, 'e.g. Ferny', Icons.tag_rounded),
                ),
                const SizedBox(height: 16),
  
                // Species
                const Text('Species / Variety', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _speciesCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the plant species.';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(context, 'e.g. Boston Fern', Icons.yard_rounded),
                ),
                const SizedBox(height: 16),

                // Scientific Name (Optional)
                const Text('Scientific Name (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _scientificNameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: _buildInputDecoration(context, 'e.g. Nephrolepis exaltata', Icons.science_rounded),
                ),
                const SizedBox(height: 16),
  
                // Water & Fertilize Frequency in row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Watering Interval', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _waterFreq,
                            isExpanded: true,
                            dropdownColor: AppColors.surfaceElevated,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _buildInputDecoration(context, '', Icons.water_drop_rounded).copyWith(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            ),
                            items: List.generate(30, (i) => i + 1).map((days) {
                              return DropdownMenuItem<int>(
                                value: days,
                                child: Text('$days day${days > 1 ? "s" : ""}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _waterFreq = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fertilizing Interval', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _fertFreq,
                            isExpanded: true,
                            dropdownColor: AppColors.surfaceElevated,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _buildInputDecoration(context, '', Icons.science_rounded).copyWith(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            ),
                            items: [7, 14, 30, 60, 90].map((days) {
                              return DropdownMenuItem<int>(
                                value: days,
                                child: Text('$days days'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _fertFreq = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
  
                // Initial Health Score (from user feedback 8)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Initial Health Score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60)),
                        Text('$_initialHealth%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _initialHealth >= 70 ? AppTheme.primaryGreen : _initialHealth >= 40 ? AppTheme.accentAmber : AppTheme.dangerRed)),
                      ],
                    ),
                    Slider(
                      value: _initialHealth.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 10,
                      activeColor: AppTheme.primaryGreen,
                      inactiveColor: Colors.white12,
                      onChanged: (val) {
                        setState(() {
                          _initialHealth = val.round();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
  
                // Notes
                const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  decoration: _buildInputDecoration(context, 'Location, quirks, history...', Icons.assignment_rounded),
                ),
                const SizedBox(height: 24),
  
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                          setState(() => _isSaving = true);
                          try {
                            String finalImagePath = '';
                            if (_pickedImageFile != null) {
                              if (!kIsWeb) {
                                final bytes = await _pickedImageFile!.readAsBytes();
                                final savedPath = await ImageService.saveImageLocally(bytes, _pickedImageFile!.name);
                                finalImagePath = savedPath;
                              } else {
                                finalImagePath = _pickedImageFile!.path;
                              }
                            }

                            await widget.provider.addPlant(
                              nickname: _nameCtrl.text.trim(),
                              species: _speciesCtrl.text.trim(),
                              scientificName: _scientificNameCtrl.text.trim().isNotEmpty
                                  ? _scientificNameCtrl.text.trim()
                                  : '${_speciesCtrl.text.trim()} sp.',
                              imagePath: finalImagePath,
                              wateringFrequencyDays: _waterFreq,
                              fertilizingFrequencyDays: _fertFreq,
                              notes: _notesCtrl.text.trim(),
                              healthScore: _initialHealth,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🌱 ${_nameCtrl.text.trim()} added to your garden.'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppErrorUtils.getUserFriendlyMessage(e, defaultPrefix: 'Could not add plant')),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isSaving = false);
                            }
                          }
                        },
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.add_rounded, size: 20),
                  label: Text(_isSaving ? 'Saving...' : 'Plant It! 🌱', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
         ),
        ),
      ),
    );
  }
}
