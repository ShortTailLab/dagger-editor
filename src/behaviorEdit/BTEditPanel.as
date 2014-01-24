package behaviorEdit
{
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	import mx.controls.Button;
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
	
	import editEntity.EditBase;
	import editEntity.MatSprite;
	
	import manager.EventManager;
	
	public class BTEditPanel extends TitleWindow
	{
		public var currNode:BNode = null;
		private var grabLayer:UIComponent = null;
		private var editType:String;
		private var editView:BTEditView;
		
		public function BTEditPanel(target:MatSprite)
		{
			BNodeFactory.numCount = 0;
			this.title = "行为编辑";
			this.width = 900;
			this.height = 700;
			this.setStyle("backgroundColor", 0xEEE8AA);
			editType = target.type;
			
			var btnsPanel:Panel = new Panel;
			btnsPanel.title = "类型";
			btnsPanel.width = 120;
			btnsPanel.percentHeight = 100;
			var btnsView:UIComponent = new UIComponent;
			btnsPanel.addElement(btnsView);
			this.addElement(btnsPanel);
			
			var icon:EditBase = new MatSprite(null, target.type, 100);
			icon.x = 60;
			icon.y = 110;
			btnsView.addChild(icon);
			
			var btypes:Array = [BType.BTYPE_EXEC, BType.BTYPE_SEQ, BType.BTYPE_SEL,
								BType.BTYPE_PAR, BType.BTYPE_COND, BType.BTYPE_LOOP];
			var node:BNode;
			for(var i:int = 0; i < btypes.length; i++)
			{
				node = BNodeFactory.createBNode(btypes[i]);
				node.x = 20;
				node.y = 120+50*i;
				node.addEventListener(MouseEvent.MOUSE_DOWN, onNodeMouseDown);
				btnsView.addChild(node);
			}
			
			
			var btn:Button = new Button;
			btn.label = "保存";
			btn.width = 50;
			btn.height = 30;
			btn.x = 20;
			btn.y = node.y + 80;
			btn.addEventListener(MouseEvent.CLICK, onSave);
			btnsView.addChild(btn);
			
			var editGroup:HGroup = new HGroup();
			editGroup.x = 120;
			editGroup.percentWidth = 100;
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
			
			grabLayer = new UIComponent;
			this.addElement(grabLayer);
			
			initEditView();
			
			this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.addEventListener(CloseEvent.CLOSE, onClose);
		}
		
		private function initEditView():void
		{
			if(Data.getInstance().behaviorData.hasOwnProperty(editType))
			{
				editView.init(Data.getInstance().behaviorData[editType]);
			}
		}
		
		private function onSave(e:MouseEvent):void
		{
			var data:Object = editView.export();
			if(data)
			{
				Data.getInstance().behaviorData[editType] = data;
				Data.getInstance().saveBehaviorData();
			}
			else
				Alert.show("数据为空");
			
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
			editView.remove();
			
			PopUpManager.removePopUp(this);
		}
	}
}