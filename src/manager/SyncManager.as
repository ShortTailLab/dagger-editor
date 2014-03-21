package manager
{
	import com.hurlant.crypto.Crypto;
	import com.probertson.utils.GZIPBytesEncoder;
	
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	
	import by.blooddy.crypto.Base64;
	import by.blooddy.crypto.MD5;

	public class SyncManager
	{
		
		public function SyncManager() {}
		
		private static var _intance:SyncManager;
		public static function getInstance():SyncManager 
		{
			if (!_intance) _intance = new SyncManager();
			return _intance;
		}
		
		
		private const kGAMELEVEL_API_ADDRESS:String = "https://sh-test.shorttaillab.com/api/gameLevel";
		public function uploadLevelToGameServer( lid:String, data:Object, onComplete:Function):void
		{
			var details:String = "";
			
			data.key = "nimei123.J$p1ter";
			var json:String = JSON.stringify(data);
			
			var request:URLRequest = new URLRequest(this.kGAMELEVEL_API_ADDRESS);
			request.method = URLRequestMethod.POST;
			request.contentType = "application/json";
			request.data = json;
			
			var loader:URLLoader = new URLLoader(); 
			loader.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				onComplete( details );
			});
			
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, 
				function(e:HTTPStatusEvent):void
				{
					details += "\n上传: "+e.responseURL+"\n状态: ";
					if(e.status==200) details+="成功"
					else details+=("失败 "+e.status+"\n");
				});
			
			loader.load( request );
		}
		public function uploadLevelsToGameServer(dataList:Array):void
		{	
			var total:int = dataList.length;
			var count:int = 0;
			var details:String = "";
			for each( var data:Object in dataList )
			{
				data.key = "nimei123.J$p1ter";
				var json:String = JSON.stringify(data);
				//Utils.dumpObject(data);
				
				var request:URLRequest = new URLRequest(this.kGAMELEVEL_API_ADDRESS);
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

		public function uploadConfigFileToOSSFromPath(path:String, onComplete:Function) :void
		{
			var file:File = new File(path);
			var self:SyncManager = this;
			
			file.addEventListener(Event.COMPLETE, function(e:Event):void 
			{
				self.uploadConfigFileToOSS(file, onComplete);
			});
			file.load();
		}
		
		public function uploadConfigFileToOSS(file:File, onComplete:Function):void 
		{
			
			var path:File = Data.getInstance().resolvePath("tmp/");
			if( path.isDirectory ) 
				path.deleteDirectory(true);
			
			var tmp:File = new File(path.url+"/config/"+file.name);
			var fstream:FileStream = new FileStream();
			fstream.open( tmp, FileMode.WRITE );
			fstream.writeBytes( file.data );
			fstream.close();
				
			this.oss_upload( path, "dagger-configs", "CONFIG-VERSION.json", 
				function(msg:String):void
				{
					if( path.isDirectory ) path.deleteDirectory(true);
					onComplete(msg);
				}
			);
		}
		
		public function uploadLevelsToOSS( lid:String, onComplete:Function ):void 
		{
			var export:File = Data.getInstance().resolvePath("export/");
			if( export.exists && export.isDirectory )
				export.deleteDirectory(true);
			
			var err1:String = Data.getInstance().exportLevelJS( lid, lid );
			var stats:Object = Data.getInstance().getLevelDataForServer( lid );
			
			//Utils.dumpObject(stats);
			if( err1 || !stats ) {
				
				if( export.exists && export.isDirectory )
					export.deleteDirectory(true);
				onComplete( err1 +"\n生成服务器数据时出错" );
				
			} else {
				
				var self:SyncManager = this;
				// may dismath between oss and gameserver
				this.oss_upload( export, "dagger-levels", "LEVEL-VERSION.json", 
					function(m:String) : void {
						if( export.exists && export.isDirectory )
							export.deleteDirectory(true);
						try
						{
							self.uploadLevelToGameServer( lid, stats,
								function( m2:String ): void {
									onComplete( m +"\n" +m2 );
								}
							);
						}catch(err:IOError) {
							onComplete(m +"\n【失败】未能成功连接；");
						}
						
					}
				);
				
			}
		}
		
		// -----------------------------------------------------
		// oss upload utils
		private const kOSS_ADDRESS:String 		= "http://oss.aliyuncs.com/";
		private const kOSS_BUCKET:String 		= "dagger-static";
		private const kOSS_KEY_ID:String 		= "z7caZBtJU2kb8g3h";
		private const kOSS_KEY_SECREET:String 	= "fuihVj7qMCOjExkhKm2vAyEYhBBv8R"; 
		private function oss_upload( path:File, tag:String, vf_path:String, onComplete:Function):void 
		{;
			if( !path.exists || !path.isDirectory ) {
				onComplete( path.url+" 不是一个有效的文件夹地址" );
				return;
			}
			var self:* = this;
			
			// load remote version file
			var loader:URLLoader = new URLLoader();
			loader.addEventListener( Event.COMPLETE, function(e:Event):void 
			{
				var remoteVersion:Object = {}, version:Object = {};
				var valid_url:String = path.url+"/";

				// local & remote version
				try {
					remoteVersion = JSON.parse(e.currentTarget.data);
				} catch(e:Error) {};
				self.oss_gen_local_version( path, valid_url, tag, version );
				
				// find diffs & merge version
				var diffs:Array = [];
				for( var key:* in version ) 
				{
					if( !(key in remoteVersion) ) 
						diffs.push( key );
					else if( remoteVersion[key].h != version[key].h )
						diffs.push( key );
				}
				for( key in remoteVersion )
				{
					if( !(key in version) ) version[key] = remoteVersion[key];
				}
				
				if( diffs.length == 0 ) onComplete("无任何需要上传的改动");
				else {
					
					function uploadVersion( msg:String ):void
					{
						var vf:File = Data.getInstance().resolvePath(vf_path);
						var fstream:FileStream = new FileStream();
						fstream.open(vf, FileMode.WRITE);
						fstream.writeUTFBytes(JSON.stringify(version));
						fstream.close();
						self.oss_upload_file_aux(
							vf, tag+"/"+vf_path, 
							function(t:String):void {
								vf.deleteFile();
								onComplete(msg); 
							}, 
							function(t:String):void {
								vf.deleteFile();
								onComplete("[ERROR] version.json failed to upload"); 
							}
						);
					}
					
					var countor:int = 0, accumMsg:String = ""; 
					function check(t:String):void {
						accumMsg += t +"\n";
						countor ++;
						if( countor == diffs.length )
							uploadVersion(accumMsg);
					}
					for each( var item:* in diffs ) 
					{
						self.oss_upload_file_aux( 
							new File( valid_url+ item ), tag+"/"+item,
							function (t:String):void { check(t); },
							function (t:String):void { check(t); }
						);
					}
				}
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR, 
				function(e:IOErrorEvent):void
				{
					onComplete("[IO-ERROR]"+e.text);
				}
			);
			loader.addEventListener(
				HTTPStatusEvent.HTTP_RESPONSE_STATUS, function(e:HTTPStatusEvent):void {}
			);
			loader.load( new URLRequest( kOSS_ADDRESS + kOSS_BUCKET + "/"+tag+"/"+vf_path ) );
		}
		
		private function oss_gen_local_version( path:File, prefix:String, tag:String, version:Object ):void
		{
			if( !path.isDirectory  ) 
			{
				var key:String = path.url.substring(prefix.length);
				version[key] = {
					d : tag,
					p : 0,
					h : Utils.getMD5Sum(path)
				}
				return;
			}
			
			for each( var item:File in path.getDirectoryListing() )
			{
				if( item.name.charAt(0) == "." ) continue;
				this.oss_gen_local_version(item, prefix, tag, version);
			}
		}
		
		private function oss_upload_file_aux(file:File, remote_path:String, onComplete:Function, onError:Function):void {
			file.addEventListener(Event.COMPLETE, function(e:Event):void {
				var urlRequest:URLRequest = new URLRequest();
				urlRequest.method = URLRequestMethod.PUT;
				urlRequest.url = kOSS_ADDRESS+kOSS_BUCKET+"/"+remote_path;

				var headers:Array = [];
				var md5:String = "";
				var extension:String = remote_path.substring(remote_path.lastIndexOf(".")+1);
				if (extension == "js" || extension == "json") {
					headers.push( new URLRequestHeader("Content-Encoding","gzip") );
					var gzipEncoder:GZIPBytesEncoder = new GZIPBytesEncoder();
					var data:ByteArray = gzipEncoder.compressToByteArray(file.data);
					urlRequest.data = data;
					md5 = MD5.hashBytes(data);
				}
				else {
					md5 = Utils.getMD5Sum(file);
					urlRequest.data = file.data;
				}
				
				var date:Date = new Date();
				var token:String = getToken(
					URLRequestMethod.PUT, md5, "application/octet-stream", 
					date, "/"+kOSS_BUCKET+"/"+remote_path
				);

				headers.push( new URLRequestHeader("Date",RFCTimeFormat.toRFC802(date)) );
				headers.push( new URLRequestHeader("Content-Md5", md5) );
				headers.push( new URLRequestHeader("Content-Type", "application/octet-stream") );
			 	headers.push( new URLRequestHeader(
					"Authorization", "OSS "+kOSS_KEY_ID+":"+token
				) );
				
				urlRequest.requestHeaders = headers;
				
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, 
					function(e:IOErrorEvent):void {
						onError( "[IO-ERROR]"+e.text );
					}
				);
				urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, 
					function(e:SecurityErrorEvent):void {
						onError( "[SECURITY-ERROR]"+e.text );
					}
				);
				
				urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, 
					function(e:HTTPStatusEvent):void {
						if( e.status == 200 )
							onComplete( "[上传成功]: \n"+e.responseURL );
						else 
							onError( "[ERROR]"+e.status );
					}
				);
				urlLoader.load(urlRequest);
			});
			file.load();
		}
		
		private function getToken(verb:String, md5:String, type:String, date:Date, filepath:String):String {
			var content:String = verb+"\n"+md5+"\n"+type+"\n"+RFCTimeFormat.toRFC802(date)+"\n"+filepath;
			
			var keyBytesArray:ByteArray = new ByteArray();
			keyBytesArray.writeMultiByte(kOSS_KEY_SECREET, "utf-8");
			
			var contentByteArray:ByteArray = new ByteArray();
			contentByteArray.writeMultiByte(content, "utf-8");
			
			var result:ByteArray = Crypto.getHMAC("hmac-sha1").compute(keyBytesArray, contentByteArray);
			//trace("\nsignature content: "+content+"\n");
			return Base64.encode(result);
		}
		
		// -----------------------------------------------------
		// upload to game server
		
	}
}