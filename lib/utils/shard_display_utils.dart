import 'package:flutter/material.dart';
import '../card_model.dart'; // For ShardType

IconData getShardIcon(ShardType shardType) {
  switch (shardType) {
    case ShardType.FIRE_SHARD:
      return Icons.whatshot;
    case ShardType.WATER_SHARD:
      return Icons.water_drop;
    case ShardType.GRASS_SHARD:
      return Icons.eco_outlined;
    case ShardType.GROUND_SHARD:
      return Icons.public_outlined;
    case ShardType.ELECTRIC_SHARD:
      return Icons.flash_on_outlined;
    case ShardType.NEUTRAL_SHARD:
      return Icons.radio_button_unchecked_outlined;
    case ShardType.LIGHT_SHARD:
      return Icons.lightbulb_outline;
    case ShardType.DARK_SHARD:
      return Icons.nightlight_round_outlined;
    default:
      return Icons.grain;
  }
}

Color getShardColor(ShardType shardType) {
  switch (shardType) {
    case ShardType.FIRE_SHARD:
      return Colors.red.shade700;
    case ShardType.WATER_SHARD:
      return Colors.blue.shade700;
    case ShardType.GRASS_SHARD:
      return Colors.green.shade700;
    case ShardType.GROUND_SHARD:
      return Colors.brown.shade600;
    case ShardType.ELECTRIC_SHARD:
      return Colors.yellow.shade800;
    case ShardType.NEUTRAL_SHARD:
      return Colors.grey.shade700;
    case ShardType.LIGHT_SHARD:
      return Colors.yellow.shade300;
    case ShardType.DARK_SHARD:
      return Colors.deepPurple.shade700;
    default:
      return Colors.grey.shade600;
  }
}
