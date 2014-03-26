package behaviorEdit
{
	
	import behaviorEdit.bnodePainter.SeqGraphPainter;
	
	import manager.EventManager;

	public class RootBNode extends BNode
	{
		public function RootBNode()
		{
			super(BType.BTYPE_ROOT, 0x228B22, true, false, 1);
			this.canMove = false;
			this.graphPainter = new SeqGraphPainter(this);
		}
		
		override public function removeFromView():void
		{
			while(childNodes.length > 0)
				BNode(childNodes.pop()).removeFromView();
			EventManager.getInstance().dispatchEvent(new BTEvent(BTEvent.TREE_CHANGE));
		}
		
		public function removeAllChildren():void
		{
			while(childNodes.length > 0)
				BNode(childNodes.pop()).removeFromView();
			EventManager.getInstance().dispatchEvent(new BTEvent(BTEvent.TREE_CHANGE));
		}
	}
}