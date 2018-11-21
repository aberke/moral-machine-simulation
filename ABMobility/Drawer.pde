import deadpixel.keystone.*;

public class Drawer {
  Keystone ks;
  int nbProjector = 2;
  CornerPinSurface[] surface = new CornerPinSurface[nbProjector];
  PGraphics offscreenSurface;
  PGraphics subSurface;
  
  Drawer(PApplet parent){
    ks = new Keystone(parent);
    offscreenSurface = createGraphics(playGroundWidth, playGroundHeight, P2D);
  }
  
  void initSurface(){
    for (int i=0; i<nbProjector;i++){
      surface[i] = ks.createCornerPinSurface((int)playGroundWidth/nbProjector, (int)playGroundHeight, 50);
    }
    subSurface = createGraphics(playGroundWidth/nbProjector, playGroundHeight, P2D);
  }
  
  void drawSurface(){
    universe.updateGraphics();
    offscreenSurface.beginDraw();
    offscreenSurface.clear();
    offscreenSurface.background(0);
    drawTableBackGround(offscreenSurface);
    offscreenSurface.rectMode(CENTER);
    offscreenSurface.stroke(#FF0000);
    offscreenSurface.noFill();
    offscreenSurface.rect(playGroundWidth/2,playGroundHeight/2,2128*SCALE, 1330*SCALE);
    universe.update();
    universe.draw(offscreenSurface);
    if(showBuilding){
       universe.grid.draw(offscreenSurface);
    }
    offscreenSurface.endDraw();
    for (int i=0; i<nbProjector;i++){
      subSurface.beginDraw();
      subSurface.clear();
      subSurface.image(offscreenSurface, -(playGroundWidth/nbProjector)*i, 0);
    
      subSurface.endDraw();
      surface[i].render(subSurface);
    }
  }
  
  void drawTableBackGround(PGraphics p) {
    p.fill(125);  
  }
}
