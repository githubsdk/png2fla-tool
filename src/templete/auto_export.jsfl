/************************************************
合并文件里的指定帧到muban.fla
并且将muban中的内容导出png图片到指定文件夹
*************************************************/

//资源停到的帧 
var _stopFrame = 3;
//文件名
var NAME = "templete";
//模板名字
var suffix = ".fla";
var templeteName = NAME+suffix;
//模板文件完整路径
var templeteFullPath = null;
//资源需要的帧
var iFrame = 0;
//资源需要的元件名字
var elemName = null;
//源文件
var sourceDom = null;
//v当前路径
var currentPath = null;
//当前文件名，不带后缀
var currentFileName = null;
//导出文件夹
var destPath = null;
//记录导出的文件名
var allPNG = "";
/*
参数 格式 
name1=h-name2=v-name3=vh
name 要修改的元件名字
=之后为自选参数
v=垂直居中
h=水平居中
*/
var params = "";

var SCRIPT_PATH = currentScriptPath();

var INFO_CONTENT = FLfile.read(SCRIPT_PATH+"auto_pulish_info.txt");

var DOM ;

var LIB; 

var PUBLISH_INFO;

init();

function init()
{
	fl.outputPanel.clear();

	openTempleteFLA();
	
	parsePublishInfo();
	
	DOM = fl.getDocumentDOM();
	LIB = DOM.library;
	
	var item_name = "role";
	var item = createItem(item_name, "Role","movie clip");
	
	var editable = LIB.editItem(item_name);
	
	if(item!=null && editable==true)
	{
		//默认参数，先添加在上边的图层
		item.timeline.addNewLayer("res");
		item.timeline.addNewLayer("label");
		item.timeline.deleteLayer(2);
	}
	
	/*
	var folder = "attack/downleft";
	createFolder(folder);
	var uirList = ["file:///F:/foozuu_works/png2fla-tool/bin-debug/assets/copy/hero_2010006/hero_2010006_attack/downleft_attack/04-downleft-0001.png",
	"file:///F:/foozuu_works/png2fla-tool/bin-debug/assets/copy/hero_2010006/hero_2010006_attack/downleft_attack/04-downleft-0002.png"];
	importFiles(uirList,folder);
	
	for(var i=0; i < 5; ++i)
		addItemsToTimeLine(item_name,["04-downleft-0001.png","04-downleft-0002.png"],"start","end",5);
	
	*/
	var uirlist = [];
	var nameslist = [];
	var poslist = [];
	for (var folder in PUBLISH_INFO)
	{
		if(folder==null || folder=="")
			continue;
		//0002.png,file:///F:/foozuu_works/png2fla-tool/copy/hero_2010006/spell/down/0002.png,-152.0,-135.0
		var infos = PUBLISH_INFO[folder];
		for(var i=0; i < infos.length; ++i)
		{
			var fileinfo = infos[i];
			nameslist.push(fileinfo[0]);
			uirlist.push(fileinfo[1]);
			poslist.push(fileinfo[2]);
		}
		createFolder(folder);
		
		importFiles(uirlist,folder);
		addItemsToTimeLine(folder,item_name,nameslist,poslist,"start","end",2);
	}
		return;
	//saveFlaAndPublish(SCRIPT_PATH+"savefile.fla");
}

function parsePublishInfo()
{
	//fullpath[:]name[*]copyuil[*]x,y[?]name[*]copyuil[*]x,y[?]name[*]copyuil|x,y
	PUBLISH_INFO = {};
	var content_array = INFO_CONTENT.split("\n");
	
	for each(var file_info in content_array)
	{
		var all_infos = file_info.split("[:]");
		var key = all_infos[0];
		var all_infos_string = all_infos[1] +"";
		var file_info_array = all_infos_string.split("[?]");
		
		PUBLISH_INFO[key] = [];
		/*
		trace("*****************")
		trace(key);
		
		if(key==null || key=="")
		{
			trace(all_infos);
		}
		trace("#################")
		*/
		for(var i=0;i < file_info_array.length;++i)
		{
			var info = file_info_array[i].split("[*]");
			PUBLISH_INFO[key].push(info);
		}
		
	}
}

function saveFlaAndPublish(savePath)
{
	fl.saveDocument(DOM , savePath);
	DOM.publish();
	fl.closeDocument(DOM);
}

