CHESS DUEL (Godot 4.3+)
1. Godot -> Import -> select project.godot (first import takes a few seconds for the models)
2. F5 to run.

MENU: Play / Stage < > / Black duel fighter: AI or Human / Quit.
	  The camera slowly orbits the floating island; Play glides down to the board.
BOARD: click a piece, click a square. Capturing starts a 2.5D duel. [T] toggles AI, [Esc] back to menu.

DUEL CONTROLS
 White: A/D move, W jump, S block, F attack, G special
 Black: Left/Right move, Up jump, Down block, ',' attack, '.' special

SPECIALS
 Pawn   Croc Soldier   - Spear Throw (straight projectile)
 Knight Monitor Knight - Monitor Charge (dash + knockback)
 Bishop Snake Wizard   - Fireball (hits + sets you on fire)
 Rook   Lizard Bomber  - Lizard Bomb (lobbed, area explosion)
 Queen  Snake God      - Divine Smite (marker, then lightning beam)
 King   Snake King     - Royal Quake (ground shockwave, jump over it)

STAGES (colours of sky, light, clouds, islands, board, duel arena)
 scripts/data.gd -> STAGES. Copy one entry, change the colours, done. 5 stages included.

SWAP THE CHESS BOARD YOURSELF (no code needed)
 Open scenes/board_visual.tscn in the Godot editor.
  - Drop your own board model (.glb / .tscn) under the "Model" node.
	While "Model" is empty the built-in island + frame is shown; once it has children, that is skipped.
  - Select the BoardVisual root and tune in the Inspector:
	  square_size  size of one square in your model's units
      surface_y    height of the playing surface
      piece_scale  makes the pieces bigger / smaller
      generate_tiles  turn OFF if your model already has its own squares
  - You can also move/rotate "Model" freely to line it up. The grid is 8x8 centred on the
    BoardVisual origin; White starts on the +Z side and plays toward -Z.
  - Click highlights are drawn as flat overlays, so they work on any board model.

TEAMS: White keeps the original colours, Black uses hue-shifted textures (*_b.png in assets/)
       plus a cyan / red ring under the feet.
ANIMATION (duel): idle breathing, walk hop, jump squash & stretch, wind-up + strike per piece,
       cast poses, charge lean, block crouch, hit-flash + recoil + hit-stop + screen shake, KO fall, victory hop.
