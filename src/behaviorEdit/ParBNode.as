package behaviorEdit
{
	import flash.geom.Point;

	public class ParBNode extends BNode
	{
		public function ParBNode(_type:String="")
		{
			super(BType.BTYPE_PAR, 0xF4A460, true);
		}
		
		override public function onLay(node:BNode):void
		{
			for(var i:int = 0; i < childNodes.length; i++)
				if(node.y < childNodes[i].y)
					break;
			
			if(node.par == this && getChildNodeIndex(node) < i)
				i--;
			node.par.removeChildNode(node.nodeId);
			childNodes.splice(i, 0, node);
			
			node.par = this;
		}
		
		override public function drawGraph():void
		{
			this.graphics.clear();
			if(childNodes.length > 0)
			{
				this.graphics.lineStyle(2);
				connect(convertToLocal(this.getRightMiddle()), convertToLocal(childNodes[0].getLeftMiddle()));
				for(var i:int = 0; i < childNodes.length-1; i++)
				{
					var startPoint:Point = convertToLocal(this.getRightMiddle());
					squareConnect(new Point(startPoint.x+5, startPoint.y), convertToLocal(childNodes[i+1].getLeftMiddle()));
				}
			}
			else
			{
				var rpos:Point = convertToLocal(this.getRightMiddle());
				connect(rpos, new Point(this.nodeWidth, rpos.y));
				this.graphics.drawCircle(this.nodeWidth+8, rpos.y, 8);
			}
			
		}
	}
}