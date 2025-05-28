
PFont consolas;
SquareGrid world;
final float[] camera = new float[2];
final boolean[] keys = new boolean[65536];
int ticks = 0;
int rand = 0;

/**
 * "The settings() function is new with Processing 3.0. It's not needed in most sketches. It's only useful when it's
 * absolutely necessary to define the parameters to size() with a variable. Alternately, the settings() function is
 * necessary when using Processing code outside the Processing Development Environment (PDE). For example, when
 * using the Eclipse code editor, it's necessary to use settings() to define the size() and smooth() values for a
 * sketch.
 * <p>
 * The settings() method runs before the sketch has been set up, so other Processing functions cannot be used at
 * that point. For instance, do not use loadImage() inside settings(). The settings() method runs "passively" to set
 * a few variables, compared to the setup() command that call commands in the Processing API."
 */
void settings() {
  size(480, 360, P3D);
}

/**
 * "The setup() function is run once, when the program starts. It's used to define initial environment properties
 * such as screen size and to load media such as images and fonts as the program starts. There can only be one
 * setup() function for each program, and it shouldn't be called again after its initial execution.
 * <p>
 * If the sketch is a different dimension than the default, the size() function or fullScreen() function must be the
 * first line in setup().
 * <p>
 * Note: Variables declared within setup() are not accessible within other functions, including draw()."
 */
void setup() {
  final int[] rands = new int[]{340345216, 525274240, 1835220480};
  rand = rands[(int) random(0, rands.length)];
  if (rand == 0) rand = 1;
  consolas = createFont("Consolas", 32);
  world = new SquareGrid(32, new int[][]{
    {0,  S,  S,  S,  S,  S,  S,  S,  S,  S, 0},
    {E, NW, SN,  N,  N,  N,  N,  N, SN, NE, W},
    {E, EW,  0,  W,  0,  0,  0,  E,  0, WE, W},
    {E,  W,  N,  0,  0,  S,  0,  0,  N,  E, W},
    {E,  W,  0,  0, SE,  0, SW,  0,  0,  E, W},
    {E,  W,  0,  E,  0,  0,  0,  W,  0,  E, W},
    {E,  W,  0,  0, NE,  0, NW,  0,  0,  E, W},
    {E,  W,  S,  0,  0,  N,  0,  0,  S,  E, W},
    {E, EW,  0,  W,  0,  0,  0,  E,  0, WE, W},
    {E, SW, NS,  S,  S,  S,  S,  S, NS, SE, W},
    {0,  N,  N,  N,  N,  N,  N,  N,  N,  N, 0},
  });
    // hint(ENABLE_KEY_REPEAT);

    //if (g.isGL()) {
    //    ((PGraphicsOpenGL) g).textureSampling(2);
    //}

    //canvas = createGraphics(640, 480, P3D);
}

  // 250508 >>
void keyPressed() {
  if (key != CODED) keys[key] = true;
}

void keyReleased() {
  if (key != CODED) keys[key] = false;
}

