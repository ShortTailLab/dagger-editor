package behaviorEdit
{
	import flash.geom.Point;
	
	import behaviorEdit.bnodePainter.SeqGraphPainter;

	public class SelBNode extends BNode
	{
		public function SelBNode()
		{
			super(BType.BTYPE_SEL, 0xD15FEE, true, true);
			this.graphPainter = new SeqGraphPainter(this);
		}
		
		override public function onDragIn(node:BNode):void
		{
			for(var i:int = 0; i < childNodes.length; i++)
				if(node.y < childNodes[i].y)
					break;
			
			if(node.par == this && getChildNodeIndex(node) < i)
				i--;
			node.par.removeChildNodeById(node.nodeId);
			childNodes.splice(i, 0, node);
			
			node.par = this;
		}
		
	}
}