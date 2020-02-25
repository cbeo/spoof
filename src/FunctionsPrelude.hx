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
      default: return Err(PrimOpError(sexpr, "Trying to add something that is not a number."));
      }
    return Ok(Atom(sum));
  }

  static function minus(sexpr: Sexpr):EvalResult {
    if (sexpr.isNil()) return Err(SyntaxError(sexpr));
    switch (sexpr) {
    case Cons(Atom(hd),Atom(Nil)) if (PrimOps.isNumber(hd)):
      return Ok(Atom(PrimOps.negate(hd)));

    case Cons(Atom(hd), rest) if (PrimOps.isNumber(hd)): {
        var diff = hd;
        while ( !rest.isNil() ) switch (rest) {
          case Cons(Atom(num), tl) if (PrimOps.isNumber(num)): {
              diff = PrimOps.minus(diff, num);
              rest = tl;
            }
          default: return Err(PrimOpError(sexpr, "Trying to subtract something that is not a number."));
          }
        return Ok(Atom(diff));
      };
    default: return Err(PrimOpError(sexpr, "Trying to subtract something that is not a number."));
    }
  }

  static function cons(sexpr: Sexpr):EvalResult {
    return switch(sexpr) {
    case Cons(hd, Cons(tl, Atom(Nil))):
      Ok(Cons(hd,tl));
    default:
      Err(PrimOpError(sexpr, "CONS takes exactly two arguments"));
    }
  }

  static function first(sexpr: Sexpr):EvalResult {
    return switch (sexpr) {
    case Cons(Atom(Nil),Atom(Nil)): Ok(Atom(Nil));
    case Cons(Cons(hd,_),Atom(Nil)): Ok(hd);
    default:
      Err(PrimOpError(sexpr, "FIRST takes exactly one argument, either NIL or a CONS value"));
    };
  }

  static function rest(sexpr: Sexpr):EvalResult {
    return switch (sexpr) {
    case Cons(Atom(Nil),Atom(Nil)): Ok(Atom(Nil));
    case Cons(Cons(_,tl),Atom(Nil)): Ok(tl);
    default:
      Err(PrimOpError(sexpr, "REST takes exactly one argument, either a NIL or a CONS value"));
    };
  }

  public function exists(name:UnicodeString):Bool {
    return get(name) != null;
  }

  public function get(name:UnicodeString):Null<FnType> {
    return switch (name) {
    case "+": plus;
    case "-": minus;
    case "CONS": cons;
    case "CAR" | "FIRST": first;
    case "CDR" | "REST" : rest;
    default: null;
    }
  }

  public function set(name:UnicodeString,fn:FnType) {
    throw "cannot overwrite prelude function";
  }

  public function new () {}

}