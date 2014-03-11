package manager
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.Capabilities;
	
	import mx.controls.Alert;

	public class SyncManager
	{
		private const GAMELEVEL_API_ADDRESS:String 	= "https://sh-test.shorttaillab.com/api/gameLevel"
		
		private static var mInstance:SyncManager;
		public static function getInstance():SyncManager {
			if (!mInstance) mInstance = new SyncManager();
			return mInstance;
		}
		
		public function SyncManager() {}
		
		public function uploadLevelProfilesToServer(dataList:Array):void
		{	
			var total:int = dataList.length;
			var count:int = 0;
			var details:String = "";
			for each( var data:Object in dataList )
			{
				data.key = "nimei123.J$p1ter";
				var json:String = JSON.stringify(data);
				//Utils.dumpObject(data);
				
				var request:URLRequest = new URLRequest(this.GAMELEVEL_API_ADDRESS);
				request.method = URLRequestMethod.POST;
				request.contentType = "application/json";
				request.data = json;

				var loader:URLLoader = new URLLoader(); 
				loader.addEventListener(Event.COMPLETE, function(e:Event):void
				{
					count ++;
					if( count == total )
					{
						Alert.show(details);
					}
				});
				
				loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, 
					function(e:HTTPStatusEvent):void
					{
						details += "\n上传: "+e.responseURL+"\n状态: ";
						if(e.status==200)
							details+="成功"
						else 
							details+=("失败 "+e.status+"\n");
					});
				
				loader.load( request );
			}
		}
		
		private function cmd(commands:Vector.<String>):void
		{
			var info:* = new NativeProcessStartupInfo();
			info.arguments = commands;
	
			if((Capabilities.os.indexOf("Windows") >= 0))
				info.executable = new File("c:\\windows\\system32\\cmd.exe");
			else if((Capabilities.os.indexOf("Mac") >= 0))
				info.executable = new File("/bin/bash");
			
			var native:NativeProcess = new NativeProcess();
			native.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, 
				function(event:ProgressEvent):void 
				{
					var process:NativeProcess = event.target as NativeProcess;
					var data:String = process.standardOutput.readUTFBytes(
						process.standardOutput.bytesAvailable
					);
					trace( data );
				});
			native.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, 
				function(event:ProgressEvent):void 
				{
					var process:NativeProcess = event.target as NativeProcess;
					var data:String = process.standardOutput.readUTFBytes(
						process.standardOutput.bytesAvailable
					);
					trace( "[ERROR]"+data );
				});
			native.start( info );
		}
		
		// 
		private const kOSS_ACCESS_KEY:String = "z7caZBtJU2kb8g3h";
		private const kOSS_ACCESS_PRIVATE_KEY:String = "fuihVj7qMCOjExkhKm2vAyEYhBBv8R";
		private const kLEVEL_VERSION:String = "LEVEL-VERSION.json";
		public function uploadLevelsToStaticServer(tag:String):void
		{
			var root:String = File.desktopDirectory.resolvePath("editor").url;
			var script:String = File.desktopDirectory.resolvePath("editor/data/makeDist.py").url;
			
			var commands:Vector.<String> = new Vector.<String>();
			commands.push("python");
			commands.push(script);
			commands.push("../export/");
			commands.push(tag);
			commands.push("level");
			commands.push(kLEVEL_VERSION);
			commands.push(kOSS_ACCESS_KEY);
			commands.push(kOSS_ACCESS_PRIVATE_KEY);
			
			this.cmd(commands);
		}
	}
}