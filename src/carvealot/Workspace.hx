package carvealot;

import hxClipper.Clipper.IntPoint;
import hxClipper.Clipper.Path;

class Workspace
{
  var units:WUnits;
  public var int_scalar(default,null):Float;

  var width:Float;
  var height:Float;
  var depth:Float;

  public var objects(default,null):Array<WObject>;

  public function new()
  {
    objects = [];
  }

  public function set_units(u:WUnits)
  {
    // TODO: scale current contents?
    units = u;
    int_scalar = switch units {
      case WU_MM: 100;     // 0.01 mm precision
      case WU_INCH: 2000; // 1/2000 inch (.0127mm)
    }
  }

  public function set_size(w:Float=0, h:Float=0, d:Float=0)
  {
    if (w!=0) width = w;
    if (h!=0) height = h;
    if (d!=0) depth = d;
  }

  public inline function toInt(v:Float):Int
  {
    return Math.floor(int_scalar * v);
  }

  public function add_circle(x: Float, y:Float, r:Float, segments=36): WObject
  {
    var wo = new WObject();
    var circlePath = [];
    for (i in 0...segments) {
      var theta = (i / segments) * 2 * Math.PI;
      circlePath.push(new IntPoint( toInt(x + r * Math.cos(theta)), toInt(y + r * Math.sin(theta) )));
    }
    circlePath.push(circlePath[0]); // Close path
    wo.paths.push(circlePath);
    objects.push(wo);
    return wo;
  }
}

enum WUnits {
  WU_MM;
  WU_INCH;
}
