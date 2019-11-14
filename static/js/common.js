
/* Notes in tariffs pages
=================================================*/
function showNote(blockParentID){
	var blockNote=document.getElementById(blockParentID+'note');
	var blockParent=document.getElementById(blockParentID);	
	if ((!(blockNote.style.display))||(blockNote.style.display=='none')){
		if ( navigator.appName == 'Microsoft Internet Explorer' ) {blockNote.style.display='block';} else {blockNote.style.display='table-cell';}
		blockParent.className='noteOn';
		}
	else {
		blockNote.style.display='none';
		blockParent.className='noteOff';
		}	
	return false;
	}

function showOrHideAllNotesByNote(blockParentID){
	var blockNote=document.getElementById(blockParentID+'note');
	var blockParent=document.getElementById(blockParentID);
	
	if ((!(blockNote.style.display))||(blockNote.style.display=='none')) {toDo='show';} else {toDo='hide';}
	
	if (navigator.appName == 'Microsoft Internet Explorer')
	{
		if (toDo=='show') hideAllNotes();
		if (toDo=='hide') showAllNotes();
		
	} else {
		if (toDo=='show') showAllNotes();
		if (toDo=='hide') hideAllNotes();
	}
	}

var win=0;

function popUp (url,w,h) {
	if(win) { 
		if(!win.closed) {win.close();} 
		}	
	w+=20; h+=20;
	win = window.open(url,'winname','menubar=no,directories=no,location=no,resizable=yes,scrollbars=no, toolbar=no, width='+w +',height='+h);
	return false;
	}


	function fullView(init,target,src,w,h,xOffset,yOffset){
		target=target?$id(target):$id(init.childNodes[0])
		if (!src) src=init.href
		var blockNum=1,
		cW=document.body.clientWidth
		if (xOffset==null) {
			xOffset=50;
			}
		if (yOffset==null){
			yOffset=80;
			}
		var blockID="fullpreview_"+blockNum;
		if ($id(blockID)) {
			killFullView(blockID);
			}
		var 
			pos=getWhereIs(target),
			o= '<div class="fv-body">' 
					+'<a onclick="return killFullView(\''+blockID+'\')" title="Картинка закрывается по нажатию">'
					+'<img src="'+src+'" width="'+w+'" height="'+h+'"/>'
					+'</a>'
				+'</div>',
			block=setChild(document.body,blockID,"fullview",'div',o);
		
		if ((pos.left+xOffset+w)>cW && (pos.left+xOffset)>w) {
			xOffset-=w-100;
			}
			
		block.style.left=pos.left+xOffset+"px";
		block.style.top=pos.top+yOffset+"px";
		
		if (block.childNodes[0] && block.childNodes[0].className && block.childNodes[0]=="fv-body") {
			var blockBody=block.childNodes[0]
				blockBody.style.width=w+"px"
				blockBody.style.height=h+"px"
			}
		block.style.width=w+0+"px";
		block.style.height=h+0+"px";
		return false;		
		}
	
	function killFullView(block){
		block=$id(block)
		document.body.removeChild(block)
		return false
		}


/* Whois Drop Down */
	function registerWhoisDropDown(){
		var 
			$field = $('#domain'),
			$btnClose = $('#whois-dd-btn-close'),
			$dd = $('#whois-dropdown'),
			place = function(){
				var offset = $field.offset();
				$dd.css({
					left: offset.left,
					top: offset.top + $field.outerHeight(),
					width: $field.width() + 2
					});
				};
		$field.focus(function(){
			place();
			$dd.show();
			});
		$btnClose.click(function(){
			$dd.hide();
			});
		$dd.appendTo(document.body);
		$(document.body).bind('anyClick',function(e , $target){
			if (!$target.is('#domain,#whois-dropdown,#whois-dropdown *')){
				$dd.hide();
				}
			});
		}
	function showWhoisDropDown(){
		$('#whois-dropdown').show();
		}
	function hideWhoisDropDown(){
		$('#whois-dropdown').hide();
		}
		
/* Banner
=================================================*/
function buildBanner(src,width,height,version){
	$flash(
		{
			src:src,
			width:width||'100%',
			height:height||'100%',
			version:version||7
			}
		);

	return false;	
	}
	
