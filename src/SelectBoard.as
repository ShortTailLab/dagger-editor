package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	
	import mx.core.UIComponent;
	
	import spark.components.TextInput;
	
	public class SelectBoard extends UIComponent
	{
		private var selectMats:Sprite = null;
		private var timeInput:TextInput = null;
		private var xInput:TextInput = null;
		private var triggerInput:TextInput = null;
		
		public function SelectBoard()
		{
			var selectLabel:TextField = Utils.getLabel("选择", 0, 0, 14);
			this.addChild(selectLabel);
			
			var timeLabel:TextField = Utils.getLabel("时间", 0, 60, 14);
			this.addChild(timeLabel);
			timeInput = new TextInput;
			timeInput.width = 80;
			timeInput.height = 30;
			timeInput.restrict = "0123456789";
			timeInput.x = 0; 
			timeInput.y = timeLabel.y + 20;
			this.addChild(timeInput);
			
			var xLabel:TextField = Utils.getLabel("x:", 0, timeLabel.y+70, 14);
			this.addChild(xLabel);
			xInput = new TextInput;
			xInput.width = 80;
			xInput.height = 30;
			xInput.restrict = "0123456789";
			xInput.x = 0; 
			xInput.y = xLabel.y + 20;
			this.addChild(xInput);
			
			var triggerLabel:TextField = Utils.getLabel("触发时间", 0, xLabel.y+70, 14);
			this.addChild(triggerLabel);
			triggerInput = new TextInput;
			triggerInput.width = 80;
			triggerInput.height = 30;
			triggerInput.restrict = "0123456789";
			triggerInput.x = 0; 
			triggerInput.y = triggerLabel.y + 20;
			this.addChild(triggerInput);
		}
		
		
		
	}
}