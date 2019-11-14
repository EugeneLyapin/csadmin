/* Common
================================================*/
function isset(val){
	return (val || val==0 || val=='');
	}
/* Functions and types
====================================*/
	function $function(f,params){		 
		if (is_function(f)){
			var args = Array.prototype.slice.call(arguments);
			return f(args.slice(1))
			}
		return false;
		}
	
	/* Inheritance */
	Function.prototype.inheritsFrom = function(superClass) {
		var Inheritance = function(){};	
		Inheritance.prototype = superClass.prototype;	
		this.prototype = new Inheritance();	
		this.prototype.constructor = this;	
		this.superClass = superClass;
		this.prototype._parent=superClass.prototype;
		this.prototype._parentMethod=function(method){
			var args = Array.prototype.slice.call(arguments);
			
			if (is_function(this._parent[method])){
				this._parent[method].call(this,args.slice(1));
				}
			}
		return this;
		}
	
	function is_function(func){
		return (func && typeof(func)=='function');
		}
	function is_object(o){
		return (typeof(o)=='object');
		}
	
	function is_array(o){		
		return (o!=null && typeof(o)=='object' && o.unshift!=undefined);
		}
	
	function is_string(o){
		return (typeof(o)=='string');
		}
	
	function is_numeric(o){
		return !isNaN(o);
		}
	function is_null(o){
		return o===null;
		}
	
	function is_date(o){
		return (o && typeof(o)=='object' && is_function(o.getTime));
		}
		
	function method_exists(obj,m){
		return ( is_object(obj) && is_function((obj)[m]) );
		}
		
	

/* Browser detect
================================================*/
var BROWSER={
	isIE:((navigator.appVersion.indexOf("MSIE") != -1) ? true : false),
	isIE6:((document.all && !window.opera && !window.XMLHttpRequest) || (navigator.appVersion.indexOf("MSIE 6")!=-1)),
	isOpera:((navigator.userAgent.indexOf("Opera") != -1) ? true : false),
	isOpera95:((navigator.userAgent.indexOf("Opera") != -1) && window.scrollX==undefined),
	isFirefox:((navigator.userAgent.indexOf("Firefox") != -1) ? true : false),
	isGecko:!document.attachEvent && document.addEventListener
	};
var OPERATING_SYSTEM={
	isLinux:navigator && navigator.platform && navigator.platform.search('Linux')>=0,
	isBsd:navigator && navigator.platform && navigator.platform.search(/Bsd/i)>=0
	}
OPERATING_SYSTEM.isUnix=(OPERATING_SYSTEM.isLinux||OPERATING_SYSTEM.isBsd);



/* AJAX and Forms
====================================*/
	function doScript(scriptSRC,params){
		var newScript = document.createElement("SCRIPT"), paramsString="";
		//	if (!params) var params={};
		if (!scriptSRC){
			scriptSRC=PATH_AJAX;
			}
		if (!params.from) params.from="js";
		if (!params.resultwrapper) params.resultwrapper="js";
		for (p in params) {paramsString+=paramsString?"&"+p+"="+params[p]:"?"+p+"="+params[p]}
		scriptSRC+=paramsString;
		//alert (scriptSRC); return;
		newScript.type="text/javascript";
		newScript.src=scriptSRC;   
		//document.write (scriptSRC); return;
		document.body.appendChild(newScript);
		}
	
	function putAndSendForm(fAction,fMethod,fData,fFiles){
		var f=setChild(document.body,null,null,"form"),i;
		if (fAction) f.action=fAction;
		if (fMethod) f.method=fMethod;
		for (var iName in fData)
		{ 
			i=setChild(f,null,null,"input")
			//i.setProperty("type","hidden");
			i.name=iName
			i.value=fData[iName]
		}
		
		if (fFiles)
		{
			for (var fName in fFiles)
			{
				var ff=fFiles[fName], newff=f.appendChild(ff);
				// for (var pr in ff) newff[pr]=ff[pr]
				newff.value=ff.value;
				
				//alert(i.value);
			}
			i=setChild(f,null,null,"input")
			i.name="MAX_FILE_SIZE"
			i.value=30000
			f.enctype="multipart/form-data";
		}
		
	
		f.submit();
		}
	function getRadioValue(el){
		var res=null
		el=$name(el);
		if (!el) {
			//alert ('not found '+el)
			return "";
			}
		
		for (var i=0; i<el.length; i++){
			var iEl=el[i];
			if (iEl.checked) {
				res=iEl.value;
				break;					
				}
			}
		return res;
		}
		
	function putInCursorPlace(field,text){
		var pos=getCaretPos(field);
		field.value=field.value.substr(0,pos)+text+field.value.substr(pos);
		}
	function getCaretPos(obj){
		obj.focus();
		if(obj.selectionStart) {
			return obj.selectionStart;//Gecko
			}
		else if (document.selection){
			//IE		
			var sel = document.selection.createRange();
			var clone = sel.duplicate();
			sel.collapse(true);
			clone.moveToElementText(obj);
			clone.setEndPoint('EndToEnd', sel);
			return clone.text.length;
			}		
		return 0;
		}
		
	function selectNode (node){
		node=$id(node);
		if (!node){
			return;
			}
		var selection, range, doc, win;
		if ((doc = node.ownerDocument) && (win = doc.defaultView) && typeof win.getSelection != 'undefined' && typeof doc.createRange != 'undefined' && (selection = window.getSelection()) && typeof selection.removeAllRanges != 'undefined'){
			range = doc.createRange();
			range.selectNode(node);
			selection.removeAllRanges();
			selection.addRange(range);
			}
		else if (document.body && typeof document.body.createTextRange !=
		'undefined' && (range = document.body.createTextRange())){
			range.moveToElementText(node);
			range.select();
			}
		}
		
	/* XML
	====================================*/
	function parseLineXML(xml){
		if (!xml) {
			return false;
			}
		var res=[],
			fc=xml.firstChild,
			fcA={}
		if (!fc) return {};
		if (fc.nodeType != 1) fc= fc.nextSibling;
		
		//Get fc attributes
		for (var a=0;a<fc.attributes.length;a++){
			var attr=fc.attributes[a]
			if (attr.nodeType!=2) continue
			fcA[attr.nodeName]=attr.nodeValue
			}

 	 	for (var i=0;i<fc.childNodes.length;i++){
			
			var node=fc.childNodes[i]
			if (node.nodeType!=1) continue
			
			res[i]={value:node.firstChild?node.firstChild.data:"",data:{}}
			for (var a=0;a<node.attributes.length;a++){
				var attr=node.attributes[a]
				if (attr.nodeType!=2) continue
				res[i].data[attr.nodeName]=attr.nodeValue
				}
			}
		return {head:fcA,body:res};
		}
		
		if (typeof DOMParser == "undefined") {
			   DOMParser = function () {return false;}
			
			   DOMParser.prototype.parseFromString = function (str, contentType) {
				  if (typeof ActiveXObject != "undefined") {
						 var d = new ActiveXObject("MSXML.DomDocument");
						 d.loadXML(str);
						 return d;
					  } else if (typeof XMLHttpRequest != "undefined") {
						 var req = new XMLHttpRequest;
						 req.open("GET", "data:" + (contentType || "application/xml") +
										 ";charset=utf-8," + encodeURIComponent(str), false);
						 if (req.overrideMimeType) {
							req.overrideMimeType(contentType);
							}
						 req.send(null);
						 return req.responseXML;
						}
					return false;
					}
			}
	
	/* Set cursor positions in input elements
	====================================*/	

		function moveCaretToStart(inputObject){		
			 if (inputObject.createTextRange){
				 //IE
				var r = inputObject.createTextRange();
				r.collapse(true);
				r.select();
				}
			else if (inputObject.selectionStart){
				// Mozilla/Gecko
				inputObject.setSelectionRange(0,0);
				inputObject.focus();
				}
			}
		
		function moveCaretToEnd(inputObject){
			 if (inputObject.createTextRange){
				//IE
				var r = inputObject.createTextRange();
				r.collapse(false);
				r.select();
				}
			else if (inputObject.selectionStart){
				// Mozilla/Gecko
				var end = inputObject.value.length;
				inputObject.setSelectionRange(end,end);
				inputObject.focus();
				}
			}

		
	/* Get textarea lines
	================================================*/
	function textareaCurLineNum(obj){
		obj=$id(obj);
		var rowHeight=obj.clientHeight/obj.rows;
		var curHeight=obj.createTextRange().boundingHeight;		
		return parseInt(curHeight/rowHeight)+(obj.value!=''?1:0);
		}
	function getTextareaLines(field){
		field=$id(field);
		var 
			value=$value(field);
		if (!value || !value.length){
			return 1;
			}
		var
			rows=value.split('\n'),
			rowsNum=rows.length,
			colsNum=field.cols,
			symbolWidth=6,
			symbolsPerRow=field.cols?field.cols:Math.ceil(field.clientWidth/symbolWidth);

		for (var i=0; i<rows.length; i++){
			
			var row=rows[i],
				subRowsNum=row.length/symbolsPerRow;
			
			if (subRowsNum>1){
				rowsNum+=Math.ceil(subRowsNum)-1;
				}
			}			
		return rowsNum;
		}

