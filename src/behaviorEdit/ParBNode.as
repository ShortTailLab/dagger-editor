package behaviorEdit
{
	import flash.geom.Point;

	public class ParBNode extends BNode
	{
		public function ParBNode(_type:String="")
		{
			super(BType.BTYPE_PAR, 0xF4A460, true, true, BNodeDrawStyle.PAR_DRAW);
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