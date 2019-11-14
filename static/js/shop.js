var timerID = null;
var enable_submittion = true;

function getWhereIs(block)
{
	var blockLeft = 0;
    var blockTop = 0;
        while(block) {
        	blockLeft += block.offsetLeft;
            blockTop += block.offsetTop;
            block = block.offsetParent;
        }
        return { left:blockLeft, top:blockTop }
}

function showNote(evnt)
{
	evnt = evnt || window.event;
    var whatIs = evnt.target || evnt.srcElement;
	var whereIs = getWhereIs(whatIs);
	
	whereIs.left=whereIs.left-noteBlockWidth-2;
	whereIs.top+=0;
	noteBlock.style.left=whereIs.left+'px';
	noteBlock.style.top=whereIs.top+'px';
	noteBlock.style.display='block';
	
	return false;
}


var isMSIE = (document.attachEvent != null);
var isGecko = (!document.attachEvent && document.addEventListener);

var DraggingItem = {};

function startDrag (event, _this, _targetBlock)
{
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

function ProceedDrag (event)
{
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


function PutBack (item)
{
	item.style.zIndex = 2;
}
//alert (document.body.clientWidth);\


function buildPU(init,puid,domainname,domain_number)
{
	var popupID='popup'+puid+(domain_number?('_'+domain_number):'');
	if( $(popupID) ) return false;
	
	var pairs = [];
	$('dns_'+puid+(domain_number?('_'+domain_number):'')).value.split("\n").each( function(pair){
		var tmp = [];
		tmp = pair.split(" ");
		if (tmp.length > 0) pairs.push(tmp);
	});

	var newPU=document.createElement("DIV");
	//alert (init);
	wiInit=getWhereIs(init);

	newPU.setAttribute('id',popupID);
	newPU.setAttribute('class','popup');
	output = '<table class="popup" cellpadding="0" cellspacing="0"><tr><td class="popup-cont"><div class="popup-cont" ><h4 class="popup" onmousedown="startDrag(event,this,\''+popupID+'\');">DNS-серверы для домена <strong>'+domainname+'</strong></h4><div class="popup-body "><table id="popup_table_'+puid+(domain_number?('_'+domain_number):'')+'" class="input"><tr><th class="label">&nbsp;</th><th>Имя</th><th>IP-адрес</th></tr>';
	for(var i=0; i<=Math.max(2,pairs.length); i++){
		var name = '';
		var ip = '';
		if(pairs.length > i ){
			name = pairs[i][0] || '';
			ip = pairs[i][1] || '';
		}
		output += '<tr><td class="label">DNS'+(i+1)+':</td><td class="value"><input name="name" onkeypress="checkPU('+puid +','+domain_number+')" type="text" value="'+name+'" /></td><td class="value"><input type="text" value="'+ip+'" /></td><td class="btn">&nbsp;</td></tr>';
	}
	output += '</table><div class="submit-wide"><div class="submit"><table class="submit-wide"><tr><td><div class="btn short1"><div class="press"><div class="l"><div class="r"><button type="submit" onclick="savePU('+puid+',\''+domainname+'\','+domain_number+');" onfocus="blur();"><b>OK</b></button></div></div></div></div></td><td><div class="btn wide1"><div class="press"><div class="l"><div class="r"><button type="submit" onclick="emptyPU('+puid+','+domain_number+');" onfocus="blur();"><b>Очистить поля</b></button></div></div></div></div></td><td><div class="btn"><div class="press"><div class="l"><div class="r"><button type="submit" onfocus="blur();" onclick="killPU(\''+popupID+'\');"><b>Закрыть</b></button></div></div></div></div></td></tr></table></div></div></div>  </div></td><td class="popup-r">&nbsp;</td></tr><tr><td class="popup-b">&nbsp;</td><td class="popup-br">&nbsp;</td></tr></table><'+'!'+'--[if lte IE 6.5]><iframe></iframe><![endif]--'+'>';

	newPU.innerHTML=output;
	newPU.className="popup";
	
	var cW=document.body.clientWidth,
	cH=document.body.clientHeight;
	winY=(isMSIE)?document.body.scrollTop:window.pageYOffset;
	//alert (cH);

	
	//newPU.style.top=parseInt(cH/2 - newPU.offsetHeight/2)+"px";
	newPU=document.body.appendChild(newPU); 
	newPU.style.left=parseInt(cW/2 - newPU.offsetWidth/2)+"px";
	newPU.style.top=parseInt(wiInit.top - newPU.offsetHeight/2)+"px";
	//alert (newPU.offsetHeight);
	
	return false;
}

function checkPU(puid,domain_number)
{
	alertsKillAll();
	var popupID='popup'+puid+(domain_number?('_'+domain_number):'');
	
	var names = $$('#'+popupID+' input[name="name"]');
	var empty_count = names.length;
	names.each(function(el){if(el.value != '')empty_count--;});
	if(empty_count==0){ 
		var trs = $$('#'+popupID+' table.input tr');
		var last_tr = trs[trs.length - 1];
		var new_tr = last_tr.cloneNode(true);
		var tds = new_tr.childNodes;
		tds[0].innerHTML = 'DNS'+trs.length+':';
		tds[1].childNodes[0].value = '';
		tds[2].childNodes[0].value = '';
		new_tr.id = 'dns_tr_' + Math.random();
		last_tr.parentNode.appendChild(new_tr);
		new_tr.hide();
		Effect.Appear(new_tr.id, { duration: 0.5 });
	}
}

function emptyPU(puid,domain_number)
{
	alertsKillAll();
	var popupID='popup'+puid+(domain_number?('_'+domain_number):'');
	$$('#'+popupID+' input').each(function(input){
		input.value = '';
	});
}

function savePU(puid,domainname,domain_number)
{
	alertsKillAll();
	popupID='popup'+puid+(domain_number?('_'+domain_number):'');
	var inputs = $$('#'+popupID+' input');
	var dns_pairs = [];
	for ( var i = 0; i < inputs.length; i+=2 ){
		var dns_name = inputs[i];
		var dns_ip = inputs[i+1];
		
 		if(!dns_name.id) dns_name.id = 'dns_' + Math.random();
		if(!dns_ip.id) dns_ip.id = 'dns_' + Math.random();
		
		if(dns_name.value != '' || dns_ip.value != '' ){
			if( !/^([\d-a-zа-я]+\.)+(\w{2,4})$/i.test(dns_name.value) ){
				buildAlert("Недопустимое имя", 1, dns_name.id);
				return false;
			}else if( dns_ip.value != '' && !/^(\d{1,3}\.){3}\d{1,3}$/i.test(dns_ip.value) ){
				buildAlert("Недопустимый IP-адрес", 1, dns_ip.id);
				return false;
			}else{
				dns_pairs.push( dns_name.value + (dns_ip.value == ''?'':' ' + dns_ip.value) );
			}
		}
	}
	if(dns_pairs.length == 1){
		buildAlert("Требуется указание хотябы 2х серверов", 1, inputs[0].id);
		return false;
	}else if( dns_pairs.length > 1 ){
		new Ajax.Request('/xml/', {
			method: 'post',
			requestHeaders: {Accept: 'application/json'},
			parameters: {action : 'check', domain_name : domainname, request : 'check_ns', ns : dns_pairs.join("\n") },
			onSuccess: function(transport, json) {
				
				var result = eval( '(' + transport.responseText + ')');
				var dns_name;

				if (result.error == 'ok') {
					$('note_'+puid+(domain_number?('_'+domain_number):'')+'_empty').hide();
					$('note_'+puid+(domain_number?('_'+domain_number):'')).show();
					$('dns_ul_'+puid+(domain_number?('_'+domain_number):'')).innerHTML = '<li>' + dns_pairs.join('</li><li>') + '</li>';
					$('dns_'+puid+(domain_number?('_'+domain_number):'')).value = dns_pairs.join("\n");
					killPU(popupID);
				}else{
					var row = result.number;
					for ( var i = 0; i < inputs.length; i+=2){
						if( inputs[i].value != '' ){
							if(row == 0){
								dns_name = inputs[i];
								break;
							}
							row--;
						}
					}
					buildAlert(result.error, 1, dns_name.id)
				}
			}
		});
		
	}else{
		$('note_'+puid+(domain_number?('_'+domain_number):'')+'_empty').show();
		$('note_'+puid+(domain_number?('_'+domain_number):'')).hide();
		$('dns_ul_'+puid+(domain_number?('_'+domain_number):'')).innerHTML = '';
		$('dns_'+puid+(domain_number?('_'+domain_number):'')).value = '';
		killPU(popupID);
	}
}

function killPU(puid)
{
	alertsKillAll();
	$(puid).remove();
	
	return false
	
}


function buildLogin(init,puid){
	try {
		pageTracker._trackPageview('/basket?checkout=true');
	} catch (err) {}

	var newPU=document.createElement("DIV"),
	wiInit=getWhereIs(init)
	
	if (!puid) puid="login"
	
	var popupID='popup'+puid,
		iframeID='ifm_'+popupID;
	
	if (document.getElementById(popupID)) {
		if (document.getElementById('login_auth')){
			var focusField=document.getElementById('login_auth')
			focusField.focus();
			}	
		return false
		}
	//alert (init);
	

	newPU.setAttribute('id',popupID);
	newPU.className='auth';
var output='<table class="auth" cellpadding="0" cellspacing="0"><tr><td class="auth-cont">'+
'<div class="auth-cont" >'+
	'<h4 class="auth" onmousedown="startDrag(event,this,\''+popupID+'\');">Авторизация</h4>'+
	'<div class="auth-body">'+
		'<div class="note" id="login_for_error">Для использования всех сервисов, вам необходимо пройти авторизацию:</div>'+
		'<form action="" method="POST" id="auth">'+
			'<div class="inputs">'+
				'<label for="login_auth">Логин:</label>'+
				'<input type="text" maxlength="7" id="login_auth" name="login_auth" />'+
			'</div>'+
			'<div class="inputs">'+
				'<label for="psw_auth">Пароль:</label>'+
				'<input type="password" id="psw_auth" name="psw_auth" />'+
			'</div>'+
			'<div class="submit">'+
				'<div class="more">'+
				 '<a href="https://cp.masterhost.ru/cgi-bin/changepass.pl">Забыли пароль?</a>'+
				'</div>'+			
				'<div class="btn"><div class="press"><div class="l"><div class="r">'+
					'<button type="submit" onfocus="blur();" onclick="return ClientLogin(\''+popupID+'\');"><b>OK</b></button>'+
				'</div></div></div></div>'+
				
				'<div class="btn"><div class="press"><div class="l"><div class="r">'+
					'<button onfocus="blur();" onclick="return kill_login_win(\''+popupID+'\')"><b>Отмена</b></button>'+
				'</div></div></div></div>'+
				'<a href="https://cp.masterhost.ru/registration" class="reg">Зарегистрироваться</a>'+
			'</div>'+
		'</form>'+
	'</div>'+
'</div>'+
'</td><td class="auth-r">&nbsp;</td></tr><tr><td class="auth-b">&nbsp;</td><td class="auth-br">&nbsp;</td></tr></table><'+'!'+'--[if lte IE 6.5]><iframe id="'+iframeID+'"></iframe><![endif]--'+'>';
	newPU.innerHTML=output;
	newPU.className="auth";
	
	var cW=document.body.clientWidth,
	cH=document.body.clientHeight,
	winY=(isMSIE)?document.body.scrollTop:window.pageYOffset;
	//alert (cH);


	

	//newPU.style.top=parseInt(cH/2 - newPU.offsetHeight/2)+"px";
	newPU=document.body.appendChild(newPU); 
	newPU.style.left=parseInt(cW/2 - newPU.offsetWidth/2)+"px";
	//newPU.style.top=parseInt(wiInit.top - newPU.offsetHeight/2)+"px";
	newPU.style.top="40px";
	//alert (newPU.offsetHeight)
	
	if (document.getElementById(iframeID))
	{
		var ifm=document.getElementById(iframeID);
		ifm.style.height=newPU.clientHeight;
		ifm.style.width=newPU.clientWidth+4;
	}
	
	var focusField=document.getElementById('login_auth')
	focusField.focus();
	
	
	return false;
}


var win = 0;

function kill_login_win(id) {
	alertsKillAll();
	killPU(id);
	return false;
}

function newin(url)
{
	if(win && !win.closed) win.close();
	w=800; h=400;
	win = window.open(url,'winname','menubar=1,directories=1,location=1,resizable=1,scrollbars=1,toolbar=1, status=1, titlebar=1, width='+w +',height='+h);
	return false;
}

var balloons=new Array();

function isOpenBalloon()
{
	for (var bid=0;bid<balloons.length;bid++){
			if (!balloons[bid]) continue
			if (balloons[bid][1]==1) return true;
		}
	return false;
}



function preBuildBalloon(init,bid, tarif, period, l_tarif, l_period, domain_number)
{
	bid=parseInt(bid);
	
	balloons[bid]=new Array(init,0); //balloons[*][1] - is_balloon_builded flag 
	var timeStop=300; //pause
	timerID=setTimeout("doBuildBalloon("+bid+", "+tarif+", '"+period+"', "+l_tarif+", "+l_period+", '"+domain_number+"')",timeStop);

}

function doBuildBalloon(bid, tarif, period, l_tarif, l_period, domain_number)
{
	clearTimeout(timerID);
	
	//alert (isOpenBalloon());
	if (!isOpenBalloon())
	{
		if (balloons[bid][1]==0) buildBalloon(balloons[bid][0],bid, tarif, period, l_tarif, l_period, domain_number);
	} else {
		if (balloons[bid][1]==0) return;
		//buildBalloonWarn(balloons[bid][0],bid);
	}
}

function freeBuildBalloon(bid, tarif, period, l_tarif, l_period, domain_number)
{
	bid=parseInt(bid);
	if (balloons[bid][1]<1) balloons[bid][1]=-1;
}

function buildBalloon(init,bid, tarif, period, l_tarif, l_period, domain_number)
{
	if (isOpenBalloon()) {
		//buildBalloonWarn(balloons[bid][0],bid);
		return;
	}

    var outText = 'акций нет';
	new Ajax.Request('/xml/', {
	  method: 'get',
	  requestHeaders: {Accept: 'application/json'},
	  parameters: {action : 'get', bid : bid, request : 'promotion_list', tarif : tarif, period : period, l_tarif : l_tarif, l_period : l_period, domain_number: domain_number},
	  onSuccess: function(transport, json) {
		var result = eval( '(' + transport.responseText + ')');
	    outText = result.otext;
 
 		wiInit=getWhereIs(init);
		//alert (wiInit.left+" "+wiInit.top);
		newBln=document.createElement("DIV");
		newBln=document.body.appendChild(newBln);
		newBln.setAttribute("id","balloon"+bid);
		if (result.promo_state == 'on')
		{
			newBln.setAttribute("class","balloon on");
			newBln.className="balloon on";
		} else {
			newBln.setAttribute("class","balloon");
			newBln.className="balloon";
		}
		newBln.innerHTML = outText + '<'+'!'+'--[if lte IE 6.5]><iframe id="ifm'+bid+'"></iframe><![endif]--'+'>';
		
		newBln.style.left=(isMSIE)?parseInt(wiInit.left+5)+"px":parseInt(wiInit.left+4)+"px";
		newBln.style.top=(isMSIE)?parseInt(wiInit.top-newBln.clientHeight+26)+"px":parseInt(wiInit.top-newBln.clientHeight+23)+"px";
		newBln.style.zIndex=100+parseInt(bid);
		
		// give sizes to iframe 
		if (document.getElementById("ifm"+bid))
		{
			ifm=document.getElementById("ifm"+bid);
			ifm.style.height=newBln.clientHeight;
			ifm.style.width=newBln.clientWidth+4;
		}

		//if (!balloons[bid] || balloons[bid][1]==0)
		balloons[bid]=new Array(init,1);
	  }
	});
}


function buildBalloonWarn(init,bid)
{
	var wiInit=getWhereIs(init);
	//alert (wiInit.left+" "+wiInit.top);
	var newBln=document.createElement("DIV");
	newBln=document.body.appendChild(newBln);
	newBln.setAttribute("id","balloon"+bid);
	newBln.setAttribute("class","balloon");
	newBln.className="balloon";
	newBln.innerHTML='<div class="tl"><div class="tr"><div class="content">Закройте остальные окна</div></div></div><div class="bl"><div class="br"><div class="bottom-bar"><a href="#" onclick="return killBalloon('+bid+');">Ok</a></div></div></div><'+'!'+'--[if lte IE 6.5]><iframe id="ifm'+bid+'"></iframe><![endif]--'+'>';
	
	newBln.style.left=parseInt(wiInit.left+7)+"px";
	newBln.style.top=parseInt(wiInit.top-newBln.clientHeight+27)+"px";
	newBln.style.zIndex=100+parseInt(bid);
	
	// give sizes to iframe 
	if (document.getElementById("ifm"+bid))
	{
		ifm=document.getElementById("ifm"+bid);
		ifm.style.height=newBln.clientHeight;
		ifm.style.width=newBln.clientWidth+4;
	}

	balloons[bid]=new Array(init,2);
	timerWarnID=setTimeout("clearTimeout(timerWarnID); killBalloon("+bid+")",1000);
	//alert (balloons[2][1]);
}

function killBalloon(bid)
{
	if (document.getElementById('balloon'+bid))
	{
		var bln=document.getElementById('balloon'+bid);
		document.body.removeChild(bln);
		balloons[bid][1]=-1;
	}
	return false;	
}

function RemovePresentAction(bid, tarif, period, l_tarif, l_period, domain_number)
{
    	var action = $('blnchp'+ bid ).value;
		new Ajax.Request('/xml/', {
		  method: 'get',
		  parameters: {action : 'set', bid : bid, request : 'remove_promotion', tarif : tarif, period : period, promotion: action, domain_number: domain_number },
		  onSuccess: function(transport) {
		    var result = transport.responseText;
		    add_check_selected_tlds_action();
	    	killBalloon(bid);
		    destroy_action_block(tarif, period, result, l_tarif, l_period, domain_number);
		  }
		});

	return false;	
}

function ClosePresentAction(bid, tarif, promo, period)
{
		new Ajax.Request('/xml/', {
		  method: 'get',
		  parameters: {action : 'set', bid : bid, request : 'remove_promotion', tarif : tarif, period : period, promotion: promo },
		  onSuccess: function(transport) {
		    var result = transport.responseText;
		    destroy_action_block(tarif, bid, result);
		  }
		});

	return false;	
}

function SaveBalloon(bid, tarif, period, l_tarif, l_period, domain_number)
{
	if (document.getElementById('balloon'+bid))
	{
    		var ff = document.getElementById('blnch'+bid+'1');
		var action = $CBF('action_ballon', 'blnch'+ bid );
		if(!action) return false;
		var closeButtons = $$('.close-action')
		for (var i = 0; i < closeButtons.length; i++)
		{
			closeButtons[i].onclick();
		}
		new Ajax.Request('/xml/', {
		  method: 'get',
		  parameters: {action : 'set', bid : bid, request : 'set_promotion', tarif : tarif, period : period, promotion: action, l_tarif: l_tarif, l_period: l_period, domain_number: domain_number },
		  onSuccess: function(transport) {
		    var result = transport.responseText;
		    add_check_selected_tlds_action();
		    build_action_block(tarif, period, action, result, l_tarif, l_period, domain_number);
		  }
		});
		var bln=document.getElementById('balloon'+bid);
		document.body.removeChild(bln);
		balloons[bid][1]=-1;
	}
	return false;	
}

function RemoveAction(bid)
{
	if (document.getElementById('balloon'+bid))
	{
		bln=document.getElementById('balloon'+bid);
		document.body.removeChild(bln);
		balloons[bid][1]=-1;
	}
	return false;	
}


function doResize()
{
	//alert (balloons[2][1]);
	for (var bid=0;bid<balloons.length;bid++)
	{
		if (!balloons[bid]) continue
		if (balloons[bid][1]>=1)
		{
			init=balloons[bid][0];
			
			wiInit=getWhereIs(init);
			//alert (wiInit.top);
			bln=document.getElementById("balloon"+bid);
			bln.style.left=(isMSIE)?parseInt(wiInit.left+7)+"px":parseInt(wiInit.left+6)+"px";
			bln.style.top=(isMSIE)?parseInt(wiInit.top-bln.clientHeight+27)+"px":parseInt(wiInit.top-bln.clientHeight+23)+"px";;
		}
	}
}


GLOBAL_EVENTS.append("onresize","doResize");


/* Confirm
=================================================*/
var confirmResult=null
	function doConfirm(msg,onOK,onCancel){
		var confirmID="confirm",
			defaultMessage="Вы уверены?"
		if (!msg) msg=defaultMessage
		if (!confirmID) return 
		
		blockScreen()
		var	o=
			'<table class="popup" cellpadding="0" cellspacing="0">'
+'				<tr>'
+'					<td class="popup-cont">'
+'						<div class="popup-cont">'
+'							<h4 class="popup" onmousedown="startDrag(event,this,\''+confirmID+'\');"><span>Внимание</span></h4>'
+'							<div class="popup-body ">'
+								msg
+'								<div class="submit">'
+'									<table class="submit-wide">'
+'										<tr>'
+'											<td>'
+'												<div class="btn"><div class="press"><div class="l"><div class="r">'
+'												<button type="submit" onfocus="blur()" id="confirmBtnOK"><b>OK</b></button>'
+'												</div></div></div></div>'
+'											</td>'
+'											<td>'
+'												<div class="btn"><div class="press"><div class="l"><div class="r">'
+'												<button type="submit" onfocus="blur();"  id="confirmBtnCancel"><b>Отмена</b></button>'
+'												</div></div></div></div>'
+'											</td>'
+'										</tr>'
+'									</table>'
+'								</div>'
+'							</div>'
+'						</div>'
+'					</td>'
+'					<td class="popup-r">&nbsp;</td>'
+'				</tr>'
+'				<tr>'
+'					<td class="popup-b">&nbsp;</td>'
+'					<td class="popup-br">&nbsp;</td>'
+'				</tr>'
+'			</table><'+'!'+'--[if lte IE 6.5]><iframe></iframe><![endif]--'+'>',
		cBlock=setChild(document.body,confirmID,"popup confirm","DIV",o)
		putInScreenCenter(cBlock,true)
		
		var btnOK=$id('confirmBtnOK'),
			btnCancel=$id('confirmBtnCancel')
			
			btnOK.obj=onOK
			btnCancel.obj=onCancel
			
			btnOK.onclick=doConfirmResult
			btnCancel.onclick=doConfirmResult
			
		var ifm=(ifms=$tagname("IFRAME",cBlock))?ifms[0]:''
		if (ifm){
			ifm.style.height=cBlock.clientHeight;
			ifm.style.width=cBlock.clientWidth+4;			
			}
		return confirmResult
		}
		
	function doConfirmResult(){
		var cBlock=$id('confirm')
		
		unblockScreen()
		unsetChild(cBlock)
		
		if (this.obj){
			if (typeof this.obj =="object")
				$function (this.obj.func,this.obj.params||null)
			else if (typeof this.obj =="string")
				$function (this.obj)
			}
		
		
		
		}


/* Prototype Extensions
=================================================*/

	/* Form extensions
	=================================================*/
	
	
	/**
	 * Returns the value of the selected radio button in the radio group
	 * 
	 * @param {radio Object} or {radio id} el
	 * OR
	 * @param {form Object} or {form id} el
	 * @param {radio group name} radioGroup
	 */
	function $RF(el, radioGroup) {
		if (!el) return false;
		el = $(el);
		if (!el) return false;
		if(el.type == 'radio') {
			var el = el.form;
			if (!el) return false;
			radioGroup = el.name;
		} else if (el.tagName.toLowerCase() != 'form') {
			return false;
		}
		var inputs = el.getInputs('radio', radioGroup);
		if (!inputs) return false;
		for (var i = 0; i < inputs.length; i++)
		{
			if (inputs[i] && inputs[i].checked) return inputs[i].value;
		}
		return false;
	}

	function $CBF(el, checkGroup) {
		if (!el) return false;
		el = $(el);
		if (!el) return false;
		if(el.type == 'checkbox') {
			var el = el.form;
			if (!el) return false;
			checkGroup = el.name;
		} else if (el.tagName.toLowerCase() != 'form') {
			return false;
		}
		var inputs = el.getInputs('checkbox', checkGroup);
		if (!inputs) return false;
		for (var i = 0; i < inputs.length; i++)
		{
			if (inputs[i] && inputs[i].checked) return inputs[i].value;
		}
		return false;
	}

	/* AJAX extensions
	=================================================*/
	
		var indicatorInterval;
		
		Ajax.Request.prototype.respondToReadyState=function(readyState) {
			var state = Ajax.Request.Events[readyState];
			var transport = this.transport, json = this.evalJSON();
		
			if (state == 'Complete') {
			  try {
				this._complete = true;
				(this.options['on' + this.transport.status]
				 || this.options['on' + (this.success() ? 'Success' : 'Failure')]
				 || Prototype.emptyFunction)(transport, json);
			  } catch (e) {
				this.dispatchException(e);
			  }
		
			  if ((this.getHeader('Content-type') || 'text/javascript').strip().
				match(/^(text|application)\/(x-)?(java|ecma)script(;.*)?$/i))
				  this.evalResponse();
			}
		
			try {
			  (this.options['on' + state] || Prototype.emptyFunction)(transport, json);
			  Ajax.Responders.dispatch('on' + state, this, transport, json);
			} catch (e) {
			  this.dispatchException(e);
			}
		
			if (state=='Loading' && !this.options.onLoading && (this.options.indicate==null || this.options.indicate==true)) this.showIndicator(transport)
			if (state == 'Complete') {
			  // avoid memory leak in MSIE: clean up
		
			if (this.isIndicatorOn) this.hideInterval=setTimeout('Ajax.Request.prototype.hideIndicator();  clearInterval(Ajax.Request.prototype.hideInterval)',200)
			  this.transport.onreadystatechange = Prototype.emptyFunction;
			  
			}
		  }
		  
		  
		  
		 Ajax.Request.prototype.placeIndicator=function(){
			var indy=$id('indy')
			if (!indy) 	{this.hideIndicator(); return false}
			
			var	core=indy.childNodes[0]
		
			indy.style.width=document.body.clientWidth+"px"
			indy.style.height=document.body.clientHeight+"px"
		
			putInScreenCenter(core)
		
			//over.style.height=Math.max(document.documentElement.clientHeight,document.body.clientHeight)+"px"
			//over.style.width="100%"
			} 
		  
		  
		 Ajax.Request.prototype.showIndicator=function(transport){
			if ($id('indy')) {return false;}
			var  state=Ajax.Request.Events[transport.readyState]
			if (state!='Loading') {
				this.hideIndicator();
				return false;
				}
			blockScreen()
			this.indy=setChild(document.body,'indy',null,'DIV','<div>Загрузка</div>');
			this.isIndicatorOn=true
			indicatorInterval=setInterval("Ajax.Request.prototype.placeIndicator()",1000)
		
			//alert (document.getElementById("indy").innerHTML)
			}
		
		Ajax.Request.prototype.hideIndicator=function(){
			var indy=$id('indy')
			if (!indy) return false
			unblockScreen()
			//this.placeIndicator=Prototype.emptyFunction
			
			clearInterval(indicatorInterval)
		
			unsetChild(indy)
			this.isIndicatorOn=false
			}
	
	

/* Domain name syntax check
=================================================*/
function check_literal(field, trim, dots_allowed, event) {
  var f = document.getElementById(field);
  if ( trim && ( /^[-\.]+|[-\.]+$/.test(f.value) ) ){
    f.style.backgroundColor = '#FDB4B5';
    f.value = f.value.replace(/^[-\.]+|[-\.]+$/g,"");
    f.value = f.value.replace(/^(..)--+/, "$1-");
    if ( check_literal.t ) clearTimeout(check_literal.t);
    check_literal.t = null;
    check_literal.t = setTimeout("$('"+field+"').style.backgroundColor = '#FFF'",50);
  }
  if( ( dots_allowed && ( ( !/^[\da-z-\.]*$/i.test(f.value) && !/^[\dа-я-\.]*(\.\w+)?$/i.test(f.value) ) || /\.\.+/g.test(f.value) ) ) || 
      ( !dots_allowed && (!/^[\dа-я-]*$/i.test(f.value) && !/^[\da-z-]*$/i.test(f.value)) ) ||
      /^..--/.test(f.value) ){
    f.style.backgroundColor = '#FDB4B5';
    f.value=f.defaultValue;
    if ( check_literal.t ) clearTimeout(check_literal.t);
    check_literal.t = null;
    check_literal.t = setTimeout("$('"+field+"').style.backgroundColor = '#FFF'",50);
  } else {
    f.defaultValue=f.value;
  }
}
check_literal.t = null;

	
/* Domain zones check
=================================================*/
function check_selected_tlds(id, num) {
	var suffix = '';
	if ( num != null ) suffix = '_'+num;

	var tlds = $$('#tlds'+suffix+' input');
	if( id == 'alltld'+suffix ) {
		for(var i = 0; i < tlds.length; i++) {
			var tld = tlds[i];
			var alltld = $(id);
			if( tld.id != 'alltld'+suffix ) tld.checked=alltld.checked;
		}
	}else{
		var checked_count = 0
		for(var i = 0; i < tlds.length; i++) {
			if( tlds[i].id != ('alltld'+suffix) && tlds[i].checked) checked_count++;
		}
		$('alltld'+suffix).checked = checked_count == (tlds.length-1);
	}
}

function add_check_selected_tlds_action(num) {
	var suffix = '';
	if ( num != null ) suffix = '_'+num;
	
	if( !$('tlds'+suffix) ) return ;
	$$('#tlds'+suffix+' input').each(function(tld){
		tld.observe('click', function(event){
			check_selected_tlds(tld.id, num);
		});
	});
}
