package
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
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
		protected var _executeCount:uint;
		protected var _allFoundFiles:Dictionary;
		protected var _allFoundFilesVec:Vector.<FileData>;
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
		
		protected var _bmd:BitmapData;
		protected var _imagePos:String;
		
		/**
		 *新的图像保存位置 
		 */		
		protected const IMAGE_SAVED_FOLDER:String = "copy";
		/**
		 *新的图像偏移量保存文件 
		 */		
		protected const IMAGE_POS_FILE:String = IMAGE_SAVED_FOLDER + "/image_pos.txt";
		
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
				var content:String = _fileStream.readUTF();
				var cfg:Object = JSON.parse(content);
				return cfg;
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
					copyConfig(source, CONFIG, _workingPath.getDirectoryListing());
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
			_imagePos = null;
			_imagePos = "";

			_panel.start.enabled = false;
			var children:Array = _workingPath.getDirectoryListing();
			
			_executeCount = 0;
			for(var key:String in _allFoundFiles)
			{
				delete _allFoundFiles[key];
			}
			_allFoundFiles = null;
			_allFoundFiles = new Dictionary();
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
			//TODO:读入所有配置文件 children
			for each(var child:File in children)
			{
				if(child.isDirectory==false)
					continue;
				var vec:Vector.<FileData> = new Vector.<FileData>;
				fildAllImages(child.getDirectoryListing(),extentions,vec, child);
				if(vec.length>0)
				{
					_allFoundFiles[child.url] = vec;
					_allFoundFilesVec = _allFoundFilesVec.concat(vec);
					_allCopyConfigs[child.url] = readConfig(child);
				}
				_executeCount += vec.length;
			}
			
			log("本次处理文件数："+_executeCount);
			extentions = null;
			executeAllImage(_allFoundFilesVec, onAllImagesDone);
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
		
		protected function onAllImagesDone(...args):void
		{
			updateState();
			var file:File = _workingPath.parent;
			saveContent(file.resolvePath(IMAGE_POS_FILE), _imagePos);
			//System.setClipboard(_imagePos);
			Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, _imagePos);
			_imagePos = null;
			if(_panel.uiloader.contains(_bmp)==true)
			{
				_bmp.parent.removeChild(_bmp);
				_bmp.bitmapData.dispose();
			}
			return;
			executeJSFL();
			
			return;
			//以下将jsfl拷贝到工作目录的代码不需要了
			file = File.applicationDirectory.resolvePath("templete/"+JSFL_FILE);
			var save_path:String = _workingPath.nativePath;
			save_path = save_path.replace(_workingPath.name, IMAGE_SAVED_FOLDER);
			var jsfl:File = new File(save_path);
			copyConfig(file, JSFL_FILE,[ jsfl], callback);
			function callback():void
			{
				
				jsfl = jsfl.resolvePath(JSFL_FILE);
				jsfl.openWithDefaultApplication();
			}
		}
		
		protected function executeJSFL():void
		{
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
				
				var cfg:Object = _allCopyConfigs[child.root.url];
				var shift_x:Number = 0;
				var shift_y:Number = 0;
				if(cfg!=null)
				{
					shift_x = cfg.x;
					shift_y = cfg.y;
				}
				executeImageAndSave(bmp.bitmapData, file, shift_x, shift_y);
				//addChild(_bmp);
				//_panel.uiloader.source = _bmp;
				_loader.unloadAndStop(true);
				_loader.unload();
				executeAllImage(images, onDone);
				log(file.name+" 完成。");
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
		protected function executeImageAndSave(source:BitmapData, image:File, shiftX:Number, shiftY:Number):void
		{
			if(source==null)
				return;
			var rect:Rectangle = getBitmapDataValidRect(source);
			shiftX = shiftX - rect.x;
			shiftY = shiftY - rect.y;
			if(shiftX<0)
				Debugger.log(shiftX);
			var dest:BitmapData = new BitmapData(rect.width, rect.height);
			dest.copyPixels(source, rect, new Point(0,0));
			if(_bmp.bitmapData!=null)
			{
				_bmp.bitmapData.dispose();
			}
			_bmp.bitmapData = dest;
			_bmp.x = -shiftX; 
			_bmp.y = -shiftY;

			//保存处理过的图像
			var save_path:String = image.nativePath;
			save_path = save_path.replace(_workingPath.name, IMAGE_SAVED_FOLDER);
			var ba:ByteArray = new ByteArray();
			dest.encode(dest.rect,new PNGEncoderOptions(false),ba);
			saveContent(new File(save_path), ba, true);
			ba = null;
			
			//图像偏移量加入字符串
			_imagePos = _imagePos+image.url+":"+shiftX.toFixed(1)+"|"+shiftY.toFixed(1)+";\n";
			
			//预览
			if(_panel.uiloader.contains(_bmp)==true)
			{
				_bmp.parent.removeChild(_bmp);
			}
			_panel.uiloader.addChild(_bmp);
			_panel.uiloader.graphics.clear();
			_panel.uiloader.graphics.beginFill(0, 0.2);
			_panel.uiloader.graphics.drawRect(-shiftX, -shiftY, rect.width, rect.height);
			_panel.uiloader.graphics.endFill();
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
					_executeCount++;
					saveList.push(new FileData(child,root));
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
		protected function copyConfig(source:File, destPath:String, children:Array, callBack:Function=null):void
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
				source.copyToAsync(dest, _panel.override_copy.selected);
				source.addEventListener(Event.COMPLETE, onCopyHandler);
				source.addEventListener(IOErrorEvent.IO_ERROR, onCopyHandler);
			}else{
				Debugger.log(child.name);
				copyConfig(source, destPath, children,callBack);
			}
			
			function onCopyHandler(e:Event):void
			{
				source.removeEventListener(Event.COMPLETE, onCopyHandler);
				source.removeEventListener(IOErrorEvent.IO_ERROR, onCopyHandler);
				copyConfig(source, destPath, children,callBack);
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
			trace(rect, bmp.getRect(this));
			graphics.beginFill(0xff00ff);
			graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			graphics.endFill();
		}
		
		//"assets/icon.png"
		protected function openWithDefaultApplication(fileName:String="assets/icon.png"):void
		{
			var file:File = File.applicationDirectory.resolvePath(fileName);
			trace(file.url);
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