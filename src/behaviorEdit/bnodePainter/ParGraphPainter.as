package behaviorEdit.bnodePainter
{
	import flash.geom.Point;
	
	import behaviorEdit.BNode;
	import behaviorEdit.bnodeController.BNodeController;
	
	public class ParGraphPainter extends BasePainer
	{
		public function ParGraphPainter(ctrl:BNodeController)
		{
			super(ctrl);
		}
		
		override public function paint():void
		{
			var paintNode:BNode = controller.node
			paintNode.graphics.clear();
			if(paintNode.childNodes.length > 0)
			{
				paintNode.graphics.lineStyle(2, controller.color);
				Utils.horConnect(paintNode, paintNode.convertToLocal(paintNode.getRightPoint()), paintNode.convertToLocal(paintNode.childNodes[0].getLeftPoint()), 2, controller.color);
				for(var i:int = 0; i < paintNode.childNodes.length-1; i++)
				{
					var startPoint:Point = paintNode.convertToLocal(paintNode.getRightPoint());
					Utils.squareConnect(paintNode, new Point(startPoint.x+5, startPoint.y), paintNode.convertToLocal(paintNode.childNodes[i+1].getLeftPoint()), 2, controller.color);
				}
			}
			else
			{
				var rpos:Point = paintNode.convertToLocal(paintNode.getRightPoint());
				Utils.horConnect(paintNode, rpos, new Point(paintNode.nodeWidth, rpos.y), 2, controller.color);
				paintNode.graphics.drawCircle(paintNode.nodeWidth+8, rpos.y, 8);
			}
		}
	}
}