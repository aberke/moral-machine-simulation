// Mobility motifs are sequences of 'types' of places to go.
// These types correspond to building blocks on the gridwhere these
// types of activity take place.
public final String RESIDENTIAL = "R";
public final String OFFICE = "O";
public final String AMENITY = "A";


public class Agent {

  // Networks is a mapping from network name to RoadNetwork.
  // e.g. "car" --> RoadNetwork, ... etc
  private HashMap<String, RoadNetwork> networks;
  private HashMap<String, PImage[]> glyphsMap;
  private RoadNetwork map;  // Curent network used for mobility type.
  private int worldId;  // 1=Bad world; 2=Good world


  private int residentialBlockId;
  private int officeBlockId;
  private int amenityBlockId;
  private int householdIncome;
  private int occupationType;
  private int age;

  // Agents have mobility motifs that determine their trips
  // mobility motifs are made up of sequences of:
  // R (residential)
  // O (office)
  // A (amenity)
  // The sequence represents the agent's daily mobility patterns
  private String mobilityMotif;
  private String[] mobilitySequence;
  // ms keeps track of where agent is in their mobility sequence.
  // The value cycles through the indicies of the mobilitySequenceArray.
  private int ms;

  // Variables specific to trip within mobility motif sequence.
  private int srcBlockId;  // source block for current trip
  private int destBlockId;  // destination block for current trip
  // Keeps track of destination location so that if block is moved, destination can update
  private PVector destBlockLocation;
  private String mobilityType;
  private PImage[] glyph;
  private PVector pos;
  private Node srcNode, destNode, toNode;  // toNode is like next node
  private ArrayList<Node> path;
  private PVector dir;
  private float speed;
  private boolean isZombie;


  Agent(HashMap<String, RoadNetwork> _networks, HashMap<String, PImage[]> _glyphsMap, int _worldId,
        int _residentialBlockId, int _officeBlockId, int _amenityBlockId,
        String _mobilityMotif,
        int _householdIncome, int _occupationType, int _age){
    networks = _networks;
    glyphsMap = _glyphsMap;
    worldId = _worldId;
    residentialBlockId = _residentialBlockId;
    officeBlockId = _officeBlockId;
    amenityBlockId = _amenityBlockId;
    mobilityMotif = _mobilityMotif;
    householdIncome = _householdIncome;
    occupationType = _occupationType;
    age = _age;
    isZombie = false;
  }
  
  
  public void initAgent() {
    // Set up mobility sequence.  The agent travels through this sequence.
    ms = 0;
    switch(mobilityMotif) {
      case "ROR" :
        mobilitySequence = new String[] {"R", "O"};
        break;
      case "RAAR" :
        mobilitySequence = new String[] {"R", "A", "A"};
        break;
      case "RAOR" :
        mobilitySequence = new String[] {"R", "A", "O"};
        break;
      case "RAR" :
        mobilitySequence = new String[] {"R", "A"};
        break;
      case "ROAOR" :
        mobilitySequence = new String[] {"R", "O", "A", "O"};
        break;
      case "ROAR" :
        mobilitySequence = new String[] {"R", "O", "A"};
        break;
      case "ROOR" :
        mobilitySequence = new String[] {"R", "O", "O"};
        break;
      default:
        mobilitySequence = new String[] {"R", "O"};
        break;
    }

    destBlockId = -1;
    setupNextTrip();
  }


  public void setupNextTrip() {
    // destination block < 0 before the first trip (right after agent is initialized).
    if (destBlockId < 0) {
      srcBlockId = getBlockIdByType(mobilitySequence[ms]);
    } else {
      // The destination block becomes the source block for the next trip.
      srcBlockId = destBlockId;
    }

    ms = (ms + 1) % mobilitySequence.length;
    String destType = mobilitySequence[ms];
    destBlockId = getBlockIdByType(destType);

    // Determine whether this agent 'isZombie': is going to or from 'zombie land'
    boolean srcOnGrid = universe.grid.isBuildingInCurrentGrid(srcBlockId);
    boolean destOnGrid = universe.grid.isBuildingInCurrentGrid(destBlockId);
    isZombie = !(srcOnGrid && destOnGrid);

    // Mobility choice partly determined by distance
    // agent must travel, so it is determined after zombieland
    // status is determined.
    setupMobilityType();

    destBlockLocation = universe.grid.getBuildingLocationById(destBlockId);
    
    // Get the nodes on the graph
    // Note the graph is specific to mobility type and was chosen when mobility type was set up.
    srcNode = getNodeByBlockId(srcBlockId);
    destNode = getNodeByBlockId(destBlockId);

    calcRoute();
  }


  public Node getNodeByBlockId(int blockId) {
    if (universe.grid.isBuildingInCurrentGrid(blockId)) {
      return map.getRandomNodeInsideROI(universe.grid.getBuildingCenterPosistionPerId(blockId),BUILDING_SIZE);
    } else {
      return map.getRandomNodeInZombieLand();
    }
  }


