
public class World {
  // Networks is a mapping from network name to RoadNetwork.
  // e.g. "car" --> RoadNetwork, ... etc
  private HashMap<String, RoadNetwork> networks;
  private HashMap<String, PImage[]> glyphsMap;
  private ArrayList<Agent> agents;
  
  int id;

  PImage background;
  PGraphics pg;

  World(int _id, String _background, HashMap<String, PImage[]> _glyphsMap){
    id = _id;
    glyphsMap = _glyphsMap;
    background = loadImage(_background);
    agents = new ArrayList<Agent>();

    // Create the road networks.
    RoadNetwork carNetwork = new RoadNetwork("network/current_network/car_"+id+".geojson", "car", id);
    RoadNetwork bikeNetwork = new RoadNetwork("network/current_network/bike_"+id+".geojson", "bike", id);
    RoadNetwork pedNetwork = new RoadNetwork("network/current_network/ped_"+id+".geojson", "ped", id);
    networks = new HashMap<String, RoadNetwork>();
    networks.put("car", carNetwork);
    networks.put("bike", bikeNetwork);
    networks.put("ped", pedNetwork);

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
    int numZombieAgents = 0;
    if (id == 1) {
      numZombieAgents = int((0.5)*NUM_AGENTS_PER_WORLD);  // Additional 50% -- This number should be tweaked.
    }

    if (INIT_AGENTS_FROM_DATAFILE) {
      createRandomAgents(numZombieAgents, true);
      createAgentsFromDatafile(numNormalAgents);
    } else {
      createRandomAgents(numZombieAgents, true);
      createRandomAgents(numNormalAgents, false);
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


  public void createRandomAgents(int num, boolean zombie) {
    for (int i = 0; i < num; i++) {
      createRandomAgent(zombie);
    }
  }

  public void createRandomAgent(boolean isZombie) {
    // Randomly assign agent blocks and attributes.
    int rBlockId;
    int oBlockId;
    int aBlockId;
    do {
      rBlockId = int(random(PHYSICAL_BUILDINGS_COUNT));
      oBlockId = int(random(PHYSICAL_BUILDINGS_COUNT));
      aBlockId = int(random(PHYSICAL_BUILDINGS_COUNT));
    } while (rBlockId == oBlockId || rBlockId == aBlockId || oBlockId == aBlockId);

    // If this agent is a zombie,
    // either R or O block must be a virtual block in zombie land.
    if (isZombie) {
      if (int(random(2)) < 1) {
        rBlockId = VIRTUAL_ZOMBIE_BUILDING_ID;
      } else {
        oBlockId = VIRTUAL_ZOMBIE_BUILDING_ID;
      }
    }

    String mobilityMotif = "ROR";
    int householdIncome = int(random(12));  // [0, 11]
    int occupationType = int(random(5)) + 1;  // [1, 5]
    int age = int(random(100));

    agents.add(new Agent(networks, glyphsMap, id, rBlockId, oBlockId, aBlockId, mobilityMotif, householdIncome, occupationType, age)); 
  }


  public void update(){
    for (Agent a : agents) {
      a.update();
    }
  }

  public void draw(PGraphics pg){
    pg.background(0);
    pg.image(background, 0, 0, pg.width, pg.height);


    if (showNetwork) {
      drawNetworks(pg);
    }

    for (Agent agent : agents) {
      agent.draw(pg, showGlyphs);
    }
  }

  public void updateGraphics() {
    pg.beginDraw();

    pg.background(0);
    if(showBackground){
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
}
