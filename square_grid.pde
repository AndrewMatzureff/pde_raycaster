import java.util.Arrays;
import java.util.function.Predicate;
import java.util.function.IntUnaryOperator;

final int EAST_VISIBLE = 1;
final int SOUTH_VISIBLE = 2;
final int WEST_VISIBLE = 4;
final int NORTH_VISIBLE = 8;

final int E = 1;
final int S = 2;
final int W = 4;
final int N = 8;

final int A = E | S | W | N;
final int SE = S | E, SW = S | W, NE = N | E, NW = N | W;
final int EW = E | W, WE = EW, NS = N | S, SN = NS;
final int EE = E | NS, SS = S | WE, WW = W | NS, NN = N | WE;

int toIndex(int cell, int length) {
//        final int halfLength = length / 2;
//        final int index = cell + halfLength;
//        return ((-(index / halfLength) >> 31) & ((length << 31) >> 31)) + index;
  return length % 2 == 0
    ? 0
    : cell + length / 2;
}

class Surface {
  //final int x, y;
  final int edge;
  Surface(/*int x, int y,*/ int edge) {
    //this.x = x;
    //this.y = y;
    this.edge = edge;
  }
  
  //int hashCode() {return Objects.hash(x, y, edge);}
  int hashCode() {return edge;}
  boolean equals(Object other) {
    final Surface surface = other != null && Surface.class.equals(other.getClass()) ? (Surface) other : null;
    return surface == this || surface != null && surface.edge == this.edge;// && surface.x == this.x && surface.y == this.y; 
  }
}

Surface surface(int x, int y, int edge) {return new Surface(/*x, y,*/ edge);}
    
class SquareGrid {
  final float scale;
  final int width, height;
  final Map<Surface, Integer> palette;
  final int[][] cells;
  
  //SquareGrid(float scale, int width, int height, Map<Integer, Integer> palette, int[][] cells, Function<Surface, Integer> mods) {
  //  this(scale, width, height, palette, cells);
  //  for (int i = 0; i < height; i++) {
  //    for (int j = 0; j < width; j++) {
  //      cells[i][j] = mods.apply(surface(j, i, cells[i][j]));
  //    }
  //  }
  //}
  
  SquareGrid(float scale, int width, int height, Map<Surface, Integer> palette, int[][] cells) {
    this.scale = scale;
    this.width = width;
    this.height = height;
    this.palette = palette;
    this.cells = cells;
  }
  
  SquareGrid(float scale, Map<Surface, Integer> palette, int[][] cells) {
    this(scale, Arrays.stream(cells).mapToInt(r -> r.length).min().orElse(0), cells.length, palette, cells);
  }
  
  //SquareGrid(float scale, Map<Integer, Integer> palette, int[][] cells) {
  //  this(scale, palette, cells, (v, k) -> v);
  //}
  
  color getMaterial(int x, int y, int edge) {
    return palette.get(surface(x, y, edge));
  }
  
  float scaledWidth() {
    return width * scale;
  }
  
  float scaledHeight() {
    return height * scale;
  }

  int columnToIndex(int column) {
    return toIndex(column, width);
  }

  int rowToIndex(int row) {
    return toIndex(row, height);
  }

  private float global(float n, int c, int d) {
    final float g = c * scale + n;

    return d % 2 == 0
      ? g - Math.signum(g) * scale / 2
      : g;
  }

  float xGlobal(float x, int c) {
    return global(x, c, width);
  }

  float yGlobal(float y, int r) {
    return global(y, r, height);
  }

  private float local(float n, int d) {
    final float l = n % scale - scale / 2 * Math.signum(n);
    return d % 2 == 0
      ? l
      : scale / 2 * Math.signum(-l) - (scale / 2 * Math.signum(n) - n % scale);
  }

  float xLocal(float x) {
    return local(x, width);
  }
  
  float yLocal(float y) {
    return local(y, height);
  }
  
  private int at(float n, int d) {
    return d % 2 == 0
      ? (int) (Math.ceil(Math.abs(n) / scale) * Math.signum(n))// * scale()
      : Math.round(n / scale);// * scale();
  }
  
  int columnAt(float x) {
    return at(x, width);
  }
  
  int rowAt(float y) {
    return at(y, height);
  }

