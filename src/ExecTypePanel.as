package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import spark.components.TitleWindow;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	
	public class ExecTypePanel extends TitleWindow
	{
		public function ExecTypePanel()
		{
			this.title = "选择节点类型";
			this.setStyle("backgroundColor", 0x00BFFF);
			
			var menu:UIComponent = new UIComponent;
			var i:int = 0;
			var h:Number = 0.0;
			var w:Number = 0.0;
			for(var item:String in Data.getInstance().behaviorBaseNode)
			{
				
				var label:TextField = Utils.getLabel(item, 0, 0, 16);
				label.selectable = false;
				label.border = true;
				label.background = true;
				label.backgroundColor = 0xffffff;
				label.width = label.textWidth+10;
				label.height = label.textHeight+5;
				label.x = 0;
				label.y = h;
				label.addEventListener(MouseEvent.MOUSE_DOWN, onBtnClick);
				menu.addChild(label);
				h += label.textHeight+10;
				w = Math.max(w, label.textWidth+10);
			}
			menu.x = 0;
			menu.y = 5;
			this.addElement(menu);
			
			this.width = w+20;
			this.height = h+40;
			
			this.addEventListener(CloseEvent.CLOSE, onClose);
		}
		
		private function onClose(e:CloseEvent):void
		{
			PopUpManager.removePopUp(this);
		}
		
		private function onBtnClick(e:MouseEvent):void
		{
			e.stopPropagation();
			var label:TextField = e.currentTarget as TextField;
			var evt:MsgEvent = new MsgEvent(MsgEvent.EXEC_TYPE);
			evt.hintMsg = label.text;
			this.dispatchEvent(evt);
			PopUpManager.removePopUp(this);
		}
	}
}