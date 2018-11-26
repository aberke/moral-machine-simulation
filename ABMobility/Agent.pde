// Mobility motifs are sequences of 'types' of places to go.
// These types correspond to building blocks on the gridwhere these
// types of activity take place.
public final String RESIDENTIAL = "R";
public final String OFFICE = "O";
public final String AMENITY = "A";

// Agents wait before their next trip begins so that they do not all flow out at once
public final int TRIP_START_TIMER_MAX = 100;  // Wait up to this many passes

public final int YIELD_RIGHT_MAX = 50;
public final int YIELD_MAX = 10;


public static int CAR_OUTTER_BUFFER_AREA_SIZE = 8;
public static int CAR_INNER_BUFFER_AREA_SIZE = 5;
public static int BIKE_OUTTER_BUFFER_AREA_SIZE = 6;
public static int BIKE_INNER_BUFFER_AREA_SIZE = 3;
public static int PED_OUTTER_BUFFER_AREA_SIZE = 6;
public static int PED_INNER_BUFFER_AREA_SIZE = 3;

public static int DEFAULT_BUFFER_DEBUG_COLOR = #888888;
public static int COLLISION_BUFFER_DEBUG_COLOR = #FF0000; // RED
public static int BUFFER_OCCUPIED_BUFFER_DEBUG_COLOR = #FFFF00; // YELLOW


public class Agent {

  // Networks is a mapping from network name to RoadNetwork.
  // e.g. CAR --> RoadNetwork, ... etc
  private HashMap<String, RoadNetwork> networks;
  private HashMap<String, PImage[]> glyphsMap;
  private RoadNetwork map;  // Curent network used for mobility type.

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
  private Node srcNode, destNode, nextNode;  // nextNode moves from srcNode towards destNode
  private ArrayList<Node> path;  // Path is a list of nodes from destNode to nextNode.  e.g. [destNode, node, node, ..., nextNode]
  private int pathIndex; // Keeps track of index that agent has traveled in path.  Moves from back of path to front. 
  private PVector dir;
  private float speed, highSpeed, lowSpeed;
  private boolean travelsOffGrid;

  private int yield;
  private Agent yieldingTo;

  private int bufferDebugColor;
  private int innerBufferAreaSize, outterBufferAreaSize;

  private int tripBeginsCountdown;


