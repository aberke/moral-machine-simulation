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


Drawer drawer;
Universe universe;
boolean showBuilding = true;
boolean showBackground = false;
boolean showGlyphs = true;
boolean showNetwork = false;
boolean showAgent = true;
boolean showZombie = false;


void settings() {
  fullScreen(P3D, SPAN);
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
    showBuilding= !showBuilding;
  break;
  case ' ':
   showBackground=!showBackground;
  break;
  case 'g':
    showGlyphs = !showGlyphs;
    break;
  case 'n':
    showNetwork = !showNetwork;
    break;
  case 'z':
    showZombie=!showZombie;
    break;
  }
}
