package;

import Sexpr.*;

// Special forms to include: quote, if, do (which is like progn in CL), lambda,
// let, labels, function, throw, catch, mut (which is like setf in CL)

/* SPECIAL FORMS
 
- QUOTE, IF    : do what you'd expect
- DO           : is like PROGN in CL or BEGIN in Scheme
- LAMBDA       : should be as close as possible to CL's lambda
- FUNCTION     : lookups up a symbol in the function environment
- LET          : basically CL's let*
- LABELS       : should behave much like CL's labels
- MUT          : behaves like CL's Setf

// 

*/

class Evaluator {

    var globalEnv: Env<Sexpr>;
    var globalFenv: Env<FnType>;

    public function eval(sexpr:Sexpr, ?env:Env<Sexpr>, ?fenv:Env<FnType>):EvalResult {
        env = if (env == null) globalEnv else env;
        fenv = if (fenv == null) globalFenv else fenv;

        return switch (sexpr) {
            case Atom(Sym("NIL")):
            Ok(Atom(Nil));
            
            case Atom(Sym("TRUE")):
            Ok(Atom(True));
            
            case Atom(Sym(name)):
            evalSymbol(name, env);
            
            case Atom(_): // keywords, strings, numbers, objects, functions
            Ok(sexpr);
            
            case Cons(Atom(Sym("#QUASIQUOTE")), Cons(expr, Atom(Nil))):
            evalQuasiQuoted(expr, env, fenv);
            
            case Cons(Atom(Sym("QUOTE")), Cons(expr,Atom(Nil))):
            Ok(expr);
            
            case Cons(Atom(Sym("IF")), Cons(condExpr, Cons(thenExpr, elseExpr))):
            evalIf(condExpr, thenExpr, elseExpr, env, fenv);
            
            case Cons(Atom(Sym("PROGN")), rest):
            evalDo(rest, env, fenv);
            
            case Cons(Atom(Sym("LAMBDA")),  Cons(lambdaList, body)):
            makeFunction(lambdaList, body, env, fenv);

            case Cons(Atom(Sym("MACRO")), Cons(lambdaList, body)):
            makeMacro(lambdaList, body, env, fenv);
            
            case Cons(Atom(Sym("FUNCTION")), Cons( fn, Atom(Nil))):
            evalFunctionLookup(fn, env, fenv);
            
            case Cons(Atom(Sym("DEFVAR")), Cons(Atom(Sym(variable)), Cons(expr, _))):
            eval(expr, env, fenv).then( value -> {
                globalEnv.update(variable, value, true);
                return Ok(Atom(Sym(variable)));
            });

            case Cons(Atom(Sym("DEFUN")), Cons(Atom(Sym(variable)), Cons(lambdaList, body))):
            makeFunction(lambdaList, body, env, fenv)
                .then(fn -> switch(fn) {
                    case Atom(Fn(fn)): {
                        globalFenv.update(variable, fn, true);
                        return Ok(Atom(Sym(variable)));
                    }
                    default: throw "something has gone horribly wrong";
                });

            case Cons(fexpr, args):
            functionApplication(fexpr, args, env, fenv);
            
            default:
            Err(SyntaxError(sexpr));
        };
    }
    
    function evalQuasiQuoted(sexpr:Sexpr, env:Env<Sexpr>, fenv:Env<FnType>): EvalResult {
        switch (sexpr)
        {
            case Cons(Cons(Atom(Sym("#UNQUOTE")), Cons(expr, Atom(Nil))), rest):
            {
                switch ( eval(expr, env, fenv) )
                {
                    case Ok(val): switch( evalQuasiQuoted( rest, env, fenv ))
                    {
                        case Ok( rest2 ):
                        return Ok( Cons(val, rest2) );

                        case anError:
                        return anError;
                    };

                    case anError:
                    return anError;
                }
            };

            case Cons(Cons(Atom(Sym("#SPLICE")), Cons(expr, Atom(Nil))), rest):
            {
                switch ( eval(expr, env, fenv) )
                {
                    case Ok(Atom(val)):
                    return Err(SpliceError(Atom(val)));

                    case Ok(vals): switch ( evalQuasiQuoted( rest, env, fenv ))
                    {
                        case Ok(restVal): return Ok( vals.append( restVal ));
                        case anError: return anError;
                    };

                    case anError:
                    return anError;
                }
            };
            
            case Cons(first,rest):
            {
                switch ( evalQuasiQuoted( first, env, fenv ))
                {
                    case Ok(firstVal): switch (evalQuasiQuoted( rest, env, fenv))
                    {
                        case Ok(restVal): return Ok(Cons(firstVal, restVal));
                        case anError: return anError;
                    }
                    case anError:
                    return anError;
                }
            };

            case Atom(a): return Ok(Atom(a));
        }
    }
        
    function evalSymbol(name:UnicodeString, env):EvalResult {
        return switch (env.lookup(name)) {
            case Some(val): Ok(val);
            case None: Err(UnboundSymbol(name));
        }
    }
    
