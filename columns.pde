void render(PGraphics pg, float startX, float startY, float pathLength, int pathDepth, Column column) {
  if (Objects.isNull(column) || pathDepth == 3) {
    return;
  }

  final Step hit = column.step;
  
  if(Objects.isNull(hit)) {
    pg.stroke(column.surface);
    pg.vertex(column.index, 0, 0); //y = -depth * height / 2
    render(pg, startX, startY, 0, 0, column.child);
    pg.stroke(rand * rand * rand - 3 * rand | #ff000000);
    pg.vertex(column.index, height, 0);
    return;
  }

  final float endX = hit.x + hit.xHitOffset;
  final float endY = hit.y + hit.yHitOffset;
  final float depth = pathLength + dist(startX, startY, endX, endY);
  final int shade = (int) (depth*0 * #ffffff*0) | 0xff000000 | (column.surface + 0*world.getMaterial(0, 0, hit.edgeSeen));//(hit.edgeSeen >>> 8); // hdr
  
  
  
  
  
  
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  //final float xA = startX, yA = startY, xB = endX, yB = endY;
  //final float viewX = xB - xA;
  //final float viewY = yB - yA;
  //final float viewL = sqrt(viewX * viewX + viewY * viewY);
  //final float inverseViewL = isZero(viewL, 0.0001) ? 0 : 1 / viewL;
  //final float viewAngle = acos(viewX * inverseViewL);
  //final float marchAngle = yB < yA ? TWO_PI - viewAngle : viewAngle;
  
  //pg.stroke(shade);
  //  pg.vertex(startX + width / 2, startY + height / 2);
  //render(pg, endX, endY, column.child);
  //pg.stroke((shade + ticks / (ticks * rand + 1)) + rand | #ff000000);
  //  pg.vertex(startX + width / 2 + viewX, startY + height / 2 + viewY);
  
  pg.stroke(shade);
  pg.vertex(hit.viewportColumn, -10000 / depth + height / 2, 0); //y = -depth * height / 2
  render(pg, endX, endY, depth, pathDepth + 1, column.child);
  pg.stroke((shade + ticks / (ticks * rand + 1)) + rand | #ff000000);
  pg.vertex(hit.viewportColumn, 10000 / depth + height / 2, 0);
}