function addItemsToTimeLine(folder,itemName, itemNames, posList, startLabel, endLabel, frameInterval)
{
	var editable = LIB.editItem(itemName);
	var r = LIB.selectItem(itemName);
	trace(r);
	var items = LIB.getSelectedItems();
	var items_count = itemNames.length;
	var timeline = items[0].timeline;
	
	var add_frames = items_count * frameInterval;
	var frame_count = timeline.frameCount;
	
	//新的原件有一个空帧，所以要减去一
	var start_index = frame_count==1 ? frame_count-1 : frame_count;
	var dest_index = start_index + add_frames - 1;
	timeline.currentLayer=0;
	
	timeline.insertBlankKeyframe(dest_index);
	if(start_index!=0)
		timeline.convertToKeyframes(start_index);
		
	timeline.setFrameProperty("name", startLabel, start_index);
	timeline.setFrameProperty("name", endLabel, dest_index);
	
	timeline.currentLayer = 1;
	//timeline.currentFrame = start_index;
	timeline.insertFrames(start_index==0 ? add_frames-1:add_frames, false, start_index);
	if(start_index!=0)
		timeline.convertToBlankKeyframes(start_index);
	var add_index_start = start_index;
	for(var i=0;i<items_count;++i)
	{		
		//选择起始帧
		timeline.currentFrame = add_index_start;
		if(i!=0)
			timeline.convertToBlankKeyframes(add_index_start);
		var add_item = folder+"/"+itemNames[i];
		trace(add_item);
		LIB.addItemToDocument({x:0, y:0},add_item);
		var pos_string = posList[i];
		var pos_array = pos_string.split(",");
		
		//我也不知道为什么上边的坐标设置有问题，所以这里只好重新设置
		var selected = DOM.selection[0];
		
		selected.x = Number(pos_array[0]);
		selected.y = Number(pos_array[1]);
		add_index_start+=frameInterval;
		continue;
		var dest_index = start_index+add_frames-1;
		if(start_index==0)
			dest_index += 1;
		timeline.insertBlankKeyframe(dest_index);
		//timeline.removeFrames(dest_index);

		
		
		
	}
}

/** 创建一个顶级文件夹*/
function createFolder(folder)
{
	LIB.selectNone();
	LIB.newFolder(folder);
	LIB.updateItem();
}

/** 导入uirList里的所有文件到库里，并且移动到指定文件夹*/
function importFiles(uirList,folder)
{
	for each(var uir in uirList)
	{
		//file = FLfile.platformPathToURI(file);
		DOM.importFile(uir,true);
		
		if(folder!=null)
		{
			LIB.moveToFolder(folder,getFileNameByUIR(uir), true); 
		}
	}
}

/** 根据uir获取文件名*/
function getFileNameByUIR(uir)
{
	if(uir!=null)
	{
		var folders = uir.split("/");
		return folders.pop();
	}
	return null;
}

/**
	创建一个原件，并制定原件名和as3.0导出类名
*/
function createItem(itemName,linkName,itemType)
{
	var r = LIB.addNewItem(itemType, itemName);
	if(r==true)
	{
		var r = LIB.selectItem(itemName);
		trace(1)
		if(r==false)
			return null;
		var items = LIB.getSelectedItems();
		trace(items[0].name)
		if(linkName!=null)
		{
			items[0].linkageExportForAS = true;
			items[0].linkageClassName = linkName;
		}
		trace(3)
		return items[0];
	}
	return null;
}

function openTempleteFLA()
{
	fl.openDocument(SCRIPT_PATH+templeteName);
	var paths = getFolders(SCRIPT_PATH);
	
	for each (var path in paths)
        {
			trace(path);
		}
		
	
}

function currentScriptPath()
{
	var url = fl.scriptURI;

	var parts = url.split("/");
	var script_name = parts.pop();
	url = url.replace(script_name,"");
	
	return url;
}
 
//f();
function f()
{
        var folder = fl.browseForFolderURL("选择资源文件夹");
        if (! folder)
        {
                return;
        }
		destPath = fl.browseForFolderURL("选择导出目标文件夹");
        if (! destPath)
        {
                return;
        }
		trace(destPath);
        var paths = getAllFiles(folder);
        if (confirm("将要批量导出" + paths.length + "个文件"))
        {
                publish(paths);
        }
}
//导出
function exportPNG()
{
	var target = fl.openDocument(templeteFullPath);
	var lib = target.library;
	lib.editItem("empty");
	lib.selectItem("empty");
	var tl = lib.getSelectedItems()[0].timeline;
	//trace(tl.frameCount)
	tl.pasteFrames(0);	
	target.exitEditMode();
	var path = currentPath.replace(currentFileName, "");
	var savepath = FLfile.uriToPlatformPath(destPath) +"\\"+ currentFileName.replace(".fla", "");
	
	//修改导出配置
	var profile = target.exportPublishProfileString();
	var pngname = currentFileName.replace(".fla", ".png");
	profile = profile.replace("<defaultNames>1</defaultNames>", "<defaultNames>0</defaultNames>");
	profile = profile.replace("<pngDefaultName>1</pngDefaultName>", "<pngDefaultName>0</pngDefaultName>");
	profile = profile.replace("<pngFileName>"+NAME+"</pngFileName>", "<pngFileName>11"+pngname+"</pngFileName>");
	//trace(profile)
	while(profile.indexOf(NAME)!=-1)
	{
		profile = profile.replace(NAME, savepath);
	}
	target.importPublishProfileString(profile);
	updateItems(target);
	//发布文件
	//trace(target.exportPublishProfileString());
	target.publish(savepath, true);
	allPNG = allPNG + "\n" + savepath;
	fl.closeDocument(target, false);
	return profile;
}

