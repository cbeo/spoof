
typedef FnType = Sexpr -> EvalResult;

enum Atomic {
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
  Ob(ob:Dynamic);       // any non-readible object (arrays, vecs, class instances, etc)
}

enum EvalError {
  UnboundSymbol(s:UnicodeString);
  UnboundFunctionSymbol(s:UnicodeString);
  BadFunctionApplication(ll: Sexpr, vals:Sexpr);
  MalformedLambdaList(ll:Sexpr);
  MalformedIfForm(form:Sexpr);
  BadFunctionVal(form:Sexpr);
  SpliceError(s:Sexpr);
  SyntaxError(expr:Sexpr);
}

typedef EvalResult = Result<EvalError,Sexpr>;

interface Bindings<T> {
  function get(name:UnicodeString):Null<T>;
  function set(name:UnicodeString, val:T):Void;
  function exists(name:UnicodeString):Bool;
}

