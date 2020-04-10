package spoof;

@:using(Sexpr.SexprExtensions)
enum Sexpr {
    Nil;                // nil
    True;               // the true value
    Z(i:Int);             // integer
    R(f:Float);           // float
    Str(s:UnicodeString); // string
    Sym(s:UnicodeString); // symbol
    Kwd(s:UnicodeString); // keywords
    Regex(r:EReg, str:UnicodeString);
    Char(c:Int);          // Unicode Character?
    Fn(fn:FnType);
    Macro(fn:FnType);
    Ob(ob:Dynamic);       // any non-readible object (arrays, vecs, class instances, etc)
    Cons(head:Sexpr,tail:Sexpr);
}

class SexprExtensions {

    public static function isNil(exp:Sexpr):Bool {
        return switch (exp) { case Nil: true; default: false;};
    }
    
    public static function isCons(exp:Sexpr):Bool {
        return switch (exp) { case Cons(_,_): true; default: false;};
    }
    
    public static function isAtom(expr:Sexpr):Bool {
        return !isCons(expr);
    }
    
    public static function isList(expr:Sexpr):Bool {
        return isCons(expr) || isNil(expr);
    }
    
    public static function isSymbol(expr:Sexpr):Bool {
        return switch (expr) {
            case Sym(_) | Kwd(_): true;
            default: false;
        };
    }
    
    public static function isNumber(expr:Sexpr):Bool {
        return switch (expr) {
            case Z(_) | R(_): true;
            default: false;
        };
    }

    public static function isReal(expr:Sexpr):Bool {
        return switch (expr) {
            case R(_):true;
            default: false;
        };
    }

    public static function isInt(expr:Sexpr):Bool {
        return switch (expr) {
            case Z(_):true;
            default: false;
        };
    }

    public static function isChar(expr:Sexpr):Bool {
        return switch (expr) {
            case Char(_):true;
            default: false;
        };
    }

    public static function isBool(expr:Sexpr):Bool {
        return switch (expr) {
            case Nil | True:true;
            default: false;
        };
    }

    
    public static function negate(expr:Sexpr):Sexpr {
        return switch (expr) {
            case Z(n): Z(-1 * n);
            case R(n): R(-1 * n);
            default: throw "Fatal: Cannot negate non numeric value";
        };
    }

    public static function equal(lhs:Sexpr,rhs:Sexpr):Bool {
        return Type.enumEq(lhs,rhs);
    }

    // intended to get the name of symbols
    public static function symbolName(expr:Sexpr):UnicodeString {
        return switch (expr) {
            case Sym(name): name;
            case Kwd(name): name;
            default: throw "Fatal Error. symbolName called with non-symbol argument";
        }
    }

    public static function head(exp:Sexpr):Option<Sexpr> {
        return switch (exp) {
            case Nil: Some(Nil);
            case Cons(h,_): Some(h);
            case _: None;
        };
    }

    public static function tail(exp:Sexpr):Option<Sexpr> {
        return switch (exp) {
            case Nil: Some(Nil);
            case Cons(_,tl): Some(tl);
            case _: None;
        };
    }

    public static function append(e1: Sexpr, e2:Sexpr): Sexpr {
        var acc = e2;
        var rev = e1.reverse();
        rev.foreach( t -> acc = Cons(t, acc));
        return acc;
    }

  public static function reverse(exp:Sexpr):Sexpr {
    var acc = Nil;

      while ( !exp.isNil() ) switch (exp) {
          case Cons(hd,tl): {
              acc = Cons(hd, acc);
              exp = tl;
          }
          default: throw 'Fatal Error:  $exp is not a list';
      }
      return acc;
  }

    public static function map(exp:Sexpr, fn:Sexpr->Sexpr):Sexpr {
        var acc = Nil;
        while ( !exp.isNil() ) switch (exp) {
            case Cons(hd,tl): {
                acc = Cons(fn(hd), acc);
                exp = tl;
            }
            default: throw 'Fatal Error: $exp is not a list';
        }
        return reverse(acc);
    }

    public static function foreach(exp:Sexpr, fn:Sexpr->Void) {
        while ( !exp.isNil() ) switch (exp) {
            case Cons(hd,tl): {
                fn(hd);
                exp = tl;
            }
            default: throw 'Fatal Error: $exp is not a list';
        }
    }

    public static function list(a:Array<Sexpr>):Sexpr {
        var sexpr = Nil;
        a.reverse();
        for (s in a) sexpr = Cons(s,sexpr);
        return sexpr;
    }

    public static function getf(plist:Sexpr, key:Sexpr): Sexpr {
        return switch (plist) {
            case Cons(keyEntry,Cons(valEntry, more)):
            if ( equal(keyEntry, key) ) valEntry else getf(more, key);

            default: Nil;
        };
    }

    public static function unwrap(exp:Sexpr,nilIsFalse = false):Dynamic {
        return switch(exp) {
            case Nil if (nilIsFalse): false;
            case Nil: null;
            case True: true;
            case Z(i):i;
            case R(f):f;
            case Str(s):s;
            case Sym(s):s;
            case Kwd(s):s;
            case Regex(r,_):r;
            case Char(c):c;
            case Ob(ob): ob;
            default: throw 'Fatal Error: Cannot unwrap $exp';
        };
    }
}