function updateItems(dom)
{
	dom.selectAll();
	for (var i=0;i<dom.selection.length; ++i)
	{
		var item = dom.selection[i];
		allPNG = allPNG + "\n" + item.left+" " + item.name;
		executeParam(item, dom);
	}
}

function executeParam(item, dom)
{
	if(params==null || params=="")
		return;
	var pl = params.split("-");
	for each(var param in pl)
	{
		dom.selectNone();
		var paraminfo = param.split("=");
		var name = paraminfo[0];
		var values = paraminfo[1];
		if(item.name==name)
		{
			item.selected = true;
			var mx = 0;
			var my = 0;
			//水平居中
			if(values.indexOf("h")>=0)
			{
				mx = item.x-item.left-item.width/2;
			}
			//垂直居中
			if(values.indexOf("v")>=0)
			{
				my = item.y-item.top-item.height/2
			}
			dom.moveSelectionBy({x:mx, y:my})
		}else{
			item.selected = false;
		}
	}
}

//检查是否有指定参数
function checkParam(key)
{
	return params.search(key)>=0;
}

//从路径名分离出元件名和需要的帧
function spliceNameAndFrame(path)
{
	var parts = path.split("/");
	var name = parts[parts.length-2];
	parts = name.split("_");
	elemName = parts[0];
	elemName = elemName.replace("[d]", currentFileName.replace(".fla", ""))
	iFrame = parts[1];
	params = parts[2] || "";
}

//设置模板文件路径
function buildTempletePath(path, fileName)
{
	trace(path + fileName);
	templeteFullPath = path.replace(fileName, templeteName);
}


function publish(paths)
{
        if (paths.length > 20)
        {
                if (! confirm("文件比较多(" + paths.length + ")个,是否继续?"))
                {
                        return;
                }
        }
        fl.outputPanel.clear();
        trace("开始批量发布");
		
		/*
		for each (var path in paths)
        {
				//跳过模板
				if(path.search(templeteName)>=0)
				{
					templeteFullPath = path;
					break
				}
		}
		*/
		
        for each (var path in paths)
        {
			
				//跳过模板
				if(path.search(templeteName)>=0)
				{
					continue;
				}
				
				//打开资源
				sourceDom = fl.openDocument(path);				
				buildTempletePath(path, sourceDom.name);
				currentPath = path;
				currentFileName = sourceDom.name;
				spliceNameAndFrame(path);
				
				 var lib = sourceDom.library
				sourceDom.library.selectNone()
				var b = lib.selectItem(elemName);
				//针对命名不规范的，使用遍历查找类名
				if(b==false)
				{
					for each(var d in lib.items)
					{
						trace(d.linkageClassName + "_" + d.name)
						if(d.linkageClassName!=elemName)
							continue;
						elemName = d.name;
						lib.selectItem(elemName);
						
						 break;
					}
				}
				// trace(lib.getSelectedItems()[0]+b+elemName);
				var b = lib.editItem(elemName);
				var tl = lib.getSelectedItems()[0].timeline;
				//选择包含有效资源的图层
				for(var i=0; i < tl.layers.length; ++i)
				{
					var layer = tl.layers[i];
					if(layer.frameCount==iFrame&&layer.layerType!="guided")
					{
						tl.currentLayer = i;
						break;
					}
				}
				
				tl.copyFrames(iFrame-1);
				tl.pasteFrames(0);
				//sourceDom.clipCopy();
				
				var e = exportPNG();
				//trace(e);
				
				fl.closeDocument(sourceDom, false);
        }
       trace(allPNG);
}

function trace(string)
{
	fl.trace(string);
}

function getFiles(folder, type)
{
        return FLfile.listFolder(folder+"/*."+type,"files");
}
function getFolders(folder)
{
        return FLfile.listFolder(folder+"/*","directories");
}
function getAllFiles(folder)
{
        //递归得到文件夹内所有as文件
        var list = getFiles(folder, "fla").concat(getFiles(folder, "xfl"));
        var i = 0;
        for each (var file in list)
        {
                list[i] = folder + "/" + file;
                i++;
        }
        var folders = getFolders(folder);
        for each (var childFolder in folders)
        {
                list = list.concat(getAllFiles(folder + "/" + childFolder));
        }
        return list;
}