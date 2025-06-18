import 'package:flutter/material.dart';
import '../card_model.dart'
    as app_card; // Assuming CardRarity and Card are here

class FramedCardImageWidget extends StatelessWidget {
  final app_card.Card card; // Pass the whole card or just necessary fields
  final double width;
  final double height;
  final BoxFit fit;
  final Color? frameColorOverride;

  const FramedCardImageWidget({
    super.key,
    required this.card,
    this.width = 70, // Default width
    this.height = 90, // Default height
    this.fit = BoxFit.cover,
    this.frameColorOverride,
  });

  @override
  Widget build(BuildContext context) {
    Color imageFrameColor;
    double imageFrameWidth = 1.5;

    if (frameColorOverride != null) {
      imageFrameColor = frameColorOverride!;
      imageFrameWidth = 2.0; // Default active frame width
    } else {
      switch (card.rarity) {
        case app_card.CardRarity.RARE:
          imageFrameColor = app_card.kRareColor;
          imageFrameWidth = 2.0;
          break;
        case app_card.CardRarity.SUPER_RARE:
          imageFrameColor = app_card.kSuperRareColor;
          imageFrameWidth = 2.5;
          break;
        case app_card.CardRarity.ULTRA_RARE:
          imageFrameColor = app_card.kUltraRareColor;
          imageFrameWidth = 3.0;
          break;
        default:
          imageFrameColor = Colors.transparent;
          imageFrameWidth = 0.0;
      }
    }

    // Add this print statement for debugging
    print(
      "FramedCardImageWidget: Displaying card '${card.name}', imageUrl: '${card.imageUrl}'",
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0), // Outer radius for the frame
        border: imageFrameWidth > 0
            ? Border.all(color: imageFrameColor, width: imageFrameWidth)
            : Border.all(
                color: Colors.transparent,
                width: 0,
              ), // Ensure a border object exists for consistent layout if no specific frame
        // boxShadow can be kept if you like the depth, or removed for a flatter look
      ),
      child: ClipRRect(
        // Inner ClipRRect to ensure image respects the frame's rounded corners
        // Adjust radius if frame is very thick to prevent image corners peeking
        borderRadius: BorderRadius.circular(
          10.0 - imageFrameWidth > 0 ? 10.0 - imageFrameWidth : 0,
        ),
        child: Image.asset(
          // Always prepend "assets/" to the stored imageUrl
          card.imageUrl.isNotEmpty
              ? "assets/${card.imageUrl}"
              : "assets/Themes/default_card_image.jpg",
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // Add this print to see the specific error for the image asset
            print(
              // Log the path that was attempted
              "FramedCardImageWidget: Image.asset FAILED for 'assets/${card.imageUrl}'. Error: $error",
            );
            return Image.asset(
              "assets/Themes/default_card_image.jpg", // Ensure fallback also has "assets/"
              fit: fit,
            ); // Fallback to your default JPG
          },
        ),
      ),
    );
  }
}
