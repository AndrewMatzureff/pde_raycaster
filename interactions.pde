class Observer {
  void view(float angle, float x, float y, SquareGrid world, Consumer<Step> view) {
    //IntStream.iterate(
    //  0,
    //  i -> i < width,
    //  i -> i + 1
    //)
    //  //.parallel()
    //  .mapToObj(i -> rayFromViewport(angle, x, y, i, width, /*HALF_PI + sin(ticks / 60f) * HALF_PI*/ radians(90), world))
    //  .forEach(r -> r.cast(view));
  }
}

class Column {
  final int index;
  final color surface;
  final Step step;
  final Column child;
  
  Column(int index, color surface, Step step, Column child) {
    this.surface = surface;
    this.step = step;
    this.index = index;
    this.child = child;
  }
  
  Column(color surface, Step step, Column child) {
    this(step.viewportColumn, surface, step, child);
  }
  
  Column superimposed(Column onto) {
    return new Column(onto.index, lerpColor(this.surface, onto.surface, 0.825f), onto.step, this);
    //return new Column(onto.surface, onto.step, this);
  }
}

class Reflection {
  final SquareGrid scene;
  final int viewportColumn;
  Reflection(SquareGrid scene, int viewportColumn) {
    this.scene = scene;
    this.viewportColumn = viewportColumn;
  }
  Column interact(Step step) {
    if (isZero(step.increment, 0.00001)) {
      throw new RuntimeException("Step increment is intolerably close to zero: " + step);
    }
    
    final float hitX = step.x + step.xHitOffset;
    final float hitY = step.y + step.yHitOffset;
    final float reflectionX;
    final float reflectionY;
    
    if ((step.edgeSeen & (E | W)) != 0) {
      reflectionX = hitX - (hitX - step.x) / step.increment;
      reflectionY = hitY + (hitY - step.y) / step.increment;
    } else if ((step.edgeSeen & (S | N)) != 0) {
      reflectionX = hitX + (hitX - step.x) / step.increment;
      reflectionY = hitY - (hitY - step.y) / step.increment;
    } else {
      throw new RuntimeException("Expected a terminal Step but no edge was detected: " + step);
    }
    
    final float angleOfReflection = angleOf(hitX, hitY, reflectionX, reflectionY);
    
    return Optional.<Ray>of(new Ray(angleOfReflection, reflectionX, reflectionY, step.viewportColumn, scene))
        .map(r -> r.cast(step.depth - 1))
        .map(c -> c.superimposed(new Column(scene.getMaterial(0, 0, step.edgeSeen), step, null)))
        .orElse(new Column(scene.getMaterial(0, 0, step.edgeSeen), step, null));
  }
}
  
Function<Step, Column> reflection(SquareGrid scene, int column) {
  return new Reflection(scene, column)::interact;
}