void gradient() {
  push();
  
  fill(#ffffff);
  rect(0, 0, width, height / 2);
  
  beginShape();
  fill(#000025);
  vertex(0, height / 2);
  vertex(width, height / 2);
  fill(rand * rand * rand - 3 * rand);
  vertex(width, height);
  vertex(0, height);
  endShape(CLOSE);
  
  pop();
}

void draw() {
  background(#10252575);
  gradient();
  stroke(255);
  
  final int x = 0, y = 1;
  
  final float[] mouse = new float[]{
  mouseX - width / 2,
  mouseY - height / 2
  };
  
  final float viewX = mouse[x] - camera[x];
  final float viewY = mouse[y] - camera[y];
  final float viewL = sqrt(viewX * viewX + viewY * viewY);
  final float inverseViewL = isZero(viewL, 0.0001) ? 0 : 1 / viewL;
  final float viewAngle = acos(viewX * inverseViewL);
  final float marchAngle = mouse[y] < camera[y] ? TWO_PI - viewAngle : viewAngle;
      //System.out.println("viewX=%f,viewY=%f,viewL=%f".formatted(viewX, viewY, viewL));
  
  if (keys['r'] || keys['R']) rand = (int) random(0xffffffff, 0x7fffffff);
  push();
  fill(#000000);
  textFont(consolas);
  text("rand=" + rand, 25, 25);
  pop();
  
  //direction of movement == -view
  
  final float[] vr = keys['d'] || keys['D'] ? new float[]{-1,1} : new float[2];
  final float[] vl = keys['a'] || keys['A'] ? new float[]{1,-1} : new float[2];
  final float[] vd = keys['s'] || keys['S'] ? new float[]{-1,-1} : new float[2];
  final float[] vu = keys['w'] || keys['W'] ? new float[]{1,1} : new float[2];
  final float[] v = new float[]{
    vr[x] + vl[x] + vd[x] + vu[x],
    vr[y] + vl[y] + vd[y] + vu[y]
  };
  
  camera[x] += 2.5f * (viewX * inverseViewL * (vd[x] + vu[x]) + viewY * inverseViewL * (vl[x] + vr[x]));//(
    //(keys['d'] || keys['D'] ?  1 : 0) +
    //(keys['a'] || keys['A'] ? -1 : 0));
  camera[y] += 2.5f * (viewY * inverseViewL * (vd[y] + vu[y]) + viewX * inverseViewL * (vl[y] + vr[y]));//(
    //(keys['s'] || keys['S'] ?  1 : 0) +
    //(keys['w'] || keys['W'] ? -1 : 0));
  // << 250508
      
      beginShape(LINES);
      //vertex(endX + width / 2, 100, depth / 100f);
      //vertex(endX + width / 2, height - 100, depth / 100f);
      vertex(camera[x] + width / 2, camera[y] + height / 2);
      vertex(camera[x] + width / 2 + viewX, camera[y] + height / 2 + viewY);
      endShape();
      
      //System.out.println("ticks=" + ticks);
      System.out.println("camera=[%f,%f]".formatted(camera[x], camera[y]));
  $(() -> {
  // 250508 >>
    view((float) marchAngle, camera[x], camera[y], world, hit -> {
      final float startX = camera[x];
      final float startY = camera[y];
      final float endX = hit.x + hit.xHitOffset;
      final float endY = hit.y + hit.yHitOffset;
      final float depth = dist(startX, startY, endX, endY);
      //final int pizzaz = (ticks & 0xff) << 16 | (ticks & 0xff) << 8 | (ticks & 0xff);
      final int pizzaz = contrast(hit.edgeSeen, #ff0000, #00ff00, #0000ff, #ff00ff, #00ffff);
      //final int shade = (int) (fade(pizzaz, depth * 0.01)) | 0xff000000; // fade to black
      //final int shade = (int) ((depth * (#ffffff & hit.edgeSeen))) | 0xff000000; // metallic
      //final int shade = (fade((pizzaz + (int) (depth * (#ffffff & hit.edgeSeen))) / 2, depth * 0.01)) | 0xff000000; // ftb + metallic
      final int shade = (int) (depth * #ffffff + 0*ticks * hit.edgeSeen) | 0xff000000; // hdr
      //if (hit.edgeSeen != 0)
      //System.out.println("hit.edgeSeen == " + hit.edgeSeen);
      
      stroke(#25ffffff);
      beginShape(LINES);
      vertex(startX + width / 2, startY + height / 2);
      vertex(  endX + width / 2,   endY + height / 2);
      endShape();
      beginShape(LINES);
      stroke(shade);
      vertex(hit.viewportColumn, -10000 / depth + height / 2);
      stroke((shade + ticks / (ticks * rand + 1)) + rand | #ff000000);
      vertex(hit.viewportColumn, 10000 / depth + height / 2);
      endShape();
  // << 250508
    });
    
    view((float) marchAngle, camera[x], camera[y], world, (index, isColumn) -> {
      push();
      beginShape();
      
      if (isColumn) {
        final int c = index;
        
        stroke(#55ffffff);
        vertex(width / 2 - world.scaledWidth() / 2 + c * world.scale, height / 2 - world.scaledHeight() / 2);
        stroke(#55000000);
        vertex(width / 2 - world.scaledWidth() / 2 + c * world.scale, height / 2);
        stroke(#55ffffff);
        vertex(width / 2 - world.scaledWidth() / 2 + c * world.scale, height / 2 + world.scaledHeight() / 2);
      } else {
        final int r = index;
        
        stroke(#55ffffff);
        vertex(width / 2 - world.scaledWidth() / 2, height / 2 - world.scaledHeight() / 2 + r * world.scale);
        stroke(#55000000);
        vertex(width / 2, height / 2 - world.scaledHeight() / 2 + r * world.scale);
        stroke(#55ffffff);
        vertex(width / 2 + world.scaledWidth() / 2, height / 2 - world.scaledHeight() / 2 + r * world.scale);
      }
      
      endShape();
      pop();
    });
  });
    
  ticks++;
}
