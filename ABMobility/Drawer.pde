
public class Drawer {
  PGraphics offscreenSurface;
  PGraphics surface;
  
  Drawer(PApplet parent) {
    offscreenSurface = createGraphics(DISPLAY_WIDTH, DISPLAY_HEIGHT, P2D);
    surface = createGraphics(DISPLAY_WIDTH, DISPLAY_HEIGHT, P2D);
  }
  
  void drawSurface(){
    offscreenSurface.beginDraw();
    offscreenSurface.clear();
    offscreenSurface.background(0);
    offscreenSurface.fill(125);
    offscreenSurface.rectMode(CENTER);
    offscreenSurface.stroke(#FF0000);
    offscreenSurface.noFill();
    offscreenSurface.rect(DISPLAY_WIDTH/2, DISPLAY_HEIGHT/2, DISPLAY_WIDTH, DISPLAY_HEIGHT);
    universe.update();
    universe.draw(offscreenSurface);
    if(showBuilding){
       universe.grid.draw(offscreenSurface);
    }
    offscreenSurface.endDraw();
    surface.beginDraw();
    surface.clear();
    surface.image(offscreenSurface, 0, 0);
  
    surface.endDraw();
    image(surface, 0, 0);
  }
}
