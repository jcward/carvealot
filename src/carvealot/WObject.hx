package carvealot;

import hxClipper.Clipper.IntPoint;

#if js
import js.html.svg.SVGElement;
#end

class WObject
{
  public var paths(default,null):Array<Array<IntPoint>>; // These are all INT, hence the scalar (e.g. 2000 for inch, 100 for mm)

  public function new()
  {
    paths = [];
  }

  #if js
  public static function ofSVG(svg:SVGElement, int_scalar:Float)
  {
    var wo = new WObject();
    wo.paths = util.SVGUtil.SVGToPaths(svg, int_scalar);
    return wo;
  }
  #end
}
