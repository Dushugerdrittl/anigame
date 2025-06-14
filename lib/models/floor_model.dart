// To potentially reference Card types or IDs

class Floor {
  final String id;
  final String name;
  final String description;
  final int numberOfLevels;
  final List<String> themedCardPoolIds; // List of Card IDs that can appear as enemies in this floor
  final int baseRewardPerLevel;
  final int rewardForFloorCompletion; // Extra reward for clearing all levels

  const Floor({
    required this.id,
    required this.name,
    required this.description,
    required this.numberOfLevels,
    required this.themedCardPoolIds,
    this.baseRewardPerLevel = 20,
    this.rewardForFloorCompletion = 100,
  });
}