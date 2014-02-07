package
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import spark.components.TitleWindow;
	import mx.controls.TextInput;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	
	public class RenamePanel extends TitleWindow
	{
		private var input:TextInput;
		
		public function RenamePanel()
		{
			this.title = "重命名";
			this.width = 200;
			this.height = 100;
			
			input = new TextInput;
			input.height = 30;
			input.width = 150;
			this.addElement(input);
			
			var btn:Button = new Button;
			btn.label = "确定";
			btn.y = 40
			btn.addEventListener(MouseEvent.CLICK, onRenameClick);
			this.addElement(btn);
			
			this.addEventListener(CloseEvent.CLOSE, onClose);
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onClose(e:CloseEvent):void
		{
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			PopUpManager.removePopUp(this);
		}
		
		private function onAdded(e:Event):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onKeyDown(e:KeyboardEvent):void
		{
			if(e.keyCode == Keyboard.ENTER)
				onRenameClick(null);
		}
		
		private function onRenameClick(e:MouseEvent):void
		{
			if(input.text.length > 0)
			{
				var evt:MsgEvent = new MsgEvent(MsgEvent.RENAME_LEVEL);
				evt.hintMsg = input.text;
				this.dispatchEvent(evt);
			}
			PopUpManager.removePopUp(this);
		}
	}
}