package org.zamedev.particles.util;

abstract DynamicExt(Dynamic) from Dynamic to Dynamic {
    public inline function new() {
        this = {};
    }

    @:arrayAccess
    public inline function set(key : String, value : Dynamic) : Void {
        Reflect.setField(this, key, value);
    }

    @:arrayAccess
    public inline function get(key : String) : DynamicExt {
        #if js
            return untyped this[key];
        #else
            return Reflect.field(this, key);
        #end
    }

    public inline function exists(key : String) : Bool {
        return Reflect.hasField(this, key);
    }

    public inline function remove(key : String) : Bool {
        return Reflect.deleteField(this, key);
    }

    public inline function keys() : Array<String> {
        return Reflect.fields(this);
    }
}
