package;

class FunctionsPrelude implements Bindings<FnType> {
  // can assume that the sexpr is going to be a list.

  static function plus(sexpr: Sexpr):EvalResult {
    var sum = Z(0);
    var form = sexpr;
    while (!form.isNil() ) switch (form) {
      case Cons(Atom(num),tail) if (PrimOps.isNumber(num)): {
       form = tail;
       sum = PrimOps.plus(sum, num);
      };
      default: return Err(SyntaxError(sexpr));
      }
    return Ok(Atom(sum));
  }

  public function exists(name:UnicodeString):Bool {
    return get(name) != null;
  }

  public function get(name:UnicodeString):Null<FnType> {
    return switch (name) {
    case "+": plus;
    default: null;
    }
  }

  public function set(name:UnicodeString,fn:FnType) {
    throw "cannot overwrite prelude function";
  }

  public function new () {}

}