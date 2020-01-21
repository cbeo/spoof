package;

class Printer {

  public static function printToString(s:Sexpr, ?inList:Bool = false): UnicodeString {
    var buf = new StringBuf();

    switch (s) {
    case Atom(Nil): buf.add("NIL");
    case Atom(True): buf.add("TRUE");
    case Atom(Z(i)): buf.add(Std.string(i));
    case Atom(R(f)): buf.add(Std.string(f));
    case Atom(Str(s)): buf.add('"$s"');
    case Atom(Sym(s)): buf.add(s);
    case Atom(Kwd(s)): {
      buf.add(":");
      buf.add(s);
    }
    case Atom(Char(c)): {
      buf.add("#\\");
      buf.addChar(c);
    }
    case Atom(Fn(f)): buf.add(Std.string(f));
    case Atom(Ob(ob)): buf.add(Std.string(ob));
    case Cons(Atom(Sym("#QUASIQUOTE")), Cons(quoted,Atom(Nil))): {
      buf.add("`");
      buf.add( printToString( quoted ));
    }
    case Cons(Atom(Sym("#UNQUOTE")), Cons(unquoted, Atom(Nil))): {
      buf.add(",");
      buf.add( printToString( unquoted ));
    }
    case Cons(Atom(Sym("#SPLICE")), Cons(spliced, Atom(Nil))): {
      buf.add(",@");
      buf.add( printToString( spliced ));
    }
    case Cons(hd, Atom(Nil)): {
      if (!inList) buf.add("(");
      buf.add( printToString(hd) );
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