package spoof;

abstract MapBindings<T>(Map<UnicodeString,T>) 
    from Map<UnicodeString,T> to Map<UnicodeString,T>
    {
        public inline function new() {
            this = new Map();
        }
    }

