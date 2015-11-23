package fileUtils
{
	import flash.filesystem.File;

	public class FileData
	{
		protected var _url:String;
		protected var _sName:String;
		protected var _nativePath:String;
		protected var _sRootName:String;
		protected var _folderPath:String;
		protected var _fullPath:String;
		
		public function FileData(file:File=null, root:File=null)
		{
			if(file!=null && root!=null)
			{
				_url = file.url;
				_sName = file.name;
				_nativePath = file.nativePath;
				
				_folderPath = _url.replace("/"+file.name,"");
				_folderPath = _folderPath.replace(root.url+"/","");
				_fullPath = _url.replace(root.url+"/","");
				_sRootName = root.name;
			}
		}
		
		public function get fullPath():String
		{
			return _fullPath;
		}

		public function get url():String
		{
			return _url;
		}
		
		/**
		 *文件名 
		 * @return 
		 * 
		 */		
		public function get sName():String
		{
			return _sName;
		}
		
		public function get nativePath():String
		{
			return _nativePath;
		}
		
		/**
		 *根目录名 
		 * @return 
		 * 
		 */		
		public function get sRootName():String
		{
			return _sRootName;
		}
		
		/**
		 *获得文件在根目录下的完整路径 
		 * @return 
		 * 
		 */		
		public function get folderPath():String
		{
			return _folderPath;
		}
		
	}
}