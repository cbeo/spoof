package;

@:using(Sexpr.SexprExtensions)
enum Sexpr {
  Atom(a:Atomic);
  Cons(head:Sexpr,tail:Sexpr);
}

class SexprExtensions {
  public static function isNil(exp:Sexpr):Bool {
    return switch (exp) {
    case Atom(Nil): true;
    case _: false;
    }
  }

  public static function isCons(exp:Sexpr):Bool {
    return switch (exp) {
    case Cons(_,_): true;
    case _: false;
    }
  }

  public static function isAtom(expr:Sexpr):Bool {
    return !isCons(expr);
  }

  public static function head(exp:Sexpr):Option<Sexpr> {
    return switch (exp) {
    case Atom(Nil): Some(exp);
    case Cons(h,_): Some(h);
    case _: None;
    }
  }

  public static function tail(exp:Sexpr):Option<Sexpr> {
    return switch (exp) {
    case Atom(Nil): Some(exp);
    case Cons(_,tl): Some(tl);
    case _: None;
    }
  }

  public static function reverse(exp:Sexpr):Sexpr {
    var acc = Atom(Nil);

    while ( !isNil(exp) ) switch (exp) {
      case Cons(hd,tl): {
        acc = Cons(hd, acc);
        exp = tl;
      }
      default: throw "Fatal Error while reversing list";
      }
    return acc;
  }

  public static function map(exp:Sexpr, fn:Sexpr->Sexpr):Sexpr {
    var acc = Atom(Nil);
    while ( !isNil(exp) ) switch (exp) {
      case Cons(hd,tl): {
        acc = Cons(fn(hd), acc);
        exp = tl;
      }
      default: throw "Fatial Error while mapping list";
      }
    return reverse(acc);
  }
}
