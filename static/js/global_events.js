/* global window events */
var GLOBAL_EVENTS={
	$onload:new Array(),
	$onresize:new Array(),
	onloadExecute:function(){
		var eData=this.eData
		for (var fNum=0;fNum<eData.$onload.length;fNum++){
				var fName=eData.$onload[fNum].func,
					fParams=eData.$onload[fNum].params
				$function(fName,fParams)				
			}
				
		},
	onresizeExecute:function(){
		var eData=this.eData
		for (var fNum=0;fNum<eData.$onresize.length;fNum++){
				var fName=eData.$onresize[fNum].func,
					fParams=eData.$onresize[fNum].params
				$function(fName,fParams)
			}
				
		},
		
	append:function(eventType,fName,fParams){
		if (!eventType || !this["$"+eventType]) return false
		//alert (eventType+" "+fName)
		this["$"+eventType].push({func:fName,params:fParams})
		return false
		},
	ready:function(){

		window.eData=this
		window.onresize=this.onresizeExecute
		window.onload=this.onloadExecute
		
		
//		var o=''
//		for (var e in window) if (e=='onload') o+=e+="->"+window[e]+" "
//		alert (o)
		}	
}
GLOBAL_EVENTS.ready()

/* //global window events */