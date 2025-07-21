import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Assuming Riverpod is used in your project
import 'package:letmegoo/constants/app_theme.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // For YouTube video embedding
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For social media icons
import 'package:url_launcher/url_launcher.dart'; // Import for external link launching

// --- Profile Page Implementation ---
// This is the main widget for the About Us page.
class AboutUsPage extends ConsumerStatefulWidget {
  const AboutUsPage({super.key});

  @override
  ConsumerState<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends ConsumerState<AboutUsPage> {
  final ScrollController _scrollController =
      ScrollController(); // Controller for the scrollable content
  late YoutubePlayerController
  _youtubeController; // Controller for the YouTube video player

  // The main descriptive content for the About Us page.
  final String profileContent =
      """LetMeGoo is a pioneering utility application developed by Trivandrum Technopark based IT company Richinnovations, designed to transform how urban communities handle parking-related challenges. Born from the simple yet powerful belief that "something is better than nothing," our platform creates a digital bridge between vehicle owners, enabling seamless communication when parking assistance is needed. Through voluntary registration, users become part of a cooperative network where blocked driveways, inaccessible parking spaces, and vehicle-related inconveniences can be resolved through direct, respectful communication rather than frustration and conflict.
Our privacy-first approach ensures users maintain complete control over their personal information, with granular settings that allow them to share only what they're comfortable with—from full contact details to anonymous notifications. Located in the heart of Kerala's technology hub at Technopark, Trivandrum, we combine innovative mobile technology with community-driven solutions to make urban parking more harmonious and efficient. LetMeGoo operates on the principle that when neighbors help neighbors, entire communities benefit, creating not just a parking solution, but a platform for urban cooperation and mutual assistance.""";

  // The YouTube video ID for embedding.
  final String youtubeVideoId = 'xRq85LjD-yI';

  // A list of social media links, each with a name, URL, and corresponding Font Awesome icon.
  final List<Map<String, dynamic>> socialMediaLinks = [
    {
      'name': 'Instagram',
      'url': 'https://www.instagram.com/letmegooapp/',
      'icon': FontAwesomeIcons.instagram,
    },
    {
      'name': 'Facebook',
      'url': 'https://www.facebook.com/letmegooapp/',
      'icon': FontAwesomeIcons.facebookF,
    },
    {
      'name': 'X (Twitter)',
      'url': 'https://x.com/LetMeGooApp',
      'icon': FontAwesomeIcons.xTwitter,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the YouTube player controller with the video ID and specific flags.
    _youtubeController = YoutubePlayerController(
      initialVideoId: youtubeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false, // Video will not autoplay
        mute: false, // Video will not be muted initially
        disableDragSeek: false, // Allows seeking by dragging the progress bar
        loop: false, // Video will not loop
        isLive: false, // Not a live stream
        forceHD: false, // Does not force HD quality
        enableCaption: true, // Enables captions if available
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
        .dispose(); // Dispose the scroll controller to prevent memory leaks
    _youtubeController.dispose(); // Dispose the YouTube controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design calculations.
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Determine if the screen is a tablet or a large screen based on width.
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return Scaffold(
      backgroundColor:
          AppColors.background, // Set the background color of the scaffold
      appBar: AppBar(
        backgroundColor:
            AppColors
                .background, // AppBar background matches the page background
        elevation: 0, // No shadow under the app bar
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios, // Back arrow icon
            color: AppColors.textPrimary, // Icon color
            size:
                screenWidth *
                (isLargeScreen
                    ? 0.025
                    : isTablet
                    ? 0.035
                    : 0.06), // Responsive icon size
          ),
          onPressed:
              () =>
                  Navigator.pop(context), // Pop the current route when pressed
        ),
        title: Text(
          "About Us", // Title of the page
          style: AppFonts.bold20().copyWith(
            fontSize:
                screenWidth *
                (isLargeScreen
                    ? 0.022
                    : isTablet
                    ? 0.032
                    : 0.05), // Responsive font size
            color: AppColors.textPrimary, // Text color
            fontWeight: FontWeight.w600, // Font weight
          ),
        ),
        centerTitle: true, // Center the title in the app bar
      ),
      body: SingleChildScrollView(
        controller: _scrollController, // Attach the scroll controller
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
        ), // Horizontal padding for the content
        child: Center(
          // Centers the content on larger screens
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  isLargeScreen
                      ? 800
                      : double
                          .infinity, // Max width for content on large screens
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start, // Align children to the start (left)
              children: [
                SizedBox(height: screenHeight * 0.02), // Vertical spacing
                // Header Card for "About LetMeGoo"
                Container(
                  width: double.infinity, // Takes full width available
                  decoration: BoxDecoration(
                    color: AppColors.white, // White background for the card
                    borderRadius: BorderRadius.circular(16), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.06,
                        ), // Shadow color with opacity
                        blurRadius: 12, // Blur radius for the shadow
                        offset: const Offset(0, 4), // Shadow offset (x, y)
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(
                    screenWidth * 0.04,
                  ), // Padding inside the card
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          screenWidth * 0.03,
                        ), // Padding for the icon container
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(
                            0.1,
                          ), // Light primary color background
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // Rounded corners for icon container
                        ),
                        child: Icon(
                          Icons.info_outline, // Info icon for "About Us"
                          color: AppColors.primary, // Icon color
                          size:
                              screenWidth *
                              (isLargeScreen
                                  ? 0.03
                                  : isTablet
                                  ? 0.04
                                  : 0.06), // Responsive icon size
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03), // Horizontal spacing
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start, // Align text to the start (left)
                          children: [
                            Text(
                              "About LetMeGoo", // Main title in the header card
                              style: AppFonts.bold20().copyWith(
                                fontSize:
                                    screenWidth *
                                    (isLargeScreen
                                        ? 0.02
                                        : isTablet
                                        ? 0.03
                                        : 0.045),
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4), // Small vertical spacing
                            Text(
                              "Pioneering Urban Parking Solutions", // Subtitle in the header card
                              style: AppFonts.regular14().copyWith(
                                fontSize:
                                    screenWidth *
                                    (isLargeScreen
                                        ? 0.014
                                        : isTablet
                                        ? 0.02
                                        : 0.032),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.025), // Vertical spacing
                // "Our Mission" Section
                _buildSection(
                  context,
                  "Our Mission", // Title for this section
                  profileContent, // Content for this section
                  screenWidth,
                  isTablet,
                  isLargeScreen,
                ),

                // YouTube Video Section
                _buildSectionContainer(
                  context,
                  screenWidth,
                  isTablet,
                  isLargeScreen,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Watch Our Video", // Title for the video section
                        style: AppFonts.semiBold18().copyWith(
                          fontSize:
                              screenWidth *
                              (isLargeScreen
                                  ? 0.018
                                  : isTablet
                                  ? 0.028
                                  : 0.042),
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.03), // Vertical spacing
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Rounded corners for the video player
                        child: YoutubePlayer(
                          controller:
                              _youtubeController, // Assign the YouTube controller
                          showVideoProgressIndicator:
                              true, // Show video progress indicator
                          progressIndicatorColor:
                              AppColors
                                  .primary, // Color of the progress indicator
                          progressColors: const ProgressBarColors(
                            playedColor:
                                AppColors
                                    .primary, // Color of the played portion
                            handleColor:
                                AppColors
                                    .primary, // Color of the scrubber handle
                          ),
                          onReady: () {
                            // Callback when the player is ready to play.
                            // You can add logging or other actions here.
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Social Media Section
                _buildSectionContainer(
                  context,
                  screenWidth,
                  isTablet,
                  isLargeScreen,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Connect With Us", // Title for the social media section
                        style: AppFonts.semiBold18().copyWith(
                          fontSize:
                              screenWidth *
                              (isLargeScreen
                                  ? 0.018
                                  : isTablet
                                  ? 0.028
                                  : 0.042),
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.03), // Vertical spacing
                      Wrap(
                        // `Wrap` widget allows buttons to wrap to the next line if space is insufficient
                        spacing:
                            screenWidth *
                            0.02, // Horizontal spacing between buttons
                        runSpacing:
                            screenWidth *
                            0.02, // Vertical spacing between lines of buttons
                        children:
                            socialMediaLinks.map((link) {
                              return _buildSocialMediaButton(
                                // Build each social media button
                                context,
                                link['name'],
                                link['url'],
                                link['icon'],
                                screenWidth,
                                isLargeScreen,
                                isTablet,
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),

                // Footer/Call to Action Card
                Container(
                  width: double.infinity, // Takes full width
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(
                      0.05,
                    ), // Light primary color background
                    borderRadius: BorderRadius.circular(16), // Rounded corners
                    border: Border.all(
                      color: AppColors.primary.withOpacity(
                        0.2,
                      ), // Border with primary color
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.all(
                    screenWidth * 0.04,
                  ), // Padding inside the card
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline, // Info icon
                            color: AppColors.primary, // Icon color
                            size:
                                screenWidth *
                                (isLargeScreen
                                    ? 0.025
                                    : isTablet
                                    ? 0.035
                                    : 0.05), // Responsive icon size
                          ),
                          SizedBox(
                            width: screenWidth * 0.02,
                          ), // Horizontal spacing
                          Text(
                            "Discover More", // Title for the footer card
                            style: AppFonts.semiBold16().copyWith(
                              fontSize:
                                  screenWidth *
                                  (isLargeScreen
                                      ? 0.018
                                      : isTablet
                                      ? 0.028
                                      : 0.04),
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.03), // Vertical spacing
                      Text(
                        "Discover more about LetMeGoo and our mission to simplify urban parking.", // Content for the footer card
                        style: AppFonts.regular14().copyWith(
                          fontSize:
                              screenWidth *
                              (isLargeScreen
                                  ? 0.015
                                  : isTablet
                                  ? 0.022
                                  : 0.035),
                          color: AppColors.textPrimary,
                          height: 1.5, // Line height
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.04), // Bottom spacing
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build a generic section with consistent styling (white card with shadow).
  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    double screenWidth,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.02,
      ), // Bottom margin
      decoration: BoxDecoration(
        color: AppColors.white, // White background
        borderRadius: BorderRadius.circular(16), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.04), // Padding inside the section
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align children to the start
        children: [
          Text(
            title, // Section title
            style: AppFonts.semiBold18().copyWith(
              fontSize:
                  screenWidth *
                  (isLargeScreen
                      ? 0.018
                      : isTablet
                      ? 0.028
                      : 0.042),
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenWidth * 0.03), // Vertical spacing
          Text(
            content, // Section content
            style: AppFonts.regular14().copyWith(
              fontSize:
                  screenWidth *
                  (isLargeScreen
                      ? 0.015
                      : isTablet
                      ? 0.022
                      : 0.035),
              color: AppColors.textSecondary,
              height: 1.6, // Line height for readability
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a container for sections like video and social media, with consistent styling.
  Widget _buildSectionContainer(
    BuildContext context,
    double screenWidth,
    bool isTablet,
    bool isLargeScreen,
    Widget child, // The actual content of the section
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.02,
      ), // Bottom margin
      decoration: BoxDecoration(
        color: AppColors.white, // White background
        borderRadius: BorderRadius.circular(16), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(
        screenWidth * 0.04,
      ), // Padding inside the container
      child: child, // Render the passed child widget
    );
  }

  // Helper method to build a social media button with responsive styling and external linking.
  Widget _buildSocialMediaButton(
    BuildContext context,
    String name,
    String url,
    IconData icon,
    double screenWidth,
    bool isLargeScreen,
    bool isTablet,
  ) {
    return InkWell(
      onTap: () async {
        // `onTap` is asynchronous because `canLaunchUrl` and `launchUrl` are async
        final uri = Uri.parse(url); // Parse the URL string into a Uri object
        if (await canLaunchUrl(uri)) {
          // Check if the URL can be opened by the device
          await launchUrl(uri); // Launch the URL
        } else {
          // If the URL cannot be launched, show a SnackBar notification to the user.
          print('Could not launch $url'); // Log the error to the console
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $url'),
            ), // Display a message to the user
          );
        }
      },
      borderRadius: BorderRadius.circular(
        20,
      ), // Rounded corners for the InkWell's splash effect
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal:
              screenWidth *
              (isLargeScreen
                  ? 0.02
                  : isTablet
                  ? 0.03
                  : 0.04), // Responsive horizontal padding
          vertical:
              screenWidth *
              (isLargeScreen
                  ? 0.01
                  : isTablet
                  ? 0.015
                  : 0.02), // Responsive vertical padding
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(
            0.1,
          ), // Light primary color background for the button
          borderRadius: BorderRadius.circular(
            20,
          ), // Rounded corners for the button container
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
          ), // Border with primary color
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Make the row take minimum space
          children: [
            FaIcon(
              icon, // Font Awesome icon
              color: AppColors.primary, // Icon color
              size:
                  screenWidth *
                  (isLargeScreen
                      ? 0.015
                      : isTablet
                      ? 0.025
                      : 0.04), // Responsive icon size
            ),
            SizedBox(
              width: screenWidth * 0.015,
            ), // Horizontal spacing between icon and text
            Text(
              name, // Social media platform name
              style: AppFonts.semiBold16().copyWith(
                fontSize:
                    screenWidth *
                    (isLargeScreen
                        ? 0.014
                        : isTablet
                        ? 0.02
                        : 0.032), // Responsive text size
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
