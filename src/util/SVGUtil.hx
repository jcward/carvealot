package util;

import js.Browser.*;
import js.html.svg.PathElement;
import carvealot.WObject;
import js.html.svg.SVGElement;
import hxClipper.Clipper.IntPoint;

import js.html.Element;

using StringTools;

class SVGUtil
{
  public static function pathsToSVGPath(paths:Array<Array<IntPoint>>, scale:Float)
  {
    return paths.map((path)->{
      return "M" + path.map(function(point) return '${point.x*scale},${point.y*scale}').join("L") + "Z";
    }).join(" ");
  }

  public static function woToSVGPathElements(wo:WObject, scale:Float):PathElement
  {
    // Draw the result in an SVG element

    var pathElement:PathElement = cast window.document.createElementNS("http://www.w3.org/2000/svg", "path");
    pathElement.setAttribute("d", pathsToSVGPath(wo.paths, scale));
    //pathElement.setAttribute("fill", "rgba(255,0,0,0.2)");
    pathElement.setAttribute("fill", "none");
    pathElement.setAttribute("stroke", "#444");
    pathElement.setAttribute("stroke-width", "4");
    return pathElement;
  }

  public static function SVGToPaths(svgElement: SVGElement, scalar:Float=1)
  {
    inline function toInt(v:Float):Int {
      return Math.floor(scalar*v);
    }

    var paths:Array<Array<IntPoint>> = [];

    function parsePathData(d: String): Array<IntPoint> {
      var path: Array<IntPoint> = [];
      var i = 0;
      var x = 0.0;
      var y = 0.0;
  
      while (i < d.length) {
        var command = d.charAt(i).toUpperCase();
        i++;

        // Parse command arguments
        var args = [];
        while (i < d.length) {
          var c = d.charAt(i);
          if (c >= '0' && c <= '9' || c == '.' || c == '-') {
            var start = i;
            while (i < d.length && (d.charAt(i) >= '0' && d.charAt(i) <= '9' || d.charAt(i) == '.' || d.charAt(i) == '-')) {
              i++;
            }
            args.push(Std.parseFloat(d.substring(start, i)));
          } else if (c == ' ' || c == ',') {
            i++;
          } else {
            break;
          }
        }

        // Process the command with its arguments
        switch (command) {
          case 'M': // Move to (absolute)
          x = args[0];
          y = args[1];
          path.push(new IntPoint(toInt(x), toInt(y)));
          case 'L': // Line to (absolute)
          x = args[0];
          y = args[1];
          path.push(new IntPoint(toInt(x), toInt(y)));
          case 'H': // Horizontal line to (absolute)
          x = args[0];
          path.push(new IntPoint(toInt(x), toInt(y)));
          case 'V': // Vertical line to (absolute)
          y = args[0];
          path.push(new IntPoint(toInt(x), toInt(y)));
          case 'Z': // Close path
          if (path.length > 0) path.push(path[0]);
          // Optional: Add additional cases for other SVG path commands as needed
        }
      }
  
      return path;
    }  

    // Process <path> elements
    for (eln in svgElement.querySelectorAll('path')) {
      var el:Element = cast eln;
      var d:String = el.getAttribute('d');
      if (d.length>0) paths.push(parsePathData(d));
    }
  
    // Process <rect> elements
    for (eln in svgElement.querySelectorAll('rect')) {
      var el:Element = cast eln;
      var x = Std.parseFloat(el.getAttribute('x')) ?? 0.;
      var y = Std.parseFloat(el.getAttribute('y')) ?? 0.;
      var width = Std.parseFloat(el.getAttribute('width')) ?? 0.;
      var height = Std.parseFloat(el.getAttribute('height')) ?? 0.;
      var rectPath = [
        new IntPoint(toInt(x), toInt(y)),
        new IntPoint(toInt(x + width), toInt(y)),
        new IntPoint(toInt(x + width), toInt(y + height)),
        new IntPoint(toInt(x), toInt(y + height)),
        new IntPoint(toInt(x), toInt(y)) // Close path
      ];
      paths.push(rectPath);
    }
  
    // Process <circle> elements (converted to a polygonal approximation)
    for (eln in svgElement.querySelectorAll('circle')) {
      var el:Element = cast eln;
      var cx = Std.parseFloat(el.getAttribute('cx')) ?? 0.;
      var cy = Std.parseFloat(el.getAttribute('cy')) ?? 0.;
      var r = Std.parseFloat(el.getAttribute('r')) ?? 0.;
      var circlePath = [];
      var segments = 36; // Number of segments for approximation
      for (i in 0...segments) {
        var theta = (i / segments) * 2 * Math.PI;
        circlePath.push(new IntPoint( toInt(cx + r * Math.cos(theta)), toInt(cy + r * Math.sin(theta) )));
      }
      circlePath.push(circlePath[0]); // Close path
      paths.push(circlePath);
    }
  
    // Process <ellipse> elements (converted to a polygonal approximation)
    for (eln in svgElement.querySelectorAll('ellipse')) {
      var el:Element = cast eln;
      var cx = Std.parseFloat(el.getAttribute('cx')) ?? 0.;
      var cy = Std.parseFloat(el.getAttribute('cy')) ?? 0.;
      var rx = Std.parseFloat(el.getAttribute('rx')) ?? 0.;
      var ry = Std.parseFloat(el.getAttribute('ry')) ?? 0.;
      var ellipsePath = [];
      var segments = 36; // Number of segments for approximation
      for (i in 0...segments) {
        var theta = (i / segments) * 2 * Math.PI;
        ellipsePath.push(new IntPoint( toInt(cx + rx * Math.cos(theta)), toInt(cy + ry * Math.sin(theta)) ));
      }
      ellipsePath.push(ellipsePath[0]); // Close path
      paths.push(ellipsePath);
    }
  
    // Process <polygon> elements
    for (eln in svgElement.querySelectorAll('polygon')) {
      var el:Element = cast eln;
      var points: String = el.getAttribute('points');
      if (points.length>0) {
        var r = ~/\s+/;
        var polygonPath = r.split(points.trim()).map((point)->{
          var arr = point.split(',').map((v)->Std.parseFloat(v));
          return new IntPoint(toInt(arr[0]), toInt(arr[1]));
        });
        polygonPath.push(polygonPath[0]); // Close path
        paths.push(polygonPath);
      }
    }
  
    return paths;
  }
}
