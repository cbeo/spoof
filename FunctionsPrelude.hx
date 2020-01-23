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

  static function cons(sexpr: Sexpr):EvalResult {
    return switch(sexpr) {
    case Cons(hd, Cons(tl, Atom(Nil))):
      Ok(Cons(hd,tl));
    default:
      Err(SyntaxError(sexpr));
    }
  }

  static function head(sexpr: Sexpr):EvalResult {
    return switch (sexpr) {
    case Cons(Atom(Nil),Atom(Nil)): Ok(Atom(Nil));
    case Cons(Cons(hd,_),Atom(Nil)): Ok(hd);
    default:
      Err(SyntaxError(sexpr));
    };
  }

  static function tail(sexpr: Sexpr):EvalResult {
    return switch (sexpr) {
    case Cons(Atom(Nil),Atom(Nil)): Ok(Atom(Nil));
    case Cons(Cons(_,tl),Atom(Nil)): Ok(tl);
    default:
      Err(SyntaxError(sexpr));
    };
  }

  public function exists(name:UnicodeString):Bool {
    return get(name) != null;
  }

  public function get(name:UnicodeString):Null<FnType> {
    return switch (name) {
    case "+": plus;
    case "CONS": cons;
    case "HEAD" | "CAR" | "FIRST": head;
    case "TAIL" | "CDR" | "REST" : tail;
    default: null;
    }
  }

  public function set(name:UnicodeString,fn:FnType) {
    throw "cannot overwrite prelude function";
  }

  public function new () {}

}