  private void calcRoute() {
    pos = new PVector(srcNode.x, srcNode.y);
    path = null;
    dir = new PVector(0.0, 0.0);

    if (srcNode == destNode) {
      // Agent already in destination
      toNode = destNode;
      return;
    }
    // Next node is available
    ArrayList<Node> newPath = map.graph.aStar(srcNode, destNode);
    if ( newPath != null ) {
      path = newPath;
      toNode = path.get(path.size() - 2); // what happens if there are only two nodes?
    }
  }


  public int getBlockIdByType(String type) {
    int blockId = 0;
    if (type == RESIDENTIAL) {
      blockId = residentialBlockId;
    } else if (type == OFFICE) {
      blockId = officeBlockId;
    } else if (type == AMENITY) {
      blockId = amenityBlockId;
    }
    return blockId;
  }


  public void draw(PGraphics p, boolean glyphs) {
    if (pos == null || path == null) {  // in zombie land.
      return;
    }
    if (glyphs && (glyph.length > 0)) {
      PImage img = glyph[0];
      if (img != null) {
        p.pushMatrix();
        p.translate(pos.x, pos.y);
        p.rotate(dir.heading() + PI * 0.5);
        p.translate(-1, 0);
        p.image(img, 0, 0, img.width * SCALE, img.height * SCALE);
        p.popMatrix();
      }
    } else {
      p.noStroke();
      if(worldId==1){
      p.fill(universe.colorMapBad.get(mobilityType));
      }else{
        p.fill(universe.colorMapGood.get(mobilityType));
      }
      p.ellipse(pos.x, pos.y, 10*SCALE, 10*SCALE);
    }
    
    if(showZombie & isZombie){
      p.fill(#CC0000);
      p.ellipse(pos.x, pos.y, 10*SCALE, 10*SCALE);
     }
  }

  private String chooseMobilityType() {
    /* Agent makes a choice about which mobility
     * mode type to use for route.
     * This is based on activityBased model.
    */
    // TODO(aberke): Use decision tree code from activityBased model.
    // Decision will be based on a agent path + attributes from simPop.csv.
    // Currently randomly selects between car/bike/ped based on dummy
    // probability distributions.

    // How likely agent is to choose one mode of mobility over another depends
    // on whether agent is in 'bad' vs 'good' world.
    // It also depends on how far an agent must travel.  Agents from 'zombieland'
    // are traveling further and more likely to take a car.
    String[] mobilityTypes = {"car", "bike", "ped"};
    float[] mobilityChoiceProbabilities;
    if (worldId == 1) {
      // Bad world dummy probabilities:
      if (isZombie) {
        mobilityChoiceProbabilities = new float[] {0.9, 0.1, 0};
      } else {
        mobilityChoiceProbabilities = new float[] {0.7, 0.2, 0.1};
      }
    } else {
      // Good world dummy probabilities:
      if (isZombie) {
        mobilityChoiceProbabilities = new float[] {0.3, 0.4, 0.3};
      } else {
        mobilityChoiceProbabilities = new float[] {0.1, 0.5, 0.4};
      }
    }
    
    // Transform the probability distribution into an array to randomly sample from.
    String[] mobilityChoiceDistribution = new String[100];
    int m = 0;
    for (int i=0; i<mobilityTypes.length; i++) {
      for (int p=0; p<int(mobilityChoiceProbabilities[i]*100); p++) {
        mobilityChoiceDistribution[m] = mobilityTypes[i];
        m++;
      }
    }
    // Take random sample from distribution.
    int choice = int(random(100));
    return mobilityChoiceDistribution[choice];
  }

  private void setupMobilityType() {
    mobilityType = chooseMobilityType();
    map = networks.get(mobilityType);
    glyph = glyphsMap.get(mobilityType);

    switch(mobilityType) {
      case "car" :
        speed = 0.7+ random(-0.3,0.3);
      break;
      case "bike" :
        speed = 0.3+ random(-0.15,0.15);
      break;
      case "ped" :
        speed = 0.2 + random(-0.05,0.05);
      break;
      default:
      break;
    }     
  }

  
  public void update() {
    // Check if the agent's destination block has been moved
    PVector currDestBlockLocation = universe.grid.getBuildingLocationById(destBlockId);
    if (currDestBlockLocation != destBlockLocation) {
      // The destination block has been moved!  Update the route.
      destBlockLocation = currDestBlockLocation;
      destNode = getNodeByBlockId(destBlockId);
      calcRoute();
    }

    if (path == null) { // in zombie land
      return;
    }

    PVector toNodePos = new PVector(toNode.x, toNode.y);
    PVector destNodePos = new PVector(destNode.x, destNode.y);
    dir = PVector.sub(toNodePos, pos);  // unnormalized direction to go
    
    if (dir.mag() <= dir.normalize().mult(speed).mag()) {
      // Arrived to node
      if (path.indexOf(toNode) == 0) {  
        // Arrived to destination
        pos = destNodePos;
        this.setupNextTrip();
      } else {
        // Not destination. Look for next node.
        srcNode = toNode;
        toNode = path.get(path.indexOf(toNode) - 1);
      }
    } else {
      // Not arrived to node
      pos.add(dir);
    }
  }
}
