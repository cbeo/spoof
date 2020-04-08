package;

class FFI {

    public static function FFI_0(fn:() -> Dynamic, wrap:Dynamic->Sexpr):TaggedFunctionValue {
        return {type: "function",
                value: (sexpr) -> switch (sexpr) {
                    case Nil: Ok(wrap( fn() ));
                    default: Err(PrimOpError(sexpr, "Bad FFI"));
                }};
    }

    public static function FFI_1(fn:Dynamic ->Dynamic, wrap:Dynamic->Sexpr):TaggedFunctionValue {
        return {type: "function",
                value: (sexpr) -> switch (sexpr) {
                    case Cons(arg1, Nil): Ok(wrap( fn( arg1.unwrap() )));
                    default: Err(PrimOpError(sexpr, 'Bad FFI'));
                }};
    }

    public static function FFI_2(fn:Dynamic ->Dynamic->Dynamic,
                                 wrap:Dynamic->Sexpr):TaggedFunctionValue {
        return {type: "function",
                value: (sexpr) -> switch (sexpr) {
                    case Cons(arg1, Cons(arg2, Nil)):
                    Ok(wrap( fn( arg1.unwrap(), arg2.unwrap())));
                    default: Err(PrimOpError(sexpr, 'Bad FFI'));
                }};
    }
 
    public static function FMI_0(method:String, wrap:Dynamic -> Sexpr):TaggedFunctionValue {

        return {type: "function",
                value: (sexpr) -> switch (sexpr) {
                    case Cons(ob, Nil): {
                        var unwrapped = ob.unwrap(); // throws an error...
                        var fn = Reflect.field( unwrapped, method);
                        if (fn == null) Err(PrimOpError( sexpr, 'No method $method'))
                        else Ok( wrap( Reflect.callMethod(null, fn, [])));
                    };
                    default: Err(PrimOpError( sexpr, "Bad FFI"));
                }};
    }

}
