/* Main file for agent based model simulation.
*/

float SCALE = 0.5;
public final int SIMULATION_WIDTH = 2128;
public final int SIMULATION_HEIGHT = 1330;
public final int GRID_CELL_SIZE = int((SIMULATION_WIDTH/16)*SCALE);
public final int BUILDING_SIZE = int((SIMULATION_WIDTH/16)*SCALE*2);

public int DISPLAY_WIDTH = int(SIMULATION_WIDTH * SCALE);
public int DISPLAY_HEIGHT = int(SIMULATION_HEIGHT * SCALE);

public final String BLOCKS_DATA_FILEPATH = "data/blocks.csv";

public boolean INIT_AGENTS_FROM_DATAFILE = true;
public final String SIMULATED_POPULATION_DATA_FILEPATH = "data/simPop.csv";
public final int NUM_AGENTS_PER_WORLD = 1000;


// There are two worlds that are simulated.
// One world is where autonomous vehicles are privately owned and operated.
// The other world is where autonomous vehicles are publicly shared.
public final int PRIVATE_AVS_WORLD_ID = 1;
public final int PUBLIC_AVS_WORLD_ID = 2;
// The simulation can toggle between these 2 worlds.
public int WORLD = PRIVATE_AVS_WORLD_ID; // Initialize universe with world of private AVs.


Drawer drawer;
Universe universe;

// Debug variables that can be toggled with key presses:
boolean buildingDebug = false;
boolean showBackground = false;
boolean showGlyphs = true;
boolean showNetwork = false;
boolean showAgent = true;
boolean showZombie = false;


void settings() {
  size(DISPLAY_WIDTH, DISPLAY_HEIGHT, P3D);
  // fullScreen(P3D, SPAN);
}

void setup() {
  drawer = new Drawer(this);
  universe = new Universe();
  universe.InitUniverse();
  frameRate(30);
} 

void draw() {
  background(0);
  universe.updateGraphics();
  drawer.drawSurface();
}

void keyPressed() {
  switch(key) {
  case 'b':
    buildingDebug =! buildingDebug;
  break;
  case ' ':
   showBackground =! showBackground;
  break;
  case 'g':
    showGlyphs =! showGlyphs;
    break;
  case 'n':
    showNetwork =! showNetwork;
    break;
  case 'z':
    showZombie =! showZombie;
    break;
  case 'w':
    toggleWorld();
    break;
  }
}

void toggleWorld() {
  if (WORLD == PUBLIC_AVS_WORLD_ID) {
    WORLD = PRIVATE_AVS_WORLD_ID;
  } else {
    WORLD = PUBLIC_AVS_WORLD_ID;
  }
}

