
public class World {
  PGraphics pg;
  HashMap<String,Integer> colorMapColorful;
  HashMap<String,Integer> colorMapBW;

  Grid grid;


  // Networks is a mapping from network name to RoadNetwork.
  // e.g. CAR --> RoadNetwork, ... etc
  private HashMap<String, RoadNetwork> networks;
  private HashMap<String, PImage[]> glyphsMap;
  private ArrayList<Agent> agents;

  // There are two backgrounds to show depending on world.
  private PImage backgroundPrivateWorld;
  private PImage backgroundSharedWorld;

  
  World() {
    // Set up color maps
    colorMapBW = new HashMap<String,Integer>();
    colorMapBW.put(CAR, #DDDDDD);
    colorMapBW.put(BIKE, #888888);
    colorMapBW.put(PED, #444444);
    colorMapColorful = new HashMap<String,Integer>();
    colorMapColorful.put(CAR, #ff0000); // red
    colorMapColorful.put(BIKE, #00ff00);  // green
    colorMapColorful.put(PED, #0000ff);  // blue

    // Create the glyphs and hold in map
    PImage[] carGlyph = new PImage[1];
    carGlyph[0] = loadImage("image/glyphs/car.gif");
    PImage[] bikeGlyph = new PImage[2];
    bikeGlyph[0] = loadImage("image/glyphs/bike-0.gif");
    bikeGlyph[1] = loadImage("image/glyphs/bike-1.gif");
    PImage[] pedGlyph = new PImage[3];
    pedGlyph[0] = loadImage("image/glyphs/human-0.gif");
    pedGlyph[1] = loadImage("image/glyphs/human-1.gif");
    pedGlyph[2] = loadImage("image/glyphs/human-2.gif");
    glyphsMap = new HashMap<String, PImage[]>();
    glyphsMap.put(CAR, carGlyph);
    glyphsMap.put(BIKE, bikeGlyph);
    glyphsMap.put(PED, pedGlyph);

    // Load/cache backgrounds.
    backgroundPrivateWorld = loadImage("image/background/background-red.png");
    backgroundSharedWorld = loadImage("image/background/background-white.png");
    // backgroundSharedWorld = loadImage("image/background/background-green.png");

    // Create city grid
    grid = new Grid();

    // Create the road networks.
    RoadNetwork carNetwork = new RoadNetwork("network/car.geojson", CAR);
    RoadNetwork bikeNetwork = new RoadNetwork("network/bike.geojson", BIKE);
    RoadNetwork pedNetwork = new RoadNetwork("network/ped.geojson", PED);
    networks = new HashMap<String, RoadNetwork>();
    networks.put(CAR, carNetwork);
    networks.put(BIKE, bikeNetwork);
    networks.put(PED, pedNetwork);

    agents = new ArrayList<Agent>();
    createAgents();

    pg = createGraphics(DISPLAY_WIDTH, DISPLAY_HEIGHT, P2D);
  }
  
  
  public void init() {
    for (Agent a : agents) {
      a.init();
    }  
  }


  public void createAgents() {
    int agents = NUM_AGENTS_PER_WORLD;
    if (INIT_AGENTS_FROM_DATAFILE) {
      createAgentsFromDatafile(agents);
    } else {
      createRandomAgents(agents);
    }
  }
  

  public void createAgentsFromDatafile(int num) {
    /* Creates a certain number of agents from preprocessed data. */
    Table simPopTable = loadTable(SIMULATED_POPULATION_DATA_FILEPATH, "header");
    int counter = 0;
    for (TableRow row : simPopTable.rows()) {
      int residentialBlockId = row.getInt("residential_block");
      int officeBlockId = row.getInt("office_block");
      int amenityBlockId = row.getInt("amenity_block");

      if (!validAgentBlocks(residentialBlockId, officeBlockId, amenityBlockId)) {
        continue;
      }

      String mobilityMotif = getMobilityMotif(row);
      int householdLifecycle = row.getInt("hh_lifeCycle");
      int householdIncome = row.getInt("hh_income");
      int occupationType = row.getInt("occupation_type");
      int age = row.getInt("age");
      Agent a = new Agent(networks, glyphsMap, residentialBlockId, officeBlockId, amenityBlockId, mobilityMotif, householdLifecycle, householdIncome, occupationType, age);
      agents.add(a);

      counter++;
      if (counter >= num) {
        break;
      }
    }
  }

  public String getMobilityMotif(TableRow row) {
    /* Parses a data row to return a mobility motif */
    // mobility motifs are made up of sequences of:
    // R (residential)
    // O (office)
    // A (amenity)
    // The sequence represents the agent's daily mobility patterns
    String mobilityMotif = "ROR"; // default motif
    if (row.getInt("motif_RAAR") == 1) {
      mobilityMotif = "RAAR";
    } else if (row.getInt("motif_RAOAR") == 1) {
      mobilityMotif = "RAOAR";
    } else if (row.getInt("motif_RAOR") == 1) {
      mobilityMotif = "RAOR";
    } else if (row.getInt("motif_RAR") == 1) {
      mobilityMotif = "RAR";
    } else if (row.getInt("motif_ROAOR") == 1) {
      mobilityMotif = "ROAOR";
    } else if (row.getInt("motif_ROAR") == 1) {
      mobilityMotif = "ROAR";
    } else if (row.getInt("motif_RAAR") == 1) {
      mobilityMotif = "RAAR";
    } else if (row.getInt("motif_ROOR") == 1) {
      mobilityMotif = "ROOR";
    }
    // There is also a motif_R in the data, but our agents do not just stay home...
    // default is  "ROR"
    return mobilityMotif;
  }


  public void createRandomAgents(int num) {
    for (int i = 0; i < num; i++) {
      createRandomAgent();
    }
  }

  public void createRandomAgent() {
    // Randomly assign agent blocks and attributes.
    int rBlockId;
    int oBlockId;
    int aBlockId;
    do {
      rBlockId = getRandomBuildingBlockId();
      oBlockId = getRandomBuildingBlockId();
      aBlockId = getRandomBuildingBlockId();
    } while (!validAgentBlocks(rBlockId, oBlockId, aBlockId));

    String mobilityMotif = "ROR";
    int householdLifecycle = int(random(11)) + 1;  // [1, 11]
    int householdIncome = int(random(12));  // [0, 11]
    int occupationType = int(random(5)) + 1;  // [1, 5]
    int age = int(random(100));

    agents.add(new Agent(networks, glyphsMap, rBlockId, oBlockId, aBlockId, mobilityMotif, householdLifecycle, householdIncome, occupationType, age)); 
  }


  public boolean validAgentBlocks(int rBlockId, int oBlockId, int aBlockId) {
    // Returns whether the list of buildings is valid for an agent.
    // Otherwise, the buildings should be rechosen.

    // Buildings must be different.
    if (rBlockId == oBlockId || rBlockId == aBlockId || oBlockId == aBlockId) {
      return false;
    }
    // At least one building must be on the grid.
    if (!(buildingBlockOnGrid(rBlockId) || buildingBlockOnGrid(oBlockId) || buildingBlockOnGrid(aBlockId))) {
      return false;
    }

    return true;
  }


  public void update(){
    for (Agent a : agents) {
      a.update();
    }
  }


  public void draw() {
    pg.beginDraw();

    pg.background(0);
    if(showBackground) {
      PImage background = getBackground();
      pg.tint(255, 255*BACKGROUND_OPACITY);  // Apply transparency without changing color
      pg.image(background, 0, 0, pg.width, pg.height);
    }
    if (showNetwork) {
      drawNetworks(pg);
    }

    for (Agent agent : agents) {
      agent.draw(pg);
    }
    pg.endDraw();
  }


  public void drawNetworks(PGraphics pg) {
    networks.get(CAR).draw(pg);
    networks.get(BIKE).draw(pg);
    networks.get(PED).draw(pg);
  }


  public PImage getBackground() {
    if (WORLD_ID == PRIVATE_AVS_WORLD_ID) {
      return backgroundPrivateWorld;
    } else {
      return backgroundSharedWorld;
    }
  }
}
