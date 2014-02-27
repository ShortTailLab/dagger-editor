package behaviorEdit.bnodePainter
{
	import flash.geom.Point;
	
	import behaviorEdit.BNode;
	
	public class SeqGraphPainter extends BasePainer
	{
		public function SeqGraphPainter(node:BNode)
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
					Utils.connect(graphCanvas, targetNode.convertToLocal(targetNode.childNodes[i].getBottomMiddle()), targetNode.convertToLocal(targetNode.childNodes[i+1].getTopMiddle()), 2, defaultColor);
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