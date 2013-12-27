package
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.controls.Text;

	public class MatSprite extends Sprite
	{
		public var type:String;
		public var trimWidth:Number;
		public var route:Array = null;
		
		private var isShowType:Boolean = false;
		
		public function MatSprite(_type:String, width:Number = -1, showType:Boolean = false)
		{
			this.type = _type;
			this.trimWidth = width;
			this.isShowType = showType;
			
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
			
			/*if(isShowType)
			{
				var typeText:TextField = new TextField;
				typeText.defaultTextFormat = new TextFormat(null, 8);
				typeText.text = type;
				typeText.width = skin.width;
				typeText.height = 10;
				typeText.x = -skin.width*0.5;
				typeText.y = 0;
				addChild(typeText);
			}*/
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