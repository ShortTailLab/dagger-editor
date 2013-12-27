package
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	public class MatSprite extends Sprite
	{
		public var type:String;
		public var trimWidth:Number;
		public var route:Array = null;
		
		public function MatSprite(_type:String, width:Number = -1)
		{
			this.type = _type;
			this.trimWidth = width;
			
			var path:String = Data.getInstance().matsData[_type].sourcePath;
			var loader = new Loader;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadSkin);
			loader.load(new URLRequest("Resource/"+path));
		}
		
		private function onLoadSkin(e:Event):void
		{
			var skin:Bitmap = Bitmap((e.target as LoaderInfo).loader.content);
			skin.scaleX = skin.scaleY = 0.5;
			skin.x = -skin.width*0.5;
			skin.y = -skin.height;
			addChild(skin);
			if(trimWidth > 0)
				trim(trimWidth);
		}
		
		public function trim(w:Number):void
		{
			if(this.width != w)
			{
				var scale:Number = w/this.width;
				this.scaleX = this.scaleY = scale;
			}
		}
	}
}