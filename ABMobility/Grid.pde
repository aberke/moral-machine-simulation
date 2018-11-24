


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
  public HashMap<Integer, PVector> gridMap;  // Maps building ID/location --> vector on grid.

  public PVector zombieLandLocation;

  Table table;

  Grid() {
    zombieLandLocation = new PVector(-1, -1);

    // initialize the gridMap
    gridMap = new HashMap<Integer,PVector>();
    gridMap.put(0,new PVector(1,1));gridMap.put(1,new PVector(3,1));gridMap.put(2,new PVector(6,1));gridMap.put(3,new PVector(8,1));gridMap.put(4,new PVector(11,1));gridMap.put(5,new PVector(13,1));
    gridMap.put(6,new PVector(1,4));gridMap.put(7,new PVector(3,4));gridMap.put(8,new PVector(6,4));gridMap.put(9,new PVector(8,4));gridMap.put(10,new PVector(11,4));gridMap.put(11,new PVector(13,4));
    gridMap.put(12,new PVector(1,7));gridMap.put(13,new PVector(3,7));gridMap.put(14,new PVector(6,7));gridMap.put(15,new PVector(8,7));gridMap.put(16,new PVector(11,7));gridMap.put(17,new PVector(13,7));
    gridMap.put(18, zombieLandLocation);gridMap.put(19, zombieLandLocation);gridMap.put(20, zombieLandLocation);gridMap.put(21, zombieLandLocation);gridMap.put(22, zombieLandLocation);gridMap.put(23, zombieLandLocation);

    // initialize buildings
    buildings = new ArrayList<Building>();
    table = loadTable(BLOCKS_DATA_FILEPATH, "header");
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
  }


  public void draw(PGraphics p) {
    // Draw buildings
    for (Building b: buildings) {
      if (b.loc != zombieLandLocation) {
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
