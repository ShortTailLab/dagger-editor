package behaviorEdit.bnodePainter
{
	import flash.geom.Point;
	
	import behaviorEdit.BNode;
	import tools.Utils;
	
	public class ParGraphPainter extends BasePainer
	{
		public function ParGraphPainter(node:BNode)
		{
			super(node);
		}
		
		override public function paint():void
		{
			this.clear();
			if(targetNode.childNodes.length > 0)
			{
				graphCanvas.graphics.lineStyle(2, defaultColor);
				Utils.horConnect(graphCanvas, targetNode.convertToLocal(targetNode.getRightPoint()), targetNode.convertToLocal(targetNode.childNodes[0].getLeftPoint()), 2, defaultColor);
				for(var i:int = 0; i < targetNode.childNodes.length-1; i++)
				{
					var startPoint:Point = targetNode.convertToLocal(targetNode.getRightPoint());
					Utils.squareConnect(graphCanvas, new Point(startPoint.x+5, startPoint.y), targetNode.convertToLocal(targetNode.childNodes[i+1].getLeftPoint()), 2, defaultColor);
				}
			}
			else
			{
				var rpos:Point = targetNode.convertToLocal(targetNode.getRightPoint());
				Utils.horConnect(graphCanvas, rpos, new Point(targetNode.boundingBox.width, rpos.y), 2, defaultColor);
				graphCanvas.graphics.drawCircle(targetNode.boundingBox.width+8, rpos.y, 8);
			}
		}
	}
}