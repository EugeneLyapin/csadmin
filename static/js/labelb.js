(
// Simple wrapper. $ inside always points to jQuery.
function($)
{
	var idprefix = 'class_label_target_id';
	var nextid = 1;

	var findFor = function(context, cls)
	{
		var els = $('.' + cls, context).not('label.class-label').not('label.class-js-label');
		if (els.length == 0) return els;
		return els.eq(0);
	};

	var applyFor = function()
	{
		var otherClass = this.className.replace(/\s*class(\-js)?-label\s*/g, '');
		for (var p = this.parentNode; p != null; p = p.parentNode)
		{
			var jp = $(p);
			var fel = findFor(jp, otherClass);
			if (fel.length == 1)
			{
				var id = fel.attr('id');
				if (!id || id.indexOf(idprefix) == 0)
				{
					var newid = idprefix + nextid++;
					// bugfix for MSIE.
//					fel.attr('id', newid);
					fel.get(0).id = newid;
				}
				$(this).attr('for', fel.attr('id'));
				// bugfix for MSIE.
				this.htmlFor = fel.get(0).id;
				return;
			}
		}
	};

	$.fn.applyClassLabels = function()
	{
		$('label.class-label', this).each(applyFor);
		$('label.class-js-label', this).each(applyFor);

		return this;
	};


	$(document).ready(function()
	{
		$(document.body).applyClassLabels();
	});
}

) (jQuery);
