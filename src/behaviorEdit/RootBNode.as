package behaviorEdit
{
	import mx.controls.Alert;

	public class RootBNode extends BNode
	{
		public function RootBNode()
		{
			super(BType.BTYPE_ROOT, 0x228B22, true);
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
		
	}
}