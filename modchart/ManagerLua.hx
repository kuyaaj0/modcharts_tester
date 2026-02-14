package modchart.engine;

import haxe.ds.StringMap;
import modchart.backend.math.Vector3;
import modchart.backend.core.VisualParameters;
import modchart.backend.core.ModifierParameters;

class ManagerLua {
    // Store Lua function references by name
    public static var luaFunctions:StringMap<Dynamic> = new StringMap();

    /**
     * Registers a Lua function by name.
     * @param name - Function name to call later
     * @param func - The Lua function reference
     */
    public static function registerFunction(name:String, func:Dynamic):Void {
        luaFunctions.set(name, func);
    }

    /**
     * Calls a Lua function that returns a Vector3 for render.
     */
    public static function callVector3(name:String, pos:Vector3, params:ModifierParameters):Vector3 {
        if (!luaFunctions.exists(name)) return null;
        var func = luaFunctions.get(name);
        try {
            // Call the Lua function
            var result:Dynamic = func(pos, params);
            if (result == null) return null;
            
            // Convert result back to Vector3
            return cast result;
        } catch (e:Dynamic) {
            trace('[ManagerLua] Error calling Lua render function $name: $e');
            return null;
        }
    }

    /**
     * Calls a Lua function that returns VisualParameters for visuals.
     */
    public static function callVisuals(name:String, visuals:VisualParameters, params:ModifierParameters):VisualParameters {
        if (!luaFunctions.exists(name)) return null;
        var func = luaFunctions.get(name);
        try {
            var result:Dynamic = func(visuals, params);
            if (result == null) return null;
            return cast result;
        } catch (e:Dynamic) {
            trace('[ManagerLua] Error calling Lua visuals function $name: $e');
            return null;
        }
    }

    /**
     * Optional: Clear all Lua functions
     */
    public static function clear():Void {
        luaFunctions = new StringMap();
    }
}
