package kex.io;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.MacroStringTools;

class AssetLog {
    public static var _info = false;

    macro static function info( b: Bool ) : Expr {
        _info = b;
        return macro null;
    }

    macro public static function asset_info( msg: String ) : Expr {
        if (_info) {
            var m = MacroStringTools.formatString('[ info] $msg', Context.currentPos());
            return macro @:pos(Context.currentPos()) {
                haxe.Log.trace($m);
            }
        }

        return macro null;
    }

    public static function asset_err( msg: String, ?pos: haxe.PosInfos ) {
        haxe.Log.trace('[*err*] $msg', pos);
    }
}
