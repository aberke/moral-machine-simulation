
public class Universe {

  private World world;

  // Boolean manages threading of world updates.
  private boolean updatingWorld;

  HashMap<String,Integer> colorMapColorful;
  HashMap<String,Integer> colorMapBW;
  HashMap<String, PImage[]> glyphsMap;
  Grid grid;

  PShader shader;
  PGraphics pg;

  Universe() {
    // Set up color maps
    colorMapBW = new HashMap<String,Integer>();
    colorMapBW.put(CAR, #DDDDDD);
    colorMapBW.put(BIKE, #888888);
    colorMapBW.put(PED, #444444);

    colorMapColorful = new HashMap<String,Integer>();
    colorMapColorful.put(CAR, #ff0000); // red
    colorMapColorful.put(BIKE, #00ff00);  // green
    colorMapColorful.put(PED, #0000ff);  // blue

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
    glyphsMap.put(CAR, carGlyph);
    glyphsMap.put(BIKE, bikeGlyph);
    glyphsMap.put(PED, pedGlyph);

    grid = new Grid();
    world = new World(glyphsMap);
    updatingWorld = false;

    shader = loadShader("mask.glsl");
    shader.set("width", float(DISPLAY_WIDTH));
    shader.set("height", float(DISPLAY_HEIGHT));
    shader.set("sampler", world.pg);
    pg = createGraphics(DISPLAY_WIDTH, DISPLAY_HEIGHT, P2D);
   }
   
   void InitUniverse(){
     world.InitWorld();
   }

   void update() {
    // Update the worlds and models + agents they contain
    // in separate threads than the main thread which draws
    // the graphics.
    if (pause) {
      return;
    }
    if (!updatingWorld) {
      updatingWorld = true;
      Thread t = new Thread(new Runnable() {
        public void run(){
          world.update();
          updatingWorld = false;
        }
      });
      t.start();
    }
   }

  void updateGraphics() {
    world.updateGraphics();

    pg.beginDraw();
    pg.shader(shader);
    pg.rect(0, 0, pg.width, pg.height);
    pg.endDraw();
  }

  void draw(PGraphics p) {
    p.image(pg, 0, 0);
  }
}
