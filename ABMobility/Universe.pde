
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

  Universe() {
    // Set up color maps
    colorMap = new HashMap<String,Integer>();
    colorMap.put("car",color(255,255,255));
    colorMap.put("bike",color(120,52,165));
    colorMap.put("ped",color(255,227,26));

    colorMapGood = new HashMap<String,Integer>();
    colorMapGood.put("car",color(255,255,255));
    colorMapGood.put("bike",color(0,234,169));
    colorMapGood.put("ped",color(141,198,255));

    colorMapBad = new HashMap<String,Integer>();
    colorMapBad.put("car",color(255,255,255));
    colorMapBad.put("bike",color(120,52,165));
    colorMapBad.put("ped",color(255,85,118));

    colorMapBW = new HashMap<String,Integer>();
    colorMapBW.put("car", #DDDDDD);
    colorMapBW.put("bike",#888888);
    colorMapBW.put("ped",#444444);

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
