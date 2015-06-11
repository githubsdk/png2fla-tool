package
{
	import flash.filesystem.File;

	public class FileData
	{
		protected var _nameIndex:int;
		protected var _fullPath:String;
		protected var _shiftX:Number;
		protected var _shiftY:Number;
		protected var _rootName:String;
		protected var _actionName:String;
		protected var _dirName:String;
		
		protected var _url:String;
		protected var _sName:String;
		protected var _nativePath:String;
		protected var _sRootName:String;
		
		public function FileData(file:File=null, root:File=null)
		{
			_nameIndex = -1;
			_shiftX = _shiftY = 0;
			if(file!=null && root!=null)
			{
				_url = file.url;
				_sName = file.name;
				_nativePath = file.nativePath;
				
				_fullPath = _url.replace("/"+file.name,"");
				_fullPath = _fullPath.replace(root.parent.url+"/","");
				
				_sRootName = root.name;
				
				if(file!=null && file.isDirectory==false)
				{
					var name:String = file.name.replace("."+file.extension, "");
					_nameIndex = int(name);
				}
				
				var folders:Array = fullPath.split("/");
				_actionName = folders[1];
				_dirName = folders[2];
				_rootName = folders[0];
			}
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
		
		public function get fileNameIndex():int
		{
			return _nameIndex;
		}

		public function get shiftX():Number
		{
			return _shiftX;
		}

		public function set shiftX(value:Number):void
		{
			_shiftX = value;
		}

		public function get shiftY():Number
		{
			return _shiftY;
		}

		public function set shiftY(value:Number):void
		{
			_shiftY = value;
		}

		public function get rootName():String
		{
			return _rootName;
		}

		public function get actionName():String
		{
			return _actionName;
		}

		public function get dirName():String
		{
			return _dirName;
		}

		public function get url():String
		{
			return _url;
		}

		public function get sName():String
		{
			return _sName;
		}

		public function get nativePath():String
		{
			return _nativePath;
		}

		public function get sRootName():String
		{
			return _sRootName;
		}


	}
}