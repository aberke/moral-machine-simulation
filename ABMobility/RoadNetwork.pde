// The road network is built from a geojson file.
// The nodes are parsed and put into a Pathfinder graph.

import ai.pathfinder.*;


public class RoadNetwork {
  private PVector size;
  private PVector[] bounds;  // [0] Left-Top  [1] Right-Bottom
  private Pathfinder graph;
  private String type;

  // There are nodes out of bounds of the map.
  // Agents come in and out of the perimeter of the grid/world via these nodes.
  private ArrayList<Node> offGridNodes;

  RoadNetwork(String geoJSONfile, String _type) {
    type = _type;

    // Set map bounds
    // [top-left corner, bottom-right corner]
    this.bounds = new PVector[] {new PVector(0 ,0), new PVector(1, 1)};
    this.size = new PVector(DISPLAY_WIDTH, DISPLAY_HEIGHT);

    loadGraph(geoJSONfile);
    setupOffGridNodes();
  }


  private void loadGraph(String geoJSONfile) {
    // Builds graph of nodes and edges from a geojson file.

    JSONObject json = loadJSONObject(geoJSONfile);
    JSONArray edges = json.getJSONArray("features");
    
    // Create the graph from JSON array.
    // Items of the array are edges of a graph.
    // Parse the edges to create nodes, and connect them along their edges.
    ArrayList<Node> nodes = new ArrayList<Node>();
    Node prevNode = null;

    JSONObject edge;
    JSONArray edgePoints;
    JSONArray point;
    for(int i=0; i<edges.size(); i++) {
      edge = edges.getJSONObject(i);

      JSONObject edgeProperties = edge.getJSONObject("properties");
      boolean oneWay = edgeProperties.isNull("oneway") ? false : edgeProperties.getBoolean("oneway");

      edgePoints = edge.getJSONObject("geometry").getJSONArray("coordinates");
      for(int j = 0; j<edgePoints.size(); j++) {
        point = edgePoints.getJSONArray(j);

        // Point coordinates to XY screen position
        PVector pos = toXY(point.getFloat(0), point.getFloat(1));
        
        // Node already exists (same X and Y pos)
        Node node = nodeExists(pos.x, pos.y, nodes);

        if (node != null) {
          if (j > 0){
            prevNode.connect(node);
            if (!oneWay) {
              node.connect(prevNode);
            }
          }
        } else {
          node = new Node(pos.x, pos.y);
          if (j > 0) {
            if (!oneWay) {
              prevNode.connectBoth(node);
            } else {
              prevNode.connect(node);
            }
          }
          nodes.add(node);
        }
        prevNode = node;
      }
      graph = new Pathfinder(nodes); 
    }
  }

  private Node nodeExists(float x, float y, ArrayList<Node> nodes) {
    for(Node node : nodes) {
      if(node.x == x && node.y == y) {
        return node;
      }
    }
    return null;
  }


  private PVector toXY(float x, float y) {
    return new PVector(
      map(x, this.bounds[0].x, this.bounds[1].x, 0, size.x),
      map(y, this.bounds[0].y, this.bounds[1].y, size.y, 0)
    );
  }

  private void setupOffGridNodes() {
    offGridNodes = new ArrayList<Node>();
    Node node; 
    for (int i=0; i<graph.nodes.size(); i++){
      node = (Node) graph.nodes.get(i);
      if(node.x<0 || node.x>DISPLAY_WIDTH || node.y<0 || node.y>DISPLAY_HEIGHT){
        offGridNodes.add(node);
      }
    }
  }


  public void draw(PGraphics p) {
    for (int i=0; i < graph.nodes.size(); i++){
      Node node = (Node)graph.nodes.get(i);
      for(int j=0; j<node.links.size(); j++){
        if (showGlyphs) {
          p.stroke(universe.colorMapBW.get(type));
        } else {
          if (WORLD_ID == PRIVATE_AVS_WORLD_ID) {
            p.stroke(universe.colorMapBad.get(type));
          } else {
            p.stroke(universe.colorMapGood.get(type));
          }
        }
        p.line(node.x, node.y, ((Connector)node.links.get(j)).n.x, ((Connector)node.links.get(j)).n.y);
      }
    }  
  }


  public Node getRandomNodeInsideROI(PVector pos, int size){
    ArrayList<Node> nodes = new ArrayList<Node>();
    Node node; 
    for (int i=0; i<graph.nodes.size(); i++) {
      node = (Node) graph.nodes.get(i);
        if(((node.x>pos.x-size/2) && (node.x)<pos.x+size/2) &&
        ((node.y>pos.y-size/2) && (node.y)<pos.y+size/2))
        {
          nodes.add(node);
        }       
      } 
    return nodes.get(int(random(nodes.size())));
  }
  
  
  public Node getRandomNodeOffGrid(){
    return offGridNodes.get(int(random(offGridNodes.size())));
  }  
} 