function valueInLimits(value,min,max){
	return Math.max(
			Math.min(value,max),
			min);
	}

/* DOM functions
====================================*/
	function $id(el){	
		var res;
		if (!el) {
			return false;
			}
		res=null;
		if (typeof(el)!="object"){
			res=document.getElementById(el)||null;
			if (res && res.id && res.id!=el){
				res=null;
				}
			}
		else if(el.length!=undefined && el.slideDown!=undefined){ /* check if el is jquery object */
			res=el[0];
			}
		else{
			res=el
			}
		return res;
		}
	
	function $name(el){	
		if (!el) return false;
		var els=new Array();
	
		if (typeof(el)!="object"){
			els=document.getElementsByName(el);
		} 
		
		return els;
		/* if (els.length!=0) return els;
		else return null; */
		}
	
	
	function $tagname(tg,par){	
		if (!tg) return false;
		var els=new Array();
		par=$id(par)
		if (par && typeof(par)=="object") els=par.getElementsByTagName(tg);
		else els=document.getElementsByTagName(tg);
		
		/* if (els.length>1)  */
		return els;
		/* else if (els.length==1) return els[0] */
		/* else return []; */
		}
		
	function $tag(tg,par){
		par=par?$id(par):document;
		
		var res=[];
		if (par){
			if (is_array(tg)){
				var num;
				for (var i=0;i<tg.length;i++){
					var tgres=$tag(tg[i],par);					
					if (tgres.length){
						for (var j=0;j<tgres.length;j++){
							res.push(tgres[j]);
							}
						}
					}
				}
			else if(is_string(tg)){
				res=par.getElementsByTagName(tg);
				}
			}		
		return res;
		}
	function $tagnameSingle(tg,par){
		var els=$tagname(tg,par);
		if (els){
			return els[0];
			}
		return null;
		}	
	
	function $class(el,cl){
		el=$id(el)
		if (!el) {
			return false;
			}
		el.className=cl||'';
		return el;		
		}
		
	function $value(el,val){
		var res;				
		el=$id(el)
		if (!el) {
			return '';
			}		
		if (val){
			el.value=val;
			}		
		res=el.value||'';

		return res;		
		}
	
	function $innerHTML(el,text){
		el=$id(el);
		if (!el){
			return false;
			}
		el.innerHTML=text;
		return true;
		}
		
	function $checked(el,val){
		el=$id(el);
		if (!el) {
			return false;
			}	
		if (isset(val)){			
			el.checked=val;
			}		
		return el.checked;
		}
		
	function $clear(el){
		return $innerHTML(el,CLEAR_SIGN);
		}
	
	function $focus(el){
		el=$id(el);
		if (!el || !el.focus){
			return false;
			}
		return el.focus();
		}
	
	function $blur(el){
		el=$id(el);
		if (!el || !el.blur){
			return false;
			}
		return el.blur();
		}
	
	function $toggleDisable(el,isOn){
		el=$id(el);
		if (!el){
			return false;
			}
		toggleClass(el,isOn?1:0,['field-enabled','field-disabled']);
		return el.disabled=!!isOn;
		}
		
	function $disable(el){
		return $toggleDisable(el,true);
		}
		
	function $enable(el){
		return $toggleDisable(el,false);
		}
	
	function $displaying(el){
		el=$id(el);
		if (!el){
			return false;
			}
		return !!(el.offsetHeight);
		}
		
		
	function setChildExt(settings){
		var defaultSettings={
				parent:document.body,
				tag:'DIV',
				id:''
			};
		settings=concatObjects(settings,defaultSettings);
		
		var el=$id(settings.id);
		if (el){
			return el;
			}
		if (settings.parent) {			
			try{
				var par=$id(settings.parent);
				el=document.createElement(settings.tag);
				el=par.appendChild(el);
				if (settings.id){
					el.id=settings.id;
					}
				}
			catch(e){
				}
			}
		
		if (!el) {
			return false;
			}
		if (settings.className){
			el.className=settings.className;
			}
		if (settings.content){
			el.innerHTML=settings.content;
			}
		if (settings.params && typeof settings.params=='object'){
			//el=concatObjects(el,settings.params);
			for (var i in settings.params){
				el[i]=settings.params[i];
				}
			}
		if (settings.style && typeof settings.style=='object'){
			setStyle(el,settings.style);
			}
		if (settings.onclick && typeof settings.onclick=='function'){
			el.onclick=settings.onclick;
			}
		
		if (settings.pastCreate && typeof settings.pastCreate=='function'){			
			settings.pastCreate(el);
			}
		
		return el;
		}
		
	function setStyle(el,style){
		el=$id(el);
		if (!el || !style || typeof style!='object'){
			return false;
			}
		for (var property in style){
			var value=style[property];
			if (typeof value!='object' && typeof value!='function'){
				el.style[property]=value;
				}
			}
		return true;
		}
	function setSizes(sizes){
		
		}
	function setChild(par,elID,elClass,elType,elContent,elParams){		
		if (!par){
			par=document.body;
			}
		if (!elID){
			elID='';
			}
		
		var el=$id(elID);
		
		if (par && !el && elType) 
		{
			//need to create and append new child
			par=$id(par);		
			el=document.createElement(elType);
			el=par.appendChild(el);
			if (elID) el.id=elID;
		}
		
		if (!el) return false;
		
		if (elClass) el.className=elClass;
		if (elContent) el.innerHTML=elContent;
		if (elParams) el=concatObjects(el,elParams);
		
		return el;
		}
	function unsetChild(el){
		if (!el) return false;
		el=$id(el);
		if (el.parentNode){
			el.parentNode.removeChild(el);
			}
		return true
		}	
	
	function searchInClass(el,base){
		el=$id(el);
		if (el && el.className){
			var parts=el.className.split(' ');
			for (var i=0;i<parts.length;i++){
				var part=parts[i];				
				if (part.search(base)==0){
					return part.substr(base.length);
					}
				}
			}
		return false;
		}
	
	function getElementByTagAndClass(par,elTag,elClass){
		if (!par || !elTag) return false;
	
		par=$id(par);
		var el,elNum,els=new Array(),res=null;
		els=par.getElementsByTagName(elTag);
		if (els.length>0)
		{
			for (elNum in els) {
				el=els[elNum];
				//if (el.className && el.className==elClass)
				if (el.className && in_array(el.className.split(" "),elClass))
					res=el;
			}
		}
		
		return res;
		}
	function getElementsByTagAndClass(par,elTag,elClass){
		if (!par || !elTag) return false;
	
		par=$id(par);
		var el,elNum,els=new Array(),res=new Array();
		els=par.getElementsByTagName(elTag);
		if (els.length>0){
			for (elNum in els) {
				el=els[elNum];
				if (el && el.className && in_array(el.className.split(" "),elClass))
				//if (el.className && el.className==elClass) 
				res.push(el);
			}
		}		
		return res;
		}
	function getElementByTagAndProperty(par,elTag,property,propertyValue){
		if (!par || !elTag) return false;	
		par=$id(par);
		var el,elNum,els=new Array(),res=null;
		els=par.getElementsByTagName(elTag);
		if (els.length>0){
			for (elNum in els) {
				el=els[elNum];
				//if (el.className && el.className==elClass)
				if (el[property] && el[property]==propertyValue)
					res=el;
				}
			}		
		return res
		}


