
public class World {
  PGraphics pg;

  // Networks is a mapping from network name to RoadNetwork.
  // e.g. "car" --> RoadNetwork, ... etc
  private HashMap<String, RoadNetwork> networks;
  private HashMap<String, PImage[]> glyphsMap;
  private ArrayList<Agent> agents;

  // There are two backgrounds to show depending on world.
  private PImage background_private_world;
  private PImage background_public_world;
  
  World(HashMap<String, PImage[]> _glyphsMap) {
    glyphsMap = _glyphsMap;

    // Load/cache backgrounds.
    background_private_world = loadImage("image/background/background_01.png");
    background_public_world = loadImage("image/background/background_02.png");

    // Create the road networks.
    RoadNetwork carNetwork = new RoadNetwork("network/car.geojson", "car");
    RoadNetwork bikeNetwork = new RoadNetwork("network/bike.geojson", "bike");
    RoadNetwork pedNetwork = new RoadNetwork("network/ped.geojson", "ped");
    networks = new HashMap<String, RoadNetwork>();
    networks.put("car", carNetwork);
    networks.put("bike", bikeNetwork);
    networks.put("ped", pedNetwork);

    agents = new ArrayList<Agent>();
    createAgents();

    pg = createGraphics(DISPLAY_WIDTH, DISPLAY_HEIGHT, P2D);
  }
  
  
  public void InitWorld() {
    for (Agent a : agents) {
      a.initAgent();
    }  
  }


  public void createAgents() {
    // In the 'bad' world (1) there are additional agents created as 'zombie agents'.
    // They are assigned a residence or office permenantly in zombie land
    int numNormalAgents = NUM_AGENTS_PER_WORLD;
    if (INIT_AGENTS_FROM_DATAFILE) {
      createAgentsFromDatafile(numNormalAgents);
    } else {
      createRandomAgents(numNormalAgents);
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
      int householdIncome = row.getInt("hh_income");
      int occupationType = row.getInt("occupation_type");
      int age = row.getInt("age");
      Agent a = new Agent(networks, glyphsMap, id, residentialBlockId, officeBlockId, amenityBlockId, mobilityMotif, householdIncome, occupationType, age);
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
    int householdIncome = int(random(12));  // [0, 11]
    int occupationType = int(random(5)) + 1;  // [1, 5]
    int age = int(random(100));

    agents.add(new Agent(networks, glyphsMap, id, rBlockId, oBlockId, aBlockId, mobilityMotif, householdIncome, occupationType, age)); 
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


  public void updateGraphics() {
    pg.beginDraw();

    pg.background(0);
    if(showBackground) {
      PImage background = getBackground();
      pg.image(background, 0, 0, pg.width, pg.height);
    }

    if (showNetwork) {
      drawNetworks(pg);
    }

    for (Agent agent : agents) {
      if(showAgent){
        agent.draw(pg, showGlyphs);
      }
      
    }
    pg.endDraw();
  }


  public void drawNetworks(PGraphics pg) {
    networks.get("car").draw(pg);
    networks.get("bike").draw(pg);
    networks.get("ped").draw(pg);
  }


  public PImage getBackground() {
    if (WORLD_ID == PRIVATE_AVS_WORLD_ID) {
      return background_private_world;
    } else {
      return background_public_world;
    }
  }
}
