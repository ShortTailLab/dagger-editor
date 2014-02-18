package behaviorEdit.bnodePainter
{
	import flash.events.MouseEvent;
	import flash.text.TextFormat;
	
	import mx.controls.TextInput;
	
	import behaviorEdit.bnodeController.BNodeController;
	
	public class LoopNodePainter extends BasePainer
	{
		public function LoopNodePainter(ctrl:BNodeController)
		{
			super(ctrl);
		}
		
		override public function paint():void
		{
			controller.node.nodeWidth = 110;
			controller.node.nodeHeight = 90;
			
			bg.graphics.clear();
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(color);
			bg.graphics.drawEllipse(0, 0, nodeWidth-horizontalPadding, nodeHeight-verticalPadding);
			bg.graphics.endFill();
			
			label.text = "循环次数:"
			label.width = label.textWidth+5;
			label.height = label.textHeight+5;
			label.x = 8;
			label.y = 10;
			label.setTextFormat(new TextFormat(null, 14));
			
			input = new TextInput;
			input.width = 50;
			input.height = 20;
			input.x = 15;
			input.y = 28;
			input.addEventListener(MouseEvent.MOUSE_DOWN, onLabelMouseDown);
			this.addChild(input);
		}
	}
}