/* Checking domain form
=================================================*/
function checkDomain_handle(){
	var setLink=function(){		
		var zoneName='';
		//analyse checkboxes
		for (i=1; i<=12; i++){
			var chkbox=$id('ch'+i);
			if ( chkbox && chkbox.checked ){ 
				zoneName+='&tld='+chkbox.value; 
				}
			}	
		if (!zoneName) {
			zoneName='&tld=ru';
			}
		$('#toshoplink').attr('href','http://shop.masterhost.ru/domain/?domain='+$('#domain').val()+'&tld='+zoneName);	
		}
		$('#checkdomain-form input[type=checkbox]').click(setLink);
			$('#checkdomain-form input[type=text]').keyup(setLink);
		setLink();
		}
	
	
function changeMode(){
	mode=(mode==1)?2:1;

	var states=new Array();
	states[1]=document.getElementById("state1");
	states[2]=document.getElementById("state2");

	states[1].className="off"; states[2].className="off";
	states[mode].className="on";
	
	labelBlock=document.getElementById("btnLabel");

	labelBlock.innerHTML=lblD[mode];

	return false;
	}


/* iLayers (switching panels)
=================================================*/
	function Layers(block){	
		this.switchLayer1=function(){
			this.obj.layer1.className="on"
			this.obj.layer2.className="off"
			toggleClass(this.obj.h1,1,this.obj.hClasses)
			toggleClass(this.obj.h2,0,this.obj.hClasses)
			/* this.obj.h1.className="on"
			this.obj.h2.className="off" */
			
			this.obj.h1.innerHTML=this.obj.caption1
			this.obj.h2.innerHTML='<a href="#">'+this.obj.caption2+'</a>'
			
			
			this.obj.link2=$tagname("A",this.obj.h2)[0]
			this.obj.link2.obj=this.obj
			this.obj.link2.onclick=this.obj.switchLayer2
	
			
			return false
			}
		this.switchLayer2=function(){
			this.obj.layer2.className="on"
			this.obj.layer1.className="off"
			/* this.obj.h1.className="off"
			this.obj.h2.className="on" */
			toggleClass(this.obj.h1,0,this.obj.hClasses)
			toggleClass(this.obj.h2,1,this.obj.hClasses)
			
			this.obj.h2.innerHTML=this.obj.caption2
			this.obj.h1.innerHTML='<a href="#">'+this.obj.caption1+'</a>'
			this.obj.link1=$tagname("A",this.obj.h1)[0]
			this.obj.link1.obj=this.obj
			this.obj.link1.onclick=this.obj.switchLayer1
			return false
			}
		
		this.init=function(){		
			if (!this.block) return
			this.hClasses=["off","on"]
			
			this.h1=getElementsByTagAndClass(this.block,"H3","on")[0];
				this.caption1=this.h1.innerHTML
			this.h2=getElementsByTagAndClass(this.block,"H3","off")[0];
			this.link2=$id($tagname("A",this.h2)[0]);
				this.link2.obj=this
				this.link2.onclick=this.switchLayer2
			this.caption2=this.link2.innerHTML
				
			this.layer1=getElementsByTagAndClass(this.block,"DIV","on")[0];
			this.layer2=getElementsByTagAndClass(this.block,"DIV","off")[0];
			
			
			}
		this.block=$id(block)
		this.init()	
		}
	
	function iLayers(settings){
		var 
			container,
			defaultSettings={
				},
			switchers=[],
			sets=[],
			active,
			STATE_CLASSES=['off','on'];
		this.__construct=function(settings){
			this.settings=concatObjects(settings,this.defaultSettings);
			this.container=$id(this.settings.container);		
			this.switchers=this.getSwitchers();
			this.processSwitchers();
			this.sets=this.getSets();		
			
			this.init();		
			}
		this.init=function(){
			
			}
			
			
		this.getSwitchers=function(){
			var 
				switchersContainer=getElementsByTagAndClass(this.container,'DIV','tariff-label'),
				switchers=[];
			if (switchersContainer && switchersContainer[0]){
				switchers=$tagname('H3',switchersContainer[0]);
				}
			for (var i in switchers){
				var switcher=switchers[i];
				if (!switcher.className){				
					continue;
					}				
				switcher.isSwitcher=true;
				switcher.active=(switcher.className.search(STATE_CLASSES[1])>=0)?true:false;
				}
			
			return switchers;
			}
			
			
		this.getSets=function(){
			var 
				setContainers=getElementsByTagAndClass(this.container,'DIV','set'),
				setContainer=(setContainers && setContainers[0])?setContainers[0]:null,
				sets=[];	
			if (setContainer){
				sets=getElementsByTagAndClass(setContainer,'DIV','state');			
				}
			for (var i in sets){
				sets[i].isSet=true;
				sets[i].active=(sets[i].className && sets[i].className.search(STATE_CLASSES[1])>=0)?true:false;			
				}
			return sets;
			}
			
		this.processSwitchers=function(){
			for (var i in this.switchers){
				var 
					switcher=this.switchers[i];
				if (!switcher.isSwitcher){				
					continue;
					}
				
				switcher.iLayers=this;
				var 
					strong_=$tagname('STRONG',switcher),
					a_=$tagname('A',switcher),
					captionContainer,
					caption;
				
				
				if (strong_ && strong_[0]){				
					switcher.caption=strong_[0].innerHTML;
					}
				else if (a_ && a_[0]){				
					var a=a_[0];
					switcher.caption=a.innerHTML;
					switcher.link=a.href?a.href:null;				
					a.num=i;
					a.iLayers=this;
					a.onclick=function(){
						this.iLayers.onClickHandler.call(this.iLayers,this.num);
						return false;
						}
					}
				
				
				}
			}
		this.doSwitch=function(activeNum){
			var 
				switcher=this.switchers[activeNum],
				set=this.sets[activeNum];
			for (var i in this.switchers){
				if (!this.switchers[i].isSwitcher){
					continue;
					}
				var 
					switcher=this.switchers[i],
					isActive=(i==activeNum),
					newState=isActive?1:0,
					html=isActive?
						'<strong>'+switcher.caption+'</strong>'
						:
						'<a href='+(switcher.link?switcher.link:'#')+'>'+switcher.caption+'</a>';			
				toggleClass(switcher,newState,STATE_CLASSES);
				switcher.innerHTML=html;			
				switcher.active=isActive;
				}
				
			for (var i in this.sets){
				if (!this.sets[i].isSet){
					continue;
					}
				var 
					set=this.sets[i],
					newState=(i==activeNum)?1:0;
				
				toggleClass(set,newState,STATE_CLASSES);
				}
			this.processSwitchers();
			}
		this.onClickHandler=function(activeNum){
			this.doSwitch(activeNum);
			$(window).resize();
			}	
		this.__construct(settings);
		}
		
		
	function iLayers_handle(){
		$('div.layers').each(
			function(){
				new iLayers({container:this});
				}
			);
		}
		
		
