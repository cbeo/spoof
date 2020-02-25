package;

class Repl {
    public static function main () {
        var evaluator = new Evaluator();
        var reader = new Reader("0");

        var stdin = Sys.stdin();
        var stderr = Sys.stderr();

        var incompleteInput = true;

        var input:String = "";

        while (true) {

            try {
                var readIn = stdin.readLine();
                input = if (incompleteInput) input + readIn else readIn;
                switch (reader.read(input)) {
                case Err(err) if (err.error == "eof"):
                    incompleteInput = true;
                case Err(err): {
                    incompleteInput = false;
                    formatReadError(err);
                }
                case Ok(sexpr): {
                    incompleteInput = false;
                    switch (evaluator.eval(sexpr)) {
                    case Err(err): formatEvalError(err);
                    case Ok(val): {
                        stderr.writeString( Printer.printToString( val ) );
                    }
                    }
                    stderr.writeString("\n > ");
                }
                }
            } catch (e:Dynamic) {
                trace('exception raised: $e');
            }

        }
    }


    static function formatEvalError(e:Dynamic) {
        trace(e);
    }

    static function formatReadError(e:Dynamic) {
        trace(e);
    }

}
