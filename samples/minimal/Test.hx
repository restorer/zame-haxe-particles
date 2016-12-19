package ;

class Test {
    static function main() {
        #if js
            trace("JS");
        #else
            trace("NOT JS");
        #end
    }
}
