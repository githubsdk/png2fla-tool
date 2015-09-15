package fileUtils
{
	import flash.filesystem.File;

	public class FileData
	{
		protected var _url:String;
		protected var _sName:String;
		protected var _nativePath:String;
		protected var _sRootName:String;
		protected var _fullPath:String;
		
		protected var _rootName:String;
		
		public function FileData(file:File=null, root:File=null)
		{
			if(file!=null && root!=null)
			{
				_url = file.url;
				_sName = file.name;
				_nativePath = file.nativePath;
				
				_fullPath = _url.replace("/"+file.name,"");
				_fullPath = _fullPath.replace(root.parent.url+"/","");
				
				_sRootName = root.name;
				
				var folders:Array = fullPath.split("/");
				_rootName = folders[0];
			}
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
		public function get fullPath():String
		{
			return _fullPath;
		}
		
		/**
		 *根目录文件夹名 
		 * @return 
		 * 
		 */		
		public function get rootName():String
		{
			return _rootName;
		}
	}
}