package;

import carvealot.WObject;
import carvealot.IWorkspaceView;
import carvealot.Workspace;

import hxClipper.Clipper;

#if js
import carvealot.WebWorkspaceView;

import js.Browser.window;
import js.html.svg.PathElement;
import js.html.svg.SVGElement;
#end

class Main
{
  var workspace:Workspace;
  var view:IWorkspaceView;

  public function new()
  {
    workspace = new Workspace();
    workspace.set_units(WU_MM);
    workspace.add_circle(25.4, 25.4, 25.4);
    setup_view();
  }

  function setup_view()
  {
    #if js
    var wwv = new WebWorkspaceView();
    view = wwv;
    js.Browser.document.body.appendChild(wwv.cont);
    #else
      // #error "No view for this platform";
    #end
    view.set_workspace(workspace);
  }

  public static function main()
  {
    // test_web();
    new Main();
  }

  #if js
  public static function test_web()
  {
    // Define two polygons as arrays of points (each point as an object with X and Y)
    var div = window.document.createElement('div');
    div.innerHTML = '<svg><circle cx="0" cy="0" r="0.24"/></svg>';
    var polygon1 = util.SVGUtil.SVGToPaths(cast div.children[0], 1000);/* [[
      new IntPoint(50, 150 ),
      new IntPoint(200, 50 ),
      new IntPoint(350, 150 ),
      new IntPoint(200, 300)
    ]];*/

    var polygon2 = [[
      new IntPoint(150, 100),
      new IntPoint(300, 100),
      new IntPoint(300, 250),
      new IntPoint(150, 250)
    ]];

    // Prepare the Clipper object and perform the intersection operation
    var clipper = new Clipper();
    clipper.addPaths(polygon1, PT_SUBJECT, true);
    clipper.addPaths(polygon2, PT_CLIP, true);

    var solutionPaths = new Paths();
    clipper.execute(ClipType.CT_INTERSECTION, solutionPaths);
    trace('Solution got area: '+Clipper.area(solutionPaths[0]));

    // Set the offset distance (positive to expand, negative to contract)
    var offsetDistance = -10; // Adjust to your desired offset distance

    // Create a ClipperOffset instance
    var clipperOffset = new ClipperOffset();

    // Add the solution paths to the ClipperOffset instance
    clipperOffset.addPaths(solutionPaths, JT_ROUND, ET_CLOSED_POLYGON);

    // Generate the offset paths
    var offsetPaths = new Paths();
    clipperOffset.execute(offsetPaths, offsetDistance);

    // Function to convert the result paths to SVG path data
    function toSvgPath(paths:Array<Array<IntPoint>>) {
      return paths.map((path)->{
        return "M" + path.map(function(point) return '${point.x},${point.y}').join("L") + "Z";
      }).join(" ");
    }

    // Draw the result in an SVG element
    var svgCanvas = window.document.getElementById('svgCanvas');
    for (path in [polygon1, polygon2, solutionPaths, offsetPaths]) {
      var pathElement:PathElement = cast window.document.createElementNS("http://www.w3.org/2000/svg", "path");
      pathElement.setAttribute("d", toSvgPath(path));
      var color = (path==polygon1) ? "rgba(255,0,0,0.2)" : (path==polygon2?"rgba(0,0,255,0.2)":"rgba(255,0,255,0.5)");
      pathElement.setAttribute("fill", color);
      pathElement.setAttribute("stroke", "black");
      pathElement.setAttribute("stroke-width", "1");
      svgCanvas.appendChild(pathElement);
    }
  }
  #end

}
