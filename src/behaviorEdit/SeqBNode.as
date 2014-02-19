package behaviorEdit
{
	import behaviorEdit.bnodePainter.SeqGraphPainter;

	public class SeqBNode extends BNode
	{
		public function SeqBNode()
		{
			super(BType.BTYPE_SEQ, 0xA020F0, true, true);
			this.graphPainter = new SeqGraphPainter(this);
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