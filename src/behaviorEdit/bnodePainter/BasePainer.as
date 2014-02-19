package behaviorEdit.bnodePainter
{
	import mx.core.UIComponent;
	
	import behaviorEdit.BNode;

	public class BasePainer
	{
		protected var targetNode:BNode = null;
		protected var graphCanvas:UIComponent;
		protected var defaultColor:uint;
		
		public function BasePainer(node:BNode)
		{
			targetNode = node;
			graphCanvas = new UIComponent;
			defaultColor = targetNode.color;
			targetNode.addChild(graphCanvas);
		}
		
		public function setDefaultColor(color:uint):void
		{
			defaultColor = color;
		}
		public function getCanvas():UIComponent
		{
			return graphCanvas;
		}
		public function paint():void{}
		public function clear():void
		{
			graphCanvas.removeChildren();
			graphCanvas.graphics.clear();
		}
		public function dispose():void
		{
			targetNode.removeChild(graphCanvas);
			graphCanvas = null;
		}
		
	}
}