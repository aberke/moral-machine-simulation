
public class Universe {
  // This is a universe with two alternatives for future worlds.
   private World world1; // 'Bad' world with private cars
   private World world2; // 'Good' world with shared transit
   // Booleans manage threading of world updates.
   private boolean updatingWorld1;
   private boolean updatingWorld2;
   HashMap<String,Integer> colorMap;
   HashMap<String,Integer> colorMapGood;
   HashMap<String,Integer> colorMapBad;
   HashMap<String,Integer> colorMapBW;
   HashMap<String, PImage[]> glyphsMap;
   Grid grid;

   PShader shader;
   PGraphics pg;
   
   Universe(){
     colorMap = new HashMap<String,Integer>();
     colorMapGood = new HashMap<String,Integer>();
     colorMapBad = new HashMap<String,Integer>();
     //colorMap.put("car",#FF0000);colorMap.put("bike",#00FF00);colorMap.put("ped",#0000FF);
     
     colorMap.put("car",color(255,255,255));colorMap.put("bike",color(120,52,165));colorMap.put("ped",color(255,227,26));
     colorMapGood.put("car",color(255,255,255));colorMapGood.put("bike",color(0,234,169));colorMapGood.put("ped",color(141,198,255));
     colorMapBad.put("car",color(255,255,255));colorMapBad.put("bike",color(120,52,165));colorMapBad.put("ped",color(255,85,118));
     
     colorMapBW = new HashMap<String,Integer>();
     colorMapBW.put("car",#DDDDDD);colorMapBW.put("bike",#888888);colorMapBW.put("ped",#444444);
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
     glyphsMap.put("car", carGlyph);
     glyphsMap.put("bike", bikeGlyph);
     glyphsMap.put("ped", pedGlyph);

     grid = new Grid();
     world1 = new World(1, "image/background/background_01.png", glyphsMap);
     world2 = new World(2, "image/background/background_02.png", glyphsMap);
     updatingWorld1 = false;
     updatingWorld2 = false;

      shader = loadShader("mask.glsl");
      shader.set("width", float(DISPLAY_WIDTH));
      shader.set("height", float(DISPLAY_HEIGHT));
      shader.set("left", world1.pg);
      shader.set("right", world2.pg);
     pg = createGraphics(DISPLAY_WIDTH, DISPLAY_HEIGHT, P2D);
   }
   
   void InitUniverse(){
     world1.InitWorld();
     world2.InitWorld();
   }

   void update() {
    // Update the worlds and models + agents they contain
    // in separate threads than the main thread which draws
    // the graphics.
    if (!updatingWorld1) {
      updatingWorld1 = true;
      Thread t1 = new Thread(new Runnable() {
        public void run(){
          world1.update();
          updatingWorld1 = false;
        }
      });
      t1.start();
    }
    if (!updatingWorld2) {
      updatingWorld2 = true;
      Thread t2 = new Thread(new Runnable() {
        public void run(){
          world2.update();
          updatingWorld2 = false;
        }
      });
      t2.start();
    }
   }

  void updateGraphics() {
    world1.updateGraphics();
    world2.updateGraphics();

    pg.beginDraw();
    pg.shader(shader);
    pg.rect(0, 0, pg.width, pg.height);
    pg.endDraw();
  }

  void draw(PGraphics p) {
    p.image(pg, 0, 0);
  }
}

public class World {
  private ArrayList<ABM> models;
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
    RoadNetwork carNetwork = new RoadNetwork("network/current_network/car_"+id+".geojson", "car",id);
    RoadNetwork bikeNetwork = new RoadNetwork("network/current_network/bike_"+id+".geojson", "bike",id);
    RoadNetwork pedNetwork = new RoadNetwork("network/current_network/ped_"+id+".geojson", "ped",id);
    networks = new HashMap<String, RoadNetwork>();
    networks.put("car", carNetwork);
    networks.put("bike", bikeNetwork);
    networks.put("ped", pedNetwork);

    // Create the models    
    models = new ArrayList<ABM>();
    models.add(new ABM(carNetwork, "car", id));
    models.add(new ABM(bikeNetwork, "bike", id));
    models.add(new ABM(pedNetwork, "ped", id));

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

  public void draw(PGraphics p){
    p.background(0);
    p.image(background, 0, 0, p.width, p.height);

    for (ABM m: models){
      m.draw(p);
    }
    for (Agent agent : agents) {
      agent.draw(p, showGlyphs);
    }
  }

  public void updateGraphics() {
    pg.beginDraw();

    pg.background(0);
    if(showBackground){
      pg.image(background, 0, 0, pg.width, pg.height);
    }
    
    for(ABM m: models){
      m.draw(pg);
    }
    for (Agent agent : agents) {
      if(showAgent){
        agent.draw(pg, showGlyphs);
      }
      
    }

    pg.endDraw();
  }

}


// ABM stands for Agent Based Model.
// It is currently used as a wrapper for the road network.
public class ABM {
  private RoadNetwork map;
  private String type;
  private int worldId;
  public color modelColor;
  
  ABM(RoadNetwork _map, String _type, int _worldId){
    map=_map;
    type= _type;
    worldId= _worldId;
  }
  
  public void initModel() {}
  
  public void draw(PGraphics p){
    if (showNetwork) {
      map.draw(p); 
    }
  }
}
