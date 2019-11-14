var ALERTS=new Array()
function $alert(alertID,msg,msgType,acceptor,target,focused)
{
	this.id=alertID
	this.aBlock=alertBlock(alertID)
	this.acceptor=$id(acceptor)
	this.target=target
	this.focused=$id(focused)
	this.msg=msg
	this.msgType=msgType
	
	
	if (this.focused) this.focused.focus(); 
	
	this.kill=function(){
		var aData=this.aData,
		aBlock=aData.aBlock,
		alertID=aData.id,
		target=aData.target
		ALERTS.splice(alertID,1)
		if (aBlock)	document.body.removeChild(aBlock)
		for (var tNum in target) {
			if (target[tNum]){
				target[tNum].onclick=null;
				target[tNum].onkeydown=null
				}
			}
		if (this.aData.focused) this.aData.focused.focus(); 
	}
	
	this.setPosition=function(){
		var pos=getWhereIs(this.acceptor),
		x=pos.left,
		y=pos.top,
		w=this.aBlock.clientWidth,
		h=this.aBlock.clientHeight
		
		x=x-w
		y=y-h+10
		setPosition(this.aBlock,x,y)
		return false
	}
	
	
	this.setPosition()
	this.aBlock.aData=this
	
	//set events
	this.aBlock.onclick=this.kill
	
	if (this.target.length) {
		for (var tNum in this.target) 
		{
			if (this.target[tNum])
			{
				this.target[tNum].aData=this
				this.target[tNum].onclick=this.kill
				this.target[tNum].onkeydown=this.kill
			}
		}
	}
}

function alertBlock(alertID){
	return $id("alert_"+alertID)
}

function buildAlert(msg,msgType,acceptorID,targetID,focusedID){
	
	//get free alertID
	if (targetID==null && focusedID==null) {targetID=acceptorID; focusedID=acceptorID}
	
	var alertID=1
	while (alertBlock(alertID)) alertID++

	var acceptor=$id(acceptorID),
	target=new Array(),
	focused=$id(focusedID),
	aCoords=getWhereIs(acceptor),
	o='<div class="alert-body">'+
	'<div class="tl"><div class="tr"><div class="bl"><div class="br">'+
	'<div class="alert-cont">'+msg+'</div>'+
	'</div></div></div></div>'+
	'</div>'+
	'<div class="shadow">'+
	'<div class="tr"></div><div class="tl"></div>'+
	'</div>'+
	'<'+'!'+'--[if lte IE 6.5]><iframe id="alert_ifm'+alertID+'"></iframe><![endif]--'+'>',
	alertsOnAcceptor=getAlertsOnAcceptor(acceptor)
	
	if (typeof(targetID)!='object') target.push($id(targetID))
	else for (var tNum in targetID) target[tNum]=$id(targetID[tNum])
	

	
	if (alertsOnAcceptor.length) alertsKillAll(alertsOnAcceptor); 
	
	setChild(document.body,"alert_"+alertID,"alert","DIV",o)
	var aBlock=$id(alertBlock(alertID))
	
	// give sizes to iframe
	if ($id("alert_ifm"+alertID))
	{
		var ifm=$id("alert_ifm"+alertID)
		ifm.style.height=aBlock.clientHeight;
		ifm.style.width=aBlock.clientWidth+6;
	}
	
	
	
	ALERTS[alertID]=new $alert(alertID,msg,msgType,acceptor,target,focused)

	return false
}

function alertsRebuild(){
	for (alertID in ALERTS)
		if (isTrueAlert(ALERTS[alertID]))
			ALERTS[alertID].setPosition()

	
}

function alertsKillAll(alertsToKill){
	if (!alertsToKill) alertsToKill=ALERTS
	for (alertID in alertsToKill)
		if (isTrueAlert(alertsToKill[alertID]))
			alertsToKill[alertID].kill.call(alertsToKill[alertID].aBlock)
			//alert (alertsToKill[alertID].msg)
}

function getAlertsOnAcceptor(acceptor){
	acceptor=$id(acceptor)
	if (!acceptor) return false
	var alertsOnAcceptor=new Array()
	for (alertID in ALERTS)
		if (isTrueAlert(ALERTS[alertID]) && ALERTS[alertID].acceptor==acceptor) alertsOnAcceptor.push(ALERTS[alertID])
			
	return alertsOnAcceptor
}


function isTrueAlert(a)
{
	return (a && typeof(a)=="object" && a.aBlock)
}





GLOBAL_EVENTS.append("onresize","alertsRebuild")

