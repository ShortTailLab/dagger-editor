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
	
	import by.blooddy.crypto.Base64;
	import by.blooddy.crypto.MD5;

	public class ServerManager
	{
		public function ServerManager()
		{
		}
		
		public static function getInstance():ServerManager {
			if (!_intance) {
				_intance = new ServerManager();
			}
			return _intance;
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
				var oldVersionUrl:String = SERVER_ADDRESS+versionPrefix+"/version.json";
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.addEventListener(Event.COMPLETE, onOldVersionLoad);
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
//			fileStream.writeUTFBytes(JSON.stringify(_versionDict));
			fileStream.close();
			
//			if (_needToUpload.length > 0) {
				uploadFile(versionFile, "version.json");
//			}
			
			for each (var fileKey:String in _needToUpload) {
				var file:File = new File(_localDirectoryPrefix+fileKey);
				if (file.exists) {
					uploadFile(file, fileKey);
				}
			}
		}
		
		private function uploadFile(file:File, fileKey:String):void {
			file.addEventListener(Event.COMPLETE, function(e:Event):void {
				var urlRequest:URLRequest = new URLRequest();
				urlRequest.method = URLRequestMethod.PUT;
				urlRequest.url = SERVER_ADDRESS+_versionPrefix+"/"+fileKey;
				
				var extension:String = fileKey.substring(fileKey.lastIndexOf(".")+1);
				var mimeType:String = MimeTypeMap.getMimeType(extension);
				if (mimeType == null) {
					mimeType = "application/octet-stream";
				}
				
//				var ba1:ByteArray = new ByteArray();
//				ba1.writeUTFBytes(OSS_ACCESS_KEY_SECRET);
////				ba1.writeMultiByte(OSS_ACCESS_KEY_SECRET, "utf-8");
//				var ba2:ByteArray = new ByteArray();
//				var content:String = URLRequestMethod.PUT+"\n"+"fd8d9d2dd058b4a03a3603f26157cb63"+"\n"+"application/octet-stream"+"\n"+"Thu, 09 Jan 2014 08:09:35 GMT"+"\n"+"/"+BUCKET+"/"+_versionPrefix+"/"+fileKey;
////				var content:String = "PUT\nfd8d9d2dd058b4a03a3603f26157cb63\napplication/octet-stream\nThu, 09 Jan 2014 08:09:35 GMT\n/dagger-static/dagger/version.json";
//				ba2.writeUTFBytes(content);
////				ba2.writeUTFBytes("PUT\nfd8d9d2dd058b4a03a3603f26157cb63\napplication/octet-stream\nThu, 09 Jan 2014 08:09:35 GMT\n/dagger-static/dagger/version.json");
//				trace("str length ", content.length, ba2.length);
//				var hmac:HMAC = Crypto.getHMAC("hmac-sha1");
//				var result:ByteArray = hmac.compute(ba1, ba2);
//				trace(Base64.encode(result));
				
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
					var key:String = file.url.substring(_localDirectoryPrefix.length);
					_versionDict[key] = new Object();
					_versionDict[key]["d"] = _versionPrefix;
					if (file.url.indexOf(".js") != -1) {
						_versionDict[key]["p"] = 0;
					}
					else {
						_versionDict[key]["p"] = 0;
					}
					_versionDict[key]["h"] = getMD5Sum(file);
				}
			}
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
		
		private var _versionPrefix:String;
		private var _localDirectoryPrefix:String;
		private var _versionDict:Object = new Object();
		private var _needToUpload:Vector.<String>;
		private var _serverDate:Date;
		private static var _intance:ServerManager;
		
		private var _uploadMsg:String;
		private var _numUploaded:int;
		private var _isUploading:Boolean = false;
		
		private const OSS_ACCESS_KEY_ID:String	 	= "z7caZBtJU2kb8g3h";
		private const OSS_ACCESS_KEY_SECRET:String 	= "fuihVj7qMCOjExkhKm2vAyEYhBBv8R";
		private const SERVER_ADDRESS:String 		= "http://ds.shorttaillab.com/";
		private const BUCKET:String 				= "dagger-static";
	}
}