/* Positioning and view
====================================*/
	function getWhereIs(block){
		var theBlock=block,
		blockLeft = 0,
		blockTop = 0;
			while(block) {
				blockLeft += block.offsetLeft;
				blockTop += block.offsetTop;
				block = block.offsetParent;
			}
			return {
					left:blockLeft, 
					top:blockTop,
					right:blockLeft+theBlock.offsetWidth,
					bottom:blockTop+theBlock.offsetHeight
					}
		}
	function setPosition(el,pos){
		el=$id(el)
		if (!el) {
			return false;
			}		
		if (pos.left!=null) el.style.left=pos.left+"px"
		if (pos.top!=null) el.style.top=pos.top+"px"
		
		return false
		}	
	function switchElementVisibility(el,state){
		var states=new Array('hidden','showed'),
			newState,
			currState=0
		//alert (el+" '"+$id(el).className+"' state="+state)
		el=$id(el)
		
		if (el.className.search(states[0])>-1)
			currState=0
		else if (el.className.search(states[1])>-1)
			currState=1
		newState=(state==null)?((currState==0)?1:0):state
	
		strTempl='/'+states[currState]+'/'
	
		if (el.className.search(states[currState])>-1)
			el.className=el.className.replace(states[currState], states[newState])
		else 
			el.className+=" "+states[newState]
			
		return newState
		}
	function toggleRow(el,state){
		el=$id(el)
		if (!el) return false
		var stateShow=(document.all && !window.opera)?'block':'table-row',
			states=['none',stateShow],
			state=(state && states[state])?states[state]:((!el.style.display || el.style.display=='none')?states[1]:states[0])
		el.style.display=state
		//alert (el.style.display)
		return false

		}
	function toggleClass(el,state,states){
		states=states?states:['hidden','showed']
		el=$id(el);
		if (!el){
			return false;
			}
		var searchTmpl='/'+states[0]+'/',
			newState=(state==null)?((el.className.search(states[0])>-1)?1:0):state,
			currState=(newState==0)?1:0;
		if (el.className!=null && el.className.search(states[currState])>-1){
			el.className=el.className.replace(states[currState], states[newState])
			}
		else 
			if (el.className!=null && el.className.search(states[newState])<0)
				el.className+=" "+states[newState]
		return newState;
		}
		
	function addClass(el,className){
		el=$id(el);
		if (!el){
			return false;
			}
		if ( el.className && in_array(el.className.split(' '),className) ){
			return true;
			}
		el.className+=' '+className;
		return true;
		}
	
	function hasClass(el,className){
		return (el=$id(el) && el.className && in_array(el.className.split(' '),className) );
		}
	
	function putInScreenCenter(el,setX){	
		el=$id(el);
		if (!el){
			return false;
			}
		el.style.position='absolute';
		var winH = (window.opera)? window.innerHeight:document.documentElement.clientHeight,
			winY=(document.all)?document.documentElement.scrollTop:window.pageYOffset,			
			elY=Math.round(winY+winH/2-el.clientHeight/2),
			winW=document.documentElement.offsetWidth,
			elX=setX?Math.round(winW/2-el.offsetWidth/2):null;
			//alert (winW)
			if (document.all) elY-=30
			//if (document.all) coreX-=30
			setPosition(el,{left:elX,top:elY})
		}
		
	function toggleVisibility(el,state){
		el=$id(el)
		if (!el) return false
		var 
			stateShow=(document.all && !window.opera)?'block':'table-row',
			states=['none',stateShow],
			state=(state && states[state])?states[state]:((!el.style.display || el.style.display=='none')?states[1]:states[0])
			el.style.display=state
		}
	
