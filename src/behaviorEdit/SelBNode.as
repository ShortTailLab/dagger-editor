package behaviorEdit
{
	import flash.geom.Point;

	public class SelBNode extends BNode
	{
		public function SelBNode()
		{
			super(BType.BTYPE_SEL, 0xD15FEE, true);
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
					connect(convertToLocal(childNodes[i].getBottomMiddle()), convertToLocal(childNodes[i+1].getTopMiddle()));
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