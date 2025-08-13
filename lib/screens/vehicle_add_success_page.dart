import 'package:flutter/material.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/screens/add_vehicle_page.dart';
import 'package:letmegoo/screens/privacy_preferences_page.dart';
import 'package:letmegoo/utils/core_utils.dart';
import 'package:letmegoo/widgets/commonButton.dart';

class VehicleAddSuccessPage extends StatefulWidget {
  const VehicleAddSuccessPage({super.key});

  @override
  State<VehicleAddSuccessPage> createState() => _VehicleAddSuccessPageState();
}

class _VehicleAddSuccessPageState extends State<VehicleAddSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleUpDown;
  late Animation<Offset> _moveUp;

  bool _showTextAndButtons = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleUpDown = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _moveUp = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.1),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _controller.forward();
    setState(() {
      _showTextAndButtons = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Lock image popping animation
          Center(
            child: SlideTransition(
              position: _moveUp,
              child: ScaleTransition(
                scale: _scaleUpDown,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Image.asset(
                    AppImages.lock_popper,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Success text
          if (_showTextAndButtons)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.62,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Vehicle Added Successfully',
                  style: AppFonts.semiBold24(),
                ),
              ),
            ),

          // Buttons
          if (_showTextAndButtons)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CommonButton(
                      text: "Go to Next Step",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PrivacyPreferencesPage(
                                  currentPreference: 'private',
                                  isOnboarding:
                                      true, // This tells the page it's part of onboarding flow
                                  onPreferenceChanged: (newPreference) {
                                    // This callback will handle navigation to home after privacy setting is updated
                                    CoreUtil.goToHomePage(context);
                                  },
                                ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to AddVehicle page
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddVehiclePage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Add Another Vehicle',
                        style: TextStyle(
                          color: Color(0xFF31C5F4), // blue text
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(
                            0xFF31C5F4,
                          ), // make underline blue
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
