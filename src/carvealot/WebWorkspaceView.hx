package carvealot;

import util.SVGUtil;
import js.html.svg.SVGElement;
#if js

import util.JSUtil;

import js.html.*;
import js.Browser.*;

class WebWorkspaceView implements IWorkspaceView
{
  public var cont(default,null):Element;

  var workspace:Workspace;
  var svg:SVGElement;

  public function new()
  {
    cont = document.createDivElement();
    cont.className = 'wwview-cont';
    cont.innerHTML = '<svg></svg>';
    svg = cast cont.children[0];
  }

  public function set_workspace(w:Workspace) {
    if (workspace!=null) trace('Should we change workspace / set more than once?');
    workspace = w;
    redraw();
  }
  
  public function redraw()
  {
    for (child in svg.children) child.remove();
    svg.setAttribute("width", ''+cont.offsetWidth);
    svg.setAttribute("height", ''+cont.offsetHeight);
    for (wo in workspace.objects) {
      svg.appendChild(SVGUtil.woToSVGPathElements(wo, 1/workspace.int_scalar));
    }
  }
}

#end
