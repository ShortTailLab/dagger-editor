package
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import bgedit.TmxMapView;

	public class EditMapControl
	{
		public var mapHeight:Number = 0.0;
		private var tmxFile:File = null;
		private var mapXML:XML = null;
		
		[Embed(source="background.jpg")]
		static public var BgImage:Class;
		static private var _instance:EditMapControl = null;
		static public function getInstance():EditMapControl
		{
			if(!_instance)
				_instance = new EditMapControl;
			return _instance;
		}
		
		public function EditMapControl()
		{
		}
		
		public function setMapTMX(_tmxFile:File):void
		{
			tmxFile = _tmxFile
			var fileStream:FileStream = new FileStream();
			fileStream.open(tmxFile, FileMode.READ);
			mapXML = new XML(fileStream.readUTFBytes(fileStream.bytesAvailable));
			fileStream.close();
			getAMap();
		}
		public function setDefaultMap():void
		{
			tmxFile = null;
		}
		public function getAMap():DisplayObject
		{
			var map:DisplayObject;
			var scale:Number = 0.0;
			if(tmxFile)
			{
				var imagePath:String = tmxFile.url.substring(0,tmxFile.url.lastIndexOf("/")+1) + mapXML..image.@source;
				var file:File = new File(imagePath);
				var fileStream:FileStream = new FileStream;
				fileStream.open(file, FileMode.READ);
				var imgBytes:ByteArray = new ByteArray;
				fileStream.readBytes(imgBytes, 0, fileStream.bytesAvailable);
				fileStream.close();
				
				map = new TmxMapView();
				(map as TmxMapView).loadFromXmlAndImgBytes(mapXML, imgBytes);
				var tmxMap = (map as TmxMapView).tmxMap;
				scale = 320/tmxMap.totalWidth;
				mapHeight =  (tmxMap.totalHeight-tmxMap.tileHeight)*scale; 
			}
			else
			{
				map = new BgImage as Bitmap;
				scale = 0.5;
				mapHeight = 480;
			}
			map.scaleX = map.scaleY = scale;
			return map;
		}
		
		
	}
}