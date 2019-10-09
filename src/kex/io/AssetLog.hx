package kex.io;

#if !kex_io_custom_log

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.MacroStringTools;

class AssetLog {
	public static var _level = 1; // 1 err, 2 warn, 3 info, 4 debug

	macro static function level( l: Int ) : Expr {
		_level = l;
		return macro null;
	}

	macro public static function asset_debug( msg: String ) : Expr {
		if (_level >= 4) {
			var m = MacroStringTools.formatString('[debug] $msg', Context.currentPos());

			return macro @:pos(Context.currentPos()) {
				haxe.Log.trace($m);
			}
		}

		return macro null;
	}

	macro public static function asset_info( msg: String ) : Expr {
		if (_level >= 3) {
			var m = MacroStringTools.formatString('[ info] $msg', Context.currentPos());

			return macro @:pos(Context.currentPos()) {
				haxe.Log.trace($m);
			}
		}

		return macro null;
	}

	macro public static function asset_warn( msg: String ) : Expr {
		if (_level >= 2) {
			var m = MacroStringTools.formatString('[ WARN] $msg', Context.currentPos());

			return macro @:pos(Context.currentPos()) {
				haxe.Log.trace($m);
			}
		}

		return macro null;
	}

	macro public static function asset_err( msg: String ) {
		if (_level >= 1) {
			var m = MacroStringTools.formatString('[*ERR*] $msg', Context.currentPos());

			return macro @:pos(Context.currentPos()) {
				haxe.Log.trace($m);
			}
		}

		return macro null;
	}
}

#end