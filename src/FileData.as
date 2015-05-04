package
{
	import flash.filesystem.File;

	public class FileData
	{
		protected var _file:File;
		protected var _root:File;
		public function FileData(file:File=null, root:File=null)
		{
			_file = file;
			_root = root;
		}

		public function get file():File
		{
			return _file;
		}

		public function get root():File
		{
			return _root;
		}


	}
}