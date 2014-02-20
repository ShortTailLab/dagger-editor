package behaviorEdit
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.TitleWindow;
	
	public class NodeTypePanel extends TitleWindow
	{
		private var tips:TextField = null;
		private var menu:UIComponent;
		
		public function NodeTypePanel()
		{
			this.title = "选择节点类型";
			this.setStyle("backgroundColor", 0x00BFFF);
			
			this.width = 95;
			this.height = 350;
			
			var btypes:Array = [BType.BTYPE_SEQ, BType.BTYPE_SEL,
				BType.BTYPE_PAR, BType.BTYPE_COND, BType.BTYPE_LOOP, BType.BTYPE_EXEC];
			var node:BNode;
			for(var i:int = 0; i < btypes.length; i++)
			{
				node = BNodeFactory.createBNode(btypes[i]);
				node.x = 10;
				node.y = 10+50*i;
				node.addEventListener(MouseEvent.MOUSE_DOWN, onNodeMouseDown);
				this.addElement(node);
			}
			
			
			this.addEventListener(CloseEvent.CLOSE, onClose);
		}
		
		private function onClose(e:CloseEvent):void
		{
			PopUpManager.removePopUp(this);
		}
		
		private function onNodeMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			var node:BNode = e.currentTarget as BNode;
			var evt:MsgEvent = new MsgEvent(MsgEvent.EXEC_TYPE);
			evt.hintMsg = node.type;
			this.dispatchEvent(evt);
			PopUpManager.removePopUp(this);
		}
		
	}
}