  Agent(HashMap<String, RoadNetwork> _networks, HashMap<String, PImage[]> _glyphsMap,
        int _residentialBlockId, int _officeBlockId, int _amenityBlockId,
        String _mobilityMotif,
        int _householdIncome, int _occupationType, int _age){
    networks = _networks;
    glyphsMap = _glyphsMap;
    residentialBlockId = _residentialBlockId;
    officeBlockId = _officeBlockId;
    amenityBlockId = _amenityBlockId;
    mobilityMotif = _mobilityMotif;
    householdIncome = _householdIncome;
    occupationType = _occupationType;
    age = _age;
    travelsOffGrid = false;

    bufferDebugColor = DEFAULT_BUFFER_DEBUG_COLOR;
  }
  
  
  public void initAgent() {
    // Set up mobility sequence.  The agent travels through this sequence.
    // Currently sequences with repeat trip types (e.g. RAAR) are not meaningfully
    // different (e.g. RAAR does not differ from RAR)
    // because block for triptype is staticly chosen and dest and src nodes
    // must differ.  
    // TODO: Change this?
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
    // Set up src and dest blocks
    // destination block is < 0 before the first trip (right after agent is initialized).
    if (destBlockId < 0) {
      srcBlockId = getBlockIdByType(mobilitySequence[ms]);
    } else {
      // The destination block becomes the source block for the next trip.
      srcBlockId = destBlockId;
    }

    ms = (ms + 1) % mobilitySequence.length;
    String destType = mobilitySequence[ms];
    destBlockId = getBlockIdByType(destType);

    // Determine whether this agent 'travelsOffGrid'
    boolean srcOnGrid = buildingBlockOnGrid(srcBlockId);
    boolean destOnGrid = buildingBlockOnGrid(destBlockId);
    travelsOffGrid = !(srcOnGrid && destOnGrid);

    // Mobility choice partly determined by distance
    // agent must travel, so it is determined after travelsOffGrid
    // status is determined.
    setupMobilityType();

    destBlockLocation = universe.grid.getBuildingLocationById(destBlockId);
    
    // Get the nodes on the graph
    // Note the graph is specific to mobility type and was chosen when mobility type was set up.
    srcNode = getNodeByBlockId(srcBlockId);
    destNode = getNodeByBlockId(destBlockId);

    calcRoute();

    yield = 0;
    yieldingTo = null;

    tripBeginsCountdown = int(random(TRIP_START_TIMER_MAX));
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


  public Node getNodeByBlockId(int blockId) {
    if (buildingBlockOnGrid(blockId)) {
      return map.getRandomNodeInsideROI(universe.grid.getBuildingCenterPosistionPerId(blockId), BUILDING_SIZE);
    } else {
      return map.getRandomNodeOffGrid();
    }
  }


  private void setupMobilityType() {
    mobilityType = chooseMobilityType();
    map = networks.get(mobilityType);
    glyph = glyphsMap.get(mobilityType);
    setupSpeed();
    setupBufferArea();
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
    // It also depends on how far an agent must travel.  Agents from traveling to
    // or from a location off the main grid are traveling further and more likely
    // to take a car.
    String[] mobilityTypes = {CAR, BIKE, PED};
    float[] mobilityChoiceProbabilities;
    if (WORLD_ID == PRIVATE_AVS_WORLD_ID) {
      // Bad/private world dummy probabilities:
      if (travelsOffGrid) {
        mobilityChoiceProbabilities = new float[] {0.9, 0.1, 0};
      } else {
        mobilityChoiceProbabilities = new float[] {0.7, 0.2, 0.1};
      }
    } else {
      // Good/shared world dummy probabilities:
      if (travelsOffGrid) {
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


  private void setupSpeed() {
    switch(mobilityType) {
      case CAR :
        highSpeed = 0.7 + random(-0.3, 0.3);
        lowSpeed = highSpeed - 0.2;
      break;
      case BIKE :
        highSpeed = 0.3 + random(-0.15, 0.15);
        lowSpeed = highSpeed - 0.05;
      break;
      case PED :
        highSpeed = 0.2 + random(-0.05, 0.05);
        lowSpeed = highSpeed - 0.05;
      break;
    }
    speed = highSpeed;
  }


  private void setupBufferArea() {
    switch(mobilityType) {
      case CAR :
        outterBufferAreaSize = CAR_OUTTER_BUFFER_AREA_SIZE;
        innerBufferAreaSize = CAR_INNER_BUFFER_AREA_SIZE;
      break;
      case BIKE :
        outterBufferAreaSize = BIKE_OUTTER_BUFFER_AREA_SIZE;
        innerBufferAreaSize = BIKE_INNER_BUFFER_AREA_SIZE;
      break;
      case PED :
        outterBufferAreaSize = PED_OUTTER_BUFFER_AREA_SIZE;
        innerBufferAreaSize = PED_INNER_BUFFER_AREA_SIZE;
      break;
    }
  }


  private void calcRoute() {
    pos = new PVector(srcNode.x, srcNode.y);

    path = map.graph.aStar(srcNode, destNode);
    // path may be null of nodes are not connected (sad/bad graph, but making graphs is hard)
    if (path == null || srcNode == destNode) {
      // Agent already in destination -- likely had motif sequence with repeat trip type
      // e.g. motif like "RAAR"
      pathIndex = 0;
      nextNode = destNode;
      return;  // next trip will be set up
    }
    pathIndex = path.size() - 2;
    nextNode = path.get(pathIndex);
  }


  public void draw(PGraphics p, boolean glyphs) {
    if (pos == null || path == null || dir == null) {
      return;
    }

    if (debugGridBufferArea) {
      // Outter buffer area is where agent goes more slowly
      ArrayList<int[]> gridOutterBufferAreaCells = universe.grid.getGridBufferArea((int)pos.x, (int)pos.y, dir, outterBufferAreaSize);
      universe.grid.drawGridBufferArea(p, gridOutterBufferAreaCells, bufferDebugColor);
      // Inner buffer area is where agent yields
      ArrayList<int[]> gridInnerBufferAreaCells = universe.grid.getGridBufferArea((int)pos.x, (int)pos.y, dir, innerBufferAreaSize);
      universe.grid.drawGridBufferArea(p, gridInnerBufferAreaCells, bufferDebugColor);
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
      if (WORLD_ID == PRIVATE_AVS_WORLD_ID) {
        p.fill(universe.colorMapBad.get(mobilityType));
      } else {
        p.fill(universe.colorMapGood.get(mobilityType));
      }
      p.ellipse(pos.x, pos.y, 10*SCALE, 10*SCALE);
    }
    
    if (debugOffGridTravel && travelsOffGrid) {
      // Highlight agents traveling on/off grid
      p.fill(#CC0000);
      p.ellipse(pos.x, pos.y, 10*SCALE, 10*SCALE);
     }
  }

  
  public void update() {
    if (tripBeginsCountdown > 0) {
      tripBeginsCountdown -= 1;  // WAIT it is not time for the trip to start yet
      return;
    }

    // Update the agent's position in their trip.
    PVector nextNodePos = new PVector(nextNode.x, nextNode.y);
    PVector destNodePos = new PVector(destNode.x, destNode.y);
    dir = PVector.sub(nextNodePos, pos);  // unnormalized direction to go

    // Get speed to move by based on congestion
    updateSpeed();

    if (dir.mag() <= dir.normalize().mult(speed).mag()) {
      // Agent has arrived to its nextNode
      updateNextNode();
    } else {
      // Not arrived to nextNode.

      // move to nextPosition or YIELD

      // Check if desired next position is occupied
      // Get next position by adding direction to position.

      PVector nextPosition = PVector.add(pos, dir);
      int nextPositionX = (int)nextPosition.x;
      int nextPositionY = (int)nextPosition.y;

      Agent yieldTo = universe.grid.getGridCellOtherOccupant(nextPositionX, nextPositionY, this);
      if (!(yieldTo == null)) {
        if (yieldTo == yieldingTo) {
          // Already yielding to this agent
          yield += 1;
        } else {
          yieldingTo = yieldTo;
          yield = 1;
        }

        if ((yield >= YIELD_MAX) && (mobilityType != CAR)) {
          // Bikers and pedestrians can go around others after waiting
          goAround(nextPosition);
          return;
        }
        bufferDebugColor = COLLISION_BUFFER_DEBUG_COLOR;
        yield();
        return;
      }
      // TODO: special yielding logic for right buffer
      ArrayList<int[]> gridInnerBufferAreaCells = universe.grid.getGridBufferArea((int)pos.x, (int)pos.y, dir, innerBufferAreaSize);
      yieldTo = universe.grid.getGridCellsOtherOccupant(gridInnerBufferAreaCells, this);
      if (!(yieldTo == null)) {
        if (yieldTo == yieldingTo) {
          // Already yielding to this agent
          yield += 1;
        } else {
          yieldingTo = yieldTo;
          yield = 1;
        }

        if (yield < YIELD_MAX) {
          // YIELD
          bufferDebugColor = BUFFER_OCCUPIED_BUFFER_DEBUG_COLOR;
          yield();
          return;
        }
      }
      // Made it this far with no one to yield to!
      bufferDebugColor = DEFAULT_BUFFER_DEBUG_COLOR;
      go(nextPosition);
    }
  }


  private void yield() {
    return;
  }


  private void go(PVector nextPosition) {
    yield = 0;
    yieldingTo = null;
    updatePosition(nextPosition);
  }


  private void goAround(PVector desiredNextPosition) {
    // TODO: proper goAround -- could update position to go next to desiredNextPosition
    go(desiredNextPosition);
  }


  private void updateNextNode() {
    if (pathIndex < 0) {
      // Arrived to destination (because nextNode == destNode)
      updatePosition(null);
      dir = null;
      this.setupNextTrip();
    } else {
      // Not destination. Look for next node.
      nextNode = path.get(pathIndex);
      pathIndex -= 1;
    }
  }


  public void updatePosition(PVector newPosition) {
    if (pos == newPosition) {
      return;
    }
    if (pos != null) {
      // Leave current position on grid
      universe.grid.emptyGridCell((int)pos.x, (int)pos.y);
    }
    pos = newPosition;
    if (pos != null) { // pos is set to null when new trip started
      // Enter new position on grid
      universe.grid.occupyGridCell((int)pos.x, (int)pos.y, this);
    }
  }


  public void updateSpeed() {
    /* Agent goes slowly if others are in its outter buffer area.
       Otherwise agent goes quickly.
    */
    // TODO
    // println(this + ": updateSpeed for agent with mobilityType: "+mobilityType);
    // ArrayList<int[]> gridOutterBufferAreaCells = universe.grid.getGridBufferArea((int)pos.x, (int)pos.y, dir, outterBufferAreaSize);
    // Agent otherBufferAreaOccupant = universe.grid.getGridCellsOtherOccupant(gridOutterBufferAreaCells, this);
    // println("otherBufferAreaOccupant: "+otherBufferAreaOccupant);
    // if (otherBufferAreaOccupant != null) {
    //   speed = lowSpeed;
    // } else {
    //   speed = highSpeed;
    // }
    // println("updated speed to: "+speed);
  }
}
