package;

class Test {

  public static function main () {
    testEval();
  }

  static function testPrint () {

    var reader = new Reader("10");
    var run = () -> reader.read()
      .onOk(sexpr -> trace(Printer.printToString( sexpr )))
      .onError(error -> trace('Error: $error'));

    run();

    reader.reset("10.23");
    run();

    reader.reset("(lambda (x) (list x x))");
    run();

    reader.reset("(a b c d e f g 1 2 3 4 5)");
    run();

    reader.reset("'(a b c)");
    run();
            

  }

  static function testEval  () {
    var evaluator = new Evaluator();
    var reader = new Reader("10");

    var run = () ->  reader.read()
      .onOk(sexpr -> 
            evaluator.eval(sexpr)
            .onOk(val ->
                  trace('\n${reader.input}\n    ---> ${Printer.printToString(val)}\n\n'))
            .onError(error -> trace('\nEval Error $error \n\n')))
      .onError(error -> trace('\nRead Error: $error \n\n'));

    run();

    reader.reset("(quote a-symbol)");
    run();

    reader.reset("(quote (foo bar 10 20))");
    run();

    reader.reset("(if () 1 0)");
    run();

    reader.reset("(if 1000 1 0)");
    run();

    reader.reset("(lambda (x) (if x 1 0))");
    run();

    reader.reset("(lambda () 10)");
    run();

    reader.reset("(lambda (x 10 foo) (list x nil foo))");
    run();

    reader.reset("'(\"foo\" 10 23.4 bar (ok nil true))");
    run();

    reader.reset("(do 1 2 3)");
    run();

    reader.reset("(do 1 2 3 '(foo bar) :zoobas-are-cool)");
    run();

    reader.reset("(do 1 3 ;; testing comments
                      :comments-seem-to-work?)");
    run();

    reader.reset("(if true :cool)");
    run();

    reader.reset("(if nil :cool)");
    run();

    reader.reset("(if true (if true :got-here :oh-no!) :oh-no2!)");
    run();

    reader.reset("(function (lambda () :moo))");
    run();

    reader.reset("((lambda (x) x) 10)");
    run();

    reader.reset("((lambda (x y) `(a b ,x d ,y)) 10 :foo)");
    run();

    reader.reset("((lambda () '(a b c)))");
    run ();

    reader.reset("((lambda (x y z) `(a b ,x d ,y ,@z)) 10 :foo '(foo bar goo))");
    run();

    reader.reset("#\\");
    run();

    reader.reset("#\\c");
    run();

    reader.reset("'(c o l i n)");
    run();

    reader.reset("'(#\\c #\\o #\\l #\\i #\\n #\\# #\\~ #\\space #\\newline)");
    run();

    reader.reset("(+)");
    run();

    reader.reset("(+ 1)");
    run();

    reader.reset("(+ 1 2)");
    run();

    reader.reset("(+ 1 2 3.3)");
    run();

    reader.reset("(cons 1 '(2 3))");
    run();

    reader.reset("(cons 1 (cons 2 nil))");
    run();

    reader.reset("(cons 1 2)");
    run();

    reader.reset("(cons 1)");
    run();

    reader.reset("'(1 . 2)");
    run();

    reader.reset("'(1 2 . 3)");
    run();

    reader.reset("'(1 2 . 3 4)");
    run();

    reader.reset("(car '(1 2 3))");
    run();

    reader.reset("(head nil)");
    run();

    reader.reset("(first (cons 1 2))");
    run();

    reader.reset("(cdr (cons 1 2))");
    run();

    reader.reset("(tail '(1 2 3 4))");
    run();

    reader.reset("(rest nil)");
    run();

    reader.reset("(-)");
    run();

    reader.reset("(- 10)");
    run();

    reader.reset("(- 1 1)");
    run();

    reader.reset("(- 10 3 2 1)");
    run();
  
    reader.reset("#/[fF]oo[Bb]ar/ 10");
    run();

  }


  static function testReader () {

    var reader = new Reader("10");

    var run = () -> {
                     trace(reader.input);
                     reader.read()
                     .onOk(expr -> trace('OK: $expr'))
                     .onError(err -> trace('ERROR: $err'));
    };

    run();

    reader.reset("10.3");

    run();

    reader.reset("apple");

    run();

    reader.reset("!-%$");

    run();

    reader.reset("\"Hello World!\"");

    run();

    reader.reset("  (a     b c  )   ");

    run();

    reader.reset("(a (b ((c) d) e) f)");

    run();

    reader.reset("
(defun mad-adder (&rest args)
  (fold 0 + args))
");

    run();

    reader.reset("`(foo , bar)");

    run();

    reader.reset("`(foo ,bar ,zar)");

    run();

    reader.reset("`(hey ,(there `(ok ,now)) ,cool beans)");

    run();

    reader.reset("`(hey ,(there ,now) ,cool beans)");

    run();

    reader.reset("(defmacro let-when (var expr &body body)
                    `(let ((,var ,expr))
                        (when ,var ,@body)))");

    run();

    reader.reset("(if foo bar)");
    run();

    reader.reset("(lambda () foo)");
    run();

    reader.reset("(lambda (x) (foo x))");
    run();

    reader.reset("(lambda x (foo x))");
    run();


  }

}
