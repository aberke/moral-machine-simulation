

// There a buildings in locations on grid, and then
// there are also 'virtual buildings' that are off the grid.
// Agents can be assigned to virtual buildings, in which case they
// travel between buildings on the grid and locations off the grid.

// Note: In the original implemntation that this project was forked from,
// buildings were interactive and could be moved on and off the grid.
// In that implentation, building location on the grid was not static.
// In this implementation, building location is static.
// Building ID == Location ID for the grid.
// Building IDs: [0, 1, ...count]
public static int BUILDINGS_ON_GRID_COUNT = 18;
public static int TOTAL_BULIDINGS_COUNT = 24;  // As per blocks.csv datafile

public int getRandomBuildingBlockId() {
  return int(random(TOTAL_BULIDINGS_COUNT));
}

public boolean buildingBlockOnGrid(int buildingId) {
  return (buildingId < BUILDINGS_ON_GRID_COUNT);
}


public class Grid {
  // The buildings array is indexed by the ids of the buildings it holds.
  // i.e. it maps Building.id --> Building for buildings 0...count
  private ArrayList<Building> buildings;
  // gridMap maps building ID/location --> relative (x,y) vector on grid.
  public HashMap<Integer, PVector> gridMap;

  public PVector offGridLocation;

  // Tracks which grid cells are occupied, and by which agent.
  // The agents use this to avoid collisions.
  // It maps (x, y) positions to:
  //  --> null (if unoccupied)
  //  --> Agent
  // Note: gridCellOccupancy x,y positions are absolute pixels;
  // they differ from the relative gridMap (x,y) positions
  public Agent[][] gridCellOccupancy;

  Grid() {
    offGridLocation = new PVector(-1, -1);

    // initialize the gridMap
    gridMap = new HashMap<Integer,PVector>();
    gridMap.put(0,new PVector(1,1));gridMap.put(1,new PVector(3,1));gridMap.put(2,new PVector(6,1));gridMap.put(3,new PVector(8,1));gridMap.put(4,new PVector(11,1));gridMap.put(5,new PVector(13,1));
    gridMap.put(6,new PVector(1,4));gridMap.put(7,new PVector(3,4));gridMap.put(8,new PVector(6,4));gridMap.put(9,new PVector(8,4));gridMap.put(10,new PVector(11,4));gridMap.put(11,new PVector(13,4));
    gridMap.put(12,new PVector(1,7));gridMap.put(13,new PVector(3,7));gridMap.put(14,new PVector(6,7));gridMap.put(15,new PVector(8,7));gridMap.put(16,new PVector(11,7));gridMap.put(17,new PVector(13,7));
    gridMap.put(18, offGridLocation);gridMap.put(19, offGridLocation);gridMap.put(20, offGridLocation);gridMap.put(21, offGridLocation);gridMap.put(22, offGridLocation);gridMap.put(23, offGridLocation);

    // initialize buildings
    buildings = new ArrayList<Building>();
    Table table = loadTable(BLOCKS_DATA_FILEPATH, "header");
    for (TableRow row : table.rows()) {
      // initialize buildings from data
      int id = row.getInt("id");
      int loc = id;  // initial location is same as building id
      int capacityR = row.getInt("R");
      int capacityO = row.getInt("O");
      int capacityA = row.getInt("A");
      Building b = new Building(gridMap.get(loc), id, capacityR, capacityO, capacityA);
      buildings.add(b);
    }

    // initialize gridCellOccupancy (all start unoccupied)
    gridCellOccupancy = new Agent[DISPLAY_WIDTH][DISPLAY_HEIGHT];
  }


  public void emptyGridCell(int x, int y) {
    // Empties the grid cell at (x, y).  Agents call this when they leave a cell.
    if (isCellOffGrid(x, y)) {
      return;
    }
    gridCellOccupancy[x][y] = null;
  }


