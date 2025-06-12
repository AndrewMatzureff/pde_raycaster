
PFont consolas;
PGraphics minimap;
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
//void settings() {
//}

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
  size(480, 360, P3D);
  textureMode(NORMAL);
    hint(ENABLE_DEPTH_TEST);
    hint(ENABLE_DEPTH_SORT);
  final int[] rands = new int[]{340345216, 525274240, 1835220480};
  rand = rands[(int) random(0, rands.length)];
  if (rand == 0) rand = 1;
  consolas = createFont("Consolas", 32);
  final Map<Integer, Integer> edgeColors = Map.of(
    1, #ff0000,
    2, #00ff00,
    4, #0000ff,
    8, #ff00ff
  );
  world = new SquareGrid(
    32,
    Map.<Surface, Integer>of(surface(0, 0, E), #ff0000, surface(0, 0, S), #00ff00, surface(0, 0, W), #0000ff, surface(0, 0, N), #ff00ff),
    new int[][]{
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
    }//,
    //IntUnaryOperator.identity()
    //cell -> cell | ((
    //  edgeColors.getOrDefault(cell & 1, 0) |
    //  edgeColors.getOrDefault(cell & 2, 0) |
    //  edgeColors.getOrDefault(cell & 4, 0) |
    //  edgeColors.getOrDefault(cell & 8, 0)
    //) << 8)
  );
    // hint(ENABLE_KEY_REPEAT);

    //if (g.isGL()) {
    //    ((PGraphicsOpenGL) g).textureSampling(2);
    //}

    minimap = createGraphics(480, 360, P2D);
}

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
  push();try{
  background(#10252575);
  gradient();
  stroke(255);
  
  final int x = 0, y = 1;
  
  final float[] mouse = new float[]{
  mouseX - width / 2,
  mouseY - height / 2
  };
  
  final float xA = camera[x], yA = camera[y], xB = mouse[x], yB = mouse[y];
  final float viewX = xB - xA;
  final float viewY = yB - yA;
  final float viewL = sqrt(viewX * viewX + viewY * viewY);
  final float inverseViewL = isZero(viewL, 0.0001) ? 0 : 1 / viewL;
  final float viewAngle = acos(viewX * inverseViewL);
  final float marchAngle = yB < yA ? TWO_PI - viewAngle : viewAngle;
  
  if (keys['r'] || keys['R']) rand = (int) random(0xffffffff, 0x7fffffff);
  push();
  fill(#000000);
  textFont(consolas);
  text("rand=" + rand, 25, 25, 1);
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
  
  camera[x] += 2.5f * (viewX * inverseViewL * (vd[x] + vu[x]) + viewY * inverseViewL * (vl[x] + vr[x]));
  camera[y] += 2.5f * (viewY * inverseViewL * (vd[y] + vu[y]) + viewX * inverseViewL * (vl[y] + vr[y]));
      
      //System.out.println("ticks=" + ticks);
      //System.out.println("camera=[%f,%f]".formatted(camera[x], camera[y]));
    
  $(() -> {
    minimap.beginDraw();
    minimap.clear();//.background(#00000000);
    minimap.stroke(255);
    
    minimap.beginShape(LINES);
    minimap.vertex(camera[x] + width / 2, camera[y] + height / 2);
    minimap.vertex(camera[x] + width / 2 + viewX, camera[y] + height / 2 + viewY);
    minimap.endShape();
    
    view((float) marchAngle, camera[x], camera[y], world, (index, isColumn) -> {
      //minimap.beginDraw();
      minimap.push();
      minimap.beginShape();
      
      if (isColumn) {
        final int c = index;
        
        minimap.stroke(#55ffffff);
        minimap.vertex(width / 2 - world.scaledWidth() / 2 + c * world.scale, height / 2 - world.scaledHeight() / 2);
        minimap.stroke(#55000000);
        minimap.vertex(width / 2 - world.scaledWidth() / 2 + c * world.scale, height / 2);
        minimap.stroke(#55ffffff);
        minimap.vertex(width / 2 - world.scaledWidth() / 2 + c * world.scale, height / 2 + world.scaledHeight() / 2);
      } else {
        final int r = index;
        
        minimap.stroke(#55ffffff);
        minimap.vertex(width / 2 - world.scaledWidth() / 2, height / 2 - world.scaledHeight() / 2 + r * world.scale);
        minimap.stroke(#55000000);
        minimap.vertex(width / 2, height / 2 - world.scaledHeight() / 2 + r * world.scale);
        minimap.stroke(#55ffffff);
        minimap.vertex(width / 2 + world.scaledWidth() / 2, height / 2 - world.scaledHeight() / 2 + r * world.scale);
      }
      
      minimap.endShape();
      minimap.pop();
      //minimap.endDraw();
    });
    
    view((float) marchAngle, camera[x], camera[y], 25, world, column -> {
      //Deque<Column> columns = new LinkedList<>(List.of(column));
      push();
      noFill();
        beginShape();
        render(this.getGraphics(), camera[x], camera[y], 0, 0, column);
      //while(!columns.isEmpty()) {
      //  Step hit = column.step;
      //  final float startX = camera[x];
      //  final float startY = camera[y];
      //  final float endX = hit.x + hit.xHitOffset;
      //  final float endY = hit.y + hit.yHitOffset;
      //  final float depth = dist(startX, startY, endX, endY);
      //  final int shade = (int) (depth*0 * #ffffff*0) | 0xff000000 | (column.surface + 0*world.getMaterial(0, 0, hit.edgeSeen));//(hit.edgeSeen >>> 8); // hdr
        
      //  //beginShape(LINES);
      //  //stroke(shade);
      //  //vertex(hit.viewportColumn, -10000 / depth + height / 2, 0);
      //  //stroke((shade + ticks / (ticks * rand + 1)) + rand | #ff000000);
      //  //vertex(hit.viewportColumn, 10000 / depth + height / 2, 0);
      //  //endShape();
        
      //  stroke(shade);
      //  vertex(hit.viewportColumn, -10000 / depth + height / 2, 0);
      //  stroke((shade + ticks / (ticks * rand + 1)) + rand | #ff000000);
      //  vertex(hit.viewportColumn, 10000 / depth + height / 2, 0);
        
      //  columns.pop();
        
      //  //minimap.stroke(#25ffffff);
      //  //minimap.beginShape(LINES);
      //  //minimap.vertex(startX + width / 2, startY + height / 2);
      //  //minimap.vertex(  endX + width / 2,   endY + height / 2);
      //  //minimap.endShape();
      //}
        endShape();
        pop();
    });
    minimap.endDraw();
    //image(minimap, 0, 0, 120, 90);
    //beginShape();
    //texture(minimap);
    //vertex(0, 0, 10, 0, 0);//texture uv coordinates are the last two numbers
    //vertex(width, 0, 10, 1, 0);
    //vertex(width, height, 10, 1, 1);
    //vertex(0, height, 10, 0, 1);
    //endShape();
  });
    
  ticks++;}catch(NullPointerException e){e.printStackTrace(); throw e;}
  pop();
}
