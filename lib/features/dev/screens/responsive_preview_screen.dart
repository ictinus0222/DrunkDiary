import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/theme/responsive_tokens.dart';
import '../../../core/theme/app_typography_roles.dart';
import '../../../core/widgets/responsive_layout.dart';

class ResponsivePreviewScreen extends StatefulWidget {
  static const routeName = '/dev/responsive-preview';
  const ResponsivePreviewScreen({super.key});

  @override
  State<ResponsivePreviewScreen> createState() => _ResponsivePreviewScreenState();
}

class _ResponsivePreviewScreenState extends State<ResponsivePreviewScreen> {
  double _simulatedWidth = 400;
  bool _isSimulating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isSimulating) {
      _simulatedWidth = context.screenWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RESPONSIVE DESIGN SYSTEM'),
        centerTitle: true,
        actions: [
          Switch(
            value: _isSimulating,
            onChanged: (v) => setState(() => _isSimulating = v),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSimulating) _buildWidthSlider(),
          Expanded(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isSimulating ? _simulatedWidth : double.infinity,
                color: Colors.white.withValues(alpha: 0.02),
                child: _buildPreviewContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidthSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Width: ${_simulatedWidth.toInt()}px', style: const TextStyle(fontWeight: FontWeight.bold)),
              _buildBreakpointBadge(),
            ],
          ),
          Slider(
            min: 320,
            max: 1440,
            value: _simulatedWidth,
            onChanged: (v) => setState(() => _simulatedWidth = v),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakpointBadge() {
    String label = 'MOBILE';
    Color color = Colors.green;
    if (_simulatedWidth >= AppBreakpoints.tablet) {
      label = 'DESKTOP';
      color = Colors.blue;
    } else if (_simulatedWidth >= AppBreakpoints.mobile) {
      label = 'TABLET';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPreviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: ResponsiveConstrainedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('TYPOGRAPHY ROLES', [
              Text('AppBar Title', style: AppTypography.appBarTitle(context)),
              const SizedBox(height: 16),
              Text('Feed Title', style: AppTypography.feedTitle(context)),
              const SizedBox(height: 8),
              Text('Activity Metadata', style: AppTypography.activityMetadata(context)),
              const SizedBox(height: 16),
              Text('This is a review body. It should scale intentionally between platforms to ensure readability without being overwhelming.', 
                style: AppTypography.reviewBody(context)),
              const SizedBox(height: 8),
              Text('@username', style: AppTypography.profileUsername(context)),
            ]),
            
            const SizedBox(height: 48),
            
            _buildSection('SEMANTIC WIDTHS', [
              _buildWidthBar('Feed Max Width', AppWidths.feed, Colors.amber),
              _buildWidthBar('Profile Max Width', AppWidths.profile, Colors.blue),
              _buildWidthBar('Form Max Width', AppWidths.form, Colors.purple),
            ]),

            const SizedBox(height: 48),

            _buildSection('DENSITY VISUALIZER', [
              Text('Current Density: ${LayoutDensity.fromWidth(_isSimulating ? _simulatedWidth : context.screenWidth).name.toUpperCase()}', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: List.generate(3, (index) => Expanded(
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: const Center(child: Icon(Icons.wine_bar)),
                  ),
                )),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.sectionLabel(context)),
        const Divider(color: Colors.white12, height: 32),
        ...children,
      ],
    );
  }

  Widget _buildWidthBar(String label, double width, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label (${width.toInt()}px)', style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 4),
          Container(
            height: 12,
            width: width * 0.5, // Scale down for visualization
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
