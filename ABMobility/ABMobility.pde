/* Main file for agent based model simulation.
*/

float SCALE = 0.6;
public final int SIMULATION_WIDTH = 2128;
public final int SIMULATION_HEIGHT = 1330;

public int DISPLAY_WIDTH = int(SIMULATION_WIDTH * SCALE);
public int DISPLAY_HEIGHT = int(SIMULATION_HEIGHT * SCALE);

public final int GRID_CELL_SIZE = int(DISPLAY_WIDTH/16);
public final int BUILDING_SIZE = GRID_CELL_SIZE*2;

public final String BLOCKS_DATA_FILEPATH = "data/blocks.csv";

public boolean INIT_AGENTS_FROM_DATAFILE = true;
public final String SIMULATED_POPULATION_DATA_FILEPATH = "data/simPop.csv";
public final int NUM_AGENTS_PER_WORLD = 800;


// There are two worlds that are simulated.
// One world is where autonomous vehicles are privately owned and operated.
// The other world is where autonomous vehicles are publicly shared.
public final int PRIVATE_AVS_WORLD_ID = 1;
public final int PUBLIC_AVS_WORLD_ID = 2;
// The simulation can toggle between these 2 worlds.
public int WORLD_ID = PRIVATE_AVS_WORLD_ID; // Initialize universe with world of private AVs.

// Constants to name mobility types:
public final String CAR = "CAR";
public final String BIKE = "BIKE";
public final String PED = "PED";  // (Pedestrian)


Drawer drawer;
Universe universe;

// Debug variables that can be toggled with key presses:
boolean pause = false;
boolean buildingDebug = false;
boolean showBackground = false;
boolean showGlyphs = true;
boolean showNetwork = false;
boolean debugOffGridTravel = false;
boolean debugGridBufferArea = false;


void settings() {
  size(DISPLAY_WIDTH, DISPLAY_HEIGHT, P3D);
  // fullScreen(P3D, SPAN);
}

void setup() {
  surface.setResizable(true);
  frameRate(30);
  drawer = new Drawer(this);
  universe = new Universe();
  universe.InitUniverse();
} 

void draw() {
  background(0);
  universe.updateGraphics();
  drawer.drawSurface();
}

void keyPressed() {
  switch(key) {
  case 'p':
    pause =! pause;
    break;
  case 'b':
    buildingDebug =! buildingDebug;
    break;
  case 'u':
    debugGridBufferArea =! debugGridBufferArea;
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
  // highlight agents traveling on/off grid
  case 'z':
    debugOffGridTravel =! debugOffGridTravel;
    break;
  case 'w':
    toggleWorld();
    break;
  }
}

void toggleWorld() {
  if (WORLD_ID == PUBLIC_AVS_WORLD_ID) {
    WORLD_ID = PRIVATE_AVS_WORLD_ID;
  } else {
    WORLD_ID = PUBLIC_AVS_WORLD_ID;
  }
}

