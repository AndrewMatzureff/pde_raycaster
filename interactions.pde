class Observer {
  void view(float angle, float x, float y, SquareGrid world, Consumer<Step> view) {
    IntStream.iterate(
      0,
      i -> i < width,
      i -> i + 1
    )
      //.parallel()
      .mapToObj(i -> rayFromViewport(angle, x, y, i, width, /*HALF_PI + sin(ticks / 60f) * HALF_PI*/ radians(90), world))
      .forEach(r -> r.cast(view));
  }
}

class Column {
  final color surface;
  final Step step;
  Column(color surface, Step step) {
    this.surface = surface;
    this.step = step;
  }
  
  Column superimposed(Column onto) {
    return new Column(lerpColor(this.surface, onto.surface, 0.5f), onto.step);
  }
}

class Reflection {
  final SquareGrid scene;
  Reflection(SquareGrid scene) {
    this.scene = scene;
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
        .map(c -> c.superimposed(new Column(scene.getMaterial(0, 0, step.edgeSeen), step)))
        .orElse(new Column(scene.getMaterial(0, 0, step.edgeSeen), step));
  }
}
