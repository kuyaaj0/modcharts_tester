package modchart;

import haxe.ds.StringMap;
import modchart.backend.math.Vector3;
import modchart.backend.core.VisualParameters;
import modchart.backend.core.ModifierParameters;
import modchart.engine.modifiers.DynamicModifier;
import modchart.backend.util.ModchartUtil;
import modchart.engine.events.Event;
import modchart.backend.core.Node.NodeFunction;

/**
 * ManagerLua: Haxe <-> Lua bridge for FunkinModchart.
 *
 * - Registers Lua modifier tables (render / visuals).
 * - Provides helper functions to add modifiers and control them from Lua.
 * - Resolves easing names via ModchartUtil so Lua can pass strings.
 */
class ManagerLua {
    private static var luaRenderFuncs:StringMap<Dynamic> = new StringMap();
    private static var luaVisualFuncs:StringMap<Dynamic> = new StringMap();

    /**
     * Register a Lua table containing 'name' and optional 'render'/'visuals' functions.
     * Example Lua table:
     *  { name = "spin", render = function(pos, params) ... end, visuals = function(vis, params) ... end }
     */
    public static function register(luaTable:Dynamic):Void {
        if (luaTable == null) {
            trace("[ManagerLua] register: null table");
            return;
        }
        if (luaTable.name == null) {
            trace("[ManagerLua] register: Lua table missing 'name' property!");
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
     * Run a Lua render function (position) if registered.
     */
    public static function runRender(name:String, pos:Vector3, params:ModifierParameters):Vector3 {
        final func = luaRenderFuncs.get(name);
        if (func == null) return pos;

        try {
            final luaPos = { x: pos.x, y: pos.y, z: pos.z };
            final result:Dynamic = func(luaPos, params);
            if (result == null || result.x == null || result.y == null || result.z == null)
                return pos;

            return new Vector3(result.x, result.y, result.z);
        } catch (e:Dynamic) {
            trace("[ManagerLua] Error in Lua render '" + name + "': " + e);
            return pos;
        }
    }

    /**
     * Run a Lua visuals function if registered.
     */
    public static function runVisuals(name:String, visuals:VisualParameters, params:ModifierParameters):VisualParameters {
    final func = luaVisualFuncs.get(name);
    if (func == null) return visuals;

    try {
        final result:Dynamic = func(visuals, params);
        if (result == null) return visuals;

        return {
            scaleX: result.scaleX != null ? result.scaleX : visuals.scaleX,
            scaleY: result.scaleY != null ? result.scaleY : visuals.scaleY,
            alpha:  result.alpha  != null ? result.alpha  : visuals.alpha,
            glow:   result.glow   != null ? result.glow   : visuals.glow,
            glowR:  result.glowR  != null ? result.glowR  : visuals.glowR,
            glowG:  result.glowG  != null ? result.glowG  : visuals.glowG,
            glowB:  result.glowB  != null ? result.glowB  : visuals.glowB,
            angleX: result.angleX != null ? result.angleX : visuals.angleX,
            angleY: result.angleY != null ? result.angleY : visuals.angleY,
            angleZ: result.angleZ != null ? result.angleZ : visuals.angleZ,
            skewX:  result.skewX  != null ? result.skewX  : visuals.skewX,
            skewY:  result.skewY  != null ? result.skewY  : visuals.skewY
        };
    } catch (e:Dynamic) {
        trace("[ManagerLua] Error in Lua visuals '" + name + "': " + e);
        return visuals;
    }
}

    /**
     * Wrap a Lua modifier into a DynamicModifier and register it to Manager.
     * After calling this, you may set percent/ease/etc. as usual.
     */
    public static function addModifierLua(name:String, field:Int = -1):Void {
        var modifier = new DynamicModifier();
        modifier.renderFunc = (pos, params) -> runRender(name, pos, params);
        modifier.visualsFunc = (vis, params) -> runVisuals(name, vis, params);
        Manager.instance.addScriptedModifier(name, modifier, field);
    }

    public static function addModifierLuaPercent(name:String, percent:Float = 1, field:Int = -1):Void {
        addModifierLua(name, field);
        Manager.instance.setPercent(name, percent);
    }

    // Basic passthroughs

    public static function setPercent(name:String, value:Float, player:Int = -1, field:Int = -1):Void {
        Manager.instance.setPercent(name, value, player, field);
    }

    public static function getPercent(name:String, player:Int = 0, field:Int = 0):Float {
        return Manager.instance.getPercent(name, player, field);
    }

    public static function set(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1):Void {
        Manager.instance.set(name, beat, value, player, field);
    }

    /**
     * Ease by string. Lua usually sends ease names, so accept a string and resolve it.
     * easeName example: "sineInOut", "linear", etc.
     */
    public static function ease(name:String, beat:Float, length:Float, value:Float = 1, easeName:String = "linear", player:Int = -1, field:Int = -1):Void {
        var easeFunc = ModchartUtil.getFlxEaseByString(easeName);
        Manager.instance.ease(name, beat, length, value, easeFunc, player, field);
    }

    public static function add(name:String, beat:Float, length:Float, value:Float = 1, easeName:String = "linear", player:Int = -1, field:Int = -1):Void {
        var easeFunc = ModchartUtil.getFlxEaseByString(easeName);
        Manager.instance.add(name, beat, length, value, easeFunc, player, field);
    }

    public static function setAdd(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1):Void {
        Manager.instance.setAdd(name, beat, value, player, field);
    }

    /**
     * callback - pass a Dynamic function (Lua closure). Internally we create the Haxe callback wrapper.
     */
    public static function callback(beat:Float, callback:Dynamic, field:Int = -1):Void {
        Manager.instance.callback(beat, function(e:modchart.events.Event) {
            try {
                callback(e);
            } catch (err:Dynamic) {
                trace("[ManagerLua] Error in Lua callback wrapper: " + err);
            }
        }, field);
    }

    /**
     * repeater - same idea, callback will be invoked repeatedly.
     */
    public static function repeater(beat:Float, length:Float, callback:Dynamic, field:Int = -1):Void {
        Manager.instance.repeater(beat, length, function(e:modchart.events.Event) {
            try {
                callback(e);
            } catch (err:Dynamic) {
                trace("[ManagerLua] Error in Lua repeater wrapper: " + err);
            }
        }, field);
    }

    /**
     * node: registers a node. Accepts a Dynamic function and casts it to NodeFunction.
     * Lua node function signature should match expected NodeFunction (Array<Float>, Int) -> Array<Float>
     */
    public static function node(input:Array<String>, output:Array<String>, func:Dynamic, field:Int = -1):Void {
        // attempt to cast the dynamic function to a NodeFunction; if it fails it'll throw
        try {
            Manager.instance.node(input, output, cast func, field);
        } catch (e:Dynamic) {
            trace("[ManagerLua] Failed to register node: " + e);
        }
    }

    /**
     * alias helper
     */
    public static function alias(name:String, alias:String, field:Int = -1):Void {
        Manager.instance.alias(name, alias, field);
    }

    /**
     * addEvent passthrough (accepts a prebuilt Event object, or a Dynamic callback which will be wrapped).
     */
    public static function addEvent(evOrFunc:Dynamic, field:Int = -1):Void {
        if (Reflect.isObject(evOrFunc) && Reflect.hasField(evOrFunc, "beat")) {
            // assume a full Event-like object was passed
            Manager.instance.addEvent(evOrFunc, field);
            return;
        }

        // otherwise assume a function and wrap it into Event
        if (evOrFunc != null) {
            Manager.instance.addEvent(new modchart.events.Event(0, function(e) {
                try { evOrFunc(e); } catch (err:Dynamic) { trace("[ManagerLua] Error in addEvent wrapper: " + err); }
            }, null), field);
        }
    }
}
