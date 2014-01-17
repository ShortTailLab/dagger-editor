package
{
	import editEntity.MatSprite;

	public class Mat
	{
		public var type:String = "";
		public var skin:MatSprite = null;
		public var x:Number = 0.0;
		public var y:Number = 0.0;
		public var triggerTime:int = -1;
		
		public function Mat(type:String)
		{
			this.type = type;
			skin = new MatSprite(type);
		}
	}
}