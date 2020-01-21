package;

import Sexpr.*;

class Evaluator {

  var globalEnv: Env<Sexpr>;
  var globalFenv: Env<FnType>;

  public function eval(sexpr:Sexpr, ?env:Env<Sexpr>, ?fenv:Env<FnType>):EvalResult {
    var currentEnv = if (env != null) env else globalEnv;
    var currentFenv = if (fenv != null) fenv else globalFenv;

    return switch (sexpr) {
    case Atom(Sym("NIL")):
      Ok(Atom(Nil));

    case Atom(Sym("TRUE")):
      Ok(Atom(True));

    case Atom(Sym(name)):
      evalSymbol(name, env);

    case Atom(_):
      Ok(sexpr);

    case Cons(Atom(Sym("QUOTE")), Cons(expr,Atom(Nil))):
      Ok(expr);

    case Cons(Atom(Sym("IF")), Cons(condExpr, Cons(thenExpr,Cons(elseExpr,_)))):
      evalIf(condExpr, thenExpr, elseExpr, env, fenv);

    case Cons(Atom(Sym("DO")), rest):
      evalDo(rest, env, fenv);

    case Cons(Atom(Sym("LAMBDA")),  Cons(lambdaList, body)):
      makeFunction(lambdaList, body, env, fenv);

    case Cons(Atom(Sym(fname)), args):
      functionApplication(fname, args, env, fenv);

    default:
      Err(SyntaxError(sexpr));

    };
  }

  function evalSymbol(name:UnicodeString, env):EvalResult {
    return switch (env.lookup(name)) {
    case Some(val): Ok(val);
    case None: Err(UnboundSymbol(name));
    }
  }

  function evalIf(condExpr, thenExpr, elseExpr, env, fenv): EvalResult {
    return switch (eval(condExpr, env, fenv)) {
    case Ok(Atom(Nil)): eval( elseExpr, env, fenv);
    case Ok(_): eval( thenExpr, env, fenv );
    case anError: anError;
    };
  }

  function evalDo(expr: Sexpr, env, fenv): EvalResult {
    return switch (expr) {
    case Atom(_): Ok(expr);        // I think this only happens when expr is Nil...??

    case Cons(head, Atom(Nil)):
      eval(head, env, fenv);

    case Cons(head, tail):
      eval(head, env, fenv).then(ignore -> eval(tail, env, fenv));
    };
  }

  function makeFunction(lambdaListExpr: Sexpr,
                        body: Sexpr,
                        env:Env<Sexpr>,
                        fenv:Env<FnType>
                        ): EvalResult {

    var lambdaList = new LambdaList(lambdaListExpr);

    var f =
      function (vals:Sexpr)
      {
       return switch (lambdaList.bind( vals )) {
       case Some(bindings): eval(body, env.extend( bindings ), fenv);
       case None:  Err(MalformedLambdaList(lambdaListExpr, vals));
       }
      };
    return Ok(Atom(Fn(f)));
  }

  function functionApplication(fname:UnicodeString,
                               args:Sexpr,
                               env:Env<Sexpr>,
                               fenv:Env<FnType>
                               ): EvalResult {
    switch (fenv.lookup( fname )) {
    case None:
      return Err(UnboundFunctionSymbol(fname));

    case Some(fn):
      return evalList(args, env, fenv).then(fn);
    }    
  }

  function evalList(args: Sexpr, env: Env<Sexpr>, fenv: Env<FnType>): EvalResult {
    var acc = Atom(Nil);
    while ( !args.isNil() ) switch ( args ) {
      case Cons(hd,tl): {
        args = tl;
        switch ( eval(hd, env, fenv) ) {
        case Ok(val): acc = Cons(val, acc);
        case errVal: return errVal;
        }
      }
      default: throw "Fatal Error while evaluating argument list.";
      }
    return Ok( acc.reverse() );
  }

  public function new () {
    globalEnv = new Env([]);
    globalFenv = new Env([]);
  }

}