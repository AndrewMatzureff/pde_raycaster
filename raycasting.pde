import java.util.Map;
import java.util.HashMap;
import java.util.Objects;
import java.util.Optional;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.stream.DoubleStream;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import static java.util.function.Predicate.not;

void view(float angle, float x, float y, SquareGrid world, BiConsumer<Integer, Boolean> view) {
  Stream.of(false, true)
    .map(isColumn -> IntStream.range(0, (isColumn ? world.width : world.height) + 1)
      .collect(HashMap::new, (Map t, int value) -> t.put(value, isColumn), Map::putAll))
    .forEach(map -> map.forEach(view));
}

void view(float angle, float x, float y, SquareGrid world, Consumer<Step> view) {
  //final float vpFOV = HALF_PI; // 90º
  //final float vpHalfFOV = vpFOV / 2;
  //final float vpBase = width;
  //final float vpHalfBase = vpBase / 2;
  //final float vpHeight = vpHalfBase / cos(vpHalfFOV);
  //final float vpHypotenuse = vpHalfBase / sin(vpHalfFOV);
  
  //IntStream.iterate(
  //  -width / 2,
  //  i -> i < width / 2,
  //  i -> i + 1
  //)
  //  //.parallel()
  //  .map(i -> i + (~i >>> 31)) // add 1 to 0 and greater so that we don't have to deal with sin(t) == 0; might behave different for odd widths
  //  .mapToObj(i -> asin(i / dist(0, 0, i, vpHeight)) + angle)
  //  .map(i -> new Ray(i, x, y, world))
  //  .forEach(r -> r.cast(view));
  
  IntStream.iterate(
    0,
    i -> i < width,
    i -> i + 1
  )
    //.parallel()
    .mapToObj(i -> rayFromViewport(angle, x, y, i, width, /*HALF_PI + sin(ticks / 60f) * HALF_PI*/ radians(90), world))
    .forEach(r -> r.cast(view));
    
  //DoubleStream.iterate(
  //  angle - QUARTER_PI,
  //  a -> a <= angle + QUARTER_PI,
  //  a -> a + HALF_PI / 640
  //)
  //  //.parallel()
  //  .map(n -> n % TWO_PI)
  //  .mapToObj(n -> (float) n)
  //  .map(a -> new Ray(a, x, y, world))
  //  .forEach(r -> r.cast(view));
}

class Ray {
  final SquareGrid world;
  final float angle;
  final float x, y;
  final int column;
  
  Ray(float angle, float x, float y, int column, SquareGrid world) {
    this.angle = angle;
    this.x = x;
    this.y = y;
    this.column = column;
    this.world = world;
  }

  // 250508 >>
  boolean isTerminal(Step maybeStep) {
    //return maybeStep == null || maybeStep.edgeSeen != 0;//Optional.ofNullable(maybeStep)
    //  //.filter(step -> step.edgeSeen == 0)
    //  //.isEmpty();
    return maybeStep != null && maybeStep.edgeSeen != 0;//maybeStep == null || maybeStep.edgeSeen != 0 || maybeStep.previous != null && maybeStep.previous.edgeSeen != 0;
  }
  
  void cast(Consumer<Step> view) {
  //view.accept(world.nextStep(angle, x, y));
    Stream.iterate(world.nextStep(angle, x, y, column, null, not(this::isTerminal)), /*not(this::isTerminal),*/ maybeStep ->
      /* NOTE: it seems like the very last step does not actually satisfy
       * "not(this::isTerminal)" (since edgeSeen != 0) so it is not included in the stream.
       * This means that there will be NO step included in the view where edgeSeen != 0.
       * One solution could be to add a reference to the previous step in each step so that
       * we can check whether the LAST step has edgeSeen != 0. Unfortunately this would
       * also mean that each ray terminating with a hit must compute at least 2 steps.
       */
      Optional.ofNullable(maybeStep)
        .map(step -> world.nextStep(step.angle, step.x + step.xIncrement, step.y + step.yIncrement, column, step, not(this::isTerminal)))
        .orElse(null))
      .limit(99)
      .filter(Objects::nonNull)
      //.peek(System.out::println)
      .reduce((a, b) -> b)
      .filter(this::isTerminal)
      .ifPresent(view);
  }
}
  
Ray rayFromViewport(float mainViewAngle, float x, float y, int column, int viewportWidth, float fov, SquareGrid world) {
  final float vpFOV = fov;//HALF_PI; // 90º
  final float vpHalfFOV = vpFOV / 2;
  final float vpBase = viewportWidth;
  final float vpHalfBase = vpBase / 2;
  final float vpHeight = (float)(vpHalfBase / Math.cos(vpHalfFOV));
  final float vpHypotenuse = (float)(vpHalfBase / Math.sin(vpHalfFOV));
  final int centerRelativeColumn = column - viewportWidth / 2;
  final int centerRelativeNonzeroColumn = centerRelativeColumn + (~centerRelativeColumn >>> 31);
  final float angle = (float)Math.asin(centerRelativeNonzeroColumn / dist(0, 0, centerRelativeNonzeroColumn, vpHeight)) + mainViewAngle;
  
  return new Ray(angle, x, y, column, world);
}

class Step {
  final float angle;
  final float x, y;
  final float increment;
  final float xIncrement, yIncrement;
  final float xHitOffset, yHitOffset;
  final int edgeSeen;
  final int viewportColumn;
  final Step previous;
    
  Step(//Should Step store origin + increment instead of target?
    float angle,
    float x,
    float y,
    float increment,
    float xIncrement,
    float yIncrement,
    float xHitOffset,
    float yHitOffset,
    int edgeSeen,
    int viewportColumn,
    Step previous
  ) {
    this.angle = angle;
    this.x = x;
    this.y = y;
    this.increment = increment;
    this.xIncrement = xIncrement;
    this.yIncrement = yIncrement;
    this.xHitOffset = xHitOffset;
    this.yHitOffset = yHitOffset;
    this.edgeSeen = edgeSeen;
    this.viewportColumn = viewportColumn;
    this.previous = previous;
  }
  
  String toString() {
    return "{angle:%f, x:%f, y:%f, increment:%f, xIncrement:%f, yIncrement:%f, xHitOffset:%f, yHitOffset:%f, edgeSeen:%d, viewportColumn:%d}".formatted(
      this.angle,
      this.x,
      this.y,
      this.increment,
      this.xIncrement,
      this.yIncrement,
      this.xHitOffset,
      this.yHitOffset,
      this.edgeSeen,
      this.viewportColumn
    );
  }
  
  //Step coalesce(float angle, float startX, float startY, float localOriginX, float localOriginY, Step next) {
  //  final float thisDistance = dist(
  //  return new Step(
  //    angle,
  //    startX,
  //    startY,
  //    this.increment + next.increment,
  //    this.xIncrement + next.xIncrement,
  //    this.yIncrement + next.yIncrement,
  //    this.xHitOffset + next.xHitOffset + 0 * localOriginX,
  //    this.yHitOffset + next.yHitOffset + 0 * localOriginY,
  //    this.edgeSeen | next.edgeSeen
  //  );
  //}
}

  // << 250508
