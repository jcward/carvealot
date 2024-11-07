package util;

import haxe.ds.Either; // Left/Right
import haxe.ds.StringMap;

import js.Browser.*;
import js.html.*;
import js.Promise;

import util.NotJQ.J as JQ;

import haxe.Http;
import haxe.Json;

using StringTools;

class JSUtil
{
  public static function is_on_page(e:Element) return inline is_a_descendant_of_b(e, document.body);
  public static function isOnBody(e:Element) return inline is_a_descendant_of_b(e, document.body); // alias
  public static function is_a_descendant_of_b(a:Element, b:Element):Bool
  {
    var ptr = a;
    while (ptr!=null && ptr!=b) {
      ptr = ptr.parentElement;
    }
    return ptr==b && b!=null;
  }

  public static function trace_color(msg:String, color:String="eef"):Void
  {
    var style = 'color:#333; background-color:#${color};padding:4px 6px;font-size:1.4em;line-height:1.65em;';
    untyped __js__('window.console.log("%c"+{0}, {1});', msg, style);
  }

  // Returns a callstack formatted so that in Chrome dev tools, you can
  // click on the text and it opens the file to the correct line:
  public inline static function get_js_callstack():String
  {
    return new EReg("js line ","g").replace(haxe.CallStack.toString(haxe.CallStack.callStack()),"js:");
  }

  public static function once_on_page(e:Element,
                                      f:Void->Void,
                                      ?timeout_ms=5000):Void->Void
  {
    var orig_callstack:String = #if debug get_js_callstack() #else null #end;
    var t0 = haxe.Timer.stamp();

    var cancelled = false;
    var cancel = function() {
      cancelled = true;
    }

    function monitor(has_thrown:Bool, orig_callstack:String) {
      if (cancelled) return;
      if (!is_on_page(e)) {
        var dt = haxe.Timer.stamp() - t0;
        if (dt > timeout_ms/1000 && !has_thrown) {
          #if debug trace('once_on_page, original callstack:\\n'+orig_callstack); #end
          util.LogUtil.async_throw('Error, once_on_page timeout!');
          has_thrown = true;
        }
        window.requestAnimationFrame(function(v) {
          monitor(has_thrown, orig_callstack);
        });
      } else {
        f();
      }
    }
    monitor(false, orig_callstack);

    // Allows caller to register on_dispose(cancel);
    return cancel;
  }

  private static var _clicking_out = new StringMap<{ handle:Void->Void, cleanup:Void->Void }>();
  public static function click_out(outside_of:Element,
                                   f:Void->Void,
                                   and_cancel=true):Void->Void
  {
    // Hmm, this is basically how ObjectMap works anyway
    untyped if (!outside_of.__coid__) outside_of.__coid__ = util.UUID.generate();
    var coid:String = untyped outside_of.__coid__;

    if (_clicking_out.exists(coid)) {
      // Existing listener, simply update the handler
      var exists = _clicking_out.get(coid);
      exists.handle = f;
      return exists.cleanup;
    }

    var cleanup:Void->Void = null;
    function onclick(e:Dynamic)
    {
      if (outside_of.closest('body')==null) {
        cleanup(); // off body? cleanup, no cancel, no callback
        return;
      }
      if (!is_a_descendant_of_b(e.target, outside_of)) {
      // if (JQ(e.target).closest(outside_of).length==0) {
        var f = _clicking_out.get(coid).handle;
        cleanup();
        if (and_cancel) {
          e.stopImmediatePropagation();
          e.preventDefault();
        }
        f();
      }
    }
    var opts:Dynamic = { passive:false, capture:true };
    cleanup = function() {
      window.removeEventListener('touchstart', onclick, opts);
      window.removeEventListener('mousedown', onclick, opts);
      _clicking_out.remove(coid);
    }
    window.addEventListener('touchstart', onclick, opts);
    window.addEventListener('mousedown', onclick, opts);

    _clicking_out.set(coid, { handle:f, cleanup:cleanup });

    return cleanup;
  }
  
