import java.util.Map;
import java.util.HashMap;
import java.util.Objects;
import java.util.Optional;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.UnaryOperator;
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
  IntStream.iterate(
    0,
    i -> i < width,
    i -> i + 1
  )
    //.parallel()
    .mapToObj(i -> rayFromViewport(angle, x, y, i, width, /*HALF_PI + sin(ticks / 60f) * HALF_PI*/ radians(90), world))
    .forEach(r -> r.cast(view));
}

void view(float angle, float x, float y, int depth, SquareGrid world, Consumer<Column> view) {
  IntStream.iterate(
    0,
    i -> i < width,
    i -> i + 1
  )
    //.parallel()
    .mapToObj(i -> rayFromViewport(angle, x, y, i, width, /*HALF_PI + sin(ticks / 60f) * HALF_PI*/ radians(90), world))
    .map(r -> r.cast(depth))
    //.peek(System.out::println)
    .filter(Objects::nonNull)
    .forEach(view);
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
    return maybeStep != null && (maybeStep.edgeSeen & 0xff) != 0;//maybeStep == null || maybeStep.edgeSeen != 0 || maybeStep.previous != null && maybeStep.previous.edgeSeen != 0;
  }
  
  Step nextStep(Step previous, Predicate<Step> hasNext) {
    return hasNext.test(previous) ? world.nextStep(previous.angle, previous.x + previous.xIncrement, previous.y + previous.yIncrement, previous.viewportColumn, previous.depth - 1) : null;
  }
  
  UnaryOperator<Step> nextStep(Predicate<Step> hasNext) {
    return previous -> hasNext.test(previous) ? world.nextStep(previous.angle, previous.x + previous.xIncrement, previous.y + previous.yIncrement, previous.viewportColumn, previous.depth - 1) : null;
  }
  
  void cast(Consumer<Step> view) {
    Stream.iterate(world.nextStep(angle, x, y, column, 0), Objects::nonNull, nextStep(not(this::isTerminal)))
      .limit(99)
      //.filter(Objects::nonNull)
      //.peek(System.out::println)
      .reduce((a, b) -> b)
      .filter(this::isTerminal)
      //.map(step -> pipeline.apply(step))
      //.ifPresent(s -> {System.out.println(s); view.accept(s);});
      .ifPresent(view);
  }
  
  Column cast(int depth) {
    final Column c = Stream.iterate(world.nextStep(angle, x, y, column, depth), Objects::nonNull, nextStep(not(this::isTerminal)))
      .limit(depth)
      .reduce((a, b) -> b)
      .filter(this::isTerminal)
      .map(new Reflection(world)::interact)
      .orElse(null);//background column
      //System.out.println(c);
      return c;
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
  final int depth;
  //final int exclusiveRayStepCount;
  //final int exclusiveRayCount;
  //final Step previous;
    
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
    int depth //,
    //Step previous
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
    this.depth = depth;
    //this.previous = previous;
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
      this.viewportColumn,
      this.depth
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
