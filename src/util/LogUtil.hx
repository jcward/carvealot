package util;

import haxe.CallStack;
import haxe.PosInfos;

import haxe.crypto.Md5;
import haxe.crypto.Sha1;

#if js
import js.Browser.*;
#end

class LogUtil
{

    public static inline function trace(v:Dynamic, ?infos:haxe.PosInfos)
  {
#if (debug) trace(v, infos); #end
  }

  public static inline function async_throw(s:String, add_stacktrace:Bool=true, ?pos:PosInfos)
  {
    #if (js && BROWSER_JS)
    var errmsg = s+"";
    untyped __js__('window.console.log.apply(window.console, {0})', format_err(errmsg, pos));
    __async_throw(pos, errmsg, add_stacktrace);
    #else
    __async_throw(pos, s, add_stacktrace);
    #end
  }

#if js
  private static function format_err(s:String, pos:PosInfos):Array<Dynamic>
  {
    var f = "";
    if (pos!=null) {
      f = pos.fileName;
      if (f.lastIndexOf('/')>=0) f = f.substr(f.lastIndexOf('/')+1);
    }

    var rtn = [];
    untyped __js__("
    var pmsg = {1} ? ' - '+{2}+':'+{1}.lineNumber+'['+{1}.className+'.'+{1}.methodName+']' : '';
    {3} = ['%c'+{0}+pmsg, 'color:#333; background-color:#fdd;padding:4px 6px;font-size:1.2em;line-height:1.45em;border-top:2px solid #f66;']", s, pos, f, rtn);
    return rtn;
  }
#end

  private static function __async_throw(pos:PosInfos, s:String, add_stacktrace:Bool=true)
  {
    new Err(s,pos).log();

    // js.Lib.debug();
    // new ErrorDisplay(_recent_log.join("\n"), s + (add_stacktrace ? get_readable_stack(1) : ""));
  }

  public static function get_cls_s(obj:Dynamic): String {return Type.getClassName(Type.getClass(obj));}
  public static function get_pos_s(pos:PosInfos): String {
    if (pos==null) return "unknown position";
    return '${pos.className}.${pos.methodName}() at ${pos.fileName}:${pos.lineNumber}';
  }

  public inline static function get_readable_stack(start_depth:Int=0, stop_at:EReg=null) : String
  {
    var result:String = 'No StackTrace Available.';
    if (stop_at==null) stop_at =~/Object\.Main/;
    #if js
      // Only works if source maps are loaded... So not production...
      untyped __js__("result = new Error().stack");
      var stack = result==null ? [] : result.split("\n");
      var stop = stack.length;
      for (i in 0...stop) {if (stop_at.match(stack[i])) { stop=i+1; break; }}
      stack = stack.slice(start_depth+2, stop); // First line is "Error:...", second is get_readable_stack
      result = "\t"+stack.join("\n\t");
    #else
      // The generic Haxe code does not give a good implementation in JS,
      // as it uses obfuscated line numbers (not source mapped)
      result = haxe.CallStack.toString(haxe.CallStack.callStack());
    #end
    return result;
  }

}
