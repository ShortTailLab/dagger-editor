package behaviorEdit
{
	import flash.events.MouseEvent;
	import flash.text.TextFormat;
	
	import mx.controls.TextArea;

	public class ExecBNode extends BNode
	{
		
		private var inputLabel:TextArea;
		
		public function ExecBNode()
		{
			super(BType.BTYPE_EXEC, 0xF0FFF0, false);
		}
		
		
		override public function init(_view:BTEditView):void
		{
			super.init(_view);
			
			nodeWidth = 200;
			nodeHeight = 120;
			
			bg.graphics.clear();
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(color);
			bg.graphics.drawRect(0, 0, nodeWidth-horizontalPadding, nodeHeight-verticalPadding);
			bg.graphics.endFill();
			label.setTextFormat(new TextFormat(null, 16));
			label.x = 5;
			label.y = 5;
			
			inputLabel = new TextArea();
			inputLabel.width = 150;
			inputLabel.height = 60;
			inputLabel.x = 10;
			inputLabel.y = 20;
			inputLabel.addEventListener(MouseEvent.MOUSE_DOWN, onLabelMouseDown);
			this.addChild(inputLabel);
		}
		
		override public function initData(data:Object):void
		{
			if(data)
				inputLabel.text = data.content;
		}
		
		override public function exportData():Object
		{
			if(inputLabel.text != "")
			{
				var obj:Object = new Object;
				obj.content = inputLabel.text;
				return obj;
			}
			return null;
		}
		private function onLabelMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
		}
		
		
	}
}