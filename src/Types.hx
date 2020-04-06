
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
    Macro(fn:FnType);
    Ob(ob:Dynamic);       // any non-readible object (arrays, vecs, class instances, etc)
}

enum EvalError {
  BadFunctionApplication(ll: Sexpr, vals:Sexpr);
  BadFunctionVal(form:Sexpr);
  MalformedIfForm(form:Sexpr);
  MalformedLambdaList(ll:Sexpr);
  PrimOpError(exp:Sexpr,description:UnicodeString);
  SpliceError(s:Sexpr);
  SyntaxError(expr:Sexpr);
  UnboundFunctionSymbol(s:UnicodeString);
  UnboundSymbol(s:UnicodeString);
}

typedef EvalResult = Result<EvalError,Sexpr>;

interface Bindings<T> {
  function get(name:UnicodeString):Null<T>;
  function set(name:UnicodeString, val:T):Void;
  function exists(name:UnicodeString):Bool;
}

