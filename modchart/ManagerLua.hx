package modchart;

import haxe.ds.StringMap;
import modchart.backend.math.Vector3;
import modchart.backend.core.VisualParameters;
import modchart.backend.core.ModifierParameters;
import modchart.engine.modifiers.DynamicModifier;
import modchart.engine.events.Event;
import flixel.tweens.FlxEase;
import modchart.engine.PlayField;

/**
 * ManagerLua - Lua ↔ Haxe bridge for FunkinModchart
 * Allows Lua to add, modify, and control modchart modifiers in real time.
 */
class ManagerLua {
    private static var luaRenderFuncs:StringMap<Dynamic> = new StringMap();
    private static var luaVisualFuncs:StringMap<Dynamic> = new StringMap();

    /** Register a Lua table containing name, render, visuals */
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

    /** Run a Lua render function */
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

    /** Run a Lua visuals function */
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

    /** Add a DynamicModifier from Lua */
    public static function addModifierLua(name:String, field:Int = -1):Void {
        var pf:PlayField = Manager.instance.playfields[0];
        var modifier = new DynamicModifier(pf);
        modifier.renderFunc = (pos, params) -> runRender(name, pos, params);
        modifier.visualsFunc = (vis, params) -> runVisuals(name, vis, params);
        Manager.instance.addScriptedModifier(name, modifier, field);
    }

    /** Adds modifier and sets percent immediately */
    public static function addModifierLuaPercent(name:String, percent:Float = 1, field:Int = -1):Void {
        addModifierLua(name, field);
        Manager.instance.setPercent(name, percent);
    }

    // -------------------------------
    // Utility / Ease Functions
    // -------------------------------

    // -------------------------------
// Utility / Ease Functions
// -------------------------------
private static function getEaseByString(easeName:String) {
    if (easeName == null) return FlxEase.linear;
    switch (easeName.toLowerCase().trim()) {
        case "backin": return FlxEase.backIn;
        case "backinout": return FlxEase.backInOut;
        case "backout": return FlxEase.backOut;

        case "bouncein": return FlxEase.bounceIn;
        case "bounceinout": return FlxEase.bounceInOut;
        case "bounceout": return FlxEase.bounceOut;

        case "circin": return FlxEase.circIn;
        case "circinout": return FlxEase.circInOut;
        case "circout": return FlxEase.circOut;

        case "cubein": return FlxEase.cubeIn;
        case "cubeinout": return FlxEase.cubeInOut;
        case "cubeout": return FlxEase.cubeOut;

        // common synonyms
        case "cubicin": return FlxEase.cubeIn;
        case "cubicinout": return FlxEase.cubeInOut;
        case "cubicout": return FlxEase.cubeOut;

        case "elasticin": return FlxEase.elasticIn;
        case "elasticinout": return FlxEase.elasticInOut;
        case "elasticout": return FlxEase.elasticOut;

        case "expoin": return FlxEase.expoIn;
        case "expoinout": return FlxEase.expoInOut;
        case "expoout": return FlxEase.expoOut;

        case "quadin": return FlxEase.quadIn;
        case "quadinout": return FlxEase.quadInOut;
        case "quadout": return FlxEase.quadOut;

        case "quartin": return FlxEase.quartIn;
        case "quartinout": return FlxEase.quartInOut;
        case "quartout": return FlxEase.quartOut;

        case "quintin": return FlxEase.quintIn;
        case "quintinout": return FlxEase.quintInOut;
        case "quintout": return FlxEase.quintOut;

        case "sinein": return FlxEase.sineIn;
        case "sineinout": return FlxEase.sineInOut;
        case "sineout": return FlxEase.sineOut;

        case "smoothstepin": return FlxEase.smoothStepIn;
        case "smoothstepinout": return FlxEase.smoothStepInOut;
        case "smoothstepout": return FlxEase.smoothStepOut;

        case "smootherstepin": return FlxEase.smootherStepIn;
        case "smootherstepinout": return FlxEase.smootherStepInOut;
        case "smootherstepout": return FlxEase.smootherStepOut;

        // explicit linear fallback names
        case "linear": return FlxEase.linear;
        case "none": return FlxEase.linear;

        default:
            // last-resort attempt: try to pick FlxEase by simple heuristics
            // (e.g., allow "sine" -> sineInOut)
            if (easeName.toLowerCase().contains("sine")) return FlxEase.sineInOut;
            if (easeName.toLowerCase().contains("quad")) return FlxEase.quadInOut;
            if (easeName.toLowerCase().contains("cube") || easeName.toLowerCase().contains("cubic")) return FlxEase.cubeInOut;
            return FlxEase.linear;
    }
}

    public static function ease(name:String, beat:Float, length:Float, value:Float = 1, easeName:String = "linear", player:Int = -1, field:Int = -1):Void {
        var easeFunc = getEaseByString(easeName);
        Manager.instance.ease(name, beat, length, value, easeFunc, player, field);
    }

    public static function add(name:String, beat:Float, length:Float, value:Float = 1, easeName:String = "linear", player:Int = -1, field:Int = -1):Void {
        var easeFunc = getEaseByString(easeName);
        Manager.instance.add(name, beat, length, value, easeFunc, player, field);
    }

    // -------------------------------
    // Other Lua Helpers
    // -------------------------------

    public static function setPercent(name:String, value:Float, player:Int = -1, field:Int = -1):Void {
        Manager.instance.setPercent(name, value, player, field);
    }

    public static function getPercent(name:String, player:Int = 0, field:Int = 0):Float {
        return Manager.instance.getPercent(name, player, field);
    }

    public static function set(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1):Void {
        Manager.instance.set(name, beat, value, player, field);
    }

    public static function setAdd(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1):Void {
        Manager.instance.setAdd(name, beat, value, player, field);
    }

    public static function callback(beat:Float, callback:Dynamic, field:Int = -1):Void {
        Manager.instance.callback(beat, function(e:Event) {
            try callback(e) catch (err:Dynamic) trace("[ManagerLua] Error in Lua callback: " + err);
        }, field);
    }

    public static function repeater(beat:Float, length:Float, callback:Dynamic, field:Int = -1):Void {
        Manager.instance.repeater(beat, length, function(e:Event) {
            try callback(e) catch (err:Dynamic) trace("[ManagerLua] Error in Lua repeater: " + err);
        }, field);
    }

    public static function alias(name:String, alias:String, field:Int = -1):Void {
        Manager.instance.alias(name, alias, field);
    }

    public static function addEvent(evOrFunc:Dynamic, field:Int = -1):Void {
        if (evOrFunc == null) return;
        Manager.instance.addEvent(new Event(0, function(e) {
            try evOrFunc(e) catch (err:Dynamic) trace("[ManagerLua] Error in addEvent: " + err);
        }, null), field);
    }
}