/* Displaying page
====================================*/
	function SitePageBase(){
		this.displayPage=function(html,title,caption){
			var contentBlock=$id("pageContent"),
				captionBlock=$tagname("H1",$id("caption"))

			if (title && !caption){
				caption=title;
				}
				
			$innerHTML(contentBlock, (caption?'<h1>'+caption+'</h1>':'')+ html);
			if (captionBlock && caption){
				captionBlock.innerHTML=caption;
				}
			if (title){
				document.title=title;
				}
			
			}
		this.redirect=function(page){
			if(!page) page="/";
			if (page.search(/^http\:\/\//i)<0){
				if (page.substr(0,1)!='/'){
					page="/"+page;
					}
				//page=SITE_URL+page;
				}
			window.location=page;
			return false;
			}
		this.refresh=function(){
			window.location.reload(false);
			}
		this.initialize();
		}
	SitePageBase.prototype={
		initialize:function(){
			this.putEvents();
			},
		putEvents:function(cnt){			
			var $this=this;		
			if (!cnt){
				cnt=document.body;
				}				
			$('.action',cnt).each(
				function(n){
					var str=searchInClass(this,'action_');
					if (str){
						var parts=str.split('_');							
						if (parts.length==2){
							var params=parts[1].split('.');
							var method='action_'+params.shift();								
							$(this).bind(
								parts[0],
								function(){
									$function(window[method],this,params[1])
									if (this.tagName.toLowerCase()=='a'){											
										return false;
										}
									}
								)
							}
						}
					}
				);				
			}
		}

function action_printPage(a){
	$(document.body).addClass('print-page');
	/*setTimeout(
		function(){
			print();
			},
		200
		);*/
	}
function action_printPageCancel(a){
	$(document.body).removeClass('print-page');
	}
	
var getImgSize=function(src,onready){
	var 
		size={width:0,height:0},
		img=new Image();
	img.onload=function(){
		size.width=this.width;
		size.height=this.height;
		$.isFunction(onready) && onready(size);
		return;
		}
	img.src=src;
	}
/* Main initialize
=================================================*/
;(function($){
    $(function(){
    	
    	/* Gallery */
    	checkDomain_handle();
			iLayers_handle();
			window['SitePage']=new SitePageBase();			
			
			/*Images previews*/
			$('.preview a').add('a.preview').not('a.preview-skip').click(function(){
				var 
					el=$(this),
					full=el.attr('href');
				if (!full || !full.match(/\.(jpg|jpeg|gif|png)$/)){					
					return;
					}				
				var 
					fullId='img-fullview',
					remove=function(){
						$('#'+fullId).remove();
						},
					view=function(size){
						remove();
						$('<img />')
							.attr({
								src:full,
								id:fullId,
								title:'Для закрытия кликните по картинке'
								})
							.css({
								position:'absolute',
								top:Math.round((document.body.scrollTop || document.documentElement.scrollTop || 0)+($(window).height()-size.height)/2),
								left:'50%',
								marginLeft:-Math.round(size.width/2),
								cursor:'pointer'
								})
							.click(remove)
							.appendTo(document.body);
						el.data('_size',size);
						return true;
						}
				el.data('_size') && view(el.data('_size')) || getImgSize(full,view);
				!document._contentsImgPreview && $(document.body).click(remove) && (function(){document._contentsImgPreview=true;})();
				return false;
				});    	
    	
    	
    	/* Tabs */
        $('div.tabs').each(function(){        	
            var 
				defaultEm = 13.8,
                tabs=this,
                w=0,
                offset=2,
                tt=$(this).prev('.tabs-border').find('.tabs-title'),
                em=Math.round(Number((tt.css('fontSize')||'').slice(0,-2)||defaultEm)),
                encodeHash=function(hsh){
                    return 'tab-'+hsh;
                    },
                decodeHash=function(hsh){
                    if (hsh && hsh.charAt(0)=='#'){
                        hsh=hsh.substr(1);
                        }                    
                    if (hsh && hsh.substr(0,4)=='tab-'){                        
                        return hsh.substr(4);
                        }
                    return hsh;
                    };            
            tt.css('fontSize',em+'px');            
            $(this)
                .find('>dl>dd').each(function(){
                    $(this).find('a[rel]').click(function(){
                        $('#'+$(this).attr('rel'),tabs).prev('dt').click();
                        return false;
                        })
                    }).end()
                .find('>dl>dt').eq(0).addClass('first-tab').end() 
                .each(function(){w+=$(this).outerWidth(true)+($.support.htmlSerialize?0:1);})
                .click(function(){
                    $(this).focus(function(){$(this).blur()})                    					.siblings('.active').removeClass('active').filter('dt').find('strong').each(function(){$(this).replaceWith('<a href="javascript:;">'+$(this).html()+'</a>')})
                    .end().end().end()                    
                    .find('a').each(function(){$(this).replaceWith('<strong>'+$(this).html()+'</strong>')}).end()
                    .next('dd').andSelf().addClass('active');
                    
                    var hsh=encodeHash($(this).next('dd').attr('id'));
                    if (hsh){
                        location.hash=hsh;
                        }
                    return false;
                    })    
            .end().prev('.tabs-border').find('.tabs-title').css(
                'paddingLeft',
                (Math.ceil(w/em)+offset)+'em'
                );  
           
            !tt.html() && tt.html('&nbsp;'); 
            location.hash && $('dd#'+decodeHash(location.hash)).prev('dt').click(); 
            });
            
        $(document.body).click(function(e){
        	var target=$(e.target);
        	if (target.is('code, code *')){
        		selectNode(target.closest('code'));
        		}
        	});
        	
        /* Common body click event dispatcher */
		if (!document.body._bodyClickBounded) {
			$('*',document.body).live('mousedown',function(e){
				$(document.body).triggerHandler('anyClick',[$(e.target)]);
				});
			document.body._bodyClickBounded=true;
			}
			
		/* Best choice */
		(function(){
			var 
				$layers = $('.layers'),
				$stables = $layers.find('.servicetable'),
				bcMarginTop = -16,
				bcMarginBottom = -17,
				bcBorderWidth = 3,
				shadowCornerHeight = 78,
				bcPrepare = function($bc){
					
					/* Adding shadow */
					var shadows = {};
					$.each(['tl','tr','r','br','bl','l'],function(){
						shadows[String(this)] = $('<span class="bc-overlay-shadow bc-overlay-shadow-' + String(this) + '" />').appendTo($bc);
						});
					$bc.data('shadows', shadows);
					$bc.data('bcc', $bc.find('>div').eq(0));
					/* Applying base style and show */
					$bc
						.css({
							position: 'absolute'
							})
						.show();
						
					},
				
				bcPlace = function(/* jQuery */$bc, /* jQuery */$ph){
					var
						
						/** @type {jQuery} Top placeholder */
						$tph = $ph.eq(0),
						
						/** @type {jQuery} Bottom placeholder */
						$bph = $ph.eq($ph.size() - 1),
						
						/** @type {jQuery} Content core container */
						$bcc = $bc.data('bcc'),
						
						/** @type {jQuery} Shadows containers */
						shadows = $bc.data('shadows'),
						
						/** @type {Object} */
						tphOffset = $tph.position(),
						
						/** @type {Object) */
						bphOffset = $bph.position(),
						
						/** @type {Number} Top of placeholders */
						t = tphOffset.top,
						
						/** @type {Number} Bottom of placeholders */
						l = bphOffset.left,
						
						/** @type {Number} Width of placeholders */
						w = $tph.outerWidth(),
						
						/** @type {Number} Bottom of placeholders */
						h = bphOffset.top + $bph.outerHeight() - t,
						
						bcTop = t + bcMarginTop,
						bcHeight = h - bcMarginTop - bcMarginBottom,
						bccHeight = $bcc.height(),
						bShadowBottom = - bcMarginBottom + bcBorderWidth - 1;
						
					if (bcHeight - bccHeight < 0){
						bShadowBottom -= (bcHeight - bccHeight);
						bcHeight = bccHeight;
						}					
					$(shadows.bl).add(shadows.br).css('bottom' , bShadowBottom);
					$(shadows.l).add(shadows.r).css('bottom' , bShadowBottom + shadowCornerHeight);
					$bc.css({
						top:t + bcMarginTop,
						left:l,
						width:w,
						height:bcHeight
						});
					}
				
			$stables.each(function(){
				var 
					$stable = $(this),
					$stableWrapper = $stable.closest('.servicetable-wrap'),
					
					/** @type {jQuery} TH & TD of best choice (placeholders to overlay) */
					$ph = $stable.find('th.best-choice,td.best-choice'),
					
					/** @type {jQuery} best choice overlay container */
					$bc = $stableWrapper.find('.bc-overlay');
					
				if (!$ph.size() || !$bc.size()){
					/* There is no best choice in this servicetable */
					return;
					}
				bcPrepare($bc);
				bcPlace($bc , $ph);
				$(window).resize(function(){
					bcPlace($bc , $ph);
					});
				});		
			})();	
			
		/* Tariffs order bonus */
		(function(){
			var 
				cSelector = '.tariff-order-bonus-overlay',
				aSelector = 'a.tariff-order-bonus',
				cMarginLeft = -10, 
				cMarginRight = -10, 
				hideAll = function(){
					$(cSelector).hide();
					},
				prepare = function(/* jQuery */$c , /* jQuery */$a){
					$c.appendTo(document.body);
					$a.data('_cnt' , $c);
					$a.data('_wrap' , $a.closest('.tariff-order-wrap'));
					},
				place = function(/* jQuery */$c , /* jQuery */$a){
					if ($c.is(':visible')){
						var 
							$wrap = $a.data('_wrap'),
							ao = $a.offset(),
							wo = $wrap.offset();
						$c.css({
							top:ao.top + $a.outerHeight(),
							left:wo.left + cMarginLeft,
							width:$wrap.outerWidth() - cMarginLeft -cMarginRight
							});
						
						}
					};
			$(document.body).bind('anyClick',function(e , $target){
				if ($target.is (aSelector)){
					var 
						$c = $target.data('_cnt'),
						_v = false;
					if ($c && $c.size() && $c.is(':visible')){
						_v = true;
						}
					hideAll();
					_v && $c.show() && place($c);
					}
				else if (!$target.is(cSelector + ',' + cSelector+' *')){
					hideAll();
					}
				});
			$(aSelector).click(function(){
				var 
					/** @type {jQuery} Target link */
					$a = $(this),
					
					/** @type {jQuery} Container */
					$c = $a.data('_cnt');
				
				if (!$c || !$c.size()){
					$c = $a.parent().next(cSelector);
					prepare($c , $a);
					
					}
				$c.toggle();
				place($c , $a);
				return false;
				});
			$(window).resize(function(){
				$(aSelector).each(function(){
					var 
						$a = $(this),
						$c = $a.data('_cnt');
					if ($c && $c.is(':visible')){
						place($c , $a);
						}
					});
				});
			})();
			
			
        });
})(jQuery);