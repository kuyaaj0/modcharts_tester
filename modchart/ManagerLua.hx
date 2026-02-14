package modchart;

import haxe.ds.StringMap;
import modchart.backend.math.Vector3;
import modchart.backend.core.VisualParameters;
import modchart.backend.core.ModifierParameters;
import modchart.engine.modifiers.Modifier;
import modchart.Manager;
import flixel.util.FlxEase.EaseFunction;

/**
 * ManagerLua is the bridge between Lua scripts and the modchart system.
 * It allows Lua to register custom modifiers that affect arrow positions,
 * visuals, and call Manager functions from Lua.
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

    // ===========================
    // Expose Haxe Manager functions to Lua
    // ===========================

    public static function addModifier(name:String, field:Int = -1) {
        Manager.instance.addModifier(name, field);
    }

    public static function addScriptedModifier(name:String, instance:Dynamic, field:Int = -1) {
        Manager.instance.addScriptedModifier(name, cast(instance, Modifier), field);
    }

    public static function setPercent(name:String, value:Float, player:Int = -1, field:Int = -1) {
        Manager.instance.setPercent(name, value, player, field);
    }

    public static function getPercent(name:String, player:Int = 0, field:Int = 0):Float {
        return Manager.instance.getPercent(name, player, field);
    }

    public static function addEvent(event:Dynamic, field:Int = -1) {
        Manager.instance.addEvent(event, field);
    }

    public static function set(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1) {
        Manager.instance.set(name, beat, value, player, field);
    }

    public static function ease(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, player:Int = -1, field:Int = -1) {
        Manager.instance.ease(name, beat, length, value, easeFunc, player, field);
    }

    public static function add(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, player:Int = -1, field:Int = -1) {
        Manager.instance.add(name, beat, length, value, easeFunc, player, field);
    }

    public static function setAdd(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1) {
        Manager.instance.setAdd(name, beat, value, player, field);
    }

    public static function repeater(beat:Float, length:Float, callback:Dynamic->Void, field:Int = -1) {
        Manager.instance.repeater(beat, length, callback, field);
    }

    public static function callback(beat:Float, callback:Dynamic->Void, field:Int = -1) {
        Manager.instance.callback(beat, callback, field);
    }

    public static function node(input:Array<String>, output:Array<String>, func:Dynamic->Void, field:Int = -1) {
        Manager.instance.node(input, output, func, field);
    }

    public static function alias(name:String, alias:String, field:Int) {
        Manager.instance.alias(name, alias, field);
    }
}
