import 'package:flutter/material.dart';

import 'cracker_barrel_game_page.dart';
import 'flappy_buddy_game_page.dart';
import 'widgets/mini_game_tile.dart';

class MiniGamesPage extends StatelessWidget {
  const MiniGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Games'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          MiniGameTile(
            title: 'Flappy Buddy',
            description:
                'Tap anywhere to keep the bird afloat. Dodge the care-pillars and chase a new high streak.',
            icon: Icons.flight_takeoff_outlined,
            destination: FlappyBuddyGamePage(),
          ),
          SizedBox(height: 16),
          MiniGameTile(
            title: 'Cracker Barrel Peg Puzzle',
            description:
                'Jump pegs over each other to clear the triangular board. Fewer pegs left means a sharper mind!',
            icon: Icons.extension_outlined,
            destination: CrackerBarrelGamePage(),
          ),
        ],
      ),
    );
  }
}
