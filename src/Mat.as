package
{
	import editEntity.EditBase;
	import editEntity.MatSprite;

	public class Mat
	{
		public var editView:EditView = null;
		public var type:String = "";
		public var skin:EditBase = null;
		public var x:Number = 0.0;
		public var y:Number = 0.0;
		
		public function Mat(_editView:EditView, type:String)
		{
			this.editView = _editView;
			this.type = type;
			
		}
		
		public function initFromData(data:Object):void{}
		
		public function toExportData():Object{return null;}
	}
}