package behaviorEdit
{
	import flash.geom.Point;
	
	import mx.controls.Alert;
	
	import manager.EventManager;

	public class RootBNode extends BNode
	{
		public function RootBNode()
		{
			super(BType.BTYPE_ROOT, 0x228B22, true, false, BNodeDrawStyle.SEQ_DRAW);
			this.canMove = false;
		}
		
		override public function onAdd(nodeType:String):void
		{
			if(childNodes.length == 0)
			{
				super.onAdd(nodeType);
			}
			else
				Alert.show("Root节点只能添加一个子节点");
			
		}
		
		override public function removeSelf():void
		{
			while(childNodes.length > 0)
				BNode(childNodes.pop()).removeSelf();
			EventManager.getInstance().dispatchEvent(new BTEvent(BTEvent.TREE_CHANGE));
		}
		
	}
}