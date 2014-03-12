package manager
{
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.hash.HMAC;
	import com.probertson.utils.GZIPBytesEncoder;
	
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
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	import mx.rpc.events.HeaderEvent;
	
	import by.blooddy.crypto.Base64;
	import by.blooddy.crypto.MD5;

	public class SyncManager
	{
		
		private var _versionPrefix:String;
		private var _localDirectoryPrefix:String;
		private var _versionDict:Object = new Object();
		private var _needToUpload:Vector.<String>;
		private var _serverDate:Date;
		private static var _intance:SyncManager;
		
		private var _uploadMsg:String;
		private var _numUploaded:int;
		private var _isUploading:Boolean = false;
		
		private const OSS_ACCESS_KEY_ID:String	 	= "z7caZBtJU2kb8g3h";
		private const OSS_ACCESS_KEY_SECRET:String 	= "fuihVj7qMCOjExkhKm2vAyEYhBBv8R";
		// dagger static server (oss)
		private const STATIC_SERVER_ADDRESS:String 	= "http://ds.shorttaillab.com/"; 
		private const BUCKET:String 				= "dagger-static";
		private const GAMELEVEL_API_ADDRESS:String 	= "https://sh-test.shorttaillab.com/api/gameLevel"
		
		public function SyncManager() {}
		
		public static function getInstance():SyncManager 
		{
			if (!_intance) _intance = new SyncManager();
			return _intance;
		}
		
		public function uploadLevelsToServer(dataList:Array):void
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
		
		/**
		 * 
		 * @param localDiretory  local directory, like file:///Users/yourname/Desktop/editor/Resources
		 * @param versionPrefix  version prefix in server, like dev, or release, or test
		 * @return 
		 * 
		 */
		public function uploadFilesToServer(localDirectory:File, versionPrefix:String="dagger"):Boolean {
			this.oss_upload_directory( localDirectory, versionPrefix, "LEVEL-VERSION.json", function(){}, function(){});
			return true;
		}
		
		private const kOSS_ADDRESS:String 	= "http://oss.aliyuncs.com/";
		private const kOSS_BUCKET:String 	= "dagger-static";
		public function oss_upload_directory( path:File, tag:String, version:String, onComplete:Function, onError:Function):void 
		{
			if( !path.exists || !path.isDirectory ) {
				trace( path+" is not a valid directory");
				return;
			}
			var self = this;
			
			// load remote version file
			var loader:URLLoader = new URLLoader();
			loader.addEventListener( Event.COMPLETE, function(e:Event):void 
			{
				var remoteVersion:Object = {}, version = {};
				var valid_url:String = path.url+"/";
				
				// local & remote version
				try {
					remoteVersion = JSON.parse(e.currentTarget.data);
				} catch(e:Error) {};
				self.oss_gen_local_version( path, valid_url, tag, version );
				
				// merge version
				var diffs:Array = [];
				for( var key:* in remoteVersion ) 
				{
					if( !(key in version) ) {
						version[key] = remoteVersion;
					} else {
						if( remoteVersion[key].h != version[key].h )
							diffs.push( valid_url+key );
					}
				}
				for each( var item:* in diffs ) 
					trace(item);
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void
			{
				onError("[IO-ERROR]"+e.text);
			});
			loader.load( new URLRequest( kOSS_ADDRESS + kOSS_BUCKET + "/"+tag+"/"+version ) );
		}
		
		private function oss_gen_local_version( path:File, prefix:String, tag:String, version:Object ):void
		{
			for each( var item:File in path.getDirectoryListing() )
			{
				if( item.name.charAt(0) == "." ) continue;
				if( item.isDirectory ) this.oss_gen_local_version(item, prefix, tag, version);
				else{
					var key:String = item.url.substring(prefix.length);
					version[key] = {
						d : tag,
						p : 0,
						h : Utils.getMD5Sum(item)
					}
				}
			}
		}
		
		private function oss_upload_file_aux(file:File, fileKey:String, onComplete:Function, onError:Function):void {
			file.addEventListener(Event.COMPLETE, function(e:Event):void {
				var urlRequest:URLRequest = new URLRequest();
				urlRequest.method = URLRequestMethod.PUT;
				urlRequest.url = STATIC_SERVER_ADDRESS+_versionPrefix+"/"+fileKey;
				
				var headers:Array = [];
				var md5:String = "";
				var extension:String = fileKey.substring(fileKey.lastIndexOf(".")+1);
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
				
				var date = new Date();
				var token = getToken(
					URLRequestMethod.PUT, md5, "application/octet-stream", 
					date, "/"+BUCKET+"/"+_versionPrefix+"/"+fileKey
				);

				headers.push( new URLRequestHeader("Date",RFCTimeFormat.toRFC802(date)) );
				headers.push( new URLRequestHeader("Content-Md5", md5) );
				headers.push( new URLRequestHeader("Content-Type", "application/octet-stream") );
			 	headers.push( new URLRequestHeader(
					"Authorization", "OSS "+OSS_ACCESS_KEY_ID+":"+token
				) );
				
				urlRequest.requestHeaders = headers;
				
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, 
					function(e:IOErrorEvent) {
						onError( "[IO-ERROR]"+e.text );
					}
				);
				urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, 
					function(e:SecurityErrorEvent) {
						onError( "[SECURITY-ERROR]"+e.text );
					}
				);
				
				urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, 
					function(e:HTTPStatusEvent) {
						if( e.status == 200 )
							onComplete( e.responseURL );
						else 
							onError( "[ERROR]"+e.status );
					}
				);
				urlLoader.load(urlRequest);
			});
			file.load();
		}
		
		private function onOldVersionLoad(e:Event):void {
			var oldDict:Object;
			try {
				oldDict = JSON.parse(e.currentTarget.data);
			}
			catch (e:Error) {
				oldDict = new Object();
			}
			_needToUpload = new Vector.<String>();
			for (var key:String in _versionDict) {
				if (oldDict[key]) {
					if (oldDict[key]["h"] != _versionDict[key]["h"]) {
						oldDict[key] = _versionDict[key];
						_needToUpload.push(key);
					}
				}
				else {
					oldDict[key] = _versionDict[key];
					_needToUpload.push(key);
				}
			}
			
			var tmpDirectory:String = _localDirectoryPrefix.substring(0, _localDirectoryPrefix.lastIndexOf("/",_localDirectoryPrefix.length-2));
			var versionFile:File = new File(tmpDirectory+"/version.json");
			var fileStream:FileStream = new FileStream();
			fileStream.open(versionFile, FileMode.WRITE);
			fileStream.writeUTFBytes(JSON.stringify(oldDict));
			fileStream.close();
			
			//uploadFile(versionFile, "version.json");
		}
		
		private function onOldVersionLoadError(e:IOErrorEvent):void {
			trace("old version file load error");
			_uploadMsg += e.text+"\n信息: IO error\n";
			onOldVersionLoad(null);
		}
		
		private function checkFinish():void {
			if (_numUploaded == _needToUpload.length+1) {
				Alert.show(_uploadMsg, "上传日志");
				_isUploading = false;
			}
		}
		
		private function getToken(verb:String, md5:String, type:String, date:Date, filepath:String):String {
			var content:String = verb+"\n"+md5+"\n"+type+"\n"+RFCTimeFormat.toRFC802(date)+"\n"+filepath;
			
			var keyBytesArray:ByteArray = new ByteArray();
			keyBytesArray.writeMultiByte(OSS_ACCESS_KEY_SECRET, "utf-8");
			
			var contentByteArray:ByteArray = new ByteArray();
			contentByteArray.writeMultiByte(content, "utf-8");
			
			var result:ByteArray = Crypto.getHMAC("hmac-sha1").compute(keyBytesArray, contentByteArray);
			trace("\nsignature content: "+content+"\n");
			return Base64.encode(result);
		}
	}
}