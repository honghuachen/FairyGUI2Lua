/**
 * Created by xiaocai on 2017/9/7.
 * QQ:1817700497
 */
package {
import fairygui.editor.plugin.ICallback;
import fairygui.editor.plugin.IFairyGUIEditor;
import fairygui.editor.plugin.IPublishData;
import fairygui.editor.plugin.IPublishHandler;
import fairygui.editor.publish.gencode.GenCodeUtils;
import fairygui.editor.utils.PinYinUtil;
import fairygui.editor.utils.UtilsFile;
import fairygui.editor.utils.UtilsStr;

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.describeType;

public final class GenerateLuaCodePlugin implements IPublishHandler {
    public static const FILE_MARK:String = "--This is an automatically generated class by FairyGUI. Please do not modify it.";

    public var publishData:IPublishData;
    public var stepCallback:ICallback;


    protected var projectSettings:Object;
    protected var packageFolder:File;
    protected var packageName:String = "";
    protected var packagePath:String = "";

    protected var sortedClasses:Array = [];
    protected var prefix:String = "";

    private var _editor:IFairyGUIEditor;


    public function GenerateLuaCodePlugin(editor:IFairyGUIEditor) {
        _editor = editor;
    }

    public function doExport(data:IPublishData, callback:ICallback):Boolean {
        publishData = data;
        stepCallback = callback;
        prefix = _editor.project.customProperties["lua_class_prefix"];
        if (prefix == null)
        {
            prefix = "";
        }

        clearLogFile();

        var gen_lua:String = _editor.project.customProperties["gen_lua"];
        if (gen_lua != "true") {
            return false;
        }

        init("lua");
        loadTemplate("Lua");

        stepCallback.callOnSuccess();
        return true;
    }

    protected function init(fileExtName:String):void {
        var path:String = null;
        var targetFolder:File = null;
        var oldFiles:Array = null;
        var file:File = null;
        var fileContent:String = null;
        var project:Object = publishData['_project'];
        this.projectSettings = project.settingsCenter.publish;
		
		var xml:XML = flash.utils.describeType(project);
		printLog("project-------------\n"+xml.toXMLString());
		xml = flash.utils.describeType(project.settingsCenter);
		printLog("project.settingsCenter-------------\n"+xml.toXMLString());
		xml = flash.utils.describeType(project.settingsCenter.publish);
		printLog("project.settingsCenter.publish-------------\n"+xml.toXMLString());
		
        try {
            path = this.projectSettings.codePath;
            path = UtilsStr.formatStringByName(path, project.customProperties);
            targetFolder = new File(project.basePath).resolvePath(path);
            if (!targetFolder.exists) {
                targetFolder.createDirectory();
            }
            else if (!targetFolder.isDirectory) {
                stepCallback.addMsg("Invalid code path!");
                stepCallback.callOnFail();
                return;
            }
        }
        catch (err:Error) {
            stepCallback.addMsg("Invalid code path!");
            stepCallback.callOnFail();
            return;
        }
        this.packageName = PinYinUtil.toPinyin(publishData.targetUIPackage.name, false, false, false);
        this.packageFolder = new File(targetFolder.nativePath + File.separator + this.packageName + "_Lua");
        if (!this.projectSettings.packageName || this.projectSettings.packageName.length == 0) {
            this.packagePath = this.packageName;
        }
        else {
            this.packagePath = this.projectSettings.packageName + "." + this.packageName;
        }
        if (this.packageFolder.exists) {
            oldFiles = this.packageFolder.getDirectoryListing();
            for each(file in oldFiles) {
                if (!(file.isDirectory || file.extension != fileExtName)) {
                    fileContent = UtilsFile.loadString(file);
                    if (UtilsStr.startsWith(fileContent, FILE_MARK)) {
                        UtilsFile.deleteFile(file);
                    }
                }
            }
        }
        else {
            this.packageFolder.createDirectory();
        }
        GenCodeUtils.prepare(publishData);
        this.sortedClasses.length = 0;//清空数组
        for each(var classInfo:Object in publishData.outputClasses) {
            //if (classInfo.superClassName == "GComponent") {
                this.sortedClasses.push(classInfo);
           // }
        }
        this.sortedClasses.sortOn("classId");
    }

    protected function loadTemplate(param1:String):void {
        var _loc3_:Object = null;
        var project:Object = publishData['project'];
        var _loc2_:File = new File(project.basePath + "/template/" + param1);
        if (_loc2_.exists) {
            _loc3_ = this.loadTemplate2(_loc2_);
            if (_loc3_["Binder"] && _loc3_["Component"]) {
                this.createFile(_loc3_);
                return;
            }
        }
        _loc2_ = File.applicationDirectory.resolvePath("template/" + param1);
        _loc3_ = this.loadTemplate2(_loc2_);
        this.createFile(_loc3_);
    }

    private function loadTemplate2(param1:File):Object {
        var _loc4_:File = null;
        var _loc5_:String = null;
        var _loc2_:Array = param1.getDirectoryListing();
        var _loc3_:Object = {};
        for each(_loc4_ in _loc2_) {
            if (_loc4_.extension == "template") {
                _loc5_ = _loc4_.name.replace(".template", "");
                _loc3_[_loc5_] = UtilsFile.loadString(_loc4_);
            }
        }
        return _loc3_;
    }
	
	//生成luaIde的引用标注代码
	private function MenberType2LuaIdeFlag(type:String):String{
		var flag:String = "";
		if(type == "Controller")
			flag = "--@RefType [luaIde#CS.FairyGUI.Controller]"
		else if(type == "Transition")
			flag = "--@RefType [luaIde#CS.FairyGUI.Transition]"
		else if(type == "GButton")
			flag = "--@RefType [luaIde#CS.FairyGUI.GButton]"
		else if(type == "GList")
			flag = "--@RefType [luaIde#CS.FairyGUI.GList]"
		else if(type == "GComponent")
			flag = "--@RefType [luaIde#CS.FairyGUI.GComponent]"
		else if(type == "GTextField")
			flag = "--@RefType [luaIde#CS.FairyGUI.GTextField]"
		else if(type == "GComboBox")
			flag = "--@RefType [luaIde#CS.FairyGUI.GComboBox]"
		else if(type == "GLabel")
			flag = "--@RefType [luaIde#CS.FairyGUI.GLabel]"
		else if(type == "GLoader")
			flag = "--@RefType [luaIde#CS.FairyGUI.GLoader]"
		else if(type == "GObject")
			flag = "--@RefType [luaIde#CS.FairyGUI.GObject]"
		else if(type == "GGraph")
			flag = "--@RefType [luaIde#CS.FairyGUI.GGraph]"
		else if(type == "GGroup")
			flag = "--@RefType [luaIde#CS.FairyGUI.GGroup]"
		else if(type == "GImage")
			flag = "--@RefType [luaIde#CS.FairyGUI.GImage]"
		else if(type == "GMovieClip")
			flag = "--@RefType [luaIde#CS.FairyGUI.GMovieClip]"
		else if(type == "GRichTextField")
			flag = "--@RefType [luaIde#CS.FairyGUI.GRichTextField]"
		else if(type == "GTextInput")
			flag = "--@RefType [luaIde#CS.FairyGUI.GTextInput]"
		else if(type == "GProgressBar")
			flag = "--@RefType [luaIde#CS.FairyGUI.GProgressBar]"
		else if(type == "GSlider")
			flag = "--@RefType [luaIde#CS.FairyGUI.GSlider]"		
	
		return flag;
	}
	
	//判断是否是导出组建类
	private function GetSortedClasses(className:String):Object{
		for each(var classInfo:Object in this.sortedClasses) {
			if(className == classInfo.className)
				return classInfo;
		}
		return null;
	}
	
	//导出类的lua生成代码
	private function GenClassContent(className:String,superClassName:String):String{
		for(var i:String in projectSettings){
			printLog("projectSettings:key="+i+" value="+projectSettings[i]);
			
		}
		for(var k:String in projectSettings) {
			//trace("Key: " + k + " - value: " + obj[k]);
		}
		printLog(projectSettings.getMemberByName);
		
		var content:String = "";	
		var classContent:Array = [];
		
		var childIndex:int = 0;
		var controllerIndex:int = 0;
		var transitionIndex:int = 0;
		var classInfo:Object = GetSortedClasses(className);
		if(classInfo == null){
			printLog("classInfo is null="+className);
			return "";
		}
		
		className = classInfo.className;
		childIndex = 0;
		controllerIndex = 0;
		transitionIndex = 0;
		
		/*members : [
		* 			{ name : "n1" : type : "GImage" },
		* 			{ name : "list" : type : "GList" },
		* 			{ name : "a1" : type : "GComponent", src : "Component1" },
		* 			{ name : "a2" : type : "GComponent", src : "Component2", pkg : "Package2" },
		* 		]
		*/
		for each(var memberInfo:Object in classInfo.members) {
			if (!checkIsUseDefaultName(memberInfo.name)) {
				var memberName:String = "self." + memberInfo.name;
				var sortedClasses:Object = GetSortedClasses(memberInfo.src);
				var memUrl:String = memberInfo.name;
				var root:String = "win";
				if(superClassName != ""){
					//memUrl = superClassName + "/" + memberInfo.name;
					root = "self." +superClassName;
				}
				
				if(superClassName != ""){
					memberName = "self." +superClassName+"."+ memberInfo.name;
					root = "self." +superClassName + ".component";
				}
				else
					classContent.push(" ");
				
				if(sortedClasses == null){
					classContent.push("\t" + MenberType2LuaIdeFlag(memberInfo.type));
					//memberName = "self." + superClassName+"."+ memberInfo.name;
				}
				else{
					classContent.push(" ");
					classContent.push("\t"+memberName+ "= {}");
					classContent.push("\t"+memberName+ ".url = \"ui://" + publishData.targetUIPackage.id + sortedClasses.classId + "\"");				
					classContent.push("\t" + "--@RefType [luaIde#CS.FairyGUI."+sortedClasses.superClassName+"]");
					memberName = memberName + ".component";
				}	
				printLog(memberName);
				if (memberInfo.type == "Controller") {
					if (projectSettings.getMemberByName) {
						classContent.push("\t" + memberName + " = "+root+":GetController(\"" + memUrl + "\")");
					}
					else {
						classContent.push("\t" + memberName + " = "+root+":GetControllerAt(" + controllerIndex + ")");
					}
					controllerIndex++;
				}
				else if (memberInfo.type == "Transition") {
					if (projectSettings.getMemberByName) {
						classContent.push("\t" + memberName + " = "+root+":GetTransition(\"" + memUrl + "\")");
					}
					else {
						classContent.push("\t" + memberName + " = "+root+":GetTransitionAt(" + transitionIndex + ")");
					}
					transitionIndex++;
				}
				else {
					if (projectSettings.getMemberByName) {
						classContent.push("\t" + memberName + " = "+root+":GetChild(\"" + memUrl + "\")");
					}
					else {
						classContent.push("\t" + memberName + " = "+root+":GetChildAt(" + childIndex + ")");
					}
					childIndex++;
				}
				
				if(sortedClasses != null){
					if(superClassName == "")
						classContent.push(GenClassContent(memberInfo.src,memberInfo.name));
					else
						classContent.push(GenClassContent(memberInfo.src,superClassName+"."+memberInfo.name));
				}
			}
		}		
		
		content = classContent.join("\r\n");
		return content;
	}
	
	protected function createFile(param1:*):void {
		var binderName:String = null;
		var binderContext:String = null;
		var binderRequire:Array = [];
		var binderContent:Array = [];
		
		var className:String = null;
		var classContext:String = null;
		var classContent:Array = null;
		
		var childIndex:int = 0;
		var controllerIndex:int = 0;
		var transitionIndex:int = 0;
		
		for each(var classInfo:Object in sortedClasses) {
			className = prefix + classInfo.className;
			classContext = param1["Component"];
			classContent = [];
			childIndex = 0;
			controllerIndex = 0;
			transitionIndex = 0;
			
			classContext = classContext.replace("{packageName}", packagePath);
			classContext = classContext.split("{uiPkgName}").join(publishData.targetUIPackage.name);
			classContext = classContext.split("{uiResName}").join(classInfo.className);
			classContext = classContext.split("{className}").join(className);
			classContext = classContext.replace("{componentName}", classInfo.superClassName);
			classContext = classContext.replace("{uiPathID}", formate("ui://{0}",publishData.targetUIPackage.id + classInfo.classId));
			classContext = classContext.replace("{uiPathName}", formate("ui://{0}/{1}" ,publishData.targetUIPackage.name , classInfo.className));
			classContext = classContext.replace("{uiPackageID}", publishData.targetUIPackage.id);
			classContext = classContext.replace("{uiPackageName}", publishData.targetUIPackage.name);
			
			classContent.push(GenClassContent(classInfo.className,""))
			classContext = classContext.replace("{content}", classContent.join("\r\n"));
			UtilsFile.saveString(new File(packageFolder.nativePath + File.separator + className + "Model.lua"), FILE_MARK + "\n\n" + classContext);
		}
		
		stepCallback.callOnSuccess();
	}

    protected function createFile2(param1:*):void {
        var binderName:String = null;
        var binderContext:String = null;
        var binderRequire:Array = [];
        var binderContent:Array = [];

        var className:String = null;
        var classContext:String = null;
        var classContent:Array = null;

        var childIndex:int = 0;
        var controllerIndex:int = 0;
        var transitionIndex:int = 0;

        for each(var classInfo:Object in sortedClasses) {
            className = classInfo.className;
            classContext = param1["Component"];
            classContent = [];
            childIndex = 0;
            controllerIndex = 0;
            transitionIndex = 0;

            classContext = classContext.replace("{packageName}", packagePath);
            classContext = classContext.split("{uiPkgName}").join(publishData.targetUIPackage.name);
            classContext = classContext.split("{uiResName}").join(classInfo.className);
            classContext = classContext.split("{className}").join(className);
            classContext = classContext.replace("{componentName}", classInfo.superClassName);
            classContext = classContext.replace("{uiPath}", "ui://" + publishData.targetUIPackage.id + classInfo.classId);
            for each(var memberInfo:Object in classInfo.members) {
                if (!checkIsUseDefaultName(memberInfo.name)) {
                    var memberName:String = "self." + memberInfo.name;
                    if (memberInfo.type == "Controller") {
                        if (projectSettings.getMemberByName) {
                            classContent.push("\t" + memberName + " = self:GetController(\"" + memberInfo.name + "\");");
                        }
                        else {
                            classContent.push("\t" + memberName + " = self:GetControllerAt(" + controllerIndex + ");");
                        }
                        controllerIndex++;
                    }
                    else if (memberInfo.type == "Transition") {
                        if (projectSettings.getMemberByName) {
                            classContent.push("\t" + memberName + " = self:GetTransition(\"" + memberInfo.name + "\");");
                        }
                        else {
                            classContent.push("\t" + memberName + " = self:GetTransitionAt(" + transitionIndex + ");");
                        }
                        transitionIndex++;
                    }
                    else {
                        if (projectSettings.getMemberByName) {
                            classContent.push("\t" + memberName + " = self:GetChild(\"" + memberInfo.name + "\");");
                        }
                        else {
                            classContent.push("\t" + memberName + " = self:GetChildAt(" + childIndex + ");");
                        }
                        childIndex++;
                    }
                }
            }
            classContext = classContext.replace("{content}", classContent.join("\r\n"));
            binderRequire.push("require('"+ className +"')")
            binderContent.push("fgui.register_extension(" + className + ".URL, " + className + ");");
            UtilsFile.saveString(new File(packageFolder.nativePath + File.separator + className + ".lua"), FILE_MARK + "\n\n" + classContext);
        }

        binderName = packageName + "Binder";
        binderContext = param1["Binder"];
        binderContext = binderContext.replace("{packageName}", packagePath);
        binderContext = binderContext.split("{className}").join(binderName);
        binderContext = binderContext.replace("{bindRequire}", binderRequire.join("\r\n"));
        binderContext = binderContext.replace("{bindContent}", binderContent.join("\r\n"));
        UtilsFile.saveString(new File(packageFolder.nativePath + File.separator + binderName + ".lua"), FILE_MARK + "\n\n" + binderContext);
        stepCallback.callOnSuccess();
    }

    private function checkIsUseDefaultName(name:String):Boolean {
		if(!this.projectSettings.ignoreNoname)
			return false;
		if (name.charAt(0) == "n" || name.charAt(0) == "c" || name.charAt(0) == "t") {
            return _isNaN(name.slice(1));
        }
        return false;
    }

    private function _isNaN(str:String):Boolean {
        if (isNaN(parseInt(str))) {
            return false;
        }
        return true;
    }

    //-------------------------输出log到文件--------------------------

    private function printLog(log:String):void {
        var path:String = getLogFilePath();
        var file:File = new File(path);
        var fileStream:FileStream = new FileStream();
        fileStream.open(file, FileMode.APPEND);
        fileStream.writeUTFBytes(log + "\n");
        fileStream.close();
    }

    private function clearLogFile():void {
        var path:String = getLogFilePath();
        var file:File = new File(path);
        if (file.exists) {
            file.deleteFile();
        }
    }

    private function getLogFilePath():String {
        var project:Object = publishData['_project'];
        this.projectSettings = project.settingsCenter.publish;
        var path:String = this.projectSettings.codePath;
        return UtilsStr.formatStringByName(path, project.customProperties) + "/log.txt";
    }
	
	private function formate(str:String, ...args):String{ 
		for(var i:int = 0; i<args.length; i++){ 
			str = str.replace(new RegExp("\\{" + i + "\\}", "gm"), args[i]); 
		} 
		return str; 
	}
}
}