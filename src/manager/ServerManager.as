package manager
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
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
			_versionPrefix = versionPrefix;
			_localDirectoryPrefix = localDiretory.url;
			if (_localDirectoryPrefix.charAt(_localDirectoryPrefix.length-1) != "/") {
				_localDirectoryPrefix += "/";
			}
			if (localDiretory.exists && localDiretory.isDirectory) {
				scanDirectory(localDiretory);
				var oldVersionUrl:String = "http://ds.shorttaillab.com/"+versionPrefix+"/version.json";
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.addEventListener(Event.COMPLETE, onOldVersionLoad);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onOldVersionLoadError);
				urlLoader.load(new URLRequest(oldVersionUrl));
				
				return true;
			}
			else {
				return false;
			}
		}
		
		private function onOldVersionLoad(e:Event):void {
			var oldDict:Object = JSON.parse(e.currentTarget.data);
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
			var versionFile:File = new File(tmpDirectory+"/"+"version.json");
			var fileStream:FileStream = new FileStream();
			fileStream.open(versionFile, FileMode.WRITE);
			fileStream.writeUTFBytes(JSON.stringify(oldDict));
			fileStream.close();
			
			versionFile.load();
			var urlRequest:URLRequest = new URLRequest();
//			urlRequest.
//			versionFile.addEventListener(Event.COMPLETE, onUploadComplete);
			
		}
		
		private function onOldVersionLoadError(e:IOErrorEvent):void {
			
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
						_versionDict[key]["p"] = 1;
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
			return MD5.hashBytes(bytesArray);
		}
		
		private var _versionPrefix:String;
		private var _localDirectoryPrefix:String;
		private var _versionDict:Object = new Object();
		private var _needToUpload:Vector.<String>;
		private static var _intance:ServerManager;
	}
}