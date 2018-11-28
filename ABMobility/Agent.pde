// Mobility motifs are sequences of 'types' of places to go.
// These types correspond to building blocks on the gridwhere these
// types of activity take place.
public final String RESIDENTIAL = "R";
public final String OFFICE = "0";
public final String AMENITY = "A";

// Agents wait before their next trip begins so that they do not all flow out at once (there would be too much traffic!)
public final int TRIP_START_COUNTDOWN_MAX = 10*NUM_AGENTS_PER_WORLD;  // Wait up to this many passes

// When agents use shared transit as their travel mode, they join another vehicle (a shared AV).
// Implementation: A new agent is not placed on the grid.
// Instead, given time passes befor their trip to take place, and then they begin their next trip.
// They choose a new mobility mode of transit for each new trip.
// The visual result is fewer agents on the grid (because they are sharing the vehicles).
// Shared transit trip time was determined based on the average trip time for other agent mobility modes.
public final int SHARED_TRANSIT_TRIP_TIME = 2000;

public final int YIELD_MAX = 100;

public static int DEFAULT_BUFFER_DEBUG_COLOR = #888888;
public static int COLLISION_BUFFER_DEBUG_COLOR = #FF0000; // RED
public static int BUFFER_OCCUPIED_BUFFER_DEBUG_COLOR = #FFFF00; // YELLOW


public class Agent {

  // Networks is a mapping from network name to RoadNetwork.
  // e.g. CAR --> RoadNetwork, ... etc
  private HashMap<String, RoadNetwork> networks;
  private HashMap<String, PImage[]> glyphsMap;
  private RoadNetwork map;  // Curent network used for mobility type.

  // Agents are from a simulated population based on real census survey data.
  // They have attributes from this data that determine their travel choices.
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

  // This is for yielding decisions & coordinating who goes or yields when
  // It is public so that other agents can check if they are being yielded to by this agent (i.e. talk)
  // Maps other agents in buffer area to amount of time have been yielding to them
  // (Agent) who yielding to --> Int (time spent yielding to them)
  public HashMap<Agent, Integer> yieldToMap;

  public boolean onSharedTransitTrip;
  public int sharedTransitTripTime;

  private int bufferDebugColor;
  private int innerBufferAreaSize, outterBufferAreaSize;
  private PVector bufferOffset;

