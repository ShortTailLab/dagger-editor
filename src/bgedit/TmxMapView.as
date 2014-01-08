package bgedit
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.core.UIComponent;
	
	import net.pixelpracht.tmx.TmxLayer;
	import net.pixelpracht.tmx.TmxMap;
	import net.pixelpracht.tmx.TmxTileSet;
	
	public class TmxMapView extends UIComponent
	{
		public function TmxMapView()
		{
			
		}
		
		public function load(tmxPath:String, onComplete:Function=null):void {
			_onComplete = onComplete;
			_tmxPath = tmxPath;
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onTmxLoad);
			urlLoader.load(new URLRequest(_tmxPath));
		}
		
		private function onTmxLoad(e:Event):void {
			_xml = new XML(e.currentTarget.data);
			_tmxMap = new TmxMap(_xml);
			
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoad);
			var prefix:String = _tmxPath.substring(0, _tmxPath.lastIndexOf("/")+1);
			loader.load(new URLRequest(prefix + _xml..image.@source));
		}
		
		private function onImageLoad(e:Event):void {
			_tileSetImage = new Bitmap((e.currentTarget.content as Bitmap).bitmapData);
			loadLayers();
		}
		
		private function loadLayers():void {
			for (var name:String in _tmxMap.tileSets) {
				tileSetName = name;
				break;
			}
			
			var tileSet:TmxTileSet = _tmxMap.getTileSet(tileSetName);
			tileSet.image = _tileSetImage.bitmapData;
			
			if (_layers) {
				for (var i:int = 0; i < _layers.length; i++) {
					_layerContainer.removeChild(_layers[i]);
				}
			}
			
			_layerContainer = new Sprite();
			addChild(_layerContainer);
			_layers = new Vector.<TmxLayerView>();
			for (i = 0; i < _tmxMap.layersNameArray.length; i++) {
				var layer:TmxLayer = _tmxMap.getLayer(_tmxMap.layersNameArray[i]);
				var tmxLayerView:TmxLayerView = new TmxLayerView();
				tmxLayerView.init(layer);
				_layers.push(tmxLayerView);
				_layerContainer.addChild(tmxLayerView);
			}
			
			setMask();
			
			if (_onComplete != null) {
				_onComplete.apply();
				_onComplete = null;
			}
		}
		
		private function setMask():void {
			var sprite:Sprite = new Sprite();
			sprite.graphics.beginFill(0x000000);
			sprite.graphics.drawRect(0, 0, tmxMap.totalWidth, tmxMap.totalHeight);
			sprite.graphics.endFill();
			addChild(sprite);
			_layerContainer.mask = sprite;
		}
		
		public function loadFromXmlAndImage(xml:XML, image:Bitmap):void {
			_xml = xml;
			_tmxMap = new TmxMap(_xml);
			_tileSetImage = image;
			loadLayers();
		}
		
		public function loadFromXmlAndImgBytes(xml:XML, imgBytes:ByteArray):void{
			_xml = xml;
			_tmxMap = new TmxMap(_xml);
			var loader:Loader = new Loader;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadImgBytes);
			loader.loadBytes(imgBytes);
		}
		private function onLoadImgBytes(e:Event):void
		{
			var bmp:Bitmap = (e.target as LoaderInfo).content as Bitmap;
			_tileSetImage = bmp;
			loadLayers();
		}
		
		public function get tmxMap():TmxMap {
			return _tmxMap;
		}
		
		public static var tileSetName:String;
		
		private var _tmxPath:String;
		
		private var _xml:XML;
		private var _tmxMap:TmxMap;
		private var _tileSetImage:Bitmap;
		private var _layers:Vector.<TmxLayerView>;
		private var _onComplete:Function;
		private var _layerContainer:Sprite;
	}
}