package behaviorEdit
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	import spark.components.Panel;
	
	public class PathEditPanel extends Panel
	{
		var screenFrame:UIComponent = null;
		var screenRX:int = 720;
		var screenRY:int = 1280;
		var padding:int = 30;
		
		public function PathEditPanel()
		{
			this.title = "重命名";
			this.width = screenRX*0.5+padding*2;
			this.height = screenRY*0.5+padding*2 + 50;
			
			screenFrame = new UIComponent;
			screenFrame.graphics.lineStyle(1);
			screenFrame.graphics.drawRect(0, 0, screenRX*0.5, screenRY*0.5);
			screenFrame.x = padding;
			screenFrame.y = padding;
			this.addElement(screenFrame);
			
			var btn:Button = new Button;
			btn.label = "确定";
			btn.y = 40;
			btn.addEventListener(MouseEvent.CLICK, onSave);
			this.addElement(btn);
			
			this.addEventListener(CloseEvent.CLOSE, onClose);
		}
		
		private function onClose(e:CloseEvent):void
		{
			PopUpManager.removePopUp(this);
		}
		
		private function onSave(e:MouseEvent):void
		{
		}
	}
}