package;

class FunctionsPrelude {
    // can assume that the sexpr is going to be a list.

    static function plus(sexpr: Sexpr):EvalResult {
        var sum = Z(0);
        var form = sexpr;
        while (!form.isNil() ) switch (form) {
            case Cons(num,tail) if (num.isNumber()): {
                form = tail;
                sum = PrimOps.plus(sum, num);
            };
            default: return Err(PrimOpError(sexpr, "Trying to add something that is not a number."));
        }
        return Ok(sum);
    }
    

    static function mult(sexpr: Sexpr):EvalResult {
        var prod = Z(1);
        var form = sexpr;
        while (!form.isNil()) switch (form) {
            case Cons(num,tail) if (num.isNumber()): {
                form = tail;
                prod = PrimOps.mult(prod, num);
            };
            default:
            return Err(PrimOpError(sexpr, "Trying to multiply non-numeric argumetns."));
        }
        return Ok(prod);
    }
    

    static function minus(sexpr: Sexpr):EvalResult {
        if (sexpr.isNil()) return Err(SyntaxError(sexpr));
        switch (sexpr) {
        case Cons(hd, Nil) if (hd.isNumber()):
            return Ok(hd.negate());
            
        case Cons(hd, rest) if (hd.isNumber()): {
            var diff = hd;
            while ( !rest.isNil() ) switch (rest) {
                case Cons(num, tl) if (num.isNumber()): {
                    diff = PrimOps.minus(diff, num);
                    rest = tl;
                }
                default:
                return Err(PrimOpError(sexpr, "Trying to subtract something that is not a number."));
            }
            return Ok(diff);
        };
        default:
            return Err(PrimOpError(sexpr, "Trying to subtract something that is not a number."));
        }
    }
    
    static function cons(sexpr: Sexpr):EvalResult {
        return switch(sexpr) {
            case Cons(hd, Cons(tl, Nil)):
            Ok(Cons(hd,tl));
            default:
            Err(PrimOpError(sexpr, "CONS takes exactly two arguments"));
        }
    }
    
    static function first(sexpr: Sexpr):EvalResult {
        return switch (sexpr) {
            case Cons(Nil,Nil): Ok(Nil);
            case Cons(Cons(hd,_),Nil): Ok(hd);
            default:
            Err(PrimOpError(sexpr, "FIRST takes exactly one argument, either NIL or a CONS value"));
        };
    }
    
    static function rest(sexpr: Sexpr):EvalResult {
        return switch (sexpr) {
            case Cons(Nil,Nil): Ok(Nil);
            case Cons(Cons(_,tl),Nil): Ok(tl);
            default:
            Err(PrimOpError(sexpr, "REST takes exactly one argument, either a NIL or a CONS value"));
        };
    }
    
    static function equal(sexpr:Sexpr):EvalResult {
        return switch (sexpr) {
            case Cons(n1,Cons(n2,Nil)):
            if (n1.equal(n2)) Ok(True) else Ok(Nil);

            default:
            Err(PrimOpError(sexpr, 'EQ takes exactly 2 arguments'));
        };
    }

    public function exists(name:UnicodeString):Bool {
        return get(name) != null;
    }
    
    public function get(name:UnicodeString):Null<TaggedFunctionValue> {
        return switch (name) {
            case "+": {type:"function", value:plus};
            case "-": {type:"function", value:minus};
            case "*": {type:"function", value:mult};
            case "EQUAL": {type:"function", value:equal};
            case "CONS": {type:"function", value:cons};
            case "CAR" | "FIRST": {type:"function", value:first};
            case "CDR" | "REST" : {type:"function", value:rest};
            // Math FFI
            case "ABS":  FFI.FFI_1(Math.abs, R);
            case "ACOS": FFI.FFI_1(Math.acos, R);
            case "ASIN": FFI.FFI_1(Math.asin, R);
            case "ATAN": FFI.FFI_1(Math.atan, R);
            case "CEILING": FFI.FFI_1(Math.ceil, Z);
            case "COS": FFI.FFI_1(Math.cos, R);
            case "EXP": FFI.FFI_1(Math.exp, R);
            case "FLOOR": FFI.FFI_1(Math.floor, Z);
            case "LOG": FFI.FFI_1(Math.log, R);
            case "MAX": FFI.FFI_2(Math.max, R);
            case "MIN": FFI.FFI_2(Math.min, R);
            case "POW": FFI.FFI_2(Math.pow, R);
            case "RANDOM": FFI.FFI_0(Math.random, R);
            case "ROUND": FFI.FFI_1(Math.round, Z);
            case "SIN": FFI.FFI_1(Math.sin, R);
            case "SQRT": FFI.FFI_1(Math.sqrt, R);
            case "TAN": FFI.FFI_1(Math.tan, R);
            case "NANP": FFI.FFI_1(Math.isNaN, R);
            case "ATAN2": FFI.FFI_2(Math.atan2, R);

            default: null;
        }
    }
    
    public function set(name:UnicodeString,fn:TaggedFunctionValue) {
        throw "cannot overwrite prelude function";
    }
    
    public function new () {}
    
}
