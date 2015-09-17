package fileUtils
{
	import flash.filesystem.File;
	import flash.utils.Dictionary;

	public class FilesInFolder
	{
		protected var _filesInFolder:Dictionary;
		protected var _filesList:Vector.<FileData>;
		
		public function FilesInFolder()
		{
			_filesInFolder = new Dictionary();
			_filesList = new Vector.<FileData>;
		}
		
		public function init(children:Array, extensions:Array, root:File):void
		{
			if(_filesList!=null)
				_filesList.length = 0;
			findAllImages(children, extensions, _filesList, root);
		}
		
		public function addFolder(children:Array, extensions:Array, root:File):void
		{
			findAllImages(children, extensions, _filesList, root);
		}
		
		/**
		 *找出所有图像 
		 * @param children
		 * 
		 */		
		protected function findAllImages(children:Array,extensions:Array, saveList:Vector.<FileData>, root:File):void
		{
			if(children==null || children.length==0)
				return;
			var child:File = children.pop();
			if(child==null)
				return;
			if(child.isDirectory==true)
			{
				findAllImages(child.getDirectoryListing(),extensions, saveList,root);
			}
			else
			{
				if(extensions!=null &&extensions.indexOf( child.extension)>=0)
				{
					var fd:PngFileData = new PngFileData(child,root);
					saveList.push(fd);
					var folder_file_dic:Dictionary = _filesInFolder[root.name];
					if(folder_file_dic==null)
						_filesInFolder[root.name] = folder_file_dic = new Dictionary();
					var vec:Vector.<PngFileData> = folder_file_dic[fd.folderPath];
					if(vec==null)
						folder_file_dic[fd.folderPath] = vec = new Vector.<PngFileData>;
					vec.push(fd);
				}
			}
			findAllImages(children,extensions, saveList,root);
		}

		public function get filesList():Vector.<FileData>
		{
			return _filesList;
		}

		public function get filesInFolder():Dictionary
		{
			return _filesInFolder;
		}

	}
}