  /**
   * Inject CSS into a style tag in the header. Hashes to
   * avoid injecting the same CSS twice.
   **/
  public static function inject_css(css:String):Void
  {
    var id:String = 'cinj-'+haxe.crypto.Md5.encode(css);
    untyped __js__('
      if (!document.getElementById({0})) {
          var a = document.createElement("style");
          a.id = {0};
          a.styleSheet ? a.styleSheet.cssText = {1} : a.appendChild(document.createTextNode({1}));
          document.getElementsByTagName("head")[0].appendChild(a)
      }', id, css);
  }

  private static var css_loaded:StringMap<Bool>;
  public static function load_css(url:String):Promise<String>
  {
    // If already loaded resolve immediately
    if (css_loaded==null) css_loaded = new StringMap<Bool>();
    if (css_loaded.exists(url)) return Promise.resolve(url);
    // Load css and append to head
    var loaded_promise = new Promise(
      function(resolve,reject) {
        var req = new Http(url);
        req.onData = function (data) {
          var link = document.createElement('link');
          link.setAttribute('rel', 'stylesheet');
          link.setAttribute('type', 'text/css');
          link.setAttribute('href', url);
          document.head.appendChild(link);
          css_loaded.set(url, true);
          resolve(url);
        }
        req.onError = function(data) {
          reject(data);
        }
        req.request();
    });
    return loaded_promise;
  }

  private static var json_loaded:StringMap<Dynamic> = new StringMap<Dynamic>();
  public static function load_json(url:String,
                                   ?callback:Dynamic->Void,
                                   ?enable_cache:Bool=false):Promise<Dynamic>
  {
    // If already loaded resolve immediately
    if (enable_cache && json_loaded.exists(url)) {
      var obj = json_loaded.get(url);
      if (Std.is(obj, js.Promise)) {
        // Chain to this callback, and return the existing promise
        if (callback!=null) {
          obj.then(function(data) callback(data),
                   function(err) callback(null));
        }
        return obj;
      } else {
        if (callback!=null) callback(obj);
        return Promise.resolve(obj);
      }
    }

    var loaded_promise = new Promise(
      function(resolve,reject) {
        var req = new Http(url);
        req.onData = function (data) {
          var obj:Dynamic = null;

          try {
            obj = Json.parse(data);
            if (enable_cache) json_loaded.set(url,obj);
            resolve(obj);
          } catch(e:Dynamic) {
            reject(e);
          }

          if (callback!=null) callback(obj);
        }
        req.onError = function(data) {
          reject(data);
          if (callback!=null) callback(null);
        }
        req.request();
    });
    if (enable_cache) json_loaded.set(url,loaded_promise);
    return loaded_promise;
  }


  #if BROWSER_JS
  private static var _prefixed:StringMap<String> = [
    'transform' => 'webkitTransform',
    'transformOrigin' => 'webkitTransformOrigin',
    'transform-origin' => 'webkitTransformOrigin',
    'perspective-origin' => 'webkitPerspectiveOrigin',
    'perspective' => 'webkitPerspective',
    'animation' => 'webkitAnimation',
  ];
	public static function apply_css(e:Element, obj:Dynamic):Void
  {
    var keys = Reflect.fields(obj);
    for (p in keys) {
      var val:String = Reflect.field(obj, p);
      untyped e.style[p] = val;
      if (_prefixed.exists(p)) untyped e.style[_prefixed.get(p)] = val;
    }
  }
  #end

	public inline static function cssTransform(e:Element, transform:String, transformOrigin:String=null):Void
  {
    // e:OneOf<Element, JQuery>
    // var elem:Element = switch(e) { case Left(v): v; case Right(j): j[0]; }

    // Silly iOS/safari requires webkit prefix on transforms
    untyped e.style['transform'] = transform;
		untyped e.style['webkitTransform'] = transform;

    if (transformOrigin!=null) {
      untyped e.style['transformOrigin'] = transformOrigin;
			untyped e.style['webkitTransformOrigin'] = transformOrigin;
    }
  }

}
