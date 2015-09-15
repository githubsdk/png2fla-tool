package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.PNGEncoderOptions;
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
	import flash.net.FileFilter;
	import flash.net.URLRequest;
	import flash.system.System;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import debugger.Debugger;
	
	import fileUtils.FilesInFolder;
	
	import fl.controls.Label;
	import fl.controls.TextArea;
	import fl.core.UIComponent;
	import fl.events.SliderEvent;
	
	import utils.FormularChecker;
	
	public class Png2Fla extends Sprite
	{
		protected var _panel:PanelSkin;
		protected var _workingPath:File;
		protected var _bCopying:Boolean;
		protected var _loader:Loader;
		protected var _allFoundFiles:Dictionary;
		protected var _allFoundFilesVec:Vector.<PngFileData>;
		/**
		 *路径做索引，保存每个根目录 import_config.txt 的内容
		 */		
		protected var _allImportConfigs:Dictionary;
		protected var _bmp:Bitmap;
		
		protected const CONFIG:String = "import_config.json";
		protected var _fileStream:FileStream;
		/**
		 * 工具自身数据保存位置
		 */		
		protected const TOOL_DATA_SAVE:File = File.applicationStorageDirectory;
		
		protected const TOOL_DATA_FILE:String = "png2fla_saved.json";
		
		protected const JSFL_FILE:String = "auto_export.jsfl";
		
		protected const TEMPLETE_FOLDER:String = "templete";
		
		protected var _bmd:BitmapData;
		
		protected const ADDONS:String="addons";
		protected var _addons:String;
		/**
		 *工具保存数据 
		 */		
		protected var _saveData:Object;
		
		protected var _filesInFolder:FilesInFolder;
		
		/**
		 *新的图像保存位置 
		 */		
		protected const IMAGE_SAVED_FOLDER:String = "copy";
		/**
		 *新的图像偏移量保存文件 
		 */		
		protected const IMAGE_POS_FILE:String = IMAGE_SAVED_FOLDER + "/auto_pulish_info.json";
		
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
			
			_saveData = readLastPath(TOOL_DATA_FILE);
			var last_path:String = _saveData.path;
			_addons = _saveData.addons;
			if(_addons==null || _addons.length==0)
			{
				_addons = ADDONS;
			}
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
					try{
						var cfg:Object = JSON.parse(content);
						return cfg;
					}catch(e:Error)
					{
						log(dir.nativePath+"目录下的配置文件解析出错");
					}
				
				}
				_fileStream.close();
			} 
			catch(error:Error) 
			{
				log(dir.nativePath+"目录下不存在配置文件："+CONFIG);
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
				case _panel.open_path:
				{
					_workingPath.openWithDefaultApplication();
					break;
				}
				case _panel.default_addons:
				{
					_addons = ADDONS;
					var addonfile:File = addonsFile;
					_addons = addonfile.url;
					_saveData.addons = _addons;
					saveContent(TOOL_DATA_SAVE.resolvePath(TOOL_DATA_FILE), JSON.stringify(_saveData));
					updateState();
					break;
				}
				case _panel.addons:
				{
					selectAddonsPath();
					break;
				}
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
					var source:File = addonsFile;
					copyConfig(source, CONFIG, _workingPath.getDirectoryListing(),updateState,_panel.override_copy.selected);
					break;
				}
			}
		}
		
		/**
		 *选择自定义的模板目录并保存 
		 * 
		 */		
		private function selectAddonsPath():void
		{
			var dir:File = File.applicationDirectory;
			dir.browseForOpen("选择模板文件:",[new FileFilter("文本文件","*.txt;*.json")]);
			dir.addEventListener(Event.SELECT, onAddonsPathSelected);
			dir.addEventListener(Event.CANCEL, onAddonsPathSelected);
		}

		protected function onAddonsPathSelected(event:Event):void
		{
			var dir:File = File.desktopDirectory;
			dir.removeEventListener(Event.SELECT, onWorkingPathSelected);
			dir.removeEventListener(Event.CANCEL, onWorkingPathSelected);
			var addonfile:File = event.target as File;
			
			switch(event.type)
			{
				case Event.CANCEL:
				{
					break;
				}
				case Event.SELECT:
				{
					_addons = addonfile.url;
					_saveData.addons = _addons;
					saveContent(TOOL_DATA_SAVE.resolvePath(TOOL_DATA_FILE), JSON.stringify(_saveData));
					break;
				}
			}
			updateState();
		}
		
		
		
		/**
		 *模板文件目录 
		 * @return 
		 * 
		 */		
		protected function get addonsFile():File
		{
			var addons:File;
			if(_addons==ADDONS)
			{
				addons = File.applicationDirectory.resolvePath(_addons+"/"+CONFIG);
			}else{
				addons = new File(_addons);
			}
			return addons;
		}
		
		protected function start():void
		{
			if(_workingPath==null)
				return;
			log("开始导图","00ff00");
			
			if(_loader==null)
			{
				_loader = new Loader();
			}

			_panel.start.enabled = false;
			
			time();
			var children:Array = _workingPath.getDirectoryListing();
			time(true, "找到所有文件夹");
			
			for(var key:String in _allFoundFiles)
			{
				delete _allFoundFiles[key];
			}
			_allFoundFiles = null;
			_allFoundFiles = new Dictionary();
			
			_allImportConfigs = new Dictionary();
			_allFoundFilesVec ||= new Vector.<PngFileData>();
			_allFoundFilesVec.length = 0;
			_bmp = new Bitmap();
			addChild(_bmp);
			
			//需要查找的文件类型
			var extentions:Array = new Array();
			if(_panel.png.selected==true)
				extentions.push(_panel.png.label);
			if(_panel.jpg.selected==true)
				extentions.push(_panel.jpg.label);

			//找出所有文件，添加必要信息保存成FileData列表
			time();
			_filesInFolder = null;
			_filesInFolder = new FilesInFolder();
			for each(var char:File in children)
			{
				if(char.isDirectory==false)
					continue;
				_filesInFolder.addFolder(char.getDirectoryListing(), extentions, char);
				_allImportConfigs[char.name] = readConfig(char);
			}
			
			var fc:FormularChecker = new FormularChecker();
			fc.execute(_filesInFolder.filesInFolder);
			return;
			time(true, "找出所有文件并保存");
			//排序文件，对于保存配置来说顺序很重要，因为要按照文件名从小到大的顺序添加到fla的时间轴
			for each(var folder_files_dic:Dictionary in _filesInFolder.filesInFolder)
			{
				for each(var vec:Vector.<PngFileData> in folder_files_dic)
				{
					vec = vec.sort(fileDataSort);
					_allFoundFilesVec = _allFoundFilesVec.concat(vec);
				}
			}
			time(true, "排序文件");
			log("本次处理文件数："+_allFoundFilesVec.length);
			extentions = null;
			//组个处理图像并保存
			executeAllImage(_allFoundFilesVec.reverse(), onAllImagesDone);
			time(true, "处理图像");
			return;
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
		
		protected function fileDataSort(a:PngFileData, b:PngFileData):int
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
			for (var char_folder:String in _filesInFolder.filesInRootFolder)
			{
				var json:Object = generateSaveContent(char_folder, getFullPath(_workingPath.resolvePath(char_folder).url) );
				if(json==null)
					continue;
				jsons.push(json);
			}
			content = JSON.stringify(jsons, null, 4);
			
			saveContent(file.resolvePath(IMAGE_POS_FILE), content);
			
			
			if(_panel.uiloader.contains(_bmp)==true)
			{
				_bmp.parent.removeChild(_bmp);
				_bmp.bitmapData.dispose();
			}
			_panel.uiloader.graphics.clear();
			
			copyAndRunTempleteFileAndJSFL();
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
		protected function getSavePath(path:String, url:Boolean=false, addName:String=null):String
		{
			var save_path:String = path;
			var replace:String = addName==null ? IMAGE_SAVED_FOLDER : IMAGE_SAVED_FOLDER+"/"+addName;
			if(url==false)
				save_path = save_path.replace(_workingPath.name, replace);
			else
				save_path = save_path.replace(_workingPath.name, replace);
			return save_path;
		}
		
		protected function executeJSFL():void
		{
			return;
			var file:File = File.applicationDirectory.resolvePath("templete/"+JSFL_FILE);
			file.openWithDefaultApplication();
		}
		
		/**
		 *组个处理一组图像文件
		 * @param images
		 * @param onDone
		 * 
		 */		
		protected function executeAllImage(images:Vector.<PngFileData>, onDone:Function):void
		{
			if(images==null || images.length==0)
			{
				if(onDone!=null)
					onDone.apply(null, null);
				return;
			}
			_panel.filecount.text = images.length.toString();
			var child:PngFileData = images.pop();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderHandler);
			_loader.load(new URLRequest(child.url));
			
			function onLoaderHandler(event:Event):void
			{
				_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderHandler);
				var bmp:Bitmap = _loader.content as Bitmap;
				
				var cfg:Object = _allImportConfigs[child.rootName];
				var shift_x:Number = getCfgValue("x",child.actionName, child.dirName, cfg);
				var shift_y:Number = getCfgValue("y",child.actionName, child.dirName, cfg);
				executeImageAndSave(bmp.bitmapData, child, shift_x, shift_y);
				_loader.unloadAndStop(true);
				_loader.unload();
				executeAllImage(images, onDone);
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
		protected function executeImageAndSave(source:BitmapData, fd:PngFileData, shiftX:Number, shiftY:Number):void
		{
			if(source==null)
				return;
			var rect:Rectangle = getBitmapDataValidRect(source);
			//这里虽然保存了偏移坐标，但只是一个预览用的
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
			var save_path:String = getSavePath(fd.nativePath, false, fd.rootName);
			var ba:ByteArray = new ByteArray();
			dest.encode(dest.rect,new PNGEncoderOptions(false),ba);
			saveContent(new File(save_path), ba, true);
			ba = null;
			
			//图像偏移量加入字符串
			var fullpath:String = fd.fullPath;
			
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
		
		/**
		 *生成指定根目录下的文件信息 
		 * @param rootName 根目录的名字
		 * @param charFullPath
		 * @return 
		 * 
		 */		
		protected function generateSaveContent(rootName:String, charFullPath:String):Object
		{
			var folder_files_dic:Dictionary = _filesInFolder.filesInFolder[charFullPath];
			var DQM:String = '"';
			var first_up:String = rootName;
			var json:Object = _allImportConfigs[rootName];
			if(json==null)
			{
				log(rootName+" config json is null! 可能是解析出错了，这个文件需要单独导出。!", "ff0000");
				return null;
			}
			//为防止修改原本内容，克隆出该对象
			json = ObjectUtils.clone(json);
			//将charfolder这个key替换成rootName以保证其唯一性
			var save_data:Object = json[rootName] = json["charfolder"];
			
			
			var ignor_folders:Array = save_data.ignor || [];
			
			var classname:String = rootName;
			var namemap:Object = save_data.namemap;
			if(namemap!=null)
			{
				for (var rp:String in namemap)
				{
					classname=classname.replace(rp,namemap[rp]);
				}
			}
			classname = firstLetterUpcase(classname);
			save_data.classname = classname;
			save_data.flaname = rootName;
			//生成新的对象，赋值给folders
			var files_info_obj:Object = save_data.folders;
			files_info_obj ||= new Object();
			var labels_cfg:Object = save_data.labels;
			
			
			for (var fullname:String in folder_files_dic)
			{
				var folders_names_list:Array = fullname.split("/");
				
				//方向
				var direction_name:String = folders_names_list[2];
				//文件夹名称，比如 walk far near 以及用技能id命名的
				var action_name:String = folders_names_list[1];
				//除根目录以外的文件夹全路径
				var keyname:String = action_name;
				if(direction_name!=null)
					keyname+="/"+direction_name;
				
				var name_reverse_list:Array = new Array();
				if(direction_name!=null)
					name_reverse_list.push(direction_name);
				if(action_name!=null)
					name_reverse_list.push(action_name);
				var files_cfg_obj:Object = files_info_obj[keyname];
				//这里不管是否有配置，都只需要加入新的list信息，不配置就代表不需要
				if(files_cfg_obj==null)
				{
					files_info_obj[keyname] = files_cfg_obj = new Object();
				}
				var list:Vector.<PngFileData> = folder_files_dic[fullname];
				var count:uint = list.length;
				var infos:Array = new Array();
				//文件间隔，有的文件夹不需要全部图片都导入，如果无值，则赋值1，以防死循环
				var file_interval:int = getCfgValue("fileinterval", action_name, direction_name, json);
				//每张图片的帧数
				var interval:int = getCfgValue("interval", action_name, direction_name, json);
				interval ||= 1;
				
				var fire_poin_file:String = getCfgValue("firepointfile",action_name, direction_name, json);
				var fire_poin_frame:int = 1;
				//写入list内容
				for (var file_index:int = 0; file_index < count; file_index+=file_interval)
				{
					var fd:PngFileData = list[file_index];
					if(fire_poin_file!=null && fire_poin_file.length>0)
					{
						if(fd.sName.indexOf(fire_poin_file)>=0)
							fire_poin_frame = file_index+1;
					}
					infos.push([fd.sName,getSavePath(fd.url,true, fd.rootName),fd.shiftX.toFixed(1),fd.shiftY.toFixed(1)]);
				}
				if(fire_poin_file!=null && fire_poin_frame==1)
					log( fullname + " 没有找到 firepointfile = "+fire_poin_file+"的文件，请检查 ", "ff0000");
				files_cfg_obj.list = infos;
				files_cfg_obj.interval = interval;
				
				//label 
				var prefix:String = "";
				var fire_point:String = "";
				
				var label:String = getCfgValue("label",action_name, direction_name, json);
				if(label!=null && label.length>0)
				{
					files_cfg_obj.start_label = label;
					files_cfg_obj.end_label = label;
				}else{
					var label_join_cfg:Object = getCfgValue("labeljoin",action_name, direction_name, json);
					var join:String = getCfgValue("join",action_name, direction_name, json);
					
					var name_rewerse_count:uint = name_reverse_list.length;
					for (var name_index:uint=0;name_index<name_rewerse_count;++name_index)
					{
						if(label_join_cfg!=null && label_join_cfg.nameindex==name_index && label_join_cfg.label!=null && label_join_cfg.label!="")
						{
							if(prefix.length>0)
								prefix += join;
							prefix +=  label_join_cfg.label;
							if(fire_point.length>0)
								fire_point += join;
							fire_point += label_join_cfg.label;
						}
						if(prefix.length>0)
							prefix += join;
						prefix += name_reverse_list[name_index];
						if(fire_point.length>0)
							fire_point += join;
						fire_point += name_reverse_list[name_index];
					}
					var start_suffix:String = getCfgValue("startsuffix",action_name, direction_name, json);
					var end_suffix:String = getCfgValue("endsuffix",action_name, direction_name, json);
					files_cfg_obj.start_label = prefix + join + start_suffix;
					files_cfg_obj.end_label = prefix + join + end_suffix;
					
					var fire_point_suffix:String = getCfgValue("firepointsuffix",action_name, direction_name, json);
					fire_point = fire_point+join + fire_point_suffix;
					
					if(fire_poin_file!=null && fire_poin_file.length>0)
						files_cfg_obj.insert = [{frame:fire_poin_frame,lable:fire_point}];
				}
				
				/*var fire_point_frame_cfg:Object = getCfgValue("firepointframe",action_name, direction_name, json);
				if(fire_point_frame_cfg!=null && fire_point_frame_cfg[direction_name])
				{
					var insert_info:Object = new Object();
					insert_info.label = fire_point;
					var frames_cfg:Array = fire_point_frame_cfg[direction_name].frames;
					var insert:Array = new Array();
					if(frames_cfg)
					{
						for each(var frameindex:uint in frames_cfg)
						{
							insert.push({frame:frameindex,lable:fire_point});
						}
					}
					if(insert.length>0)
						files_cfg_obj.insert = insert;
				}*/
			}
			
			delete save_data["labels"];
			delete save_data["x"];
			delete save_data["y"];
			delete save_data["startsuffix"];
			delete save_data["startsuffix"];
			delete save_data["endsuffix"];
			delete save_data["join"];
			delete save_data["namemap"];
			delete save_data["ignor"];
			delete save_data["interval"];
			delete save_data["firepointsuffix"];
			delete save_data["ignor"];
			delete save_data["charfolder"];
			delete json["charfolder"];
			
			var content:String = JSON.stringify(json);
			return json;
		}
		
		/**
		 *查询指定的属性，如果labels中没有配置特殊的，则使用全局配置  
		 * @param property
		 * @param actionName
		 * @param dirName
		 * @param globalCfg
		 * @return 
		 * 
		 */		
		protected function getCfgValue(property:String,actionName:String, dirName:String,globalCfg:Object):*
		{
			if(globalCfg!=null && globalCfg.charfolder!=null)
			{
				var labels_cfg:Object = globalCfg.charfolder.labels;
				if(labels_cfg!=null)
				{
					var action_cfg:Object = labels_cfg[actionName];
					if(action_cfg!=null && action_cfg.hasOwnProperty(property)==true)
						return action_cfg[property];
				}
				return globalCfg.charfolder[property];
			}
		
			return null;
		}
		
		//首字母大写
		protected function firstLetterUpcase(str:String):String 
		{ 
			return str.charAt(0).toUpperCase()+str.substr(1).toLowerCase(); 
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
			var dest:File = destPath==null ? child : child.resolvePath(destPath);
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
			_panel.addons_path.text = _saveData.addons==null ? _panel.addons_path.text : _saveData.addons;
			_panel.open_path.enabled = _workingPath!=null;
			CONFIG::RELEASE
			{
				_panel.jsfl.enabled = false;
			}
			CONFIG::DEBUG
			{
				_panel.jsfl.enabled = true;
			}
			
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
					_saveData.path = _workingPath.url;
					saveContent(TOOL_DATA_SAVE.resolvePath(TOOL_DATA_FILE), JSON.stringify(_saveData));
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
			/*var bmd:BitmapData = new Test()//new BitmapData(100,100,true,0x00ffffff);
			bmd.fillRect( new Rectangle(20,20,60,60), 0xffffff00);
			var bmp:Bitmap = new Bitmap(bmd, PixelSnapping.AUTO, true);
			addChild(bmp);
			var rect:Rectangle = getBitmapDataValidRect(bmd);
			graphics.beginFill(0xff00ff);
			graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			graphics.endFill();*/
		}
		
		//"assets/icon.png"
		protected function openWithDefaultApplication(fileName:String="assets/icon.png"):void
		{
			var file:File = File.applicationDirectory.resolvePath(fileName);
			file.openWithDefaultApplication();
		}
		
		private var _latest:int=0;
		protected function time(show:Boolean=false, ...args):void
		{
			if(show==true)
			{
				log(args + " use time = " + (getTimer()-_latest) + " ms");
				log("mem use:","00ff00");
				var k:uint = 1024;
				log((System.privateMemory/k) + "kb privateMemory");
				log((System.totalMemory/k) + "kb totalMemory");
				log((System.totalMemoryNumber/k) + "kb totalMemoryNumber");
				_latest = getTimer();
			}else{
				_latest = getTimer();
			}
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
		
		/**
		 *读取上次的工作目录 
		 * @param fileName
		 * @return 
		 * 
		 */		
		private function readLastPath(fileName:String):Object
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
				return json;
			}
			
			return new Object();
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