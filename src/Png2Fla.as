package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.PNGEncoderOptions;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import debugger.Debugger;
	
	import fl.controls.Label;
	import fl.controls.TextArea;
	import fl.core.UIComponent;
	import fl.events.SliderEvent;
	
	public class Png2Fla extends Sprite
	{
		protected var _panel:PanelSkin;
		protected var _workingPath:File;
		protected var _bCopying:Boolean;
		protected var _loader:Loader;
		protected var _allFoundFiles:Dictionary;
		protected var _allFoundFilesVec:Vector.<FileData>;
		/**
		 *输出文件的信息 
		 */		
		protected var _outPutFilsInfo:Dictionary;
		/**
		 *每个子文件夹下的文件 
		 */		
		protected var _filesInEveryFolder:Dictionary;
		/**
		 *每个角色文件夹下的文件列表 
		 */		
		protected var _filesInCharFolder:Dictionary;
		protected var _allCopyConfigs:Dictionary;
		protected var _bmp:Bitmap;
		
		protected const CONFIG:String = "import_config.txt";
		protected var _fileStream:FileStream;
		/**
		 * 工具自身数据保存位置
		 */		
		protected const TOOL_DATA_SAVE:File = File.applicationStorageDirectory;
		
		protected const TOOL_DATA_FILE:String = "png2fla_saved.txt";
		
		protected const JSFL_FILE:String = "auto_export.jsfl";
		
		protected const TEMPLETE_FOLDER:String = "templete";
		
		protected var _bmd:BitmapData;
		
		/**
		 *新的图像保存位置 
		 */		
		protected const IMAGE_SAVED_FOLDER:String = "copy";
		/**
		 *新的图像偏移量保存文件 
		 */		
		protected const IMAGE_POS_FILE:String = IMAGE_SAVED_FOLDER + "/auto_pulish_info.txt";
		
		public function Png2Fla()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.color = 0x0099ff;

			_panel = new PanelSkin();
			addChild(_panel);
			_panel.addEventListener(MouseEvent.CLICK,  onMouseClick);
			_panel.copy_progress.minimum = 0;
			_panel.copy_progress.maximum = 1;
			
			var cfg:String = '{"x":"10","y":"200"}';
			var o:Object = JSON.parse(cfg);
			
			var last_path:String = readLastPath(TOOL_DATA_FILE);
			if(last_path!=null)
			{
				_workingPath = new File(last_path);
				log("已设置工作目录！");
			}
			
			setAllTextSize(_panel, _panel.font_size.value);
			_panel.font_size.addEventListener(SliderEvent.CHANGE, onSliderHandler);
			updateState();
		}
		
		protected function readConfig(dir:File):Object
		{
			try
			{
				_fileStream.open(dir.resolvePath(CONFIG), FileMode.READ);
				if(_fileStream.bytesAvailable>0)
				{
					var content:String = _fileStream.readUTFBytes(_fileStream.bytesAvailable);
					var cfg:Object = JSON.parse(content);
					return cfg;
				}
				_fileStream.close();
			} 
			catch(error:Error) 
			{
				log(dir+"目录下不存在配置文件："+CONFIG);
			}
			
			return null;
		}
		
		protected function onSliderHandler(event:SliderEvent):void
		{
			Debugger.log(_panel.font_size.minimum, _panel.font_size.maximum, _panel.font_size.value);
			setAllTextSize(_panel, _panel.font_size.value);
		}
		
		protected function onMouseClick(event:MouseEvent):void
		{
			switch(event.target)
			{
				case _panel.jsfl:
				{
					copyAndRunTempleteFileAndJSFL();
					break;
				}
				case _panel.start:
				{
					start();
					break;
				}
				case _panel.select_path:
				{
					chooseWorkingPath();
					break;
				}
				case _panel.copy_config:
				{
					var source:File = File.applicationDirectory.resolvePath("templete/"+CONFIG);
					copyConfig(source, CONFIG, _workingPath.getDirectoryListing(),updateState,_panel.override_copy.selected);
					break;
				}
			}
		}
		
		protected function start():void
		{
			if(_workingPath==null)
				return;
			log("========开始导图","00ff00");
			
			if(_loader==null)
			{
				_loader = new Loader();
				//_panel.uiloader.source = _loader;
			}

			_panel.start.enabled = false;
			var children:Array = _workingPath.getDirectoryListing();
			
			for(var key:String in _allFoundFiles)
			{
				delete _allFoundFiles[key];
			}
			_allFoundFiles = null;
			_allFoundFiles = new Dictionary();
			for (key in _outPutFilsInfo)
			{
				delete _outPutFilsInfo[key];
			}
			_outPutFilsInfo = null;
			_outPutFilsInfo = new Dictionary();
			for (key in _filesInEveryFolder)
			{
				delete _filesInEveryFolder[key];
			}
			_filesInEveryFolder = null;
			_filesInEveryFolder = new Dictionary();
			
			for (key in _filesInCharFolder)
			{
				delete _filesInCharFolder[key];
			}
			_filesInCharFolder = null;
			_filesInCharFolder = new Dictionary();
			
			_allCopyConfigs = new Dictionary();
			_allFoundFilesVec ||= new Vector.<FileData>();
			_allFoundFilesVec.length = 0;
			_bmp = new Bitmap();
			addChild(_bmp);
			
			var extentions:Array = new Array();
			if(_panel.png.selected==true)
				extentions.push(_panel.png.label);
			if(_panel.jpg.selected==true)
				extentions.push(_panel.jpg.label);

			//找出所有文件，添加必要信息保存成FileData列表
			var allfiles:Vector.<FileData> = new Vector.<FileData>;
			for each(var char:File in children)
			{
				if(char.isDirectory==false)
					continue;
				fildAllImages(char.getDirectoryListing(), extentions,allfiles, char);
				_allCopyConfigs[char.name] = readConfig(char);
			}
			//排序文件
			for each(var folder_files_dic:Dictionary in _filesInEveryFolder)
			{
				for each(var vec:Vector.<FileData> in folder_files_dic)
				{
					vec = vec.sort(fileDataSort);
					_allFoundFilesVec = _allFoundFilesVec.concat(vec);
				}
			}
			log("本次处理文件数："+_allFoundFilesVec.length);
			extentions = null;
			executeAllImage(_allFoundFilesVec.reverse(), onAllImagesDone);
			return;
			/*for each(var child:File in children)
			{
				if(child.isDirectory==false)
					continue;
				var cfg:File = child.resolvePath(CONFIG);
				if(cfg.exists==true)
				{
					Debugger.log(child.url);
				}else{
					log("该目录下不存在必要的配置文件，请检查："+child.nativePath,"ff0000");
				}
			}*/
		}
		
		/**
		 *获得文件在根目录下的完整路径  
		 * @param path
		 * @return 
		 * 
		 */		
		public function getFullPath(url:String):String
		{
			var fullpath:String = "";
			if(url!=null)
			{
				fullpath = url.replace(_workingPath.url+"/","");
			}
			return fullpath;
		}
		
		protected function fileDataSort(a:FileData, b:FileData):int
		{
			if(a.fileNameIndex>b.fileNameIndex)
				return 1;
			return -1;
		}
		
		protected function onAllImagesDone(...args):void
		{
			updateState();
			var file:File = _workingPath.parent;
			var content:String = "";
			var jsons:Array = new Array();
			for (var char_folder:String in _filesInCharFolder)
			{
				var json:Object = generateSaveContent(char_folder, getFullPath(_workingPath.resolvePath(char_folder).url) );
				jsons.push(json);
			}
			content = JSON.stringify(jsons);
			saveContent(file.resolvePath(IMAGE_POS_FILE), content);
			
			
			if(_panel.uiloader.contains(_bmp)==true)
			{
				_bmp.parent.removeChild(_bmp);
				_bmp.bitmapData.dispose();
			}
			
			copyAndRunTempleteFileAndJSFL();
			return;
			executeJSFL();
			
			return;
		}
		
		protected function copyAndRunTempleteFileAndJSFL():void
		{
			var file:File = File.applicationDirectory.resolvePath("templete");
			var save_path:String = getSavePath(_workingPath.nativePath);
			var target:File = new File(save_path);
			copyConfig(file, TEMPLETE_FOLDER,[target], callback,true);
			function callback():void
			{
				var jsfl:File = new File(save_path);
				jsfl = jsfl.resolvePath(TEMPLETE_FOLDER);
				jsfl = jsfl.resolvePath(JSFL_FILE);
				jsfl.openWithDefaultApplication();
			}
		}
		
		/**
		 *把路径转化为图片副本保存的路径 
		 * @param path
		 * @return 
		 * 
		 */		
		protected function getSavePath(path:String, url:Boolean=false):String
		{
			var save_path:String = path;
			if(url==false)
				save_path = save_path.replace(_workingPath.name, IMAGE_SAVED_FOLDER);
			else
				save_path = save_path.replace(_workingPath.name, IMAGE_SAVED_FOLDER);
			return save_path;
		}
		
		protected function executeJSFL():void
		{
			return;
			var file:File = File.applicationDirectory.resolvePath("templete/"+JSFL_FILE);
			file.openWithDefaultApplication();
		}
		
		protected function executeAllImage(images:Vector.<FileData>, onDone:Function):void
		{
			if(images==null || images.length==0)
			{
				if(onDone!=null)
					onDone.apply(null, null);
				return;
			}
			var child:FileData = images.pop();
			var file:File = child.file;
			Debugger.log(file.extension, file.name);
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderHandler);
			_loader.load(new URLRequest(file.url));
			
			function onLoaderHandler(event:Event):void
			{
				_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderHandler);
				var bmp:Bitmap = _loader.content as Bitmap;
				
				var cfg:Object = _allCopyConfigs[child.root.name];
				var shift_x:Number = 0;
				var shift_y:Number = 0;
				if(cfg!=null)
				{
					shift_x = cfg.x;
					shift_y = cfg.y;
				}
				executeImageAndSave(bmp.bitmapData, child, shift_x, shift_y);
				//addChild(_bmp);
				//_panel.uiloader.source = _bmp;
				_loader.unloadAndStop(true);
				_loader.unload();
				executeAllImage(images, onDone);
			//	log(file.nativePath+" 完成。");
			}
		}
		
		/**
		 *剔除图像无效透明像素并保存 
		 * @param source
		 * @param image
		 * @param shiftX
		 * @param shiftY
		 * 
		 */		
		protected function executeImageAndSave(source:BitmapData, fd:FileData, shiftX:Number, shiftY:Number):void
		{
			if(source==null)
				return;
			var image:File = fd.file;
			var rect:Rectangle = getBitmapDataValidRect(source);
			fd.shiftX =  rect.x-shiftX;
			fd.shiftY =  rect.y-shiftY;
			var dest:BitmapData = new BitmapData(rect.width, rect.height);
			dest.copyPixels(source, rect, new Point(0,0));
			if(_bmp.bitmapData!=null)
			{
				_bmp.bitmapData.dispose();
			}
			_bmp.bitmapData = dest;
			_bmp.x = fd.shiftX;
			_bmp.y = fd.shiftY;

			//保存处理过的图像
			var save_path:String = getSavePath(image.nativePath);
			var ba:ByteArray = new ByteArray();
			dest.encode(dest.rect,new PNGEncoderOptions(false),ba);
			saveContent(new File(save_path), ba, true);
			ba = null;
			
			//图像偏移量加入字符串
			var fullpath:String = fd.fullPath;
			var fileinfo:Array = _outPutFilsInfo[fullpath];
			if(fileinfo==null)
			{
				_outPutFilsInfo[fullpath] = fileinfo = new Array();
			}
			/*
				fullpath[:]name[*]copyuil[*]x,y[?]name[*]copyuil[*]x,y[?]name[*]copyuil|x,y
			fullpath[:]name[*]copyuil[*]x,y[?]name[*]copyuil[*]x,y[?]name[*]copyuil|x,y
			*/
			fileinfo.push(image.name+"[*]"+getSavePath(image.url,true)+"[*]"+fd.shiftX.toFixed(1)+","+fd.shiftY.toFixed(1));
			
			//预览
			if(_panel.uiloader.contains(_bmp)==true)
			{
				_bmp.parent.removeChild(_bmp);
			}
			_panel.uiloader.addChild(_bmp);
			_panel.uiloader.graphics.clear();
			_panel.uiloader.graphics.beginFill(0, 0.2);
			_panel.uiloader.graphics.drawRect(fd.shiftX, fd.shiftY, rect.width, rect.height);
			_panel.uiloader.graphics.endFill();
		}
		
		protected function generateSaveContent(charName:String, charFullPath:String):Object
		{
			var folder_files_dic:Dictionary = _filesInEveryFolder[charFullPath];
			var DQM:String = '"';
			var first_up:String = charName;
			var json:Object = _allCopyConfigs[charName];
			json = ObjectUtils.clone(json);
			delete json["x"];
			delete json["y"];
			var save_data:Object = json[charName] = json["charfolder"];
			delete json["charfolder"];
			
			var ignor_folders:Array = save_data.ignor || [];
			delete json["ignor"];
			
			var classname:String = firstLetterUpcase(charName);
			save_data.classname = classname;
			save_data.flaname = charName;
			//生成新的对象，赋值给folders
			var files_info_obj:Object = save_data.folders;
			files_info_obj ||= new Object();
			for (var fullname:String in folder_files_dic)
			{
				//文件夹key值
				var keyname:String = fullname.replace(charName+"/","");
				var folder_names_list:Array = keyname.split("/");
				var first_folder:String = folder_names_list[0];
				//忽略文件夹跳过
				if(ignor_folders.indexOf(first_folder)>=0)
					continue;
				var files_cfg_obj:Object = files_info_obj[keyname];
				//这里不管是否有配置，都只需要加入新的list信息，不配置就代表不需要
				if(files_cfg_obj==null)
				{
					files_info_obj[keyname] = files_cfg_obj = new Object();
				}
				var list:Vector.<FileData> = folder_files_dic[fullname];
				var count:uint = list.length;
				var infos:Array = new Array();
				//文件间隔，有的文件夹不需要全部图片都导入，如果无值，则赋值1，以防死循环
				var interval:int = files_cfg_obj.interval;
				if(interval==0)
				{
					interval = save_data.interval || 1;
				}
				//写入list内容
				for (var i:int = 0; i < count; i+=interval)
				{
					var fd:FileData = list[i];
					infos.push([fd.file.name,getSavePath(fd.file.url,true),fd.shiftX.toFixed(1),fd.shiftY.toFixed(1)]);
				}
				files_cfg_obj.list = infos;
				files_cfg_obj.interval = interval;
				delete save_data["interva"];
				
				//label 
				var start_label:String = "start";
				var reverse_folder_names:Array = folder_names_list.reverse();
				var prefix:String = reverse_folder_names.join(save_data.join);
				if(save_data.labels!=null && save_data.labels[first_folder]!=null)
				{
					//忽略第一个文件夹
					if(save_data.labels[first_folder].ignor>0)
					{
						reverse_folder_names.pop();
						prefix = reverse_folder_names.join(save_data.join);
					}
					start_label = prefix+save_data.labels[first_folder].start_suffix;
				}
				var end_label:String = "end";
				if(save_data.labels!=null && save_data.labels[first_folder]!=null)
				{
					end_label = prefix+save_data.labels[first_folder].end_suffix;
				}
				files_cfg_obj.start_label = start_label;
				files_cfg_obj.end_label = end_label;
				
				var insert_labels_array:Array = files_cfg_obj.insert;
				if(insert_labels_array!=null && save_data.labels[first_folder]!=null)
				{
					var insert_labels_count:uint = insert_labels_array.length;
					var common_insert:Array = save_data.labels[first_folder].insert;
					for(var insert_count:int = 0; insert_count<insert_labels_count;++insert_count)
					{
						var insert_info:Object = insert_labels_array[insert_count];
						if(insert_info.frame>0)
						{
							if(common_insert!=null && common_insert[insert_count]!=null)
								insert_info.label = prefix+common_insert[insert_count].end_suffix
						}
					}
				}
			}
			var content:String = JSON.stringify(json);
			return json;
		}
		
		public static function firstLetterUpcase(str:String):String 
		{ 
			return str.charAt(0).toUpperCase()+str.substr(1).toLowerCase(); 
		}
		
		/**
		 *找出所有图像 
		 * @param children
		 * 
		 */		
		protected function fildAllImages(children:Array,extensions:Array, saveList:Vector.<FileData>, root:File):void
		{
			if(children==null || children.length==0)
				return;
			var child:File = children.pop();
			if(child==null)
				return;
			if(child.isDirectory==true)
			{
				Debugger.log(child.extension, child.name);
				fildAllImages(child.getDirectoryListing(),extensions, saveList,root);
			}
			else
			{
				if(extensions!=null &&extensions.indexOf( child.extension)>=0)
				{
					var fd:FileData = new FileData(child,root);
					saveList.push(fd);
					var folder_file_dic:Dictionary = _filesInEveryFolder[root.name];
					if(folder_file_dic==null)
						_filesInEveryFolder[root.name] = folder_file_dic = new Dictionary();
					var vec:Vector.<FileData> = folder_file_dic[fd.fullPath];
					if(vec==null)
						folder_file_dic[fd.fullPath] = vec = new Vector.<FileData>;
					vec.push(fd);
					
					var list:Dictionary = _filesInCharFolder[fd.root.name];
					if(list==null)
						_filesInCharFolder[fd.root.name]=list = new Dictionary();
					list[fd.fullPath] = vec;
				}
			}
			fildAllImages(children,extensions, saveList,root);
		}
		
		protected function executeAllFolders(children:Array):void
		{
			if(children==null || children.length==0)
				return;
			var child:File = children.pop();
			if(child.isDirectory==false)
				return;
			var cfg:File = child.resolvePath(CONFIG);
			if(cfg.exists==true)
			{
				Debugger.log(child.url);
			}else{
				log("该目录下不存在必要的配置文件，请检查："+child.nativePath,"ff0000");
			}
		}
		
		/**
		 *拷贝sorce指定的文件到childrens包含的所有目录 
		 * @param source
		 * @param destPath
		 * @param childrens
		 * 
		 */		
		protected function copyConfig(source:File, destPath:String, children:Array, callBack:Function=null,bOverride:Boolean=false):void
		{
			if(children==null || children.length==0)
			{
				if(callBack!=null)
					callBack();
				return;
			}
			var child:File = children.pop();
			if(child==null)
				return;
			var dest:File = child.resolvePath(destPath);
			if(child.isDirectory==true)
			{
				Debugger.log(child.nativePath);
				source.copyToAsync(dest, bOverride);
				source.addEventListener(Event.COMPLETE, onCopyHandler);
				source.addEventListener(IOErrorEvent.IO_ERROR, onCopyHandler);
			}else{
				Debugger.log(child.name);
				copyConfig(source, destPath, children,callBack,bOverride);
			}
			
			function onCopyHandler(e:Event):void
			{
				source.removeEventListener(Event.COMPLETE, onCopyHandler);
				source.removeEventListener(IOErrorEvent.IO_ERROR, onCopyHandler);
				copyConfig(source, destPath, children,callBack,bOverride);
				switch(e.type)
				{
					case IOErrorEvent.IO_ERROR:
					{
						log("该目录下配置文件可能已经存在:"+child.nativePath+"。或者请关闭编辑中的模板配置文件。","ff0000");
						break;
					}
					case Event.COMPLETE:
					{
						log("文件复制完成:"+child.nativePath+"");
						break;
					}
				}
			}
		}
		
		protected function updateState():void
		{
			_panel.copy_config.enabled = _workingPath!=null ;//_panel.copy_progress.value==_panel.copy_progress.maximum 
			_panel.override_copy.enabled = _workingPath!=null;
			_panel.start.enabled = _workingPath!=null && (_allFoundFilesVec==null || _allFoundFilesVec.length==0);
			_panel.current_path.text = _workingPath==null ? "请选择工作目录":_workingPath.nativePath;
		}
	
		/**
		 *打开工作目录 
		 * 
		 */		
		protected function chooseWorkingPath():void
		{
			var dir:File = File.applicationDirectory;
			dir.browseForDirectory("选择工作目录");
			dir.addEventListener(Event.SELECT, onWorkingPathSelected);
			dir.addEventListener(Event.CANCEL, onWorkingPathSelected);
		}
		
		/**
		 *选中工作目录 
		 * @param event
		 * 
		 */		
		protected function onWorkingPathSelected(event:Event):void
		{
			var dir:File = File.desktopDirectory;
			dir.removeEventListener(Event.SELECT, onWorkingPathSelected);
			dir.removeEventListener(Event.CANCEL, onWorkingPathSelected);
			_workingPath = event.target as File;
			
			switch(event.type)
			{
				case Event.CANCEL:
				{
					_workingPath = null;
					break;
				}
				case Event.SELECT:
				{
					saveContent(TOOL_DATA_SAVE.resolvePath(TOOL_DATA_FILE), '{"path":"'+_workingPath.url+'"}');
					break;
				}
			}
			updateState();
			Debugger.log(_workingPath==null ? "unselected" : _workingPath.nativePath);
		}
		
		protected function getBitmapDataValidRect(bmd:BitmapData):Rectangle
		{
			var rect:Rectangle;
			if(bmd!=null)
			{
				rect = bmd.getColorBoundsRect(0xff000000,0x00000000, false);
			}else
			{
				rect = new Rectangle();
			}
			return rect;
		}
		
		protected function testBitmapData():void
		{
			var bmd:BitmapData = new Test()//new BitmapData(100,100,true,0x00ffffff);
			bmd.fillRect( new Rectangle(20,20,60,60), 0xffffff00);
			var bmp:Bitmap = new Bitmap(bmd, PixelSnapping.AUTO, true);
			addChild(bmp);
			var rect:Rectangle = getBitmapDataValidRect(bmd);
			graphics.beginFill(0xff00ff);
			graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			graphics.endFill();
		}
		
		//"assets/icon.png"
		protected function openWithDefaultApplication(fileName:String="assets/icon.png"):void
		{
			var file:File = File.applicationDirectory.resolvePath(fileName);
			file.openWithDefaultApplication();
		}
		
		protected function log(content:String, color:String=null):void
		{
			content = "["+ (new Date()).toTimeString() +"] "+content;
			if(color!=null)
			{
				content = "<font color='#"+color+"'>"+ content+"</font>"
			}
			_panel.log.htmlText+=content;
			_panel.log.verticalScrollPosition = _panel.log.maxVerticalScrollPosition;
			//_panel.log.appendText(content);
		}
		
		/**
		 *保存上次工作目录 
		 * @param fileName
		 * @param content
		 * 
		 */		
		private function saveContent(file:File,content:Object,bytes:Boolean=false):void
		{
			if(file==null || content==null)
				return;
			_fileStream ||= new FileStream();
			_fileStream.open(file, FileMode.WRITE);
			if(bytes==true)
				_fileStream.writeBytes(ByteArray(content));
			else
				_fileStream.writeUTFBytes(String(content));
			_fileStream.close();
		}
		
		private function readLastPath(fileName:String):String
		{
			var path:String = null;
			_fileStream = new FileStream();
			try
			{
				_fileStream.open(TOOL_DATA_SAVE.resolvePath(fileName), FileMode.READ);
				if(_fileStream.bytesAvailable>0)
				{
					path = _fileStream.readUTFBytes(_fileStream.bytesAvailable);
					
				}
				_fileStream.close();
			} 
			catch(error:Error) 
			{
				
			}
			if(path!=null)
			{
				var json:Object = JSON.parse(path);
				path = json.path;
			}
			
			return path;
		}
		
		
		private function setAllTextSize(container:DisplayObjectContainer, value:uint):void
		{
			if(container==null)
				return;
			var count:uint = container.numChildren;
			var index:uint = 0;
			while(index<count)
			{
				var child:DisplayObject = container.getChildAt(index);
				if(child is TextArea || child is Label)
				{
					UIComponent(child).setStyle("textFormat", new TextFormat("_sans", value));
				}else if(child is DisplayObjectContainer)
				{
					setAllTextSize(child as DisplayObjectContainer, value);
				}
				index++;
			}
		}
		
	}
}