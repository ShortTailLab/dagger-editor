package behaviorEdit.bnodeController
{
	import behaviorEdit.BNode;
	import behaviorEdit.bnodePainter.BasePainer;

	public class BNodeController
	{
		public var type:String;
		public var node:BNode;
		public var nodePainter:BasePainer;
		public var graphPainter:BasePainer;
		public var color:uint = 0;
		
		public function BNodeController()
		{
			this.type = node.type;
		}
		
		public function renderNode():void
		{
			if(nodePainter)
				nodePainter.paint();
		}
		
		public function renderGraph():void
		{
			if(graphPainter)
				graphPainter.paint();
		}
		
		public function initData(data:Object):void
		{
		}
		
		public function exportData():Object
		{
			return null;
		}
	}
}