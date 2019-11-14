function open_basket_add(v)
{
  window.open(v.href,"","left=300,top=300,height=1,width=1,location=0,menubar=0,scrollbars=0,status=0,titlebar=0,toolbar=0");
  return false;
}
function open_subscr(v)
{
  window.open(v.href,"","left=300,top=300,height=150,width=250,location=0,menubar=0,scrollbars=0,status=0,titlebar=0,toolbar=0");
  return false;
}
function showhide_custom(id)
{
  v=document.getElementById(id);
  if(v) v.style.display=v.style.display=='none'?'block':'none';
  return false;
}
var cat_hidden=0;
function cat_show_hide_pic(e)
{
  cat_hidden=1-cat_hidden;
  var opts=document.getElementsByTagName("div");
  var i;
  for(i=0;i<opts.length;i++) if(opts[i].id=='cat_img')
   if(cat_hidden==0)
    opts[i].style.display='block';
   else
    opts[i].style.display='none';
  return false;
}

function showitem(eThis) {
	if ($(eThis).parent().hasClass('hdn')) {
		$(eThis).parent().removeClass('hdn');
		$(eThis).children('img').attr({src: "/img/deiton/minus.gif", title: "Свернуть", alt: "-"});
	} else {
		$(eThis).parent().addClass('hdn');
		$(eThis).children('img').attr({src: "/img/deiton/plus.gif", title: "Показать", alt: "+"});
	}
	$(eThis).blur();
	return false;
}
