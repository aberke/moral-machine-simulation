import ai.pathfinder.*;

public class RoadNetwork {
  private PVector size;
  private PVector[] bounds;  // [0] Left-Top  [1] Right-Bottom
  private Pathfinder graph;
  private String type;

  RoadNetwork(String GeoJSONfile, String _type) {

    ArrayList<Node> nodes = new ArrayList<Node>();
    
    // Load file
    JSONObject JSON = loadJSONObject(GeoJSONfile);
    JSONArray JSONlines = JSON.getJSONArray("features");
    
     // Set map bounds
    setBoundingBox(JSONlines);
    
    type = _type;
    
    // Import all nodes
    Node prevNode = null;
    for(int i=0; i<JSONlines.size(); i++) {
      
      JSONObject props = JSONlines.getJSONObject(i).getJSONObject("properties");
      boolean oneWay = props.isNull("oneway") ? false : props.getBoolean("oneway");
      
      JSONArray points = JSONlines.getJSONObject(i).getJSONObject("geometry").getJSONArray("coordinates");

      for(int j = 0; j<points.size(); j++) {
        // Point coordinates to XY screen position
        PVector pos = toXY(points.getJSONArray(j).getFloat(0), points.getJSONArray(j).getFloat(1));
        
        // Node already exists (same X and Y pos). Connect  -->
        Node existingNode = nodeExists(pos.x, pos.y, nodes);

        if(existingNode != null){
          if(j > 0){
            prevNode.connect(existingNode);
            if(!oneWay){
              existingNode.connect(prevNode);
            }
          }
          prevNode = existingNode;
        } else {
          Node newNode = new Node(pos.x, pos.y);
          if(j > 0){
            if(!oneWay){
              prevNode.connectBoth(newNode);
            } else {
              prevNode.connect(newNode);
            }
          }
          nodes.add(newNode);
          prevNode = newNode;
        }
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

  public void setBoundingBox(JSONArray JSONlines) {
  
    float minLng = 0;
    float minLat = 0;
    float maxLng = 1;
    float maxLat = 1;
    
    this.bounds = new PVector[] {new PVector(minLng, minLat), new PVector(maxLng, maxLat)};
    
    // Resize map keeping ratio -->
    float mapRatio = 1.6 / 1.0;
    this.size = new PVector(DISPLAY_WIDTH, DISPLAY_HEIGHT);
  }

  private PVector toXY(float x, float y) {
    return new PVector(
      map(x, this.bounds[0].x, this.bounds[1].x, 0, size.x),
      map(y, this.bounds[0].y, this.bounds[1].y, size.y, 0)
    );
  }
  
  public void draw(PGraphics p){    
    for (int i=0; i < graph.nodes.size(); i++){
      Node tempN = (Node)graph.nodes.get(i);
      for(int j=0; j<tempN.links.size(); j++){
        if (showGlyphs) {
          p.stroke(universe.colorMapBW.get(type));
        } else {
          if (WORLD_ID == PRIVATE_AVS_WORLD_ID) {
            p.stroke(universe.colorMapBad.get(type));
          } else {
            p.stroke(universe.colorMapGood.get(type));
          }
        }
        p.line(tempN.x, tempN.y, ((Connector)tempN.links.get(j)).n.x, ((Connector)tempN.links.get(j)).n.y);
      }
    }  
  }
  
  public Node getRandomNodeInsideROI(PVector pos, int size){
    ArrayList<Node> tmp = new ArrayList<Node>();
    Node tmpNode; 
    for (int i=0;i<graph.nodes.size();i++){
      tmpNode = (Node) graph.nodes.get(i);
        if(((tmpNode.x>pos.x-size/2) && (tmpNode.x)<pos.x+size/2) &&
        ((tmpNode.y>pos.y-size/2) && (tmpNode.y)<pos.y+size/2))
        {
          tmp.add(tmpNode);
        }       
      } 
    return tmp.get(int(random(tmp.size())));
  }
  
  
  public Node getRandomNodeInZombieLand(){
    ArrayList<Node> tmp = new ArrayList<Node>();
    Node tmpNode; 
    for (int i=0;i<graph.nodes.size();i++){
      tmpNode = (Node) graph.nodes.get(i);
      if(tmpNode.x<0 || tmpNode.x>DISPLAY_WIDTH || tmpNode.y<0 || tmpNode.y>DISPLAY_HEIGHT){
        tmp.add(tmpNode);
      }
    }
    return tmp.get(int(random(tmp.size())));
  }  
} 
