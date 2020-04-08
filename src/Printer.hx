package;

class Printer {

  public static function printToString(s:Sexpr, ?inList:Bool = false): UnicodeString {
    var buf = new StringBuf();

    switch (s) {
    case Nil: buf.add("NIL");
    case True: buf.add("TRUE");
    case Z(i): buf.add(Std.string(i));
    case R(f): buf.add(Std.string(f));
    case Str(s): buf.add('"$s"');
    case Sym(s): buf.add(s);
    case Regex(_,s): {
      buf.add("#/");
      buf.add(s);
      buf.add("/");
    }
    case Kwd(s): {
      buf.add(":");
      buf.add(s);
    }
    case Char(c): {
      buf.add("#\\");
      switch (c) {
      case Reader.NEWLINE:
        buf.add("Newline");

      case Reader.SPACE:
        buf.add("Space");

      case Reader.HTAB:
        buf.add("Tab");

      case Reader.RETURN:
        buf.add("Return");

      default:
        buf.addChar(c);
      }
    };
    case Fn(f): buf.add(Std.string(f));
    case Macro(f): buf.add(Std.string(f));
    case Ob(ob): buf.add(Std.string(ob));
    case Cons(Sym("#QUASIQUOTE"), Cons(quoted,Nil)): {
      buf.add("`");
      buf.add( printToString( quoted ));
    }
    case Cons(Sym("#UNQUOTE"), Cons(unquoted, Nil)): {
      buf.add(",");
      buf.add( printToString( unquoted ));
    }
    case Cons(Sym("#SPLICE"), Cons(spliced, Nil)): {
      buf.add(",@");
      buf.add( printToString( spliced ));
    }
    case Cons(hd, Nil): {
      if (!inList) buf.add("(");
      buf.add( printToString(hd) );
      buf.add(")");
    }
    case Cons(hd, tl) if(tl.isAtom()): {
        if (!inList) buf.add("(");
        buf.add( printToString(hd) );
        buf.add(" . ");
        buf.add( printToString(tl) );
        buf.add(")");
      }
    case Cons(hd,tl): {
      if (!inList) buf.add("(");
      buf.add( printToString(hd) );
      buf.add(" ");
      buf.add( printToString(tl, true) );
    }
    }

    return buf.toString();
  }

}
