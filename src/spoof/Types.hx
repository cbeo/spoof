package spoof;

typedef FnType = Sexpr -> EvalResult;

typedef TaggedFunctionValue = {
    type: String, // function or macro
    value: FnType
};


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


typedef Bindings<T> = {
  function get(name:UnicodeString):Null<T>;
  function set(name:UnicodeString, val:T):Void;
  function exists(name:UnicodeString):Bool;
}

