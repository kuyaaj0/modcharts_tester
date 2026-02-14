package modchart;

import haxe.ds.StringMap;
import modchart.backend.math.Vector3; // ✅ Correct import
import modchart.backend.core.VisualParameters;
import modchart.backend.core.ModifierParameters;

/**
 * ManagerLua is the bridge between Lua scripts and the modchart system.
 * It allows Lua to register custom modifiers that affect arrow positions
 * and visuals during gameplay.
 */
class ManagerLua {
    // Stores Lua modifier functions
    private static var luaRenderFuncs:StringMap<Dynamic> = new StringMap();
    private static var luaVisualFuncs:StringMap<Dynamic> = new StringMap();

    /**
     * Register a Lua table containing 'render' and/or 'visuals' functions.
     * The table must have a unique 'name' key for identification.
     */
    public static function register(luaTable:Dynamic) {
        if (luaTable.name == null) {
            trace("[ManagerLua] Lua table missing 'name' property!");
            return;
        }

        final name:String = luaTable.name;

        if (luaTable.render != null)
            luaRenderFuncs.set(name, luaTable.render);

        if (luaTable.visuals != null)
            luaVisualFuncs.set(name, luaTable.visuals);

        trace("[ManagerLua] Registered Lua modifier: " + name);
    }

    /**
     * Call the Lua render function if it exists.
     */
    public static function runRender(name:String, pos:Vector3, params:ModifierParameters):Vector3 {
        final func = luaRenderFuncs.get(name);
        if (func == null) return pos;

        try {
            final result:Dynamic = func({x: pos.x, y: pos.y, z: pos.z}, params);
            if (result == null) return pos;

            return new Vector3(result.x, result.y, result.z);
        } catch (e:Dynamic) {
            trace("[ManagerLua] Error in Lua render '" + name + "': " + e);
            return pos;
        }
    }

    /**
     * Call the Lua visuals function if it exists.
     */
    public static function runVisuals(name:String, visuals:VisualParameters, params:ModifierParameters):VisualParameters {
        final func = luaVisualFuncs.get(name);
        if (func == null) return visuals;

        try {
            final result:Dynamic = func(visuals, params);
            if (result == null) return visuals;

            return result;
        } catch (e:Dynamic) {
            trace("[ManagerLua] Error in Lua visuals '" + name + "': " + e);
            return visuals;
        }
    }
}