  public void occupyGridCell(int x, int y, Agent agent) {
    // Fills grid cell at (x, y) with agent.
    if (isCellOffGrid(x, y)) {
      return;
    }
    gridCellOccupancy[x][y] = agent;
  }


  public Agent getGridCellOtherOccupant(int x, int y, Agent agent) {
    // Returns agent occupying grid cell at (x, y);
    // returns null if empty or occupied by parameter agent.
    if (isCellOffGrid(x, y)) {
      return null;
    }
    Agent occupant = gridCellOccupancy[x][y];
    if (occupant == agent) {
      return null;
    }
    return occupant;
  }

  private boolean isCellOffGrid(int x, int y) {
    if (x < 0 || x >= DISPLAY_WIDTH || y < 0 || y >= DISPLAY_HEIGHT) {
      return true;
    }
    return false;
  }


  public ArrayList<int[]> getGridBufferArea(int aX, int aY, PVector dir, int bufferSize) {
    // Parameters (aX, aY) define the point for which to return a rectangular buffer
    // 'in front' of, where 'in front' is determined by direction (dir)
    //
    // i.e. if A is at (x, y) and direction is directly above, return rectangle like:
    //  -------
    //  |     |
    //  ---A---
    //
    // Returns list of [x,y] pairs representing cells in buffer area.
    ArrayList bufferAreaCells = new ArrayList<int[]>();
    // Start with cells that are a simple rectangle horizontally aligned around (aX, aY)
    // The cells are ordered from the right bottom to left top in order to prioritize looking right first
    //   --> TODO: could improve by starting at point as corner instead
    for (int x=(aX + bufferSize); x>(aX - bufferSize); x--) {
      for (int y=(aY + bufferSize); y>(aY - bufferSize); y--) {
        bufferAreaCells.add(new int[]{x, y});
      }
    }
    PVector translationVector = dir.normalize().mult(bufferSize);
    // Translate all of the cells in the simple rectangle in direction dir so that
    // buffer is 'in front' of (aX, aY)
    int[] cell;
    for (int i=0; i<bufferAreaCells.size(); i++) {
      cell = (int[])bufferAreaCells.get(i);
      int x = cell[0];
      int y = cell[1];
      int translatedX = x + (int)translationVector.x;
      int translatedY = y + (int)translationVector.y;
      int[] translatedCell = new int[]{translatedX, translatedY};
      bufferAreaCells.set(i, translatedCell);
    }
    return bufferAreaCells;
  }


  public void drawGridBufferArea(PGraphics p, ArrayList<int[]> bufferAreaCells, int bufferColor) {
    p.stroke(bufferColor, 150);
    int[] cell;
    for (int i=0; i<bufferAreaCells.size(); i++) {
      cell = bufferAreaCells.get(i);
      int x = cell[0];
      int y = cell[1];
      if (isCellOffGrid(x, y)) {
        continue;
      }
      p.point(x, y);
    }
  }


  public Agent getGridCellsOtherOccupant(ArrayList<int[]> cells, Agent agent) {
    Agent occupant = null;
    int[] cell;
    for (int i=0; i<cells.size(); i++) {
      cell = cells.get(i);
      int x = cell[0];
      int y = cell[1];
      occupant = getGridCellOtherOccupant(x, y, agent);
      if (occupant != null) {
        break;
      }
    }
    return occupant;
  }


  public void draw(PGraphics p) {
    // Draw buildings
    for (Building b: buildings) {
      if (b.loc != offGridLocation) {
        b.draw(p);
      }
    }
  }


  public PVector getBuildingCenterPosistionPerId(int id) {
    PVector buildingLoc = getBuildingLocationById(id);
    return new PVector(buildingLoc.x*GRID_CELL_SIZE + BUILDING_SIZE/2, buildingLoc.y*GRID_CELL_SIZE + BUILDING_SIZE/2);
  }


  public PVector getBuildingLocationById(int id) {
    return buildings.get(id).loc;
  }

}
