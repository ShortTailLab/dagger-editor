package behaviorEdit.bnodePainter
{
	import flash.geom.Point;
	
	import behaviorEdit.BNode;
	
	public class LoopGraphPainter extends BasePainer
	{
		public function LoopGraphPainter(node:BNode)
		{
			super(node);
		}
		
		override public function paint():void
		{
			this.clear();
			if(targetNode.childNodes.length > 0)
			{
				graphCanvas.graphics.lineStyle(2, defaultColor);
				var startPoint:Point = targetNode.convertToLocal(targetNode.getRightPoint());
				Utils.horConnect(graphCanvas, startPoint, targetNode.convertToLocal(targetNode.childNodes[0].getLeftPoint()), 2, defaultColor);
				for(var i:int = 0; i < targetNode.childNodes.length-1; i++)
				{
					Utils.connect(graphCanvas, targetNode.convertToLocal(targetNode.childNodes[i].getBottomMiddle()), targetNode.convertToLocal(targetNode.childNodes[i+1].getTopMiddle()), 2, defaultColor);
				}
				var lastPos:Point = targetNode.convertToLocal(targetNode.childNodes[targetNode.childNodes.length-1].getBottomMiddle());
				var bottomPos:Point = new Point(lastPos.x, lastPos.y+10);
				Utils.verConnect(graphCanvas, lastPos, bottomPos, 2, defaultColor);
				Utils.squareConnect(graphCanvas, new Point(startPoint.x+5, startPoint.y), bottomPos, 2, defaultColor);
			}
			else
			{
				var rpos:Point = targetNode.convertToLocal(targetNode..getRightPoint());
				Utils.horConnect(graphCanvas, rpos, new Point(targetNode.boundingBox.width, rpos.y));
				graphCanvas.graphics.drawCircle(targetNode.boundingBox.width+8, rpos.y, 8);
			}
		}
	}
}