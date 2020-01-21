
typedef FnType = Sexpr -> EvalResult;

enum Atomic {
  Nil;                // nil
  True;               // the true value
  Z(i:Int);             // integer
  R(f:Float);           // float
  Str(s:UnicodeString); // string
  Sym(s:UnicodeString); // symbol
  Char(c:Int);          // Unicode Character?
  Fn(fn:FnType);
  Ob(ob:Dynamic);       // any non-readible object (arrays, vecs, class instances, etc)
}

enum EvalError {
  UnboundSymbol(s:UnicodeString);
  UnboundFunctionSymbol(s:UnicodeString);
  MalformedLambdaList(ll: Sexpr, vals:Sexpr);
  SyntaxError(expr:Sexpr);
}

typedef EvalResult = Result<EvalError,Sexpr>;
