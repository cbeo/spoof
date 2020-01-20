package;

enum Atomic {
  Nil;                // nil
  True;               // the true value
  Z(i:Int);             // integer
  R(f:Float);           // float
  Str(s:UnicodeString); // string
  Sym(s:UnicodeString); // symbol
  Char(c:Int);          // Unicode Character?
}


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
}
