package behaviorEdit
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.HScrollBar;
	import spark.components.TitleWindow;
	import spark.components.VGroup;
	import spark.components.VScrollBar;
	
	import editEntity.MatSprite;
	
	import manager.EventManager;
	
	public class BTEditPanel extends TitleWindow
	{
		public var currSelectBNode:BNode = null;
		public var userPanel:UserPanel = null;
		public var bar:BehaviorBar = null;
		private var behaviorsPanel:BehaviorTreePanel;
		private var grabLayer:UIComponent = null;
		public var editView:BTEditView;
		
		private var controller:BTEditController = null;
		
		public function BTEditPanel(target:MatSprite)
		{
			BNodeFactory.numCount = 0;
			this.title = "行为编辑";
			this.width = 1150;
			this.height = 800;
			this.setStyle("backgroundColor", 0xEEE8AA);
			
			controller = new BTEditController(this, target.type);
			
			behaviorsPanel = new BehaviorTreePanel(controller);
			behaviorsPanel.width = 150;
			behaviorsPanel.percentHeight = 100;
			behaviorsPanel.x = 1000;
			this.addElement(behaviorsPanel);
			
			userPanel = new UserPanel(this, controller);
			this.addElement(userPanel);
			
			bar = new BehaviorBar(controller);
			bar.x = 120;
			bar.y = 0;
			this.addElement(bar);
			
			var editGroup:HGroup = new HGroup();
			editGroup.y = 40;
			editGroup.x = 120;
			editGroup.width = 880;
			editGroup.percentHeight = 100;
			var group:Group = new Group();
			group.clipAndEnableScrolling = true;
			group.percentWidth = 100;
			group.percentHeight = 100;
			editView = new BTEditView(this);
			group.addElement(editView);
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
			
			//this used to add the dragging node.
			grabLayer = new UIComponent;
			this.addElement(grabLayer);
			
			var defaultBT:String = controller.getBTs().length > 0 ? controller.getBTs()[0] : "";
			controller.setCurrEditBehavior(defaultBT);
			
			this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.addEventListener(CloseEvent.CLOSE, onClose);
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
		}
		
		private function onAddedStage(e:Event):void
		{
			this.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
		}
		
		private function onWheel(e:MouseEvent):void
		{
			if(e.ctrlKey)
			{
				var d:Number = Math.max(0.3, Math.min(1.0, editView.scaleX + e.delta*0.1));
				editView.scaleX = editView.scaleY = d;
			}
		}
		
		private function onMouseMove(e:MouseEvent):void
		{
			if(currSelectBNode)
			{
				currSelectBNode.x = this.mouseX-10;
				currSelectBNode.y = this.mouseY-15;
			}
			EventManager.getInstance().dispatchEvent(e);
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			if(currSelectBNode)
			{
				grabLayer.removeChild(currSelectBNode);
				currSelectBNode = null;
			}
			
			EventManager.getInstance().dispatchEvent(e);
		}
		
		
		public function setCurrSelectNode(nodeType:String):void
		{
			currSelectBNode = BNodeFactory.createBNode(nodeType);
			currSelectBNode.x = this.mouseX-10;
			currSelectBNode.y = this.mouseY-15;
			currSelectBNode.alpha = 0.5;
			grabLayer.addChild(currSelectBNode);
		}
		
		private function onClose(e:CloseEvent):void
		{
			controller.saveSelectItem();
			editView.remove();
			PopUpManager.removePopUp(this);
			
			var msg:String = "";
			for each(var bname:String in controller.getBTs())
				if(Utils.genBTreeJS(Data.getInstance().behaviors[bname]) == "")
				{
					trace(bname);
					msg += bname + " ";
				}
			if(msg.length > 0)
			{
				Alert.show("行为"+msg+"不合法，请检查！");
			}
		}
	}
}