  Step nextStep(float angle, float x, float y, int viewportColumn, int depth) { //, Step previous, Predicate<Step> prerequisite) {
    final float coterminal = coterminal(angle, 1000f);
    final int xCell = this.columnAt(x);
    final int yCell = this.rowAt(y);
    final int columnIndex = this.columnToIndex(xCell);
    final int rowIndex = this.rowToIndex(yCell);
    
    //if (!prerequisite.test(previous)) {//(columnIndex | rowIndex) < 0 || columnIndex >= this.width || rowIndex >= this.height) {
    //  return null;
    //}
    
    final float xLocal = this.xLocal(x);
    final float yLocal = this.yLocal(y);
    //final float marchAngle = (float) (Math.atan2(mouseX - x, mouseY - y) % TWO_PI + TWO_PI) % TWO_PI;//((System.nanoTime() / 100000000000f * TWO_PI) % TWO_PI + TWO_PI) % TWO_PI;
    final float marchAngleAdjacent = (float) Math.cos(coterminal);
    final float marchAngleOpposite = (float) Math.sin(coterminal);
    final float xCorner = coterminal < PI / 2 * 3 && coterminal >= PI / 2
        ? -this.scale / 2// - xlocal
        : this.scale / 2;// - xlocal;
    final float yCorner = coterminal < PI
        ? this.scale / 2// - ylocal
        : -this.scale / 2;// - ylocal;
    final float cornerRise = (yCorner - yLocal);
    final float cornerRun = (xCorner - xLocal);
    final float marchIncrement = (float) Math.sqrt(cornerRun * cornerRun + cornerRise * cornerRise);
    final float xIncrement = marchIncrement * marchAngleAdjacent;
    final float yIncrement = marchIncrement * marchAngleOpposite;
    final float cornerSlope = cornerRise / cornerRun;
    final float marchSlope = (marchAngleOpposite) / (marchAngleAdjacent);
    final int quadrantLocal = (int) ((coterminal / (Math.PI * 2d)) * 4d);
    String edgeCrossed;
    try {
      edgeCrossed = new String[]{"E0", "S1", "S2", "W3", "W4", "N5", "N6", "E7"}[
        quadrantLocal * 2 + (marchSlope >= cornerSlope ? 1 : 0)
      ];
    } catch (ArrayIndexOutOfBoundsException e) {
      throw new RuntimeException(
        "coterminal:%f, quadrantLocal:%d * 2 + (marchSlope:%f >= cornerSlope:%f ? 1 : 0):%d"
          .formatted(coterminal, quadrantLocal, marchSlope, cornerSlope, (marchSlope >= cornerSlope ? 1 : 0))
      );
    }
    final float interceptAxisBound;
    final Map<String, Float> edgeInterceptScalars = Map.of(
        "E0", 1f - (xLocal + marchIncrement * marchAngleAdjacent - this.scale / 2) / (marchIncrement * marchAngleAdjacent),
        "S1", 1f - (yLocal + marchIncrement * marchAngleOpposite - this.scale / 2) / (marchIncrement * marchAngleOpposite),
        "S2", 1f - (yLocal + marchIncrement * marchAngleOpposite - this.scale / 2) / (marchIncrement * marchAngleOpposite),
        "W3", 1f - (xLocal + marchIncrement * marchAngleAdjacent + this.scale / 2) / (marchIncrement * marchAngleAdjacent),
        "W4", 1f - (xLocal + marchIncrement * marchAngleAdjacent + this.scale / 2) / (marchIncrement * marchAngleAdjacent),
        "N5", 1f - (yLocal + marchIncrement * marchAngleOpposite + this.scale / 2) / (marchIncrement * marchAngleOpposite),
        "N6", 1f - (yLocal + marchIncrement * marchAngleOpposite + this.scale / 2) / (marchIncrement * marchAngleOpposite),
        "E7", 1f - (xLocal + marchIncrement * marchAngleAdjacent - this.scale / 2) / (marchIncrement * marchAngleAdjacent)
    );
    final int visibilityByEdgeInitial;
    switch (edgeCrossed.charAt(0)) {
        case 'E': visibilityByEdgeInitial = EAST_VISIBLE;
        break;
        case 'S': visibilityByEdgeInitial = SOUTH_VISIBLE;
        break;
        case 'W': visibilityByEdgeInitial = WEST_VISIBLE;
        break;
        case 'N': visibilityByEdgeInitial = NORTH_VISIBLE;
        break;
        default: throw new IllegalStateException("Unexpected value: " + edgeCrossed.charAt(0));
    };
    final int cell = (columnIndex | rowIndex) < 0 || columnIndex >= this.width || rowIndex >= this.height ? 0 : this.cells[rowIndex][columnIndex];
    //return Optional.<Step>of(
      return new Step(
        coterminal,
        x,
        y,
        marchIncrement,
        xIncrement,
        yIncrement,
        edgeInterceptScalars.get(edgeCrossed) * marchAngleAdjacent * marchIncrement,
        edgeInterceptScalars.get(edgeCrossed) * marchAngleOpposite * marchIncrement,
        visibilityByEdgeInitial & cell,// | (cell & ~0xf),
        viewportColumn,
        depth
        //previous
      );
    //);
  }
}
