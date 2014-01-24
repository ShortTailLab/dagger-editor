package behaviorEdit
{
	import flash.geom.Point;
	
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