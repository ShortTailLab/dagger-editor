package mapEdit
{
	import flash.display.Bitmap;
	import flash.filesystem.File;

	public class EditMapControl
	{
		public var mMapHeight:Number = 0.0;
		private var tmxFile:File = null;
		private var mapXML:XML = null;

		static private var _instance:EditMapControl = null;
		
		static public function getInstance():EditMapControl
		{
			if(!_instance)
				_instance = new EditMapControl;
			return _instance;
		}
		
		public function EditMapControl() 
		{
			// force calculation of height
			getAMap();
		}

		public function getAMap():Bitmap
		{
			var scale:Number = 0.0;

			var map:Bitmap = new MainScene.BgImage as Bitmap;
			var scale:Number =  360 / map.width;
			
			map.scaleX = scale;
			map.scaleY = scale;
			mMapHeight = map.height;
			
			return map;
		}
	}
}