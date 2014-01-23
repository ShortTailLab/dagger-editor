package behaviorEdit
{
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.HScrollBar;
	import spark.components.Panel;
	import spark.components.TitleWindow;
	import spark.components.VGroup;
	import spark.components.VScrollBar;
	
	import manager.EventManager;
	
	public class BTEditPanel extends TitleWindow
	{
		public var currNode:BNode = null;
		private var grabLayer:UIComponent = null;
		
		
		public function BTEditPanel()
		{
			this.title = "行为编辑";
			this.width = 900;
			this.height = 700;
			this.setStyle("backgroundColor", 0xEEE8AA);
			
			var btnsPanel:Panel = new Panel;
			btnsPanel.title = "类型";
			btnsPanel.width = 120;
			btnsPanel.percentHeight = 100;
			var btnsView:UIComponent = new UIComponent;
			btnsPanel.addElement(btnsView);
			this.addElement(btnsPanel);
			
			var btypes:Array = [BType.BTYPE_EXEC, BType.BTYPE_SEQ];
			for(var i:int = 0; i < btypes.length; i++)
			{
				var node:BNode = BNodeFactory.createBNode(btypes[i]);
				node.x = 20;
				node.y = 20+45*i;
				node.addEventListener(MouseEvent.MOUSE_DOWN, onNodeMouseDown);
				btnsView.addChild(node);
			}
			
			var editGroup:HGroup = new HGroup();
			editGroup.x = 120;
			editGroup.percentWidth = 100;
			editGroup.percentHeight = 100;
			var group:Group = new Group();
			group.clipAndEnableScrolling = true;
			group.percentWidth = 100;
			group.percentHeight = 100;
			group.addElement(new BTEditView(this));
			var vGroup:VGroup = new VGroup;
			vGroup.percentWidth = 100;
			vGroup.percentHeight = 100;
			vGroup.addElement(group);
			var hscrollbar:HScrollBar = new HScrollBar;
			hscrollbar.percentWidth = 100;
			hscrollbar.viewport = group;
			vGroup.addElement(hscrollbar);
			editGroup.addElement(vGroup);
			var vscrollbar:VScrollBar = new VScrollBar();
			vscrollbar.percentHeight = 100;
			vscrollbar.viewport = group;
			editGroup.addElement(vscrollbar);
			this.addElement(editGroup);
			
			grabLayer = new UIComponent;
			this.addElement(grabLayer);
			
			this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		private function onMouseMove(e:MouseEvent):void
		{
			if(currNode)
			{
				currNode.x = this.mouseX-10;
				currNode.y = this.mouseY-15;
			}
			EventManager.getInstance().dispatchEvent(e);
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			if(currNode)
			{
				grabLayer.removeChild(currNode);
				currNode = null;
			}
			
			EventManager.getInstance().dispatchEvent(e);
		}
		
		private function onNodeMouseDown(e:MouseEvent):void
		{
			var node:BNode = e.currentTarget as BNode;
			currNode = BNodeFactory.createBNode(node.type);
			currNode.x = this.mouseX-10;
			currNode.y = this.mouseY-15;
			currNode.alpha = 0.5;
			grabLayer.addChild(currNode);
		}
		
		private function onClose(e:CloseEvent):void
		{
			PopUpManager.removePopUp(this);
		}
	}
}