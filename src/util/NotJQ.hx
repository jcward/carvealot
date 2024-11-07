package util;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
using haxe.macro.ExprTools;
#end

#if (js && BROWSER_JS)
import js.html.*;
import js.Browser.*;
#else
typedef Element = Dynamic; // there is no element in macro context
#end


@:forward
abstract NotJQ(Array<Element>) from Array<Element> {

  // Allow NotJQ to be called like a function, like jQuery, by transforming
  // NotJQ(...) --> new NotJQ(...), which picks up all the goodness of the
  // abstract @:from functions.
  public static macro function J(e:Expr):Expr return macro ((cast $e):util.NotJQ);


  // Yummy macro for .css()
  public macro function css(This:Expr, ?a0:Expr, ?a1:Expr):Expr {
    //trace(a0);
    //trace(a1);
    switch a0.expr {
      case EConst(CString(s)): // Literal string --> style property assignment
        s = toLowerCamel(s);
        return macro { for (e in $This) e.style.$s = $a1; $This; };
      case EObjectDecl(fields): // Literal object declaration --> style property assignments
        if (a1.toString()!='null') Context.error('Unexpected second parameter to .css({})', a1.pos);
        var asgn = { expr:EBlock(fields.map((fd)->{
          var fn = fd.field;
          var fe = fd.expr;
          macro for (e in $This) e.style.$fn = $fe;
        })), pos:Context.currentPos() };
        return macro {
          $asgn;
          $This;
        }
      default:
        Context.error('NotJQ.css currently only supports (ConstString, Any) or (ObjectDecl)', a0.pos);
    }
    return macro null;
  }

  private static function toLowerCamel(s:String):String
  {
    var sb = new StringBuf();
    var next_cap = false;
    for (i in 0...s.length) {
      var c = s.charCodeAt(i);
      if (c==45) next_cap = true; // -
      else {
        sb.addChar((next_cap && c>=97 && c<=122) ? c-32 : c);
        next_cap = false;
      }
    }
    return sb.toString();
  }
#if (!macro && BROWSER_JS)

  public inline function new(arr:Array<Element>) this = arr;

  @:arrayAccess
  public inline function get(idx:Int) return this[idx];

  /* - - - - - - - - - - - - - - - - - - - - */
  /* quick / little functions that we inline */
  /* - - - - - - - - - - - - - - - - - - - - */
  public inline function click(handler:Event->Void):NotJQ return bind('click', handler);
  public inline function attr(name:String, set_val:Dynamic=-1):String
  {
    // TODO: make this a macro so we don't have to do all 3 at runtime:

    // optional remove
    if (js.Syntax.strictEq(set_val, null)) for (e in this) e.removeAttribute(name);

    // optional set
    else if (js.Syntax.strictNeq(set_val, -1)) for (e in this) e.setAttribute(name, set_val);
      
    // Return first element's attribute value:
    return this.length==0 ? null : this[0].getAttribute(name);
  }
  public inline function append(other:NotJQ):NotJQ {
    if (this.length>0) for (e in other) this[0].appendChild(e);
    return this;
  }
  public inline function addClass(cls:String):NotJQ {
    for (e in this) e.classList.add(cls);
    return this;
  }
  public inline function hasClass(cls:String):Bool {
    var has = false;
    for (e in this) if (e.classList.contains(cls)) has = true;
    return has;
  }
  public inline function removeClass(cls:String):NotJQ {
    for (e in this) e.classList.remove(cls);
    return this;
  }
  public inline function remove():NotJQ {
    for (e in this) e.remove();
    return this;
  }
  public inline function html(v:String):NotJQ {
    for (e in this) e.innerHTML = v;
    return this;
  }
  public inline function nextElementSibling():NotJQ {
    var rtn = [];
    for (e in this) {
      var n = getNES(e);
      if (n!=null) rtn.push(n);
    }
    return (untyped this.is_dynamic) ? decorate_dynamic(rtn) : rtn;
  }
  public inline function as<T>(cls:Class<T>):T return cast this[0];

  static function getNES(e:Element):Element {
    var ptr:Node = e.nextSibling;
    while (ptr!=null && js.Syntax.code('!(ptr instanceof Element)')) ptr = ptr.nextSibling;
    return untyped ptr;
  }

  /* - - - - - - - - - - - - - - - - - - - */
  /* larger functions that we don't inline */
  /* - - - - - - - - - - - - - - - - - - - */
  public function find(sel:String):NotJQ {
    var il = this.length;
    for (i in 0...il) {
      for (e in this[i].querySelectorAll(sel)) {
        // Elements only, unique
        if (js.Syntax.code('{0} instanceof Element', e) && this.indexOf(untyped e) < il) {
          this.push(untyped e);
        }
      }
    }
    var rtn = this.slice(il);
    return (untyped this.is_dynamic) ? decorate_dynamic(rtn) : rtn;
  }

  public function bind(event:String, handler:Event->Void):NotJQ
  {
    if (event.indexOf(' ')>0) {
      for (sub in event.split(' ')) bind(sub, handler);
    } else {
      for (i in 0...this.length) {
        this[i].addEventListener(event, handler);
      }
    }
    return this;
  }

  public function unbind(event:String, handler:Event->Void):NotJQ
  {
    if (event.indexOf(' ')>0) {
      for (sub in event.split(' ')) unbind(sub, handler);
    } else {
      for (i in 0...this.length) {
        this[i].removeEventListener(event, handler);
      }
    }
    return this;
  }

  // Code roughly translated from jQuery 1.11.3 (MIT license)
  public function offset():{ top:Float, left:Float }
  {
    var docElem,
        elem = this[0],
        doc = document;

    docElem = doc.documentElement;

    // Make sure it's not a disconnected DOM node
    if (!is_a_descendant_of_b(elem, document.body)) return { top: 0, left: 0 };
    var box = elem.getBoundingClientRect();
    return {
      top: box.top  + untyped ( window.pageYOffset || docElem.scrollTop ) - untyped ( docElem.clientTop  || 0 ),
      left: box.left + untyped ( window.pageXOffset || docElem.scrollLeft ) - untyped ( docElem.clientLeft || 0 )
    };
  }

  public function closest(sel:String):NotJQ
  {
    var rtn = [];
    var candidates:Array<Element> = js.Syntax.code('Array.from(document.querySelectorAll({0}))',sel);
    function find_above(e:Element):Element {
      while (e!=null) {
        if (candidates.indexOf(e)>=0) return e;
        e = e.parentElement;
      }
      return null;
    }
    for (e in this) {
      var c = find_above(e);
      if (c!=null) rtn.push(c);
    }
    return untyped this.is_dynamic ? decorate_dynamic(rtn) : rtn;
  }

  public static function is_a_descendant_of_b(a:Element, b:Element):Bool
  {
    var ptr = a;
    while (ptr!=null && ptr!=b) {
      ptr = ptr.parentElement;
    }
    return ptr==b && b!=null;
  }

  private static var isHtml = ~/^\s*</m;
  /* Infer from various element / element collections */
  @:from public static inline function fromString(s:String):NotJQ {
    // If it's html...
    if (isHtml.match(s)) {
      var d = document.createElement('div');
      d.innerHTML = s;
      return (d.children:NotJQ);
    } else {
      // Otherwise, it's a selector from the body
      return new NotJQ([document.body]).find(s);
    }
  }

  @:from public static inline function fromElement(e:Element) return new NotJQ([e]);
  @:from public static inline function fromNodeList(n:NodeList) return new NotJQ(js.Syntax.code('Array.from({0})',n));
  @:from public static inline function fromEventTarget(et:EventTarget) return new NotJQ([untyped et]);
  @:from public static inline function fromHtmlCollection(hc:HTMLCollection) return new NotJQ([for (e in hc) e]);

  // So, we want to support not only cool callsite magic that abstract provides,
  // but to give us a reasonable JQuery runtime replacement.
  private static function decorate_dynamic(a:Array<Element>):NotJQ
  {
    js.Syntax.code('
      {0}.is_dynamic = true;
      function bind(p) {
        {0}[p] = function() {
          return {1}[p].apply({0}, [{0}].concat(Array.from(arguments)));
        }
      }
      var p;
      for (p in {1}) {
        if (p.indexOf("_")!=0) bind(p);
      }
    ', a, NotJQ);
    return a;
  }
  private static function __init__() {
    js.Syntax.code('
      window.N$ = function() {
        var rtn, itm=arguments[0], t=(typeof itm);
        if (t==="string") {
          rtn = {0}.fromString(itm);
        } else if (itm instanceof Element) {
          rtn = [itm];
        }
        {0}.decorate_dynamic(rtn);
        return rtn;
      }

      var g = [document.body];
      {0}.decorate_dynamic(g);
      function bind(p) {
        window.N$[p] = function() {
          return {0}[p].apply(g, [g].concat(Array.from(arguments)));
        }
      }
      var p;
      for (p in {0}) {
        if (p.indexOf("_")!=0) bind(p);
      }

    ', NotJQ);
  }

#end
}
