import java.util.function.Consumer;
import java.util.function.Supplier;
import java.util.function.BiFunction;

void $(Runnable runnable) {
  push();
  runnable.run();
  pop();
}

<T> void $(T t, Consumer<T> consumer) {
  push();
  consumer.accept(t);
  pop();
}

<T> T $(Supplier<T> supplier) {
  push();
  final T result = supplier.get();
  pop();
  return result;
}

float average(double...n) {
  return (float) java.util.stream.DoubleStream.of(n)
    .average()
    .orElse(0);
}

float coterminal(float angle, float precision) {
  final float coterminal = round(angle * precision) / precision % TWO_PI;
  
  return coterminal + (coterminal < 0f ? TWO_PI : 0f);
}

float angleOf(float xA, float yA, float xB, float yB) {
  final float viewX = xB - xA;
  final float viewY = yB - yA;
  final float viewL = sqrt(viewX * viewX + viewY * viewY);
  final float inverseViewL = isZero(viewL, 0.0001) ? 0 : 1 / viewL;
  final float viewAngle = acos(viewX * inverseViewL);
  final float marchAngle = yB < yA ? TWO_PI - viewAngle : viewAngle;
  //System.out.println("viewX=%f,viewY=%f,viewL=%f".formatted(viewX, viewY, viewL));
  return marchAngle;
}

boolean isZero(float n, float precision) {
  return abs(n) < abs(precision);
}

color contrast(int edge, int e, int s, int w, int n, int d) {
  switch(edge) {
    case  E: return e;
    case  S: return s;
    case  W: return w;
    case  N: return n;
    default: return d;
  }
}

color fade(int r, int g, int b, float factor) {
  return
    (int) max(0, min(255, r / factor)) |
    (int) max(0, min(255, g / factor)) << 8 |
    (int) max(0, min(255, b / factor)) << 16;
}

color fade(int rgb, float factor) {
  return fade(rgb >> 16 & 0xff, rgb >> 8 & 0xff, rgb & 0xff, factor);
}
