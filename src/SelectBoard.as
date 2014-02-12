package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import spark.components.TextInput;
	
	import editEntity.EditBase;
	import editEntity.MatFactory;
	import editEntity.MatSprite;
	
	public class SelectBoard extends UIComponent
	{
		private var selectContainer:Sprite = null;
		private var timeInput:TextInput = null;
		private var xInput:TextInput = null;
		private var triggerInput:TextInput = null;
		
		private var control:SelectControl = null;
		
		public function SelectBoard(_control:SelectControl)
		{
			this.control = _control;
			control.addEventListener(Event.CHANGE, onChange);
			
			//var selectLabel:TextField = Utils.getLabel("选择", 0, 0, 14);
			//this.addChild(selectLabel);
			
			var timeLabel:TextField = Utils.getLabel("时间:(ms)", 0, 0, 14);
			this.addChild(timeLabel);
			timeInput = new TextInput;
			timeInput.width = 80;
			timeInput.height = 30;
			timeInput.restrict = "0123456789";
			timeInput.x = 0; 
			timeInput.y = timeLabel.y + 20;
			timeInput.addEventListener(FlexEvent.ENTER, onSubmitTime);
			this.addChild(timeInput);
			
			var xLabel:TextField = Utils.getLabel("x:", 0, timeLabel.y+70, 14);
			this.addChild(xLabel);
			xInput = new TextInput;
			xInput.width = 80;
			xInput.height = 30;
			xInput.restrict = "0123456789";
			xInput.x = 0; 
			xInput.y = xLabel.y + 20;
			xInput.addEventListener(FlexEvent.ENTER, onSubmitX);
			this.addChild(xInput);
			
			var triggerLabel:TextField = Utils.getLabel("触发时间", 0, xLabel.y+70, 14);
			this.addChild(triggerLabel);
			triggerInput = new TextInput;
			triggerInput.width = 80;
			triggerInput.height = 30;
			triggerInput.restrict = "0123456789";
			triggerInput.x = 0; 
			triggerInput.y = triggerLabel.y + 20;
			triggerInput.addEventListener(FlexEvent.ENTER, onSubmitTrigger);
			this.addChild(triggerInput);
			
		}
		
		public function update(e:MsgEvent = null):void
		{
			
			timeInput.text = "";
			xInput.text = "";
			triggerInput.text = "";
			if(control.targets.length == 1)	
			{
				var data:Object = EditBase(control.targets[0]).toExportData();
				timeInput.text = data.y;
				xInput.text = data.x;
				if(data.hasOwnProperty("triggerTime"))
					triggerInput.text = data.triggerTime;
			}
		}
		
		public function onChange(e:Event):void
		{
			if(selectContainer)
			{
				this.removeChild(selectContainer);
				selectContainer = null;
			}
			
			var length:int = control.targets.length;
			if(length > 0)
			{
				selectContainer = new Sprite;
				selectContainer.x = 0;
				selectContainer.y = 240;
				this.addChild(selectContainer);
				
				for(var i:int = 0; i < length; i++)
				{
					var m:EditBase = MatFactory.createMat(control.targets[i].type, 30);
					m.trim(40);
					var pos:Point = Utils.makeGrid(new Point(0, 0), 50, 8, i);
					m.x = pos.x;
					m.y = pos.y;
					selectContainer.addChild(m);
				}
				
				if(length == 1)
					EditBase(control.targets[0]).addEventListener(MsgEvent.POS_CHANGE, update);
				
			}
			update();
		}
		
		private function onInput(e:Event):void
		{
			
		}
		
		private function onSubmitTime(e:FlexEvent):void
		{
			for each(var m:EditBase in control.targets)
			{
				var data:Object = m.toExportData();
				if(timeInput.text.length > 0)
					data.y = int(timeInput.text);
				m.initFromData(data);
			}
		}
		
		private function onSubmitX(e:FlexEvent):void
		{
			for each(var m:EditBase in control.targets)
			{
				var data:Object = m.toExportData();
				if(xInput.text.length > 0)
					data.x = int(xInput.text);
				m.initFromData(data);
			}
		}
		
		private function onSubmitTrigger(e:FlexEvent):void
		{
			for each(var m:EditBase in control.targets)
			{
				var data:Object = m.toExportData();
				if(triggerInput.text.length > 0)
					data.triggerTime = int(triggerInput.text);
				else 
					data.triggerTime = 0;
				m.initFromData(data);
				if(m is MatSprite)
					MatSprite(m).showTrigger();
			}
		}
	}
}