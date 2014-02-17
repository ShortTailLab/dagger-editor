package manager
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	

	public class SyncManager extends EventDispatcher
	{
		
		private var levelDataPath:String = "http://svn.stl.com/策划文档/屌丝RPG/levelData.xlsx";
		private const bt_node_format:String = "http://oss.aliyuncs.com/dagger-static/editor-configs/bt_node_format.json";
		private const dynamic_args:String = "http://oss.aliyuncs.com/dagger-static/editor-configs/dynamic_args.json";
		
		private var syncFlag:Dictionary = new Dictionary;
		
		static private var _instance:SyncManager = null;
		static public function getInstance():SyncManager
		{
			if(!_instance)
				_instance = new SyncManager;
			return _instance;
		}
		
		public function SyncManager()
		{
		}
		
		public function sync():void
		{
			this.syncLevelData();
			this.syncConfigs();
		}
		
		public function dispatch():void
		{
			trace("tring to dispatch");
			for each(var state in syncFlag)
				if(state == false) 
				{
					trace(state+" failed");
					return;
				}
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function syncLevelData():void
		{
			var urlLoader:URLLoader = new URLLoader;
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			var req:URLRequest = new URLRequest(levelDataPath);
			req.method = URLRequestMethod.GET;
			urlLoader.addEventListener(Event.COMPLETE, onLevelDataComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, onResponse);
			urlLoader.load(req);
			syncFlag["level"] = false;
		}
		

		private var loader:URLLoader = null;
		public function syncConfigs():void
		{
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, onNodesSyncComplete);
			loader.load( new URLRequest(bt_node_format) );
			syncFlag["nodes"] = false;
			
			loader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, onArgsSyncComplete);
			loader.load( new URLRequest(dynamic_args));
			syncFlag["args"] = false;
			
		}
		
		private function onNodesSyncComplete(e:Event = null):void
		{
			var str = e.target.data;
			var baseNodes = JSON.parse(str);
			var file:File = File.desktopDirectory.resolvePath("editor/bt_node_format.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(baseNodes));
			stream.close();
			syncFlag["nodes"] = true;
			this.dispatch();
		}	
		
		private function onArgsSyncComplete(e:Event = null):void
		{
			var str = e.target.data;
			var args = JSON.parse(str);
			var file:File = File.desktopDirectory.resolvePath("editor/dynamic_args.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(args));
			stream.close();	
			syncFlag["args"] = true;
			this.dispatch();
		}
		
		private function onLevelDataComplete(e:Event):void
		{
			var bytes:ByteArray = e.target.data as ByteArray;
			if(bytes.length == 0)
				return;
			
			var file:File = File.desktopDirectory.resolvePath("editor/levelData.xlsx");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeBytes(bytes);
			stream.close();
			
			syncFlag["level"] = true;
			this.dispatch();
		}
		
		private function onIOError(e:Event):void
		{
			trace("io error!");
		}
		
		private function onSecurityError(e:Event):void
		{
			trace("security error!");
		}
		
		private function onResponse(e:Event):void
		{
			trace((e as HTTPStatusEvent).responseURL+"\n状态: "+((e as HTTPStatusEvent).status==200?"成功":("失败 "+(e as HTTPStatusEvent).status))+"\n");
		}
	}
}