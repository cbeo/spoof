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

  public static function isList(expr:Sexpr):Bool {
    return isCons(expr) || isNil(expr);
  }

  public static function isSymbol(expr:Sexpr):Bool {
    return switch (expr) {
    case Atom(Sym(_)): true;
    case _: false;
    };
  }

  public static function isNumber(expr:Sexpr):Bool {
    return switch (expr) {
    case Atom(Z(_)) | Atom(R(_)): true;
    case _: false;
    };
  }

    public static function negate(expr:Sexpr):Sexpr {
        return switch (expr) {
            case Atom(Z(n)): Atom(Z(-1 * n));
            case Atom(R(n)): Atom(R(-1 * n));
            default: throw "Fatal: Cannot negate non numeric value";
        };
    }

  // intended to get the name of symbols
  public static function symbolName(expr:Sexpr):UnicodeString {
    return switch (expr) {
    case Atom(Sym(name)): name;
    case Atom(Kwd(name)): name;
    default: throw "Fatal Error. symbolName called with non-symbol argument";
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

    public static function append(e1: Sexpr, e2:Sexpr): Sexpr {
        var acc = e2;
        var rev = e1.reverse();
        rev.foreach( t -> acc = Cons(t, acc));
        return acc;
    }

  public static function reverse(exp:Sexpr):Sexpr {
    var acc = Atom(Nil);

    while ( !isNil(exp) ) switch (exp) {
      case Cons(hd,tl): {
        acc = Cons(hd, acc);
        exp = tl;
      }
      default: {}
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

  public static function foreach(exp:Sexpr, fn:Sexpr->Void) {
    while ( !isNil(exp) ) switch (exp) {
      case Cons(hd,tl): {
        fn(hd);
        exp = tl;
      }
      default:
        throw "fatal error, expression is not a list";
      }
  }

  public static function list(a:Array<Sexpr>):Sexpr {
    var sexpr = Atom(Nil);
    a.reverse();
    for (s in a) sexpr = Cons(s,sexpr);
    return sexpr;
  }

}
