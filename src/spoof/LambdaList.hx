package spoof;

//import Sexpr.*;

class LambdaList {

    static function validSymbol(sym:String):Bool {
        return (sym != "&REST" &&
                sym != "TRUE" &&
                sym != "NIL" &&
                sym != "&OPTIONAL" &&
                sym != "&KEY");
    }

    
    public static function isValidExpression(sexpr:Sexpr):Bool {
        return switch (sexpr) {
            case Nil: true;
            
            case Cons(Sym("&REST"),Cons(Sym(sym),Nil)):
            validSymbol( sym );
            
            case Cons(Sym("&OPTIONAL"), moreArgs):
            isOptionalArgs( moreArgs );

            case Cons(Sym("&KEY"), moreArgs):
            isKeywordArgs( moreArgs );

            case Cons(Sym(sym), moreArgs) if (validSymbol(sym)):
            isValidExpression( moreArgs );

            default: false;
        };
    }

    static function isOptionalArgs( sexpr: Sexpr) : Bool {
        return switch (sexpr) {
            case Nil: true;
            
            case Cons(Sym(sym), moreArgs) if (validSymbol(sym)):
            isOptionalArgs( moreArgs);

            case Cons(Cons(Sym(sym), Cons(_default, Nil)), moreArgs) if (validSymbol(sym)):
            isOptionalArgs(moreArgs);

            default: false;                                                                         
        };
    }

    static function isKeywordArgs( sexpr: Sexpr) : Bool {
        return switch (sexpr) {
            case Nil: true;

            case Cons(Sym(sym), moreArgs) if (validSymbol(sym)):
            isKeywordArgs( moreArgs );

            case Cons(Cons(Sym(sym), Cons(_default, Nil)), moreArgs) if (validSymbol(sym)):
            isOptionalArgs( moreArgs );

            default: false;
        };
    }

    var structure:Sexpr;
    var evaluator:FnType;

    function bindOptionals(bs:PairBindings<Sexpr>, opts:Sexpr, vals:Sexpr):Option<PairBindings<Sexpr>> {
        while (true) switch ([opts,vals]) {
            case [Nil,Nil]: return Some(bs);

            case [Cons(Sym(name), moreOpts), Nil]: {
                bs.set(name, Nil);
                opts = moreOpts;
            }

            case [Cons(Cons(Sym(name), Cons( initExpr, Nil)), moreOpts), Nil]: {
                switch (  evaluator( initExpr ) ) {
                case Ok( val ): {
                    bs.set(name, val);
                    opts = moreOpts;
                }
                case Err(_): return None;
                }
            }

            case [Cons(Sym(name), moreOpts), Cons(val,moreVals)]: {
                bs.set(name, val);
                opts = moreOpts;
                vals = moreVals;
            }

            case [Cons(Cons(Sym(name), _), moreOpts), Cons(val, moreVals)]: {
                bs.set(name, val);
                opts = moreOpts;
                vals = moreVals;
            }

            default: return None;
        }
    }

    function bindKeywordArgs(bs:PairBindings<Sexpr>,
                             kwds:Sexpr,
                             vals:Sexpr
                            ):Option<PairBindings<Sexpr>>
        {
            // relies on the kwds having already been validated when the
            // function was made
            while ( !kwds.isNil() )
                switch ( kwds ) {
                    
                case Cons(Sym(name), moreKwds): {
                    bs.set(name, vals.getf(Kwd(name)));
                    kwds = moreKwds;
                }

                case Cons(Cons(Sym(name), Cons( initExpr, Nil)), moreKwds): {
                    var lookup = vals.getf(Kwd(name));
                    kwds = moreKwds;
                    
                    if (!lookup.isNil()) {
                        bs.set(name, lookup);

                    } else switch ( evaluator( initExpr ) ) {

                        case Ok(val): bs.set( name, val);
                    
                        case Err(_): return None;
                    }
                }

                default: return None;
            };
            return Some(bs);
        }
        
    public function bind( vals: Sexpr,
                          evaluator: FnType
                        ): Option<PairBindings<Sexpr>>
        { 
            this.evaluator = evaluator;
            var vals = vals;
            var lambdaList = structure;
            var bindings = new PairBindings();

            while (true) switch ([lambdaList, vals]) {
                case [Nil, Nil]:
                return Some(bindings);

                case [Cons(Sym("&REST"), Cons(Sym(name), _)), vals]: {
                    bindings.set(name,vals);
                    return Some(bindings);
                }

                case [Cons(Sym("&OPTIONAL"), optionals), vals]: 
                return bindOptionals(bindings, optionals, vals);


                case [Cons(Sym("&KEY"), kwdargs), vals]: 
                return bindKeywordArgs(bindings, kwdargs, vals);


                case [Cons(Sym(name), llTail), Cons(head, valsTail)]: {
                    bindings.set(name,head);
                    vals = valsTail;
                    lambdaList = llTail;
                }

                default:
                return None;
            }
        }

    public function new(ll: Sexpr) {
        this.structure = ll;
    }
}