/* STRING functions
====================================*/
	function NtoBR(str){
		str=str.replace(/\n/,'<br>');
		return str;
		}
	
	function BRtoN(str){		
		str=str.replace(/\r?\n/,'');
		var tmpl=new RegExp(/<br\s*\/?>/i);
		while(str.search(tmpl)>=0){
			str=str.replace(tmpl,'\n');
			}		
		
		return str;
		}
	function htmlspecialchars(text){
		while (text.indexOf('<')>=0) text=text.replace(/</,'[lt]')
		while (text.indexOf('>')>=0) text=text.replace(/>/,'[gt]')
		return text
		}
		
	function getDomainName(url){
		var domain=url.replace_multiply(
			[
				[/^http\:\/\//,''],
				[/^www\./,''],
				[/(\/|\#).*$/,'']
			 	]			
			);
		//'
		return domain;
		}
			
/* String prototypes
================================================*/
	String.prototype.firstCharUpper=function(){
		return this.substr(0,1).toUpperCase()+this.substr(1)
		}
	String.prototype.isNullDate=function(){
		return (this=="0000-00-00 00:00:00");
		}
	String.prototype.sliceEmptySides=function(){
		var n=0;		
		for (var i=0; i<this.length; i++){
			var s=this.substr(i,1);			
			if (s.search(/[\n\s]/)<0){
				break;
				}				
			else{
				n++;
				}			
			}		
		return this.substr(n);
		}
	String.prototype.replace_multiply=function(data){
		var s=this;
		for (var i=0;i<data.length;i++){
			var d=data[i];

			if (!d || !d[0] || !isset(d[1])){				
				continue;
				}
			
			while(s.search(d[0])>=0){
				s=s.replace(d[0],d[1]);	
				}
			}		
		return s;
		}
	String.prototype.numberFormat=function(){
		var 			
			str=this,
			decParts=str.split('.'),
			intStr=decParts.shift(),
			fractionStr=decParts.shift(),
			resStr='',
			parts=[];
		while(intStr.length>2){
			parts.unshift(intStr.substr(intStr.length-3,intStr.length));
			intStr = intStr.substr(0, intStr.length-3);
			}
		if (intStr.length){
			parts.unshift(intStr);
			}
		return parts.join('&nbsp;')+(fractionStr?','+fractionStr:'');	
		}
		

/* Array functions
====================================*/
	function in_array(arr,el){
		var res=0
		for (n in arr) if (el==arr[n]) res++
		return res
		}
	
	function getArgList(params){
		var argList=''
		for (var paramName in params){
				argList+=argList?',':''
				argList+='"'+params[paramName]+'"'
			}			
		return argList
		}
	function setArray(el){
		if ((typeof el=="object") && el.length!=null)	
			return el
		else
			return [el]
		}
		
/* Object functions
====================================*/
	function concatObjects(obj1,obj2){
		var res={}
		for (var pName in obj1){
			res[pName]=obj1[pName]
			}
		for (var pName in obj2)
			if (!res[pName]) res[pName]=obj2[pName]
		return res
		}


/* Debugging
====================================*/	
	function testObject(obj,isWrite,noAlert,level){
		var o="",
			sprt=isWrite?"<br/>":"\n";
		if (!level){
			level=0;
			}
		var spacer='';	
		var maxIterations=256;
		for (var i=0;i<level;i++){
			spacer+='  ';
			}
		if (level>256){
			return '..too much iterations';
			}
		if (is_object(obj)){
			var num=0;
			for (var p in obj){
				if (++num>maxIterations){
					return '..too much iterations';
					}
				var subObj=obj[p];
				var type=typeof(subObj);
				if (subObj==null){
					type='Null'
					}
				else if (subObj.pop){
					type='Array';
					}
				else if (subObj.charAt || subObj==''){
					type='String';	
					}
				else if (!isNaN(Number(subObj))){
					type='Number';	
					}
				if (is_function(subObj)){
					continue
					}
				o+=sprt+spacer+p+'['+type+']: ';				
				if (is_object(subObj)){
					o+=testObject(subObj,false,true,level+1)
					}
				else{
					o+=subObj;
					}
				}
			}
		else{
			o+=spacer+obj;
			}
		if (isWrite){
			document.write(o)
			}
		else {
			if (!noAlert)
				alert (o)
			}
		return o;
		}
	
/* PROTOTYPES
===================================== */
	
	/* String
	===================================== */
	
function stopEventBubble(e){
	if (!e) {
		var e = window.event;
		}
	if (!e){
		return;
		}
	e.cancelBubble = true;
	if (e.stopPropagation) e.stopPropagation();
	}	
	
/* EVENTS	
====================================*/
	function MXX_EVENTS(){
		this.Elements=[]
		this.Events=[]
		this.eventObj=this
		this.append=function(el,evnt,func,weight){
			el=$id(el)			
			
			if (!el) {
				return;
				}
			
			if (!in_array(this.Elements,el)){				
				el.eventObj=this;				
				el.elNum=this.Elements.push(el)-1;				
				this.Events[el.elNum]={};				
				}
				
			var evnts=setArray(evnt);			
			for (var e=0;e<evnts.length;e++){
				var cEvnt=evnts[e]
				
				if (!this.Events[el.elNum][cEvnt])
					this.Events[el.elNum][cEvnt]=[]
				var funcs=setArray(func)
				this.Events[el.elNum][cEvnt]=this.Events[el.elNum][cEvnt].concat(funcs)			
				
				if (!this["router_"+cEvnt]) eval('this["router_'+cEvnt+'"]=function(eArg){this.eventObj.router(this,"'+cEvnt+'",eArg); }')				
				
				eval('el["'+cEvnt+'"]=this["router_'+cEvnt+'"]');
				//if (cEvnt=="onresize") alert(el.id+"\n"+el.onresize)
				
				}
			
			}
		this.router=function(el,evnt,eArg){
			
			var elData=el.eventObj.Events[el.elNum]
			//FIXME
			/* if (!elData) {
				alert (el+" "+evnt)
					return;
				} */
			if (!elData || 	!elData[evnt]) {
				//alert (el.onclick)
				//evnt="onclick" 
				return
				}
				
			for (var e=0;e<elData[evnt].length;e++){
				if (elData[evnt][e] && typeof(elData[evnt][e]=="function"))
					elData[evnt][e].call(el,eArg)
				else {
					//testObject(el.eventObj.Events[el.elNum]["onfocus"])
					//testObject(elData[evnt]);
					}
				}
			//return false;//?
			
			}
		
		}
	var EVENTS=new MXX_EVENTS()
	
	function getKeyPressed(e){
		var KEYCODES=new Array()
			KEYCODES[9]="TAB"
			KEYCODES[13]="ENTER"
			KEYCODES[27]="ESC"
			KEYCODES[35]="END"
			KEYCODES[36]="HOME"
			KEYCODES[37]="ARROWLEFT"
			KEYCODES[38]="ARROWUP"
			KEYCODES[39]="ARROWRIGHT"
			KEYCODES[40]="ARROWDOWN"			
			
		var intKey=-1,
			targetField
		if (window.event){
			intKey=event.keyCode
			targetField=event.srcElement
			}
		else{
			intKey=e.which
			targetField=e.target
			}

		var res=(KEYCODES[intKey])?KEYCODES[intKey]:intKey
		return res
		}

/* Preload Images
================================================*/
var IMG_BLOCK_SCREEN=new Image();
IMG_BLOCK_SCREEN.src='/images/0.png';
IMG_BLOCK_SCREEN.width=IMG_BLOCK_SCREEN.height=1;
IMG_BLOCK_SCREEN.alt='';

/* Block screen
=================================================*/

	EVENTS.append(window,'onresize',resizeBlockScreen);
	
	function blockScreen(){
		if ($id('blockscreen')){
			return false;
			}		
		var bs=setChild(document.body,'blockscreen',null,'DIV');
		bs.overImg=bs.appendChild(IMG_BLOCK_SCREEN);
		bs.style.position='absolute';
		bs.style.top=0;
		bs.style.left=0;
		setPosition(bs,{left:0,top:0});
		/* bs.style.width='100%';
		bs.style.height='100%';	 */	
		bs.style.zIndex=100;		
		resizeBlockScreen();
		
		}
	function unblockScreen(){
		if (!$id('blockscreen')) {
			return false;
			}
		unsetChild('blockscreen');
		//setStyle(document.body,{overflow:'auto'});
		}
	function resizeBlockScreen(){		
		var bs=$id('blockscreen');
		if (!bs || !bs.overImg){			
			return false;
			}
		//setStyle(document.body,{overflow:'hidden'});
		var sizes={
			height:Math.max(document.documentElement.clientHeight,document.body.clientHeight,$id('layout-table').clientHeight,700)+"px",
			width:Math.max(document.documentElement.clientWidth,document.body.clientWidth,$id('layout-table').clientWidth,1000)+"px"
			};
		setStyle(bs,sizes);
		setStyle(bs.overImg,sizes);		
		/* bs.overImg.style.height=height;
		bs.overImg.style.width=width; */
		
		return true;
		}
		
/* Popup
================================================*/
function popUp (settings){
	var defaultSettings={
		url:'',
		width:500,
		height:500
		};
	settings=concatObjects(settings,defaultSettings);
	
	if (settings.width){
		settings.width+=20;
		}
	if (settings.height){
		settings.height+=20;
		}
	if (settings.content){
		settings.url='';
		}
	POPUP_WIN = window.open(settings.url,'POPUP_WINDOW','menubar=no,directories=no,location=no,resizable=yes,scrollbars=no, toolbar=no, '+(settings.width?'width='+settings.width:'') +','+(settings.height?'height='+settings.height:''));
	if (settings.content){
		if (!POPUP_WIN.document.body) {
			settings.content='<body>'+settings.content+'</body>';
			}
		POPUP_WIN.document.open()
		POPUP_WIN.document.write(

			'<head><title>Полное изображение</title>'
			+'<style type="text/css">A{cursor:pointer;}</style>'
			+'</head>'
			+settings.content
			);
		POPUP_WIN.document.title='Полное изображение';
		POPUP_WIN.document.close();
		}
	return false;

	}

/* iPopup
================================================*/
var ACTIVE_IPOPUP;

	function iPopup(settings){
		this.settings={};
		this.defaultSettings={
			title:'Сообщение',
			html:''
			};
			
		this.__construct=function(settings){			
			this.settings=concatObjects(settings,this.defaultSettings);
			blockScreen();
			this.build();
			ACTIVE_IPOPUP=this;
			}
			
		this.onOKHandler=function(){
			if (this.settings.onOK && typeof this.settings.onOK=='function'){
				if (!this.settings.onOK.call(this)){
					return false;
					}
				}
			this.kill();
			}
		this.onCancelHandler=function(){
			if (this.settings.onCancel && typeof this.settings.onCancel=='function'){
				this.settings.onCancel.call(this);
				}
			this.kill();
			}
		this.onBuildHandler=function(){
			if (this.settings.onBuild && typeof this.settings.onBuild=='function'){
				
				this.settings.onBuild.call(this);
				}
			}
		this.build=function(){
			var html=this.getFullHTML();
			this.block=setChildExt(
				{
					id:'iPopup',
					content:html,
					style:{
						zIndex:101
						},
					className:'iPopup'
					}
				);
			
			if (!this.block){
				return false;
				}
			$id('iPopupButtonOK').iPopup=$id('iPopupButtonCancel').iPopup=this;
			EVENTS.append(
				'iPopupButtonOK',
				'onclick',
				function(){
					this.iPopup.onOKHandler.call(this.iPopup);
					}
				);
			
			EVENTS.append(
				'iPopupButtonCancel',
				'onclick',
				function(){
					this.iPopup.onCancelHandler.call(this.iPopup);
					}
				);	
			//getElementsByTagAndClass(this.block,'DIV','iPopup-title')[0].onmousedown=startDrag(null,this,this.block)
			/* EVENTS.append(
				getElementsByTagAndClass(this.block,'DIV','iPopup-title')[0],
				'onmousedown',
				function(){
					startDrag(null,this,this.block)
					}
				); */
			
			//
			putInScreenCenter(this.block,true);
			this.onBuildHandler();
	
			}
		this.getFullHTML=function(){
			var html=
				'<div class="iPopup-wrap">'
					+'<div class="iPopup-title" onmousedown="startDrag(event,this,\'iPopup\')">'
						+'<h3>'+this.settings.title+'</h3>'
					+'</div>'
					+'<div class="iPopup-content">'
						+this.settings.html
					+'</div>'
					+'<div class="iPopup-floor">'
						+'<button id="iPopupButtonOK">OK</button>'
						+'<button id="iPopupButtonCancel">Cancel</button>'					
					+'</div>'
				+'</div>'
				;
			
			return html;
			}
		this.kill=function(){
			unsetChild(this.block);
			unblockScreen();
			};
		this.disableButtons=function(state){
			if (state!=false){
				state=true;
				}
			var btn;
			if (btn=$id('iPopupButtonOK')){
				btn.disabled=state;
				}
			if (btn=$id('iPopupButtonCancel')){
				btn.disabled=state;
				}
			}
		this.focusBtnOK=function(){
			if (btn=$id('iPopupButtonOK')){
				btn.focus();
				}
			}
		this.focusBtnCancel=function(){
			if (btn=$id('iPopupButtonCancel')){
				btn.focus();
				}
			}
		this.__construct(settings);
		}
	


/* Date prototypes
====================================*/
	var MONTHS=new Array("января","февраля","марта","апреля","мая","июня","июля","августа","сентября","октября","ноября","декабря");
	
	Date.prototype.getReadable=function(isFull){
		var d=this.getDate(),
		m=MONTHS[this.getMonth()],
		y=this.getFullYear(),
		h=this.getHours(),
		i=this.getMinutes(),
		s=this.getSeconds();
		if (d==0 && m==0 && y==0){
			o='?';
			}
		else{
			o=d+'&nbsp;'+m+'&nbsp;'+y;
			if (isFull){
				o+=h+':'+i+':'+s;
				}
			}
		return o;	
		}
	
	Date.prototype.getTimeStamp=function(){
		var d=this.getDate(),
		m=this.getMonth()+1,
		y=this.getFullYear();
		
		if (d<10) d="0"+d;
		if (m<10) m="0"+m;
		//	alert (y);
		return ""+y+m+d+"000000";
		}
	
	Date.prototype.getFromTimeStamp=function(ts){
		ts=ts+"";
		var y=parseInt(ts.substr(0,4)),
		m=parseInt(ts.substr(4,2))-1,
		d=parseInt(ts.substr(6,2));		
		this.setFullYear(y);
		this.setMonth(m);
		this.setDate(d);
		this.setHours(0);
		this.setMinutes(0);
		this.setSeconds(0);	
		return true;
		}
	
	Date.prototype.getFromDT=function(dt){
		dt=dt+"";
		var 
			y=parseInt(dt.substr(0,4)),
			m=dt.substr(5,2)-1,
			d=dt.substr(8,2);	
		this.setFullYear(y);
		this.setMonth(m);
		this.setDate(d);
		this.setHours(0);
		this.setMinutes(0);
		this.setSeconds(0);	
		return this;
		}
	
	Date.prototype.offsetDaysFromDate=function(dt,days){
		var nd=new Date();
		this.setMonth(dt.getMonth());
		this.setFullYear(dt.getFullYear());
		this.setDate(dt.getDate()+days);	
		}

/* Drag
=================================================*/
var isMSIE = document.attachEvent != null;
var isGecko = !document.attachEvent && document.addEventListener;

var DraggingItem = new Object();

function startDrag (event, _this, _targetBlock){
	DraggingItem.This = _this;
	DraggingItem.Target= document.getElementById(_targetBlock);
	DraggingItem.TargetXY=getWhereIs(DraggingItem.Target);
	//alert (DraggingItem.TargetX.left);
	//alert (DraggingItem.Target);

	var position = new Object();
	if (isMSIE)
	{
		
		position.x = window.event.clientX + document.documentElement.scrollLeft + document.body.scrollLeft;
		position.y = window.event.clientY + document.documentElement.scrollTop + document.body.scrollTop;
	}
	if (isGecko)
	{
		
		position.x = event.clientX + window.scrollX;
		position.y = event.clientY + window.scrollY;
	}

	DraggingItem.cursorStartX = position.x;
	DraggingItem.cursorStartY = position.y;
	//alert (DraggingItem.cursorStartX);
	DraggingItem.StartLeft = parseInt (DraggingItem.Target.style.left);
	DraggingItem.StartTop = parseInt (DraggingItem.Target.style.top);

	//alert (DraggingItem.Target.style.top);
	if (isNaN (DraggingItem.StartLeft)) {DraggingItem.StartLeft = DraggingItem.TargetXY.left }
	if (isNaN (DraggingItem.StartTop)) DraggingItem.StartTop = DraggingItem.TargetXY.top;

	if (isMSIE)
	{
		document.attachEvent ("onmousemove", ProceedDrag);
		document.attachEvent ("onmouseup", StopDrag);
		window.event.cancelBubble = true;
		window.event.returnValue = false;
	}
	if (isGecko)
	{
		document.addEventListener ("mousemove", ProceedDrag, true);
		document.addEventListener ("mouseup", StopDrag, true);
		event.preventDefault();
	}
}

function ProceedDrag (event){
	var position = new Object();

	if (isMSIE) {
		position.x = window.event.clientX + document.documentElement.scrollLeft + document.body.scrollLeft;
		position.y = window.event.clientY + document.documentElement.scrollTop + document.body.scrollTop;
	}
	if (isGecko)
	{

		position.x = event.clientX + window.scrollX;
		position.y = event.clientY + window.scrollY;
	}	

	var nextX = DraggingItem.StartLeft + position.x - DraggingItem.cursorStartX;
	if (nextX < -150) nextX = -150;
	DraggingItem.Target.style.left = nextX + "px";

	var nextY = DraggingItem.StartTop  + position.y - DraggingItem.cursorStartY;
	//if (nextY > 600) nextY = 600;
	DraggingItem.Target.style.top = nextY + "px";

	if (isMSIE)
	{
		window.event.cancelBubble = true;
		window.event.returnValue = false;
	}
	if (isGecko) event.preventDefault();
}

function StopDrag (event)
{	
	if (isMSIE)
	{
		document.detachEvent ("onmousemove", ProceedDrag);
		document.detachEvent ("onmouseup", StopDrag);
	}
	if (isGecko)
	{
		document.removeEventListener ("mousemove", ProceedDrag, true);
		document.removeEventListener ("mouseup", StopDrag, true);
	}

	//if (DraggingItem.AfterAction) DraggingItem.AfterAction (DraggingItem.This);

	//SaveDesktop();
}

/* Flash
================================================*/
	function paramString(params){
		if (typeof params!='object'){
			return params;
			}
		var paramsStr='';
		for (var paramName in params){
				paramsStr+=paramsStr?'&amp;':''
				paramsStr+=paramName+'='+params[paramName]
			}
			
		return paramsStr;
		}
	function parseParamString(str){
		var params={};
		var parts=str.split('?').pop().split('&');
		for(var i=0; i<parts.length; i++){
			var part=parts[i].split('=');
			params[part[0]]=part[1];
			}
		return params;
		}
	function buildFlashExt(settings){
		var defaultSettings={
				version:7,
				width:'100%',
				height:'100%',
				name:'flashmovie',
				wmode:'transparent',
				isWrite:true,
				corkImgAlt:''
			};
	
		
		settings=concatObjects(settings,defaultSettings);
		var flashvars=settings.params?paramString(settings.params):'';
		var html='';
		if (!flashChecking.DetectFlashVer(settings.version) ){			
			if (is_function(settings.noFlash)){
				settings.noFlash();
				return false;
				}
			else if (settings.corkImg){
				html='<img src="'+settings.corkImg+'" alt="'+settings.corkImgAlt+'" width="'+settings.width+'" height="'+settings.height+'"  />';
				}			
			}
		else{	
			html=
				BROWSER.isIE?
				'<'+'object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version='+settings.version+',0,0,0" width="'+settings.width+'" height="'+settings.height+'" id="'+settings.name+'"><'+'param name="movie" value="'+settings.src+'"><'+'param name="wmode" value="'+settings.wmode+'" /><'+'param name="quality" value="high"><'+'param name="allowScriptAccess" value="always" /><param name="menu" value="false" /><param name="FlashVars" value="'+flashvars+'" /><'+'/object>'
				:'<'+'embed src="'+settings.src+'" quality="high" wmode="'+settings.wmode+'" width="'+settings.width+'" height="'+settings.height+'" name="'+settings.name+'"  id="'+settings.name+'" menu="false" allowscriptaccess="always" type="application/x-shockwave-flash" pluginspace="http://www.macromedia.com/go/getflashplayer" flashvars="'+flashvars+'"/>';
			}
	
		if (settings.isWrite) {
			document.write(html);
			}
		return html;	
		}
		
		/*Alias for buildFlashExt*/
		function $flash(settings){
			return buildFlashExt(settings);
			}
	
	/*Returns link to flash object */	
	function $flashMovie(name){
		return BROWSER.isIE?window[name]:document[name];
		}

	
	
function playVideo(settings){
	//document.write('<strong>flash version is '+flashChecking.GetSwfVer()+'</strong><br/>');
	if (!flashChecking.DetectFlashVer(8)){
		return false;
		}
	var defaultSettings={
		playerSrc:'/images/swf/players/mediaplayer.swf',
		playerWidth:320,
		playerHeight:240,
		isWrite:false,
		version:8,
		params:{},
		skinSrc:'/images/swf/players/ClearOverPlaySeekMute.swf'
		};
	settings=concatObjects(settings,defaultSettings);
	if (!settings.movieSrc) {
		return false;
		}
	var params=concatObjects(
		{
			file:settings.movieSrc
			},
		settings.params
		),
		html=buildFlashExt(
			{
			width:settings.playerWidth,
			height:settings.playerHeight,
			src:settings.playerSrc,
			params:params,
			isWrite:settings.isWrite,
			version:settings.version
			}
		);
	return html;
	}
	
	
/* Flash Checking
=================================================*/
var flashChecking={
	isIE:(navigator.appVersion.indexOf("MSIE") != -1) ? true : false,
	isWin:(navigator.appVersion.toLowerCase().indexOf("win") != -1) ? true : false,
	isOpera:(navigator.userAgent.indexOf("Opera") != -1) ? true : false,
	ControlVersion:function(){
		var version;
		var axo;
		var e;
	
		// NOTE : new ActiveXObject(strFoo) throws an exception if strFoo isn't in the registry
	
		try {
			// version will be set for 7.X or greater players
			axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.7");
			version = axo.GetVariable("$version");
		} catch (e) {
		}
	
		if (!version)
		{
			try {
				// version will be set for 6.X players only
				axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.6");
				
				// installed player is some revision of 6.0
				// GetVariable("$version") crashes for versions 6.0.22 through 6.0.29,
				// so we have to be careful. 
				
				// default to the first public version
				version = "WIN 6,0,21,0";
	
				// throws if AllowScripAccess does not exist (introduced in 6.0r47)		
				axo.AllowScriptAccess = "always";
	
				// safe to call for 6.0r47 or greater
				version = axo.GetVariable("$version");
	
			} catch (e) {
			}
		}
	
		if (!version)
		{
			try {
				// version will be set for 4.X or 5.X player
				axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.3");
				version = axo.GetVariable("$version");
			} catch (e) {
			}
		}
	
		if (!version)
		{
			try {
				// version will be set for 3.X player
				axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.3");
				version = "WIN 3,0,18,0";
			} catch (e) {
			}
		}
	
		if (!version)
		{
			try {
				// version will be set for 2.X player
				axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash");
				version = "WIN 2,0,0,11";
			} catch (e) {
				version = -1;
			}
		}
		
		return version;
		},
	GetSwfVer:function(){
			// NS/Opera version >= 3 check for Flash plugin in plugin array
			var flashVer = -1;
			
			if (navigator.plugins != null && navigator.plugins.length > 0) {
				if (navigator.plugins["Shockwave Flash 2.0"] || navigator.plugins["Shockwave Flash"]) {
					var swVer2 = navigator.plugins["Shockwave Flash 2.0"] ? " 2.0" : "";
					var flashDescription = navigator.plugins["Shockwave Flash" + swVer2].description;
					var descArray = flashDescription.split(" ");
					var tempArrayMajor = descArray[2].split(".");			
					var versionMajor = tempArrayMajor[0];
					var versionMinor = tempArrayMajor[1];
					var versionRevision = descArray[3];
					if (versionRevision == "") {
						versionRevision = descArray[4];
					}
					if (versionRevision[0] == "d") {
						versionRevision = versionRevision.substring(1);
					} else if (versionRevision[0] == "r") {
						versionRevision = versionRevision.substring(1);
						if (versionRevision.indexOf("d") > 0) {
							versionRevision = versionRevision.substring(0, versionRevision.indexOf("d"));
						}
					}
					var flashVer = versionMajor + "." + versionMinor + "." + versionRevision;
				}
			}
			// MSN/WebTV 2.6 supports Flash 4
			else if (navigator.userAgent.toLowerCase().indexOf("webtv/2.6") != -1) flashVer = 4;
			// WebTV 2.5 supports Flash 3
			else if (navigator.userAgent.toLowerCase().indexOf("webtv/2.5") != -1) flashVer = 3;
			// older WebTV supports Flash 2
			else if (navigator.userAgent.toLowerCase().indexOf("webtv") != -1) flashVer = 2;
			else if ( this.isIE && this.isWin && !this.isOpera ) {
				flashVer = this.ControlVersion();
			}	
			return flashVer;
		},
	 DetectFlashVer:function(reqMajorVer, reqMinorVer, reqRevision){
			versionStr = this.GetSwfVer();
			if (versionStr == -1 ) {
				return false;
			} else if (versionStr != 0) {
				if(this.isIE && this.isWin && !this.isOpera) {
					// Given "WIN 2,0,0,11"
					tempArray         = versionStr.split(" "); 	// ["WIN", "2,0,0,11"]
					tempString        = tempArray[1];			// "2,0,0,11"
					versionArray      = tempString.split(",");	// ['2', '0', '0', '11']
				} else {
					versionArray      = versionStr.split(".");
				}
				var versionMajor      = versionArray[0];
				var versionMinor      = versionArray[1];
				var versionRevision   = versionArray[2];
		
					// is the major.revision >= requested major.revision AND the minor version >= requested minor
				if (versionMajor > parseFloat(reqMajorVer)) {
					return true;
				} else if (versionMajor == parseFloat(reqMajorVer)) {
					if (versionMinor > parseFloat(reqMinorVer))
						return true;
					else if (versionMinor == parseFloat(reqMinorVer)) {
						if (versionRevision >= parseFloat(reqRevision))
							return true;
					}
				}
				return false;
			}
		}
	}
	
	
	