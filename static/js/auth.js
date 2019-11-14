function Logout() {
	$.get(
		'/ac/',
		{action : 'user', request : 'logout'},
		function(data) {
			LoadTopData();
			$('#logout-link').empty();
			}
		);
	/*	new Ajax.Request('/ac/', {
		  method: 'get',
		  parameters: {action : 'user', request : 'logout'},
		  onSuccess: function(transport) {
			  LoadTopData();
			  $('logout-link').innerHTML = '';
	      }
    	});*/
		return false;
  }
	  
   function ClientLogin(PU_ID) {
   		var login = $('login_auth').value;
   		var pass  = $('psw_auth').value;
   		// послать запрос на AC, тот должен его обработать и выдать команду на выставление кук.  
   		if (!login || login == '' || !pass || pass == '') {
   		     buildAlert('Не заполнены все поля', 1, 'login_auth');
   		} else {
     		if (login.search(/^c\d+$/) == -1) {
    		     buildAlert('Неправильный логин', 1, 'login_auth');
    		} else {
				new Ajax.Request('/ac/', {
				  method: 'get',
				  requestHeaders: {Accept: 'application/json'},
				  parameters: {action : 'user', request : 'login', login_auth : login, password : pass},
				  onSuccess: function(transport, json) {
						var result = json? json : eval( '(' + transport.responseText + ')');
						if (result.status == 'logged') {
						    killPU(PU_ID);
							LoadTopData();
							$('logout-link').innerHTML = '<a href="#" onclick="return Logout();">Выход</a>';
						} else {
							buildAlert('Ошибка входа в систему', 1, 'login_auth', ['login_auth', 'psw_auth']);
						}
			      }
			    });
			}
   		}
		return false;
   }
   
	function LoadTopData() {
		$.get(
			'/ac/',
			{action : 'user', request : 'reload', tmpl : 'header'},
			function(data){
				$('#top_head_block').html(data);
				}
			);
		/*new Ajax.Request('/ac/', {
		  method: 'get',
		  parameters: {action : 'user', request : 'reload', tmpl : 'header'},
		  onSuccess: function(transport) {
				$('top_head_block').innerHTML = transport.responseText;
		  }
		});*/
		}