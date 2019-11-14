(
// Simple wrapper. $ inside this function always points to jQuery.
function($)
{
	var validationTimeoutTime = 100;

	var reNotDigit		= /[^\d]/g;
	var reNotNegDigit	= /\-?[^\d]/g;
	var reNotDomain		= /[^a-zа-я0-9\-\.]|^\-|^\./gi; // enable dash and dot at end of phrase as partially entered domain name.
	var reNotDomainAll	= /[^a-zа-я0-9\-\.]|^\-|^\.|\-$|\.$/gi;
	var reDomainReplacers	= [/(\.)\.+/g];
	var reDash		= /\-/g;
	var reDot		= /\./g;
	var reSpace		= /\s/g;

	var val_map = [];

	var getElValidation = function(el)
	{
		return el;
	};

	var noRegexApprover = function(el, regEx)
	{
		var v = el.value;
		var newv = v.replace(regEx, '');
		if (newv != v)
		{
			el.value = newv;
		}
	};

	var regexReplacer = function(el, regExes)
	{
		var v = el.value;
		var newv = v;
		for (var i = 0; i < regExes.length; i++)
		{
			newv = newv.replace(regExes[i], '$1');
		}
		if (newv != v)
		{
			el.value = newv;
		}
	};

	var intNumberOnlyApprover = function(e)
	{
		noRegexApprover(this, reNotNegDigit);
	};

	var intOnlyApprover = function(e)
	{
		var v = this.value;
		var newv = v;
		if (isNaN(parseInt(newv)))
		{
			newv = '0';
		}
		if (newv != v)
		{
			this.value = newv;
		}
	};

	var digitsOnlyApprover = function(e)
	{
		noRegexApprover(this, reNotDigit);
	};

	var blurPositiveOnlyApprover = function(e)
	{
		var v = this.value;
		var newv = v;
		if (isNaN(parseInt(newv)) || parseInt(newv) <= 0)
		{
			newv = '1';
		}
		if (newv != v)
		{
			this.value = newv;
		}
	};

	var domainApprover = function(e)
	{
		noRegexApprover(this, reNotDomain);
		regexReplacer(this, reDomainReplacers);
	};

	var fullDomainApprover = function(e)
	{
		noRegexApprover(this, reNotDomainAll);
		regexReplacer(this, reDomainReplacers);
	};

	var noDashApprover = function(e)
	{
		noRegexApprover(this, reDash);
	};

	var noDotApprover = function(e)
	{
		noRegexApprover(this, reDot);
	};

	var noSpaceApprover = function(e)
	{
		noRegexApprover(this, reSpace);
	};

	var validate = function(includeBlur)
	{
		for (var i = 0; i < this.validators.length; i++)
		{
			this.validator_cfn = this.validators[i];
			this.validator_cfn();
		}
		if (includeBlur == false) return;
		for (var i = 0; i < this.blurValidators.length; i++)
		{
			this.validator_cfn = this.blurValidators[i];
			this.validator_cfn();
		}
	};

	$.fn.validate = function(completeValidation)
	{
		if (completeValidation == null) completeValidation = true;
		this.each(function()
		{
			if (!this.validators)
			{
				this.validators = [];
				this.blurValidators = [];
			}
			if (!this.validate)
			{
				$.extend(this, { validate: validate });
			}
			this.validate(completeValidation);
		});

		return this;
	};

	var validationTimeout = function()
	{
		var aSelf = this;
		var val = getElValidation(this);
		val.includeBlur = false;
		var callValidator = function()
		{
			val.validatorTimer = null;
			val.validate(val.includeBlur);
		};

		if (val.validatorTimer != null)
		{
			clearTimeout(val.validatorTimer);
			val.validatorTimer = null;
		}
		val.validatorTimer = setTimeout(callValidator, validationTimeoutTime);
	};

	var fullValidationTimeout = function()
	{
		var aSelf = this;
		var val = getElValidation(this);
		val.includeBlur = true;
		var callValidator = function()
		{
			val.validatorTimer = null;
			val.validate(val.includeBlur);
		};

		if (val.validatorTimer != null)
		{
			clearTimeout(val.validatorTimer);
			val.validatorTimer = null;
		}
		val.validatorTimer = setTimeout(callValidator, validationTimeoutTime);
	};

	$.fn.applyValidators_Core = function(typing, blur)
	{
		this
			.each(function()
			{
				var val = getElValidation(this);
				if (!val.validate)
				{
					val.validatorTimer = null;
					val.validators = [];
					val.blurValidators = [];
					$.extend(val, { validate: validate });
				}
				val.validators.push(typing);
				if (blur != null)
				{
					val.blurValidators.push(blur);
				}
			})
			.keypress(validationTimeout)
			.blur(fullValidationTimeout)
			;

		return this;
	}

	$.fn.applyValidators = function()
	{
		$('input.v_number', this).applyValidators_Core(intNumberOnlyApprover, intOnlyApprover);
		$('input.v_digits', this).applyValidators_Core(digitsOnlyApprover, intOnlyApprover);
		$('input.v_positive', this).applyValidators_Core(digitsOnlyApprover, blurPositiveOnlyApprover);
		$('input.v_domain', this).applyValidators_Core(domainApprover, fullDomainApprover);
		$('input.v_nodash', this).applyValidators_Core(noDashApprover);
		$('input.v_nodot', this).applyValidators_Core(noDotApprover);
		$('input.v_nospace', this).applyValidators_Core(noSpaceApprover);

		return this;
	};

	$(document).ready(function()
	{
		$(document.body).applyValidators();
	});
}

) (jQuery);
