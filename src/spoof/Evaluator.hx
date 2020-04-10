package spoof;

//import Sexpr.*;

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
    var globalFenv: Env<TaggedFunctionValue>;

    public function eval(sexpr:Sexpr, ?env:Env<Sexpr>, ?fenv:Env<TaggedFunctionValue>):EvalResult {
        env = if (env == null) globalEnv else env;
        fenv = if (fenv == null) globalFenv else fenv;

        return switch (sexpr) {
            case Sym("NIL"):
            Ok(Nil);
            
            case Sym("TRUE"):
            Ok(True);
            
            case Sym(name):
            evalSymbol(name, env);
            
            case atom if (atom.isAtom()): // keywords, strings, numbers, objects, functions
            Ok(sexpr);
            
            case Cons(Sym("#QUASIQUOTE"), Cons(expr, Nil)):
            evalQuasiQuoted(expr, env, fenv);
            
            case Cons(Sym("QUOTE"), Cons(expr,Nil)):
            Ok(expr);
            
            case Cons(Sym("IF"), Cons(condExpr, Cons(thenExpr, elseExpr))):
            evalIf(condExpr, thenExpr, elseExpr, env, fenv);
            
            case Cons(Sym("PROGN"), rest):
            evalDo(rest, env, fenv);
            
            case Cons(Sym("LAMBDA"),  Cons(lambdaList, body)):
            makeFunction(lambdaList, body, env, fenv);

            case Cons(Sym("MACRO"), Cons(lambdaList, body)):
            makeMacro(lambdaList, body, env, fenv);
            
            case Cons(Sym("FUNCTION"), Cons( fn, Nil)):
            evalFunctionLookup(fn, env, fenv);
            
            case Cons(Sym("DEFVAR"), Cons(Sym(variable), Cons(expr, _))):
            eval(expr, env, fenv).then( value -> {
                globalEnv.update(variable, value, true);
                return Ok(Sym(variable));
            });

            case Cons(Sym("DEFUN"), Cons(Sym(variable), Cons(lambdaList, body))):
            makeFunction(lambdaList, body, env, fenv)
                .then(fn -> switch(fn) {
                    case Fn(fn): {
                        globalFenv.update(variable, {type:"function", value:fn}, true);
                        return Ok(Sym(variable));
                    }
                    default: throw "something has gone horribly wrong";
                });

            case Cons(Sym("DEFMACRO"), Cons(Sym(variable), Cons(lambdaList, body))):
            makeMacro(lambdaList, body, env, fenv)
                .then (mac -> switch(mac) {
                    case Macro(mac): {
                        globalFenv.update(variable, {type:"macro", value:mac}, true);
                        return Ok(Sym(variable));
                    }
                    default: throw "something has gone horribly wrong";
                });

            case Cons(Sym("FUNCALL"), Cons(fexpr, args)):
            eval(fexpr, env, fenv)
                .then(fn -> functionApplication(fn, args, env, fenv));

            case Cons(Sym("EVAL"), Cons(expr, Nil)):
            eval(expr, env, fenv).then( res -> eval(res, env, fenv));

            case Cons(fexpr, args):
            functionApplication(fexpr, args, env, fenv);
            
            default:
            Err(SyntaxError(sexpr));
        };
    }
    
    function evalQuasiQuoted(sexpr:Sexpr, env:Env<Sexpr>, fenv:Env<TaggedFunctionValue>): EvalResult {
        switch (sexpr)
        {
            case Cons(Cons(Sym("#UNQUOTE"), Cons(expr, Nil)), rest):
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

            case Cons(Cons(Sym("#SPLICE"), Cons(expr, Nil)), rest):
            {
                switch ( eval(expr, env, fenv) )
                {
                    case Ok(val) if (!val.isList()):
                    return Err(SpliceError(val));

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

            default: return Ok(sexpr);
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
            case Ok(Nil): switch (elseExpr) {
                case Cons(elseExpr2, Nil): eval( elseExpr2, env, fenv);
                case Nil: Ok(Nil);
                default: Err(MalformedIfForm(Cons(Sym("IF"), Cons(thenExpr, elseExpr))));
            }
            case Ok(_): eval( thenExpr, env, fenv );
            case anError: anError;
        };
    }
    
    function evalDo(expr: Sexpr, env, fenv): EvalResult {
        switch (expr) {
        case atom if (atom.isAtom()):
            return Ok(expr);        // I think this only happens when expr is Nil...??
            
        default: 
            // otherwise its a list of expressions.
            while (true) 
                switch (expr) {
                    
                case Cons(hd, Nil):
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
                       fenv:Env<TaggedFunctionValue>
                      ): EvalResult
    {
        if (!LambdaList.isValidExpression( lambdaListExpr ))
            return Err(MalformedLambdaList( lambdaListExpr ));

        var lambdaList = new LambdaList( lambdaListExpr );

        var f =
            function (vals:Sexpr)
        {
            return switch( lambdaList.bind( vals, (initExpr) -> eval(initExpr, env, fenv))) {
                case Some(bindings): evalDo(body, env.extend( bindings ), fenv);
                case None: Err( BadFunctionApplication( lambdaListExpr, vals ));
            };
        };
        return Ok(Macro(f));
    }

    function makeFunction(lambdaListExpr: Sexpr,
                          body: Sexpr,
                          env:Env<Sexpr>,
                          fenv:Env<TaggedFunctionValue>
                         ): EvalResult
    {
        
        if ( !LambdaList.isValidExpression( lambdaListExpr ))
            return Err(MalformedLambdaList( lambdaListExpr ));
        
        var lambdaList = new LambdaList( lambdaListExpr );
        
        var f =
            function (vals:Sexpr)
        {
            return switch (lambdaList.bind( vals , (initExpr) -> eval(initExpr, env, fenv))) {
                case Some(bindings): evalDo(body, env.extend( bindings ), fenv);
                case None:  Err(BadFunctionApplication(lambdaListExpr, vals));
            }
        };
        return Ok(Fn(f));
    }
    
    function evalFunctionLookup(f:Sexpr, env:Env<Sexpr>, fenv:Env<TaggedFunctionValue>):EvalResult {
        return switch(f) {
            case Fn(_): Ok(f);
            case Macro(_): Ok(f);

            case Sym(fname):
            switch (fenv.lookup(fname)) {
            case Some({type:"function", value:fnVal}): Ok(Fn(fnVal));
            case Some({type:"macro", value:fnVal}): Ok(Macro(fnVal));
            default: Err(UnboundFunctionSymbol(fname));
            };

            case Cons(Sym("MACRO"), Cons(lambdaList, body)):
            makeMacro(lambdaList, body, env, fenv);

            case Cons(Sym("LAMBDA"), Cons(lambdaList, body)):
            makeFunction(lambdaList, body, env, fenv);

            default:
            Err(BadFunctionVal(f));
        };
    }
    
    function functionApplication(fexpr:Sexpr,
                                 args:Sexpr,
                                 env:Env<Sexpr>,
                                 fenv:Env<TaggedFunctionValue>
                                ): EvalResult
    {
        return evalFunctionLookup(fexpr, env, fenv)
            .then(fnTerm -> switch (fnTerm) {
                case Macro(fn): fn( args ).then( expr -> eval( expr, env, fenv));
                case Fn(fn): evalList(args, env, fenv).then(fn);
                default: Err(BadFunctionVal(fexpr)); // wont happen
            });
    }
        
    function evalList(args: Sexpr, env: Env<Sexpr>, fenv: Env<TaggedFunctionValue>): EvalResult {
        var acc =  Nil;
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
