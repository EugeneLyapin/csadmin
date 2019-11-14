$(function(){
	var
		toggleSpeed='fast',
		closedClass='payment-item-closed',
		$list=$('#payment-list'),
		$items=$list.find('>li')
			.click(function(e){
				var 
					$target=$(e.target),
					$item=$(this);
				if ($target.is('h3,h3 *') || !isOpen($item)){
					toggle($item);
					}
				}),
		$control=$('#payment-control')
			.click(function(e){
				var 
					$target=$(e.target),
					action=String($target.attr('id')).split('-').pop();
				if ($target.is('span')){
					(action=='show'?
						$items.removeClass(closedClass).find('>div').show():
						$items.addClass(closedClass).find('>div').hide()
						)
					renderControlArea();
					}				
				}),
		renderControlArea=function(){
			var 
				controls=[],
				closedNum=$items.filter('.'+closedClass).size(),
				openedNum=$items.size() - closedNum;
			if (openedNum){
				controls.push('<span class="js-link" id="payment-control-hide">Свернуть всё</span>');
				}
			if (closedNum){
				controls.push('<span class="js-link" id="payment-control-show">Развернуть всё</span>');
				}
			$control.show().html(controls.join('&nbsp;| '));
			},
		toggle=function($item){
			isOpen($item) && 
				$item.addClass(closedClass).find('>div').slideUp(toggleSpeed) || 
				$item.removeClass(closedClass).find('>div').slideDown(toggleSpeed);
			renderControlArea();
			},
		isOpen=function($item){
			return !$item.hasClass(closedClass);
			}
	$items
		.find('>h3')
			.each(function(){
				$(this).html('<span class="payment-item-header-link">'+$(this).html()+'</span><span class="payment-item-bullet">+</span>');
				})
			.css('cursor','pointer')
			.end()		
	var hash=location.hash;
	if (hash && $items.filter(hash).size()){
		$items.filter(':not('+hash+')').addClass(closedClass).find('>div').hide()
		}
	else{
		$items.slice(1).addClass(closedClass).find('>div').hide();
		}
	renderControlArea();
	});
