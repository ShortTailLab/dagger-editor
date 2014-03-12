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
		
		// game server 
		private const kGAMELEVEL_API_ADDRESS:String = "https://sh-test.shorttaillab.com/api/gameLevel";
		private const kGAMESERVER_KEY = "nimei123.J$p1ter";
		public function uploadLevelProfilesToServer(dataList:Array, onDone:Function):void
		{
			this.uploadJson(kGAMELEVEL_API_ADDRESS, kGAMESERVER_KEY, dataList, onDone);
		}
	
		// static server 
		private const kOSS_ACCESS_KEY:String = "z7caZBtJU2kb8g3h";
		private const kOSS_ACCESS_PRIVATE_KEY:String = "fuihVj7qMCOjExkhKm2vAyEYhBBv8R";
		private const kLEVEL_VERSION:String = "LEVEL-VERSION.json";
		public function uploadLevelsToStaticServer(tag:String, onDone:Function):void
		{
			// launch upload script 
			var commands:Vector.<String> = new Vector.<String>();
//			commands.push("data/makeDist.py")
//			commands.push("export/");
//			commands.push(tag);
//			commands.push("level");
//			commands.push(kLEVEL_VERSION);
//			commands.push(kOSS_ACCESS_KEY);
//			commands.push(kOSS_ACCESS_PRIVATE_KEY);
			
			this.cmd("/bin/ls", commands, function( output ){
				onDone(output);
			}, function(output){ onDone(output); });
		}
		
		
		// helper 
		private function uploadJson(url:String, key:String, dataList:Array, onDone:Function):void
		{	
			var total:int = dataList.length;
			var count:int = 0;
			var details:String = "";
			for each( var data:Object in dataList )
			{
				data.key = key
				var json:String = JSON.stringify(data);
				
				var request:URLRequest = new URLRequest(url);
				request.method = URLRequestMethod.POST;
				request.contentType = "application/json";
				request.data = json;
				
				var loader:URLLoader = new URLLoader(); 
				loader.addEventListener(Event.COMPLETE, function(e:Event):void
				{
					count ++;
					if( count == total )
					{
						onDone(details);
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
		
		private function cmd(path:String, commands:Vector.<String>, onStandardOutput:Function, onErrorOutput:Function):void
		{
			var info:* = new NativeProcessStartupInfo();
			info.arguments = commands;
			info.workingDirectory = File.desktopDirectory.resolvePath("editor");
			info.executable = new File(path);
			
			var native:NativeProcess = new NativeProcess();
			native.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, 
				function(event:ProgressEvent):void 
				{
					try {
						var process:NativeProcess = event.target as NativeProcess;
						var data:String = process.standardOutput.readUTFBytes(
							process.standardOutput.bytesAvailable
						);
					} catch(err:Error) {
						onErrorOutput(err.message);
						return;
					}
					onStandardOutput( data );
				});
			native.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, 
				function(event:ProgressEvent):void 
				{
					try {
						var process:NativeProcess = event.target as NativeProcess;
						var data:String = process.standardOutput.readUTFBytes(
							process.standardOutput.bytesAvailable
						);
					} catch(err:Error) {
						onErrorOutput(err.message);
						return;
					}
					onErrorOutput( data );
				});
			native.start( info );
		}
		
	}
}