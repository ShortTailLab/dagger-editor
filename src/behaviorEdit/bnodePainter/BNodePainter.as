package behaviorEdit.bnodePainter
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import behaviorEdit.bnodeController.BNodeController;
	
	public class BNodePainter extends BasePainer
	{
		private var bgWidth:int;
		private var bgHeight:int;
		
		public function BNodePainter(ctrl:BNodeController)
		{
			super(ctrl);
			bgWidth = ctrl.node.nodeWidth - ctrl.node.horizontalPadding;
			bgHeight = ctrl.node.nodeHeight - ctrl.node.verticalPadding;
		}
		
		override public function paint():void
		{
			var bg:Sprite = new Sprite;
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(controller.color);
			bg.graphics.drawRect(0, 0, bgWidth, bgHeight);
			bg.graphics.endFill();
			controller.node.addChild(bg);
			
			var label = new TextField;
			label.defaultTextFormat = new TextFormat(null, 24);
			label.text = controller.type;
			label.selectable = false;
			label.width = label.textWidth+5;
			label.height = label.textHeight+5;
			controller.node.addChild(label);
			label.x = bg.width*0.5-label.textWidth*0.5;
			label.y = bg.height*0.5-label.textHeight*0.5;
		}
	}
}