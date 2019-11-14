
function isValidEmail(email){
    var RegExp = /^((([a-z]|[0-9]|!|#|$|%|&|'|\*|\+|\-|\/|=|\?|\^|_|`|\{|\||\}|~)+(\.([a-z]|[0-9]|!|#|$|%|&|'|\*|\+|\-|\/|=|\?|\^|_|`|\{|\||\}|~)+)*)@((((([a-z]|[0-9])([a-z]|[0-9]|\-){0,61}([a-z]|[0-9])\.))*([a-z]|[0-9])([a-z]|[0-9]|\-){0,61}([a-z]|[0-9])\.)[\w]{2,4}|(((([0-9]){1,3}\.){3}([0-9]){1,3}))|(\[((([0-9]){1,3}\.){3}([0-9]){1,3})\])))$/
    if(RegExp.test(email)){
        return true;
    }else{
        return false;
    }
}
function checkField(){
    var frm = document.frmValidate;
    var error = "";
    if(!isValidEmail(frm.email.value)){
        error += 'Пожалуйста введите правильный email\n';
    }
    if(!chpass()){
        error += 'Пароли не совпадают\n';
    }
    if(!chlogin()){
        error += 'Пожалуйста введите правильный логин\n';
    }
    if(!checkdblogin()){
        error += 'Пользователь уже существует\n';
    }
    if(error != ""){
        alert(error);
//	tooltip(this,error);
        return false;
    }else{
        return true;
    }
}

function chlogin()
{
    var frm = document.frmValidate, error = "";
    if(!checkLength(frm.login.value,3,50)) 
    {
            error += 'Длина логина должна быть >= 3 and <= 50 символов\n';
    	    alert(error);
	    return false;
    }
            return true;
}


function chpass()
{
    var frm = document.frmValidate, error = "";
    if(!checkLength(frm.pass1.value,8)) 
    {
            error += 'Длина пароля должна быть >= 8 символов\n';
    	    alert(error);
	    return false;
    }
    if (frm.pass1.value == frm.pass2.value && frm.pass1.value)
    {
            return true;
    }

    if (frm.pass1.value != frm.pass2.value && frm.pass2.value)
    {
//	    error += "Password don not match!\n";
//            alert(error);
            return false;
    }
    if (!frm.pass1.value && !frm.pass2.value)
    {
            return false;
    }
    
}

function newpass()
{
    var frm = document.frmValidate, error = "";
    if(frm.pass1.value.length == 0) 
    {
            error += 'Длина пароля должна быть >= 8 символов\n';
    	    alert(error);
	    return false;
    }
    if (frm.pass1.value == frm.pass2.value && frm.pass1.value)
    {
            return true;
    }

    if (frm.pass1.value != frm.pass2.value && frm.pass2.value)
    {
//	    error += "Password don not match!\n";
//            alert(error);
            return false;
    }
    if (!frm.pass1.value && !frm.pass2.value)
    {
            return true;
    }
    
}

function checkLength(text, min, max)
{
    min = min || 1;
    max = max || 1000;
    if (text.length < min || text.length > max) 
    {
	return false;
    }
	 return true;
}

function sreplace()
{
    this.value=this.value.replace(/([^0-9a-zA-z])/g,'');
}


function getsrvnameform()
{
     var objSel1 = document.getElementById("fsvrname");
     objSel1.style.visibility="invisible";
     objSel1.style.value="";
    alert("dwewd");
}

function checkdblogin(str)
{
    var frm = document.frmValidate, error = "";
    var users = frm.users.value;
//    var users = str;
    var user = ".";
    user += frm.login.value;
    user += ".";
    var l = frm.users.value.length;
    
    if(users == 0) 
    {
	return true;
    
    } else {
	if(users.substr(0, l).match(user))
	{
//	    error += "Такой пользователь существует\n";	
//            alert(error);
            return false;
	
	}
    }
    
    return true;
}
function hideconfig()
{
     var objSel1 = document.getElementById("category");
     objSel1.style.visibility="invisible";
     return true;
}
