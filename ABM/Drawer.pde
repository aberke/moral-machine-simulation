
public class Drawer {
  PGraphics surface;
  PShader shader;
  PGraphics pg;
  
  Drawer(PApplet parent) {
    surface = createGraphics(DISPLAY_WIDTH, DISPLAY_HEIGHT, P2D);
    shader = loadShader("mask.glsl");
    shader.set("width", float(DISPLAY_WIDTH));
    shader.set("height", float(DISPLAY_HEIGHT));
    shader.set("sampler", world.pg);
    pg = createGraphics(DISPLAY_WIDTH, DISPLAY_HEIGHT, P2D);
  }
  
  void drawSurface(){
    surface.beginDraw();
    surface.clear();
    surface.background(0);
    surface.rectMode(CENTER);
    surface.rect(DISPLAY_WIDTH/2, DISPLAY_HEIGHT/2, DISPLAY_WIDTH, DISPLAY_HEIGHT);

    if (!pause) {
      world.update();
    }
    world.draw();
    
    pg.beginDraw();
    pg.shader(shader);
    pg.rect(0, 0, pg.width, pg.height);
    surface.image(pg, 0, 0);
    pg.endDraw();
    
    world.grid.draw(surface);
    surface.endDraw();
    image(surface, 0, 0);
  }
}
