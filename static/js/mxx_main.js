/* DOM functions
=================================================*/

	function $id(el)
	{	
		var res;
		if (!el) return false;
		res=null;
		if (typeof(el)!="object")
		{
			if (document.getElementById(el)) res=document.getElementById(el);
		} else res=el;
		
		return res;
	}
	
	function $name(el)
	{	
		if (!el) return false;
		var els=new Array();
	
		if (typeof(el)!="object")
		{
			els=document.getElementsByName(el);
		} 
		
		if (els.length!=0) return els;
		else return null;
	}
	
	
	function $tagname(tg,par)
	{	
		if (!tg) return false;
		var els=new Array();
	
		if (par && typeof(par)=="object") els=par.getElementsByTagName(tg);
		else els=document.getElementsByTagName(tg);
		
		if (els.length!=0) return els;
		else return null;
	}
	
	function $value(el)
	{
		var res
		el=$id(el)
		if (!el) return false
		
		res=el.value?el.value:null
		return res
		
	}
	
	function $function(fName,params)
	{
		var res=null,
			paramStr=''
	
		if (params && typeof(params)=='object')
			{
				
				for (var i=0;i<params.length;i++){
					if (paramStr!='') paramStr+=','
					paramStr+=(typeof(params[i])=='string')?'"'+params[i]+'"':params[i]
					}
				//paramStr=params.join(',')
			}
		
			
		if (fName) 
		{
			eval(evalStr='res='+fName+'('+paramStr+')')
		}
		return res
	}
	
	
	
	function setChild(par,elID,elClass,elType,elContent)
	{
		if (!par && !elID) return false;
		
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
		
		return el;
		}
	
	function unsetChild(el){
		if (!el) return false;
		el=$id(el);
		el.parentNode.removeChild(el);
		return true
		}	
	function getElementByTagAndClass(par,elTag,elClass)
	{
		if (!par || !elTag) return false;
	
		par=$id(par);
		var el,elNum,els=new Array(),res=null;
		els=par.getElementsByTagName(elTag);
		if (els.length>0)
		{
			for (elNum in els) {
				el=els[elNum];
				if (el.className && el.className==elClass) res=el;
			}
		}
		
		return res;
	}
	
	function getElementsByTagAndClass(par,elTag,elClass)
	{
		if (!par || !elTag) return false;
	
		par=$id(par);
		var el,elNum,els=new Array(),res=new Array();
		els=par.getElementsByTagName(elTag);
		if (els.length>0)
		{
			for (elNum in els) {
				el=els[elNum];
				if (el.className && el.className==elClass) res.push(el);
			}
		}
		
		return res;
	}


/* AJAX functions
=================================================*/
	function doScript(scriptSRC,params){
			var newScript = document.createElement("SCRIPT"), paramsString="";
			params.from="js";
			for (p in params) {paramsString+=paramsString?"&"+p+"="+params[p]:"?"+p+"="+params[p]}
			scriptSRC+=paramsString;
			newScript.type="text/javascript";
			newScript.src=scriptSRC;   
			document.body.appendChild(newScript);
		}


/* Forms functions
=================================================*/

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
		for (var i=0; i<el.length; i++){
			var iEl=el[i]
			if (iEl.checked) {
				res=iEl.value;
				break
					
				}
			}
		return res
		}




/* String functions
=================================================*/
	function NtoBR(strToClear)
	{
	
		nIndex=strToClear.indexOf('\n');
		while (nIndex>0)
		{
			leftPart=strToClear.substr(0,nIndex);
			rightPart=strToClear.substr(nIndex+1, strToClear.length-1);
			strToClear=leftPart+"<BR>"+rightPart;
			nIndex=strToClear.indexOf("\n");
		}
	
		nIndex=strToClear.indexOf('\r');

		while (nIndex>0)
		{
			leftPart=strToClear.substr(0,nIndex);
			rightPart=strToClear.substr(nIndex+1, strToClear.length-1);
			strToClear=leftPart+rightPart;
			nIndex=strToClear.indexOf("\r");
		}
		
		return strToClear;
	}
	
	function BRtoN(strToClear)
	{
	
		nIndex=strToClear.indexOf('<BR>');
		while (nIndex>0)
		{
			leftPart=strToClear.substr(0,nIndex);
			rightPart=strToClear.substr(nIndex+4, strToClear.length-1);
			strToClear=leftPart+'\n'+rightPart;
			nIndex=strToClear.indexOf("<BR>");
		}
		
		nIndex=strToClear.indexOf('<br>');
		while (nIndex>0)
		{
			leftPart=strToClear.substr(0,nIndex);
			rightPart=strToClear.substr(nIndex+4, strToClear.length-1);
			strToClear=leftPart+'\n'+rightPart;
			nIndex=strToClear.indexOf("<br>");
		}
		
		
		return strToClear;
	}




/* Array functions
=================================================*/
	function in_array(arr,el)
	{
		var res=0
		for (elNum in arr) if (el==arr[elNum]) res++
		return res
	}
	
	

	
	
/* Block screen
=================================================*/
	function blockScreen(){
		if ($id('blockscreen')) return false
		var bs=setChild(document.body,'blockscreen',null,'DIV','<img src="/img/0.gif" alt="" width="1" height="1"/>'),
			over=bs.childNodes[0]
		over.style.height=Math.max(document.documentElement.clientHeight,document.body.clientHeight)+"px"
		over.style.width="100%"
		}
	function unblockScreen(){
		if (!$id('blockscreen')) return false
		unsetChild('blockscreen')
		}


	
	
/* Positioning
=================================================*/

	function getWhereIs(block){
		var blockLeft = 0;
		var blockTop = 0;
			while(block) {
				blockLeft += block.offsetLeft;
				blockTop += block.offsetTop;
				block = block.offsetParent;
			}
			return { left:blockLeft, top:blockTop }
		}
	
	function setPosition(el,x,y){
		el=$id(el)
		if (!el) return false
		
		if (x!=null) el.style.left=x+"px"
		if (y!=null) el.style.top=y+"px"
		
		return false
		}
	
	
	function putInScreenCenter(el,setX){
		
		var winH = (window.opera)? window.innerHeight:document.documentElement.clientHeight,
			winY=(document.all)?document.documentElement.scrollTop:window.pageYOffset,
			elY=Math.round(winY+winH/2-el.clientHeight),
			winW=document.documentElement.offsetWidth,
			elX=setX?Math.round(winW/2-el.offsetWidth/2):null
			//alert (winW)
			if (document.all) elY-=30
			//if (document.all) coreX-=30
			setPosition(el,elX,elY)
		}
		
function toggleVisibility(el,state){
	el=$id(el)
	if (!el) return false
	var stateShow=(document.all && !window.opera)?'block':'table-row',
	states=['none',stateShow],
	state=(state && states[state])?states[state]:((!el.style.display || el.style.display=='none')?states[1]:states[0])
	el.style.display=state
}

		