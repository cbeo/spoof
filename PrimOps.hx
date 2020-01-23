package;

class PrimOps {
  public static function plus(a:Atomic, b:Atomic):Atomic {
    return switch ([a,b]) {
    case [Z(i),Z(j)]: Z(i+j);
    case [Z(i),R(f)]: R(i+f);
    case [R(f),Z(i)]: R(f+i);
    case [R(f),R(g)]: R(f+g);
    default: throw "Error, cannot add non numeric values";
    };
  }

  public static function isNumber(a:Atomic):Bool {
    return Sexpr.Atom(a).isNumber();
  }

}