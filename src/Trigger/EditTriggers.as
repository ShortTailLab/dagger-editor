// ActionScript file
package Trigger
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.TitleWindow;
	
	import editEntity.MatSprite;
	
	import manager.EventManager;

	public class EditTriggers extends TitleWindow
	{
		private var host:MatSprite = null;
		
		public function EditTriggers(target:MatSprite)
		{
			this.host = target;
			
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
			addNewTrigger.x = 10; addNewTrigger.y = 10;
			var self = this;
			addNewTrigger.addEventListener(MouseEvent.CLICK, onAddTrigger);
		
			this.addEventListener(CloseEvent.CLOSE, onClose);
			EventManager.getInstance().addEventListener(TriggerEvent.REMOVE_TRIGGER, onRemoveNode);
		}
		
		private function save():void
		{
			
		}
		
		private function validChecking():Boolean
		{
			var pairs:Object = {};
			for( var i:int = 0; i<this.numElements; i++ )
			{
				if( !(this.getElementAt(i) is TNode) ) continue;
				var e:TNode = this.getElementAt(i) as TNode;
				
				if( !e.isDone() )
				{
					Alert.show("有Trigger未完成填写，请检查");
					return false;
				}
				
				if( pairs.hasOwnProperty(e.getCondType()+e.getResultType()) )
				{
					Alert.show("有重复类型的Trigger，请检查");
					return false;
				}
				
				pairs[e.getCondType()+e.getResultType()] = true;
			}
			
			return true;
		}
		
		private function onAddTrigger(evt:MouseEvent):void
		{
			if( !this.validChecking() ) return;
			this.addElement( new TNode() );
			this.relayout();
		}
		
		private function onClose(e:CloseEvent):void
		{
			// remove self 
			PopUpManager.removePopUp(this);
			
			// save all the configs
		}
		
		private function relayout():void
		{
			var y = 50;
			for( var i:int = 0; i<this.numElements; i++ )
			{
				var e:* = this.getElementAt(i);
				if( e is TNode ){
					e = TNode(e); e.x = 10; e.y = y;
					y  += (e.getHeight() + 10);
				}
			}
		}
		
		private function onRemoveNode(e:TriggerEvent):void
		{
			this.removeElement( e.from );
			this.relayout();
		}
	}
}