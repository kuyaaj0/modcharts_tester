package modchart.engine.modifiers;

import modchart.ManagerLua;
import modchart.backend.math.Vector3;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

/**
 * DynamicModifier now supports Lua-based modifiers.
 * You can assign a `luaName` to run Lua functions for both render and visuals.
 */
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class DynamicModifier extends Modifier {
    /** Optional Lua modifier name */
    public var luaName:String;

    /** Functions for Haxe-side modifiers */
    public var renderFunc:(Vector3, ModifierParameters) -> Vector3;
    public var visualsFunc:(VisualParameters, ModifierParameters) -> VisualParameters;

    public var nullSafety:Bool = true;
    private var __skipRender:Bool = false;
    private var __skipVisuals:Bool = false;

    override public function render(position:Vector3, params:ModifierParameters):Vector3 {
        if (__skipRender) return position;

        var pos = nullSafety ? position.clone() : position;

        // Haxe-side render
        if (renderFunc != null) {
            var safeParams = nullSafety ? Reflect.copy(params) : params;
            var translation = renderFunc(pos, safeParams);
            if (nullSafety && translation == null) {
                trace('[DynamicModifier] Haxe render failed!');
                __skipRender = true;
            } else if (translation != null) pos = translation;
        }

        // Lua-side render
        if (luaName != null) {
            try {
                pos = ManagerLua.runRender(luaName, pos, params);
            } catch (e:Dynamic) {
                trace('[DynamicModifier] Lua render failed for ' + luaName + ': ' + e);
                __skipRender = true;
            }
        }

        return pos;
    }

    override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
        if (__skipVisuals) return data;

        var vis = nullSafety ? Reflect.copy(data) : data;

        // Haxe-side visuals
        if (visualsFunc != null) {
            var safeParams = nullSafety ? Reflect.copy(params) : params;
            var modified = visualsFunc(vis, safeParams);
            if (nullSafety && modified == null) {
                trace('[DynamicModifier] Haxe visuals failed!');
                __skipVisuals = true;
            } else if (modified != null) vis = modified;
        }

        // Lua-side visuals
        if (luaName != null) {
            try {
                vis = ManagerLua.runVisuals(luaName, vis, params);
            } catch (e:Dynamic) {
                trace('[DynamicModifier] Lua visuals failed for ' + luaName + ': ' + e);
                __skipVisuals = true;
            }
        }

        return vis;
    }

    override public function shouldRun(params:ModifierParameters):Bool {
        return true;
    }
}
