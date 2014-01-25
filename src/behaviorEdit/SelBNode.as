package behaviorEdit
{
	import flash.geom.Point;

	public class SelBNode extends BNode
	{
		public function SelBNode()
		{
			super(BType.BTYPE_SEL, 0xD15FEE, true, true, BNodeDrawStyle.SEQ_DRAW);
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
		
	}
}