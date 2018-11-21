package kex.io;

class AssetLog {
    public static function asset_info( msg: String, ?pos: haxe.PosInfos ) {
        haxe.Log.trace('[ info] $msg', pos);
    }

    public static function asset_err( msg: String, ?pos: haxe.PosInfos ) {
        haxe.Log.trace('[*err*] $msg', pos);
    }
}
