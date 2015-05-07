package
{
	import flash.filesystem.File;

	public class FileData
	{
		protected var _file:File;
		protected var _root:File;
		protected var _nameIndex:int;
		protected var _fullPath:String;
		protected var _shiftX:Number;
		protected var _shiftY:Number;
		
		public function FileData(file:File=null, root:File=null)
		{
			_file = file;
			_root = root;
			_nameIndex = -1;
			_shiftX = _shiftY = 0;
		}

		public function get file():File
		{
			return _file;
		}

		public function get root():File
		{
			return _root;
		}
		
		/**
		 *获得文件在根目录下的完整路径 
		 * @return 
		 * 
		 */		
		public function get fullPath():String
		{
			if(_fullPath==null)
			{
				_fullPath = _file.url.replace("/"+_file.name,"");
				_fullPath = _fullPath.replace(_root.parent.url+"/","");
			}
			return _fullPath;
		}
		
		public function get fileNameIndex():int
		{
			if(_nameIndex<0)
			{
				if(_file!=null && _file.isDirectory==false)
				{
					var name:String = _file.name.replace("."+_file.extension, "");
					_nameIndex = int(name);
				}
			}
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


	}
}