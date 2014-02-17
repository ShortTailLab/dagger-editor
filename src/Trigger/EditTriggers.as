// ActionScript file
package Trigger
{
	import flash.events.MouseEvent;
	import flash.events.ContextMenuEvent;
	
	import mx.controls.Button;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.TitleWindow;
	
	import editEntity.MatSprite;
	
	import manager.EventManager;

	public class EditTriggers extends TitleWindow
	{
		private var triggers = new Array; 
		
		public function EditTriggers(target:MatSprite)
		{
			
			this.title = "触发器编辑";
			this.width = 400; this.height = 500;
			this.setStyle("backgroundColor", 0xEEE8AA);
			
			var addNewTrigger:Button = new Button;
			var view = new UIComponent;
			view.addChild(addNewTrigger);
			this.addElement(view);
			addNewTrigger.label = "添加触发器";
			addNewTrigger.width = 80;
			addNewTrigger.height = 30;
			addNewTrigger.x = 20; addNewTrigger.y = 20;
			var self = this;
			addNewTrigger.addEventListener(MouseEvent.CLICK, 
				function(e:MouseEvent)
				{
					var node = new TNode();
					node.setPosition(200, 200);
					self.addElement( node );
					triggers.push(node);
					var e2:TriggerEvent = new TriggerEvent(node, TriggerEvent.ADD_TRIGGER);
					EventManager.getInstance().dispatchEvent( e2 );
				}
			);
		
			this.addEventListener(CloseEvent.CLOSE, onClose);
			EventManager.getInstance().addEventListener(TriggerEvent.REMOVE_TRIGGER, onRemoveNode);
		}
		
		private function onClose(e:CloseEvent):void
		{
			// remove self 
			PopUpManager.removePopUp(this);
			
			// save all the configs
			
		}
		
		private function onRemoveNode(e:TriggerEvent):void
		{
			//this.removeChild( TNode(e.from) );
			this.removeElement( e.from );
		}
	}
}