  // There are small waits before new trips begin
  // These waits are randomly chosen to stagger when agents enter grid.
  private boolean isOnTrip;
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
    yieldToMap = new HashMap<Agent, Integer>();
    // Set up mobility sequence.  The agent travels through this sequence.
    // Currently sequences with repeat trip types (e.g. RAAR) are not meaningfully
    // different (e.g. RAAR does not differ from RAR)
    // because block for triptype is staticly chosen and dest and src nodes
    // must differ.  
    // TODO: Change this?
    ms = 0;
    switch(mobilityMotif) {
      case "ROR" :
        mobilitySequence = new String[] {RESIDENTIAL, OFFICE};
        break;
      case "RAAR" :
        mobilitySequence = new String[] {RESIDENTIAL, AMENITY, AMENITY};
        break;
      case "RAOR" :
        mobilitySequence = new String[] {RESIDENTIAL, AMENITY, OFFICE};
        break;
      case "RAR" :
        mobilitySequence = new String[] {RESIDENTIAL, AMENITY};
        break;
      case "ROAOR" :
        mobilitySequence = new String[] {RESIDENTIAL, OFFICE, AMENITY, OFFICE};
        break;
      case "ROAR" :
        mobilitySequence = new String[] {RESIDENTIAL, OFFICE, AMENITY};
        break;
      case "ROOR" :
        mobilitySequence = new String[] {RESIDENTIAL, OFFICE, OFFICE};
        break;
      default:
        mobilitySequence = new String[] {RESIDENTIAL, OFFICE};
        break;
    }
    destBlockId = -1;
    setupNextTrip();
  }


  public void setupNextTrip() {
    isOnTrip = false;
    tripBeginsCountdown = int(random(TRIP_START_COUNTDOWN_MAX));

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

    destBlockLocation = universe.grid.getBuildingLocationById(destBlockId);

    // Mobility choice partly determined by distance
    // agent must travel, so it is determined after travelsOffGrid
    // status is determined.
    setupMobilityType();
    if (mobilityType == SHARED_TRANSIT) {
      onSharedTransitTrip = true;
      sharedTransitTripTime = 0;
    } else {
      onSharedTransitTrip = false;

      // Get the nodes on the map
      // Note the graph is specific to mobility type and was chosen when mobility type was set up.
      srcNode = getNodeByBlockId(srcBlockId);
      destNode = getNodeByBlockId(destBlockId);
      calcRoute();
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


  public Node getNodeByBlockId(int blockId) {
    if (buildingBlockOnGrid(blockId)) {
      return map.getRandomNodeInsideROI(universe.grid.getBuildingCenterPosistionPerId(blockId), BUILDING_SIZE);
    } else {
      return map.getRandomNodeOffGrid();
    }
  }


  private void setupMobilityType() {
    mobilityType = chooseMobilityType();
    if (mobilityType == SHARED_TRANSIT) {
      return;
    }
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
    String[] mobilityTypes = {CAR, BIKE, PED, SHARED_TRANSIT};
    float[] mobilityChoiceProbabilities;
    if (WORLD_ID == PRIVATE_AVS_WORLD_ID) {
      // Bad/private world dummy probabilities:
      if (travelsOffGrid) {
        mobilityChoiceProbabilities = new float[] {1, 0, 0, 0};
      } else {
        mobilityChoiceProbabilities = new float[] {0.75, 0.15, 0.1, 0};
      }
    } else {
      // Good/shared world dummy probabilities:
      if (travelsOffGrid) {
        mobilityChoiceProbabilities = new float[] {0.2, 0.3, 0.2, 0.3};
      } else {
        mobilityChoiceProbabilities = new float[] {0.1, 0.4, 0.3, 0.2};
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
        highSpeed = 0.65 + random(0.2);
        lowSpeed = highSpeed - 0.3;
        break;
      case BIKE :
        highSpeed = 0.3 + random(0.15);
        lowSpeed = highSpeed - 0.05;
        break;
      case PED :
        highSpeed = 0.2 + random(0.05);
        lowSpeed = highSpeed - 0.05;
        break;
    }
    speed = highSpeed;
  }


  private void setupBufferArea() {
    PImage img = glyph[0];
    // TODO
    // switch(mobilityType) {
    //   case CAR :
        // the buffer goes around it
        innerBufferAreaSize = (int)(((img.width + 2)*SCALE)/2);
        outterBufferAreaSize = 2*innerBufferAreaSize;
        bufferOffset = new PVector(0, (int)((img.width*SCALE)/2));
      // break;
      // case BIKE :
      //   outterBufferAreaSize = BIKE_OUTTER_BUFFER_AREA_SIZE;
      //   innerBufferAreaSize = BIKE_INNER_BUFFER_AREA_SIZE;
      // break;
      // case PED :
      //   outterBufferAreaSize = PED_OUTTER_BUFFER_AREA_SIZE;
      //   innerBufferAreaSize = PED_INNER_BUFFER_AREA_SIZE;
      // break;
    // }
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
    if (!isOnTrip || pos == null || path == null) {
      return;
    }

    if (debugGridBufferArea) {
      // Outter buffer area is where agent goes more slowly
      ArrayList<int[]> gridOutterBufferAreaCells = universe.grid.getGridBufferArea((int)pos.x, (int)pos.y, dir, outterBufferAreaSize, bufferOffset);
      universe.grid.drawGridBufferArea(p, gridOutterBufferAreaCells, bufferDebugColor);
      // Inner buffer area is where agent yields
      ArrayList<int[]> gridInnerBufferAreaCells = universe.grid.getGridBufferArea((int)pos.x, (int)pos.y, dir, innerBufferAreaSize, bufferOffset);
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
    if (!isOnTrip && !beginTrip()) {
      return;
    }

    if (updateAsSharedTransit()) {
      // Agent is on shared transit.  It has been handled.
      return;
    }

    // Update the agent's position in their trip.
    PVector nextNodePos = new PVector(nextNode.x, nextNode.y);
    PVector destNodePos = new PVector(destNode.x, destNode.y);
    dir = PVector.sub(nextNodePos, pos);  // unnormalized direction to go

    if (dir.mag() <= dir.normalize().mult(speed).mag()) {
      // Agent has arrived to its nextNode
      updateNextNode();
    } else {
      // Not arrived to nextNode.

      yieldOrMove();
    }
  }

  public void yieldOrMove() {
    // move to nextPosition or YIELD

    // Check if desired next position is occupied
    // Get next position by adding direction to position.


    PVector nextPosition = PVector.add(pos, dir);
    int nextPositionX = (int)nextPosition.x;
    int nextPositionY = (int)nextPosition.y;

    // Determine if must yield
    boolean mustYield = false;
    // Get all the other agents in the buffer area in order to check if need to yield
    // Update timer for how long have been yielding to them
    // At the end, yieldToMap contains only the agents that are in the buffer area and are
    // not already yielding to this agent
    HashMap<Agent, Integer> prevYieldToMap = yieldToMap;
    yieldToMap = new HashMap<Agent, Integer>();

    ArrayList<int[]> yieldToAreaCells = universe.grid.getGridBufferArea((int)pos.x, (int)pos.y, dir, innerBufferAreaSize, bufferOffset);
    ArrayList<Agent> yieldTos = universe.grid.getGridCellsOtherOccupants(yieldToAreaCells, this);
    for (Agent yieldTo: yieldTos) {
      if (yieldTo.yieldToMap.get(this) != null) {
        continue;  // This other agent is already yielding to you --> do not yield to them too!
      }
      int yieldToWaitTime = 1;
      if (prevYieldToMap.get(yieldTo) != null) {
        yieldToWaitTime += prevYieldToMap.get(yieldTo);
      }
      yieldToMap.put(yieldTo, yieldToWaitTime);
      if (!mustYield && (yieldToWaitTime < YIELD_MAX)) {
        mustYield = true;
      }
    }
    if (mustYield) {
      yield();
      return;
    } else {
      // update speed to move by based on congestion
      updateSpeed();
      go(nextPosition);
    }
  }


  public boolean beginTrip() {
    if (tripBeginsCountdown == 0) {
      isOnTrip = true;
      return true;
    }
    tripBeginsCountdown -= 1;
    return false;
  }


  private void yield() {
    bufferDebugColor = BUFFER_OCCUPIED_BUFFER_DEBUG_COLOR;
    return;
  }


  private void go(PVector nextPosition) {
    bufferDebugColor = DEFAULT_BUFFER_DEBUG_COLOR;
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
    ArrayList<int[]> gridOutterBufferAreaCells = universe.grid.getGridBufferArea((int)pos.x, (int)pos.y, dir, outterBufferAreaSize, bufferOffset);
    ArrayList<Agent> otherBufferAreaOccupants = universe.grid.getGridCellsOtherOccupants(gridOutterBufferAreaCells, this);
    if (otherBufferAreaOccupants.size() > 0) {
      speed = lowSpeed;
    } else {
      speed = highSpeed;
    }
  }

  public boolean updateAsSharedTransit() {
    if (!onSharedTransitTrip) {
      return false;
    }
    sharedTransitTripTime += 1;
    if (sharedTransitTripTime > SHARED_TRANSIT_TRIP_TIME) {
      // The agent has arrived to their destination
      setupNextTrip();
    }
    return true;
  }
}










