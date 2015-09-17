package
{
	import flash.filesystem.File;
	
	import fileUtils.FileData;

	public class PngFileData extends FileData
	{
		protected var _nameIndex:int;
		protected var _shiftX:Number;
		protected var _shiftY:Number;
		protected var _actionName:String;
		protected var _dirName:String;
		
		public function PngFileData(file:File=null, root:File=null)
		{
			super(file, root);
			_nameIndex = -1;
			_shiftX = _shiftY = 0;
			if(file!=null && root!=null)
			{
				
				if(file!=null && file.isDirectory==false)
				{
					var name:String = file.name.replace("."+file.extension, "");
					_nameIndex = int(name);
				}
				
				var folders:Array = folderPath.split("/");
				_actionName = folders[0];
				_dirName = folders[1];
			}
		}
		
		/**
		 *路径名 
		 * @return 
		 * 
		 */		
		public function get dirName():String
		{
			return _dirName;
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
		
		public function get actionName():String
		{
			return _actionName;
		}

		


	}
}