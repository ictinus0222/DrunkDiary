import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/constants/reaction_config.dart';
import '../../../../../core/analytics/analytics_service.dart';
import '../../../../alcohol/models/alcohol_model.dart';
import '../../../../alcohol/screens/bottle_selection_screen.dart';
import '../../../../drink_logs/models/drink_model_dto.dart';
import '../../providers/onboarding_provider.dart';

class CameraLogStep extends ConsumerStatefulWidget {
  final bool isActive;
  final VoidCallback onLogMoment;
  final VoidCallback onNotDrinking;

  const CameraLogStep({
    super.key,
    required this.isActive,
    required this.onLogMoment,
    required this.onNotDrinking,
  });

  @override
  ConsumerState<CameraLogStep> createState() => _CameraLogStepState();
}

class _CameraLogStepState extends ConsumerState<CameraLogStep>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  // 3D Flip Card Animation
  bool _isFlipped = false;
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;

  // Camera shutter flash effect
  bool _showFlash = false;



  // Draft Log State variables
  AlcoholModel? _selectedBottle;
  String? _customDrinkName;
  DrinkReaction? _reaction;
  bool _isNotDrinkingFlow = false;
  double _rating = 3.5;
  final TextEditingController _noteController = TextEditingController();

  // Gentle floating animation for the polaroid front
  late final AnimationController _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  late final Animation<double> _floatY = Tween<double>(begin: -6, end: 6)
      .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

  late final Animation<double> _floatRotate =
      Tween<double>(begin: -0.018, end: 0.018)
          .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      _initCamera();
    }

    // Setup Flip Card Animation
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CameraLogStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposeCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_controller != null) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _hasError = true);
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _disposeCamera({bool isDisposing = false}) {
    if (!isDisposing) {
      setState(() {
        _isInitialized = false;
      });
    } else {
      _isInitialized = false;
    }
    _controller?.dispose();
    _controller = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) return;
    final controller = _controller;
    if (state == AppLifecycleState.inactive) {
      if (controller != null) {
        _disposeCamera();
      }
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _floatCtrl.dispose();
    _flipCtrl.dispose();

    _disposeCamera(isDisposing: true);
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      // Trigger flash
      setState(() => _showFlash = true);
      await Future.delayed(const Duration(milliseconds: 80));

      final file = await controller.takePicture();

      // Copy photo to application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final targetPath =
          '${appDir.path}/first_log_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(file.path).copy(targetPath);

      // Track analytics: check if this is an overwrite
      final currentDraftPath = ref.read(onboardingProvider).firstLogPhotoPath;
      if (currentDraftPath != null) {
        await ref
            .read(analyticsServiceProvider)
            .logEvent(name: 'first_log_overwritten');
      } else {
        await ref
            .read(analyticsServiceProvider)
            .logEvent(name: 'first_log_created');
      }

      // Save the draft locally
      await ref
          .read(onboardingProvider.notifier)
          .saveFirstLogDraft(photoPath: targetPath);

      setState(() {
        _showFlash = false;
        _isFlipped = true;
      });

      _flipCtrl.forward();
    } catch (e) {
      setState(() => _showFlash = false);
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _selectDrink() async {
    final result = await Navigator.push<AlcoholModel>(
      context,
      MaterialPageRoute(builder: (_) => const BottleSelectionScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedBottle = result;
        _customDrinkName = result.id.isEmpty ? result.name : null;
      });
    }
  }

  void _onDone() {
    // Save details to Riverpod provider
    if (_isNotDrinkingFlow) {
      ref.read(onboardingProvider.notifier).updateFirstLogDetails(
            alcoholName: _selectedBottle?.name ?? _customDrinkName ?? 'Custom Drink',
            alcoholId: _selectedBottle?.id.isEmpty == true ? null : _selectedBottle?.id,
            alcoholType: _selectedBottle?.type ?? 'Custom',
            isCustom: _selectedBottle == null || _selectedBottle!.id.isEmpty,
            rating: _rating,
            logKind: LogKind.review,
            note: _noteController.text,
          );
      widget.onNotDrinking();
    } else {
      ref.read(onboardingProvider.notifier).updateFirstLogDetails(
            alcoholName: _selectedBottle?.name ?? _customDrinkName ?? 'Custom Drink',
            alcoholId: _selectedBottle?.id.isEmpty == true ? null : _selectedBottle?.id,
            alcoholType: _selectedBottle?.type ?? 'Custom',
            isCustom: _selectedBottle == null || _selectedBottle!.id.isEmpty,
            reaction: _reaction ?? DrinkReaction.liked,
            logKind: LogKind.log,
            note: _noteController.text,
          );
      widget.onLogMoment();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final photoPath = state.firstLogPhotoPath;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Foreground content ────────────────────────────────────────────
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── Polaroid 3D Flip Card Container ───────────────────────────
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _floatCtrl,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _floatY.value),
                        child: Transform.rotate(
                          angle: _floatRotate.value,
                          child: child,
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: _flipAnim,
                        builder: (context, child) {
                          final rotationValue = _flipAnim.value;
                          final angle = rotationValue * pi;
                          final isBack = rotationValue > 0.5;

                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // perspective
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: isBack
                                ? Transform(
                                    transform: Matrix4.identity()..rotateY(pi),
                                    alignment: Alignment.center,
                                    child: _PolaroidBack(
                                      photoPath: photoPath ?? '',
                                      onSelectDrink: _selectDrink,
                                      selectedDrinkName: _selectedBottle?.name ?? _customDrinkName,
                                      reaction: _reaction,
                                      onReactionChanged: (reaction) {
                                        setState(() => _reaction = reaction);
                                      },
                                      isNotDrinkingFlow: _isNotDrinkingFlow,
                                      rating: _rating,
                                      onRatingChanged: (val) {
                                        setState(() => _rating = val);
                                      },
                                      onBack: () {
                                        setState(() {
                                          _selectedBottle = null;
                                          _customDrinkName = null;
                                          _isNotDrinkingFlow = true;
                                          _isFlipped = false;
                                          _reaction = null;
                                        });
                                        _flipCtrl.reverse();
                                      },
                                      noteController: _noteController,
                                      onDone: _onDone,
                                    ),
                                  )
                                : _Polaroid(
                                    controller: _isInitialized ? _controller : null,
                                    hasError: _hasError,
                                    showFlash: _showFlash,
                                    isNotDrinkingFlow: _isNotDrinkingFlow,
                                    onChooseDrink: () async {
                                      final result = await Navigator.push<AlcoholModel>(
                                        context,
                                        MaterialPageRoute(builder: (_) => const BottleSelectionScreen()),
                                      );
                                      if (result != null) {
                                        setState(() {
                                          _selectedBottle = result;
                                          _customDrinkName = result.id.isEmpty ? result.name : null;
                                          _isFlipped = true;
                                        });
                                        _flipCtrl.forward();
                                      }
                                    },
                                    onBackToCamera: () {
                                      setState(() {
                                        _isNotDrinkingFlow = false;
                                      });
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ── Copy & CTAs (Fades out when card is flipped) ─────────────
              AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Log the moment.',
                        style: AppTextStyles.section.copyWith(
                          fontSize: 36,
                          color: Colors.white,
                          height: 1.05,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Snap what you\'re drinking and build your shelf.',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white54,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _LogButton(onPressed: _takePicture),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isNotDrinkingFlow = true;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'I\'m not drinking right now',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white38,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white24,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                secondChild: const SizedBox(height: 0),
                crossFadeState: _isFlipped
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),




      ],
    );
  }
}

// ── Polaroid Front Card ────────────────────────────────────────────────────────
class _Polaroid extends StatelessWidget {
  final CameraController? controller;
  final bool hasError;
  final bool showFlash;
  final bool isNotDrinkingFlow;
  final VoidCallback? onChooseDrink;
  final VoidCallback? onBackToCamera;

  const _Polaroid({
    this.controller,
    required this.hasError,
    this.showFlash = false,
    this.isNotDrinkingFlow = false,
    this.onChooseDrink,
    this.onBackToCamera,
  });

  @override
  Widget build(BuildContext context) {
    const photoWidth = 308.0;
    const photoHeight = 368.0;
    const borderSize = 16.0;
    const bottomLabelHeight = 56.0;

    return Container(
      width: photoWidth + borderSize * 2,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                borderSize, borderSize, borderSize, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: photoWidth,
                height: photoHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: isNotDrinkingFlow
                          ? _NotDrinkingFront(
                              onChooseDrink: onChooseDrink!,
                              onBackToCamera: onBackToCamera!,
                            )
                          : (controller != null
                              ? _PolaroidPreview(controller: controller!)
                              : _PolaroidFallback(hasError: hasError)),
                    ),
                    if (showFlash)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: bottomLabelHeight,
            child: Center(
              child: Text(
                'drunk diary',
                style: TextStyle(
                  fontFamily: 'GiveYouGlory',
                  fontSize: 20,
                  color: Colors.amber.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolaroidPreview extends StatelessWidget {
  final CameraController controller;
  const _PolaroidPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    final displayW = previewSize?.height ?? 3.0;
    final displayH = previewSize?.width ?? 4.0;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: displayW,
        height: displayH,
        child: RepaintBoundary(child: CameraPreview(controller)),
      ),
    );
  }
}

class _PolaroidFallback extends StatelessWidget {
  final bool hasError;
  const _PolaroidFallback({required this.hasError});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: hasError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography_outlined,
                      size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    'Camera unavailable',
                    style: AppTextStyles.body
                        .copyWith(color: Colors.white30, fontSize: 13),
                  ),
                ],
              )
            : const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF444444)),
                strokeWidth: 1.5,
              ),
      ),
    );
  }
}

