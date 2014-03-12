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
		
		public function SyncManager()
		{
		}
		
		public static function getInstance():SyncManager {
			if (!_intance) {
				_intance = new SyncManager();
			}
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
		public function uploadFilesToServer(localDiretory:File, versionPrefix:String="dagger"):Boolean {
			if (_isUploading) {
				return true;
			}
			_isUploading = true;
			_versionPrefix = versionPrefix;
			_localDirectoryPrefix = localDiretory.url;
			_uploadMsg = "";
			_numUploaded = 0;
			if (_localDirectoryPrefix.charAt(_localDirectoryPrefix.length-1) != "/") {
				_localDirectoryPrefix += "/";
			}
			if (localDiretory.exists && localDiretory.isDirectory) {
				scanDirectory(localDiretory);
				var oldVersionUrl:String = STATIC_SERVER_ADDRESS+versionPrefix+"/version.json";
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.addEventListener(Event.COMPLETE, function(e){
					onOldVersionLoad(e);
					for each (var fileKey:String in _needToUpload) {
						var file:File = new File(_localDirectoryPrefix+fileKey);
						if (file.exists) {
							uploadFile(file, fileKey);
						}
					}
				});
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onOldVersionLoadError);
				urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, function(e:HTTPStatusEvent):void {
					for (var i:int = 0; i < e.responseHeaders.length; i++) {
						if (e.responseHeaders[i]["name"] == "Date") {
							_serverDate = RFCTimeFormat.fromRFC802(e.responseHeaders[i]["value"]);
							trace("server time: ", RFCTimeFormat.toRFC802(_serverDate));
						}
					}
				});
				urlLoader.load(new URLRequest(oldVersionUrl));
				
				return true;
			}
			else {
				return false;
			}
		}
		
		public function uploadFileToServerPath(localFile:File, serverPath:String, versionPrefix:String="dagger"):Boolean
		{
			if (_isUploading) {
				return true;
			}
			_isUploading = true;
			_versionPrefix = versionPrefix;
			_localDirectoryPrefix = localFile.url;
			_uploadMsg = "";
			_numUploaded = 0;
			if (localFile.exists && !localFile.isDirectory) {
				var versionDicKey:String = serverPath+"/"+localFile.name;
				this.makeFileVersionDic(_versionDict, localFile, versionDicKey, _versionPrefix);
				
				var oldVersionUrl:String = STATIC_SERVER_ADDRESS+versionPrefix+"/version.json";
				var urlLoader:URLLoader = new URLLoader();
				
				urlLoader.addEventListener(Event.COMPLETE, function(e){
					onOldVersionLoad(e);
					
					for each (var fileKey:String in _needToUpload) {
						uploadFile(localFile, fileKey);
					}
				});
				
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onOldVersionLoadError);
				urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, function(e:HTTPStatusEvent):void {
					for (var i:int = 0; i < e.responseHeaders.length; i++) {
						if (e.responseHeaders[i]["name"] == "Date") {
							_serverDate = RFCTimeFormat.fromRFC802(e.responseHeaders[i]["value"]);
							trace("server time: ", RFCTimeFormat.toRFC802(_serverDate));
						}
					}
				});
				urlLoader.load(new URLRequest(oldVersionUrl));
				
				return true;
			}
			else {
				return false;
			}
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
			
			uploadFile(versionFile, "version.json");
		}
		
		private function uploadFile(file:File, fileKey:String):void {
			file.addEventListener(Event.COMPLETE, function(e:Event):void {
				var urlRequest:URLRequest = new URLRequest();
				urlRequest.method = URLRequestMethod.PUT;
				urlRequest.url = STATIC_SERVER_ADDRESS+_versionPrefix+"/"+fileKey;
				
				var extension:String = fileKey.substring(fileKey.lastIndexOf(".")+1);
				var mimeType:String = MimeTypeMap.getMimeType(extension);
				if (mimeType == null) {
					mimeType = "application/octet-stream";
				}
				
				if (_serverDate == null) {
					_uploadMsg += "error: empty server date\n";
					_serverDate = new Date();
				}
				
				var headers:Array = new Array();
				var urlHeader:URLRequestHeader = new URLRequestHeader("Date",RFCTimeFormat.toRFC802(_serverDate));
				headers.push(urlHeader);
				urlHeader = new URLRequestHeader("Content-Type", mimeType);
				headers.push(urlHeader);
				
				var signature:String;
				var md5:String;
				if (extension == "js" || extension == "json") {
					urlHeader = new URLRequestHeader("Content-Encoding","gzip");
					headers.push(urlHeader);
					var gzipEncoder:GZIPBytesEncoder = new GZIPBytesEncoder();
					var data:ByteArray = gzipEncoder.compressToByteArray(file.data);
					urlRequest.data = data;
					md5 = MD5.hashBytes(data);
				}
				else {
					md5 = getMD5Sum(file);
					urlRequest.data = file.data;
				}
				signature = getSignature(URLRequestMethod.PUT, md5, mimeType, _serverDate, fileKey);
				urlHeader = new URLRequestHeader("Content-Md5", md5);
				headers.push(urlHeader);
				urlHeader = new URLRequestHeader("Authorization", "OSS "+OSS_ACCESS_KEY_ID+":"+signature);
				headers.push(urlHeader);
				
				urlRequest.requestHeaders = headers;
				
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.addEventListener(Event.COMPLETE, onUploadComplete);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, onResponse);
				urlLoader.load(urlRequest);
			});
			file.load();
		}
		
		private function onResponse(e:HTTPStatusEvent):void {
			trace("response code ", e.status, JSON.stringify(e.responseHeaders));
			_uploadMsg += "上传: "+(e as HTTPStatusEvent).responseURL+"\n状态: "+((e as HTTPStatusEvent).status==200?"成功":("失败 "+(e as HTTPStatusEvent).status))+"\n";
		}
		
		private function onUploadComplete(e:Event):void {
			trace("success");
			if ((e.currentTarget as URLLoader).data) {
				_uploadMsg += "信息: "+JSON.stringify((e.currentTarget as URLLoader).data) +"\n";
			}
			_numUploaded++;
			checkFinish();
		}
		
		private function onIOError(e:IOErrorEvent):void {
			trace("io error");
			_uploadMsg += e.text+"\n信息: IO error\n";
			_numUploaded++;
			checkFinish();
		}
		
		private function onSecurityError(e:SecurityErrorEvent):void {
			trace("security error");
			_uploadMsg += e.text+"\n信息: security error\n";
			_numUploaded++;
			checkFinish();
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
		
		private function scanDirectory(directory:File):void {
			var list:Array = directory.getDirectoryListing();
			for each (var file:File in list) {
				if (file.isDirectory) {
					scanDirectory(file);
				}
				else {
					if (file.name.charAt(0) == ".") {
						continue;
					}
					var key:String = file.url.substring(this._localDirectoryPrefix.length);
					makeFileVersionDic(_versionDict, file, key, _versionPrefix);
				}
			}
		}
		
		private function makeFileVersionDic(dic:Object, file:File, key:String, versionPrefix:String):void
		{
			dic[key] = new Object();
			dic[key]["d"] = versionPrefix;
			if (file.url.indexOf(".js") != -1) {
				dic[key]["p"] = 0;
			}
			else {
				dic[key]["p"] = 0;
			}
			dic[key]["h"] = getMD5Sum(file);
		}
		
		private function getMD5Sum(file:File):String {
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.READ);
			var bytesArray:ByteArray = new ByteArray();
			fileStream.readBytes(bytesArray, 0, fileStream.bytesAvailable);
			fileStream.close();
			return MD5.hashBytes(bytesArray);
		}
		
		/**
		 * 
		 * @param verb
		 * @param md5
		 * @param type
		 * @param date
		 * @param fileKey  file key in versionDict, e.g. level/demo.js
		 * @return 
		 * 
		 */
		private function getSignature(verb:String, md5:String, type:String, date:Date, fileKey:String):String {
			var content:String = verb+"\n"+md5+"\n"+type+"\n"+RFCTimeFormat.toRFC802(date)+"\n"+"/"+BUCKET+"/"+_versionPrefix+"/"+fileKey;
			var keyBytesArray:ByteArray = new ByteArray();
			keyBytesArray.writeMultiByte(OSS_ACCESS_KEY_SECRET, "utf-8");
			var contentByteArray:ByteArray = new ByteArray();
			contentByteArray.writeMultiByte(content, "utf-8");
			var hmac:HMAC = Crypto.getHMAC("hmac-sha1");
			var result:ByteArray = hmac.compute(keyBytesArray, contentByteArray);
			trace("signature content: "+content);
			return Base64.encode(result);
		}
	}
}