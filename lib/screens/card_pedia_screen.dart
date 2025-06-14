import 'package:anigame/widgets/star_display_widget.dart';
import 'package:flutter/material.dart';
import '../card_model.dart' as app_card;
import '../elemental_system.dart'; // Import CardType
import 'pedia_card_detail_screen.dart'; // Import the new PediaCardDetailScreen
import '../talent_system.dart'; // Import TalentType
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold
import '../data/card_definitions.dart';

class CardPediaScreen extends StatefulWidget {
  const CardPediaScreen({super.key});

  @override
  State<CardPediaScreen> createState() => _CardPediaScreenState();
}

class _CardPediaScreenState extends State<CardPediaScreen> {
  String _searchQuery = "";
  TalentType? _selectedTalentFilter; // Changed from CardRarity to TalentType
  CardType? _selectedTypeFilter; // Use CardType directly
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
     List<app_card.Card> filteredCards = CardDefinitions.availableCards.where((card) {
      final nameMatches = card.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final talentMatches = _selectedTalentFilter == null || card.talent?.type == _selectedTalentFilter; // Changed to filter by talent
      final typeMatches = _selectedTypeFilter == null || card.type == _selectedTypeFilter; // Use _selectedTypeFilter directly
      return nameMatches && talentMatches && typeMatches;
    }).toList();

    return ThemedScaffold( // Use ThemedScaffold
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 20.0, // Smaller icon
          padding: const EdgeInsets.all(5.0), // Reduced padding
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Card Pedia'),
        toolbarHeight: 30, // Set the AppBar height to 30
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cards by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TalentType?>( // Changed to TalentType
                    decoration: InputDecoration(
                      labelText: 'Talent', // Changed label
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedTalentFilter,
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All Talents")), // Changed default text
                      ...TalentType.values.map((talent) { // Iterate over TalentType
                        return DropdownMenuItem(
                          value: talent,
                          child: Text(talent.toString().split('.').last.replaceAll('_', ' ')),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTalentFilter = value;
                      });
                    },
                  ),
                ),
                 const SizedBox(width: 10),
                 Expanded(
                   child: DropdownButtonFormField<CardType?>( // Use CardType directly
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedTypeFilter,
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All Types")),
                      ...CardType.values.map((type) { // Use CardType directly
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTypeFilter = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredCards.isEmpty
                ? Center(child: Text(_searchQuery.isNotEmpty || _selectedTalentFilter != null || _selectedTypeFilter != null ? "No cards match your criteria." : "No cards available in Pedia."))
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // Adjust for screen size
                      childAspectRatio: 0.6, // Adjust for card proportions
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filteredCards.length,
                    itemBuilder: (context, index) {
                      final card = filteredCards[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PediaCardDetailScreen(card: card), // Navigate to PediaCardDetailScreen
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8), // Consistent with card shape
                        child: Card(
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          clipBehavior: Clip.antiAlias, // Important for Stack and rounded corners
                          child: _buildCardDisplaySmall(context, card), // Use a different small card display
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDisplaySmall(BuildContext context, app_card.Card card) {
    // Simplified display for Pedia (template info only)
    return Stack(
      children: [
        // Card Image
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _getRarityColor(card.rarity, context).withOpacity(0.85),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(7.0),
                bottomLeft: Radius.circular(7.0),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 3, offset: const Offset(1,1))]
            ),
            child: Text(
              card.rarity.toString().split('.').last.substring(0,1), // Display first letter of rarity
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
         Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.0), // Match card's inner rounding
            child: Image.asset(
              'assets/${card.imageUrl}',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported_outlined, size: 30, color: Colors.grey),
              ),
            ),
          ),
        ),
        // Gradient overlay for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7.0),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        // Card Name and Type
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                card.type.toString().split('.').last, // Display card type
                style: const TextStyle(fontSize: 9, color: Colors.white70, shadows: [Shadow(blurRadius: 1, color: Colors.black38)]),
              ),
            ],
          ),
        ),
        // Star Display (Top-Left or below name)
        Positioned(
          top: 4,
          left: 4,
          child: StarDisplayWidget(
            ascensionLevel: card.ascensionLevel,
            rarity: card.rarity,
            starSize: 8, // Small stars for rarity tier
          ),
        ),
      ],
    );
  }

  Color _getRarityColor(app_card.CardRarity rarity, BuildContext context) {
    switch (rarity) {
      case app_card.CardRarity.COMMON: return Colors.grey.shade600;
      case app_card.CardRarity.UNCOMMON: return Colors.green.shade600;
      case app_card.CardRarity.RARE: return Colors.blue.shade600;
      case app_card.CardRarity.SUPER_RARE: return Colors.purple.shade600;
      case app_card.CardRarity.ULTRA_RARE: return Colors.orange.shade700;
      default: return Colors.grey; // Should not happen
    }
  }

   @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