// ── Polaroid Back Details Form ──────────────────────────────────────────────
class _PolaroidBack extends StatefulWidget {
  final String photoPath;
  final VoidCallback onSelectDrink;
  final String? selectedDrinkName;
  final DrinkReaction? reaction;
  final ValueChanged<DrinkReaction> onReactionChanged;
  final bool isNotDrinkingFlow;
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final VoidCallback? onBack;
  final TextEditingController noteController;
  final VoidCallback onDone;

  const _PolaroidBack({
    required this.photoPath,
    required this.onSelectDrink,
    required this.selectedDrinkName,
    required this.reaction,
    required this.onReactionChanged,
    this.isNotDrinkingFlow = false,
    this.rating = 3.5,
    required this.onRatingChanged,
    this.onBack,
    required this.noteController,
    required this.onDone,
  });

  @override
  State<_PolaroidBack> createState() => _PolaroidBackState();
}

class _PolaroidBackState extends State<_PolaroidBack> {

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 440,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isNotDrinkingFlow && widget.onBack != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: widget.onBack,
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                ),
              Center(
                child: Text(
                  widget.isNotDrinkingFlow ? 'FAVORITE DRINK' : 'LOG DETAILS',
                  style: const TextStyle(
                    fontFamily: 'GiveYouGlory',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 1. Tappable Drink Field
          GestureDetector(
            onTap: widget.onSelectDrink,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF333333), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_bar, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.selectedDrinkName ?? 'Select Your Drink →',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.selectedDrinkName != null
                            ? Colors.white
                            : Colors.white38,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Reaction Selector / Star Slider
          if (widget.isNotDrinkingFlow) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1.0;
                    IconData icon;
                    Color color;

                    if (widget.rating >= starValue) {
                      icon = Icons.star_rounded;
                      color = Colors.amber;
                    } else if (widget.rating >= starValue - 0.5) {
                      icon = Icons.star_half_rounded;
                      color = Colors.amber;
                    } else {
                      icon = Icons.star_outline_rounded;
                      color = Colors.white24;
                    }

                    return Icon(icon, color: color, size: 28);
                  }),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '${widget.rating.toStringAsFixed(1)} / 5.0',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.amber,
                    inactiveTrackColor: const Color(0xFF0F0F0F),
                    thumbColor: Colors.amber,
                    overlayColor: Colors.amber.withValues(alpha: 0.15),
                    valueIndicatorColor: Colors.amber,
                    valueIndicatorTextStyle: const TextStyle(color: Colors.black),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: widget.rating,
                    min: 1.0,
                    max: 5.0,
                    divisions: 8,
                    label: widget.rating.toStringAsFixed(1),
                    onChanged: widget.onRatingChanged,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildReactionButton(DrinkReaction.loved, '😍 Loved It'),
                _buildReactionButton(DrinkReaction.liked, '🙂 Pretty Good'),
                _buildReactionButton(DrinkReaction.nah, '👎 Not For Me'),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // 3. Notes Field (always visible expanding TextField)
          Expanded(
            child: TextField(
              controller: widget.noteController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Add a note (optional)...',
                hintStyle: const TextStyle(color: Colors.white38),
                contentPadding: const EdgeInsets.all(12),
                fillColor: const Color(0xFF0F0F0F),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.amber, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Save Button
          ElevatedButton(
            onPressed: widget.onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: const Text(
              'Save & Continue',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(DrinkReaction reaction, String label) {
    final isSelected = widget.reaction == reaction;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onReactionChanged(reaction),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.amber.withValues(alpha: 0.15)
                : const Color(0xFF0F0F0F),
            border: Border.all(
              color: isSelected ? Colors.amber : const Color(0xFF333333),
              width: isSelected ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.amber : Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ── Shutter Button ─────────────────────────────────────────────────────────
class _LogButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _LogButton({required this.onPressed});

  @override
  State<_LogButton> createState() => _LogButtonState();
}

class _LogButtonState extends State<_LogButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.97).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 20),
              const SizedBox(width: 10),
              Text(
                'Log the Moment',
                style: AppTextStyles.body.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Not Drinking Context Card (Front Overlay) ─────────────────────────────────
class _NotDrinkingFront extends StatelessWidget {
  final VoidCallback onChooseDrink;
  final VoidCallback onBackToCamera;

  const _NotDrinkingFront({
    required this.onChooseDrink,
    required this.onBackToCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF151515),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_bar_rounded,
            color: Colors.amber,
            size: 56,
          ),
          const SizedBox(height: 12),
          const Text(
            'Favorite Drink',
            style: TextStyle(
              fontFamily: 'GiveYouGlory',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Not drinking right now? Tell us what your favorite alcohol is to build your shelf.",
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: Colors.white60,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onChooseDrink,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'Select Drink',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onBackToCamera,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Text(
                'Back to Camera',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: Colors.white38,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