    function evalIf(condExpr, thenExpr, elseExpr, env, fenv): EvalResult {
        return switch (eval(condExpr, env, fenv)) {
            case Ok(Atom(Nil)): switch (elseExpr) {
                case Cons(elseExpr2, Atom(Nil)): eval( elseExpr2, env, fenv);
                case Atom(Nil): Ok(Atom(Nil));
                default: Err(MalformedIfForm(Cons(Atom(Sym("IF")), Cons(thenExpr, elseExpr))));
            }
            case Ok(_): eval( thenExpr, env, fenv );
            case anError: anError;
        };
    }
    
    function evalDo(expr: Sexpr, env, fenv): EvalResult {
        switch (expr) {
        case Atom(_):
            return Ok(expr);        // I think this only happens when expr is Nil...??
            
        default: 
            // otherwise its a list of expressions.
            while (true) 
                switch (expr) {
                    
                case Cons(hd, Atom(Nil)):
                    return eval(hd, env, fenv);
                    
                case Cons(hd, tl): {
                    eval(hd, env, fenv);
                    expr = tl;
                }
                    
                default:
                    throw "Fatal Error in evalDo";
                }
        }
    }
    
    function makeMacro(lambdaListExpr: Sexpr,
                       body: Sexpr,
                       env:Env<Sexpr>,
                       fenv:Env<FnType>
                      ): EvalResult
    {
        if (!LambdaList.isValidExpression( lambdaListExpr ))
            return Err(MalformedLambdaList( lambdaListExpr ));

        var lambdaList = new LambdaList( lambdaListExpr );

        var f =
            function (vals:Sexpr)
        {
            return switch( lambdaList.bind( vals )) {
                case Some(bindings): evalDo(body, env.extend( bindings ), fenv);
                case None: Err( BadFunctionApplication( lambdaListExpr, vals ));
            };
        };
        return Ok(Atom(Macro(f)));
    }

    function makeFunction(lambdaListExpr: Sexpr,
                          body: Sexpr,
                          env:Env<Sexpr>,
                          fenv:Env<FnType>
                         ): EvalResult
    {
        
        if ( !LambdaList.isValidExpression( lambdaListExpr ))
            return Err(MalformedLambdaList( lambdaListExpr ));
        
        var lambdaList = new LambdaList( lambdaListExpr );
        
        var f =
            function (vals:Sexpr)
        {
            return switch (lambdaList.bind( vals )) {
                case Some(bindings): evalDo(body, env.extend( bindings ), fenv);
                case None:  Err(BadFunctionApplication(lambdaListExpr, vals));
            }
        };
        return Ok(Atom(Fn(f)));
    }
    
    function evalFunctionLookup(f:Sexpr, env:Env<Sexpr>, fenv:Env<FnType>):EvalResult {
        // f is either an Atom(Fn(_)), a Cons(Atom(Sym("LAMBDA")), _), or an Atom(Sym("name"))
        return switch(f) {
            case Atom(Fn(_)): Ok(f);
            case Atom(Macro(_)): Ok(f);

            case Atom(Sym(fname)):
            switch (fenv.lookup(fname)) {
              case Some(fnVal): Ok(Atom(Fn(fnVal)));
              case None: Err(UnboundFunctionSymbol(fname));
            };

            case Cons(Atom(Sym("MACRO")), Cons(lambdaList, body)):
            makeMacro(lambdaList, body, env, fenv);

            case Cons(Atom(Sym("LAMBDA")), Cons(lambdaList, body)):
            makeFunction(lambdaList, body, env, fenv);

            default:
            Err(BadFunctionVal(f));
        };
    }
    
    function functionApplication(fexpr:Sexpr,
                                 args:Sexpr,
                                 env:Env<Sexpr>,
                                 fenv:Env<FnType>
                                ): EvalResult
    {
        return evalFunctionLookup(fexpr, env, fenv)
            .then(fnTerm -> switch (fnTerm) {
                case Atom(Macro(fn)): fn( args ).then( expr -> eval( expr, env, fenv));
                case Atom(Fn(fn)): evalList(args, env, fenv).then(fn);
                default: Err(BadFunctionVal(fexpr)); // wont happen
            });
    }
        
    function evalList(args: Sexpr, env: Env<Sexpr>, fenv: Env<FnType>): EvalResult {
        var acc = Atom( Nil );
        while ( !args.isNil() ) switch ( args ) {
            case Cons( hd, tl ): {
                args = tl;
                switch ( eval(hd, env, fenv) ) {
                case Ok( val ): acc = Cons(val, acc);
                case errVal: return errVal;
                }
            }
            default: throw "Fatal Error while evaluating argument list.";
        }
        return Ok( acc.reverse() );
    }
    
    public function new () {
        globalEnv = new Env(new MapBindings());
        globalFenv = new Env(new FunctionsPrelude()).extend(new MapBindings());
    }
    
}
