jQuery.noConflict();

var constructor;

var client_debug_mode = false;
var cannot_submit = false;

var getActiveInputs = function(parent, issub)
{
	var r = jQuery('input', parent)
		.add(jQuery('select', parent))
		.not(jQuery('input.chapter_activator', parent));
	if (issub)
	{
		r = r.not(jQuery('input.subchapter_activator', parent))
	}
	else
	{
		r = r.not(jQuery('.sub_disable', parent))
	}
	return r;
}

function ServiceInfoBase(instance)
{
	
	this.each = function(list, f, list2)
	{
		for (var i = 0; i < list.length; i++)
		{
			if (list2 != null)
			{
				f(list[i], list2[i]);
			}
			else
			{
				f(list[i]);
			}
		}
	}

	this.findChildren = function(list, service_name)
	{
		var r = [];
		for (var i = 0; i < list.length; i++)
		{
			var childService = list[i];
			if (childService.service_name == service_name)
			{
				r.push(childService);
			}
		}
		return r;
	}

	this.findChildServices = function(service_name)
	{
		return this.findChildren(this.services, service_name);
	}

	this.apply = function()
	{
		if ('applyInfo' in instance)
		{
			instance.applyInfo(this);
		}
		var childApplier = function (s) { s.apply(); };
		this.each(this.services, childApplier);
		if ('domains' in this)
		{
			this.each(this.domains, childApplier);
		}
	}

	this.getInstance = function()
	{
		return instance;
	}
}

function ServiceInfo(instance, name)
{
	this.base = ServiceInfoBase;
	this.base(instance);

	this.service_name = name;
	this.services = [];
}

function makeServiceInfoFromServer(json, oldServiceInfo)
{
	json.base = ServiceInfoBase;
	json.base(oldServiceInfo.getInstance());

	json.each(json.services, makeServiceInfoFromServer, oldServiceInfo.services);
	if ('domains' in json)
	{
		json.each(json.domains, makeServiceInfoFromServer, oldServiceInfo.domains);
	}
}

function constructor_submittion()
{
	jQuery('input.constructor_submit_data').val(json.serialize(constructor.getBasketInfo()));
	return !cannot_submit;
}

function ConstructorChapterBase()
{
	var zones = [
		'.ru', '.net', '.su', '.com', '.org', '.info', '.biz', '.cc', '.name', '.co.uk', '.org.uk'
		];

	var unsupportedRegistrarZones = [
		'.net.ru', '.pp.ru', '.org.ru'
		];

	var _active = true;
	var _activeChain = [];
	var _activeViewsNeededToView = [];

	this.div = jQuery('<div></div>');

	this.addActiveChain = function(piece)
	{
		_activeChain.push(piece);
	}

	this.getActive = function()
	{
		return _active;
	}

	this.getActiveInputs = function()
	{
		return getActiveInputs(this.div, false);
	}

	this.activeChanged = function(newValue)
	{
		var activators = jQuery('input.chapter_activator', this.div);
		if (activators.length > 0)
		{  
			var acvt= activators.get(0);
			var dis = acvt.disabled;
			if (dis && jQuery.browser.msie)
			{
				acvt.disabled = false;
			}
			acvt.checked = newValue;
			if (dis && jQuery.browser.msie)
			{
				acvt.disabled = true;
			}
		}
		var tr = jQuery('tr', this.div);
		var inputs = this.getActiveInputs();
		if (newValue)
		{
			inputs.each(function() { this.disabled = false; });
			tr.addClass('active').removeClass('passive');
			jQuery(':text', inputs).css({color: 'black', backgroundColor: 'white'});
		}
		else
		{
			inputs.each(function() { this.disabled = true; });
			tr.removeClass('active').addClass('passive');
			jQuery(':text', inputs).css({color: '#333', backgroundColor: '#ccc'});
		}
		this.refreshPrice();
		for (var i = 0; i < _activeChain.length; i++)
		{
			_activeChain[i].setActive(newValue);
		}
	}

	this.refreshPrice = function(recursive)
	{
		var totalEl = jQuery('span.total', this.div);
		if (totalEl.length > 0)
		{
			var price = Math.floor(this.getPrice() * USD_TO_RUR * 100 + 0.5) / 100;
			totalEl.html(price.toString());
		}
		if ('owner' in this && !(recursive == false))
		{
			this.owner.refreshTotals();
		}
	}

	this.setActive = function(newValue)
	{
		var oldValue = _active;

		if (newValue != oldValue)
		{
			_active = newValue;
			this.activeChanged(newValue);
		}
	}

	this.toggleActive = function()
	{
		var activators = jQuery('input.chapter_activator', this.div);
		if (activators.length > 0 && activators.get(0).disabled)
		{
			return;
		}
		this.setActive(!this.getActive());
	}

	this.provideGrouping = function()
	{
		if (!('group' in this)) return;
		var aSelf = this;
		var group = this.owner.getChaptersOfGroup(this.group);
		var closer = jQuery('a.closer', this.div);
		if (('minimumOne' in this) && group.length == 1)
		{
			closer.hide();
		}
		else
		{
			closer.show();
		}
		closer.attr('href', 'javascript:;').click(function(evt)
		{
			aSelf.owner.dropChapter(aSelf);
			aSelf.owner = null;
			evt.preventDefault();
		});
	}

	this.isRegister = function()
	{
		return jQuery('input.domain-registration:checkbox', this.div).attr('checked');
	}

	this.getZoneOptions = function(wantedZones)
	{
		var html = [];
		for (var i = 0; i < wantedZones.length; i++)
		{
			var z = wantedZones[i];
			html = html.concat([
				'<option value="', z, '">',
				z,
				'</option>'
				]);
		}
		return html.join('');
	}
		
	this.regenZones = function()
	{
		var zoEl = jQuery('select.zone-options', this.div);
		if (zoEl.length == 0)
		{
			return;
		}
		var activeZone = zoEl.val();
		var wantedZones = [].concat(zones);
		if (this.isRegister())
		{
			for (var i = 0; i < unsupportedRegistrarZones.length; i++)
			{
				if (activeZone == unsupportedRegistrarZones[i])
				{
					activeZone = null;
					break;
				}
			}
		}
		else
		{
			wantedZones = wantedZones.concat(unsupportedRegistrarZones);
		}
		zoEl.html(this.getZoneOptions(wantedZones));
		if (activeZone == null)
		{
			activeZone = zones[0];
		}
		zoEl.val(activeZone);
	};

	this.subChapterChanged = function()
	{
	};

	this.provideHtmlCore = function(id)
	{
		var aSelf = this;
		this.div.html(jQuery('#' + id).html());

		var updatePrice = function()
		{
			aSelf.refreshPrice();
		}

		var toggleSubChapter = function()
		{
			var p = jQuery(this).parents('.subchapter');
			var subInputs = getActiveInputs(p, true);
			var oldEnabled = p.hasClass('subenabled');
			var enabled = !oldEnabled;
			if (enabled)
			{
				subInputs.removeAttr('disabled').removeClass('sub_disable');
				jQuery(':text', subInputs).css({color: 'black', backgroundColor: 'white'});
				jQuery(this).attr('checked', '');
				p.addClass('subenabled');
				jQuery('.subitem', p).addClass('subactive').removeClass('subpassive');
				this.checked = true;
			}
			else
			{
				subInputs.attr('disabled', 'yes').addClass('sub_disable');
				jQuery(':text', subInputs).css({color: '#333', backgroundColor: '#ccc'});
				jQuery(this).removeAttr('checked');
				p.removeClass('subenabled');
				jQuery('.subitem', p).removeClass('subactive').addClass('subpassive');
				this.checked = false;
			}

			aSelf.subChapterChanged();
		}

		var chapter_activator = jQuery('input.chapter_activator', this.div);
		chapter_activator.click(function()
		{
			aSelf.toggleActive();
		});
		jQuery('label.chapter_activator', this.div).click(function()
		{
			aSelf.toggleActive();
		});

		this.provideGrouping();

		var inputs = this.getActiveInputs().not('.domain-name');
		inputs.keypress(updatePrice).change(updatePrice).blur(updatePrice).keyup(updatePrice)
			.focus(function() { this.select(); });
		if (chapter_activator.length > 0) 
		{
			chapter_activator.get(0).checked = aSelf.getActive();
		}

		this.regenZones();

		jQuery('input.subchapter_activator', this.div)
			.removeAttr('checked')
			.parents('.subchapter')
				.addClass('subenabled')
			.end()
			.click(toggleSubChapter)
			.each(toggleSubChapter)
			;

		jQuery('.add_domain_text a', this.div).click(function() {
			constructor.addDomain();
			});

		handleHelpRefs(this.div);

		this.div.applyValidators().applyClassLabels();

		jQuery('a.a-hide-owner-owner', this.div).click(function()
		{
			jQuery(this.parentNode.parentNode.parentNode)
				.queue('fx', [])
				.stop()
				.hide(jQuery.browser.msie ? null : 'slow');
			jQuery('div.switchBlockVisibility').hide().css('visibility', '').show('fast');
		});
	}

	this.provideHtml = function()
	{
	}

	this.getPrice = function()
	{
		return 0;
	}

	this.addServiceInfo = function(result)
	{
	}

	this.addBasketInfo = function(result)
	{
	}

	this.getViewHtmlCore = function(id)
	{
		if (!this.getActive())
		{
			return '';
		}
		if (_activeViewsNeededToView && _activeViewsNeededToView.length > 0)
		{
			var ok = false;
			for (var i = 0; i < _activeViewsNeededToView.length; i++)
			{
				if (_activeViewsNeededToView[i].getActive())
				{
					ok = true;
					break;
				}
			}
			if (!ok)
			{
				return '';
			}
		}
		var el = jQuery('#' + id + '_2');
		var html = (el.length > 0) ? el.html() : '';
		if (html == '')
		{
			return html;
		}
		var r = jQuery(html);
		if (!el.hasClass('nototal'))
		{
			var totalEl = jQuery('span.total', r);
			var price = Math.floor(this.getPrice() * USD_TO_RUR * 100 + 0.5) / 100;
			totalEl.html(price.toString());
			if ('getCount' in this)
			{
				var countEl = jQuery('span.count', r);
				countEl.html(this.getCount().toString());
			}
		}
		return r;
	}

	this.getViewHtml = function(ok)
	{
		return '';
	}

	this.getRegisterData = function()
	{
		return {html: [], price: 0};
	}

	this.isViewOk = function()
	{
		return true;
	}

	this.needActiveViewsToView = function(list)
	{
		_activeViewsNeededToView = list;
	}
}

function StaticChapter(id)
{
	this.base = ConstructorChapterBase;
	this.base();

	this.provideHtml = function()
	{
		return this.provideHtmlCore(id);
	}

	this.getViewHtml = function()
	{
		return this.getViewHtmlCore(id);
	}
}

function BaseServicesChapter()
{
	this.base = StaticChapter;
	this.base('template_general');

	this.getPrice = function()
	{
		return 2;
	}

	this.addServiceInfo = function(result)
	{
		var r = new ServiceInfo(this, 'http');
		result.services.push(r);
	}

	this.addBasketInfo = function(result)
	{
	};
}

function UserQuotaChapter()
{
	this.base = StaticChapter;
	this.base('template_userquota');
	this.setActive(false);

	this.getChosenQuota = function()
	{
		if (!this.getActive())
		{
			return 0;
		}
		var mb = 0;
		var chooser = jQuery('select', this.div);
		if (chooser.length > 0) mb = parseInt(chooser.val());
		return mb;
	}

	this.getPrice = function()
	{
		var mb = this.getChosenQuota();
		return (mb / 50);
	}

	this.addServiceInfo = function(result)
	{
		if (!this.getActive())
		{
			return '';
		}
		var q = this.getChosenQuota();
		if (q <= 0) 
		{
			return;
		}
		var r = new ServiceInfo(this, 'penalty_du');
		r.quota = q;
		// add as http subservice
		result.findChildServices('http')[0].services.push(r);
	}

	this.addBasketInfo = function(result)
	{
		if (!this.getActive())
		{
			return '';
		}
		var q = this.getChosenQuota();
		if (q <= 0) 
		{
			return;
		}
		var r = { name: 'penalty_du', param: q };
		result.order.user.service.push(r);
	}

	this.getViewHtml = function(ok)
	{
		if (!this.getActive())
		{
			return '';
		}
		var r = jQuery(this.getViewHtmlCore('template_userquota'));
		jQuery('span.count', r).html(this.getChosenQuota());

		return r;
	}
}

function MailChapter()
{
}

function MailBaseChapter()
{
	this.base = StaticChapter;
	this.base('template_mailbase');

	this.setActive(false);

	this.getPrice = function()
	{
		if (!this.getActive())
		{
			return 0;
		}
		return 2;
	}

	this.addServiceInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var r = new ServiceInfo(this, 'mailbase');
		result.services.push(r);
	}

	this.addBasketInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
	}
}


function NothingChapter()
{
}
 
function DomainChapter()
{
	this.base = ConstructorChapterBase;
	this.base();

	this.mail = new MailChapter();
	var status = '';
	var aliasStatuses = [];
	var nothing = new NothingChapter();

	var tarif = null;
	var timerId = null;
	var oldName = '';
	var oldReg = false;
	var hasAlerts = false;
	var esc_name = '';

	this.group = 'domain';
	this.minimumOne = true;

	this.dispose = function()
	{
		if (timerId != null)
		{
			clearInterval(timerId);
			timerId = null;
		}
	}

	this.getTarif = function()
	{
		return tarif;
	}

	this.subChapterChanged = function()
	{
		if ('owner' in this)
		{
			this.owner.renewMail();
		}
	}

	this.configureAliases = function()
	{
		var addState = 'visible';
		var aliases = jQuery('.domain-aliases', this.div).children();
		for (var i = 0; i < aliases.length; i++)
		{
			var ctx = aliases[i];
			if (false
				|| jQuery('input.domain-alias-enable:checked', ctx).length == 0
			)
			{
				addState = 'hidden';
				break;
			}
		}
		if (aliases.length > 1)
		{
			jQuery('.remove-alias', aliases).show();
		}
		else
		{
			jQuery('.remove-alias', aliases).hide();
		}
		jQuery('div.add_alias_div', this.div).css('visibility', addState);
		this.hideAlertIfChanged();
	}

	this.addAlias = function()
	{
		var aSelf = this;

		var aliases = this.getAliases();

		var adddata = jQuery(jQuery('#template_domain_alias').html());
		adddata.applyClassLabels().applyValidators();
		handleHelpRefs(adddata);
		var goConfigure = function(e)
		{
			aSelf.configureAliases();
		};
		var activation = function(e)
		{
			var p = jQuery('tr', jQuery(this).parents('table.one-alias-table'));
			var inputs = jQuery('input', p).not(jQuery(this));
			var isActive = p.hasClass('alias-passive');
			this.checked = isActive;
			if (isActive)
			{
				p.removeClass('alias-passive').addClass('alias-active');
				inputs.removeAttr('disabled');
			}
			else
			{
				p.removeClass('alias-active').addClass('alias-passive');
				inputs.attr('disabled', 'yes');
			}
			this.checked = this.checked;
		};
		jQuery('input', adddata).click(goConfigure).keypress(goConfigure).keyup(goConfigure).change(goConfigure).blur(goConfigure);
		jQuery('input.domain-alias-enable', adddata).click(activation);
		jQuery('.domain-aliases', this.div).append(adddata);
		jQuery('a.remove-alias', this.div).not(jQuery('a.remove-alias-ready', this.div)).click(function()
		{
			jQuery(this).parents('.one-alias-table').replaceWith('');
			aSelf.configureAliases();
		}).addClass('remove-alias-ready');
		this.configureAliases();
	}

	this.provideHtml = function()
	{
		var aSelf = this;
		var timer_goConfigure = null;
		
		var regenZones = function()
		{
			aSelf.regenZones();
		};

		var goConfigure = function(e)
		{
			if (timer_goConfigure != null)
			{
				clearTimeout(timer_goConfigure);
			}
			timer_goConfigure = setTimeout(function() { timer_goConfigure = null; constructor.configureDomains(); }, 100);
		};

		this.provideHtmlCore('template_domain');
		jQuery('a.add-alias', this.div).click(function()
		{
			aSelf.addAlias();
		});
		jQuery('a.a-whois', this.div).click(function()
		{
			jQuery('input:hidden', aSelf.div).val(aSelf.getZone().substr(1));
			jQuery('form.form-whois', aSelf.div).submit();
		});
		jQuery('input.domain-name:text', this.div).keyup(goConfigure).keypress(goConfigure).change(goConfigure).blur(goConfigure);
		jQuery('select.domain-name', this.div).each(function()
		{
			this.selectedIndex = 0;
		});
		jQuery('input.domain-registration:checkbox', this.div).click(regenZones).change(regenZones);

		this.addAlias();

		timerId = setInterval(function() { aSelf.configureAliases(); }, 1000);
	};

	var self = this;
	var getSomeViewError = function(status, esc_name)
	{

		var err = '';

		switch (status)
		{
		case 'exist':
			err = 'Домен с таким именем уже существует. Зарегистрировать его нельзя.';
			break;
		case 'notexist':
			err = 'Домен с таким именем не существует. Возможно, Вы забыли добавить галочку &quot;Зарегистрировать&quot;?';
			break;
		case 'invalidname':
			err = '<a target="_blank" href="http://masterhost.ru/service/domain/whois/?domain='+esc_name+'&zone1='+ self.getZone().substr(1) + '">Недопустимое имя домена</a>.';
			break;
		case 'deniedname':
			err = 'Запрещенное имя домена.';
			break;
		}
		return err;
	};

	var getViewError = function()
	{
		return getSomeViewError(status, esc_name);
	};

	var getAliasError = function(index)
	{
		if (index >= aliasStatuses.length) return '';
		return getSomeViewError(aliasStatuses[index]);
	};

	var hasAliasError = function()
	{
		for (var i = 0; i < aliasStatuses.length; i++)
		{
			var err = getAliasError(i);
			if (err != '')
			{
				return true;
			}
		}
		return false;
	};

	this.isViewOk = function()
	{
		return (getViewError() == '') && !hasAliasError();
	};

	this.showDomainViewError = function(err)
	{
		var el = jQuery('input.domain-name:text', this.div).get(0);
		if(!el.id) el.id = 'constr_' + Math.random();
		buildAlert(
			err,
			1,
			el.id
			);
		oldName = this.getName();
		oldReg = this.isRegister();
	};

	this.showAliasViewError = function(index, err)
	{
		var el = jQuery('input.alias-name', this.div).get(index);
		if(!el.id) el.id = 'constr_' + Math.random();
		buildAlert(
			err,
			1,
			el.id
			);
	};

	this.showViewError = function()
	{
		var ALERTS=new Array();
		var err = getViewError();
		if (err != '')
		{
			this.showDomainViewError(err);
		}
		for (var i = 0; i < aliasStatuses.length; i++)
		{
			err = getAliasError(i);
			if (err != '')
			{
				this.showAliasViewError(i, err);
			}
		}
		hasAlerts = true;
	};

	this.getViewHtml = function(ok)
	{
		var r = this.getViewHtmlCore('template_domain');
		jQuery('span.domain-name', r).html(this.getName());
		jQuery('span.domain-zone', r).html(this.getZone());
		if (this.isRegister())
		{
			jQuery('div.domain-register', r).show();
		}
		if (this.isDnsSup())
		{
			jQuery('div.domain-dns-supp', r).show();
		}
		if (this.isCgiPhp())
		{
			jQuery('div.domain-cgi-supp', r).show();
		}
		if (this.isMailIncluded())
		{
			jQuery('div.domain-mail-supp', r).show();
		}
		if (this.getMailCount() > 0)
		{
			jQuery('div.domain-mail-account', r).show();
			jQuery('span.domain-mail-account', r).html(this.getMailCount().toString());
		}
		if (this.getMailListCount() > 0)
		{
			jQuery('div.domain-mail-list', r).show();
			jQuery('span.domain-mail-list', r).html(this.getMailListCount().toString());
		}
		var aliases = this.getAliases();
		var aliasesList = [];
		var dnsAliasesList = [];
		for (var i = 0; i < aliases.length; i++)
		{
			if (aliases[i].enabled && aliases[i].name != '')
			{
				aliasesList.push('<li>' + aliases[i].name + '</li>');
				if (aliases[i].dns)
				{
					dnsAliasesList.push('<li>' + aliases[i].name + '</li>');
				}
			}
		}
		if (aliasesList.length > 0)
		{
			jQuery('div.domain-aliases', r).show();
			jQuery('span.domain-aliases', r).html(aliasesList.length.toString());
			jQuery('div.domain-aliases-list', r).html(
				'<blockquote><ul>' + aliasesList.join('') + '</ul></blockquote>'
				);
		}
		if (dnsAliasesList.length > 0)
		{
			jQuery('div.domain-dns-aliases', r).show();
			jQuery('span.domain-dns-aliases', r).html(dnsAliasesList.length.toString());
			jQuery('div.domain-dns-aliases-list', r).html(
				'<blockquote><ul>' + dnsAliasesList.join('') + '</ul></blockquote>'
				);
		}

		return r;
	}


	this.getRegisterData = function()
	{
		var r = { html: [], price: 0 };
		if (tarif != null && this.isRegister())
		{
			if ('price' in tarif)
			{
				r.price = parseFloat(tarif.price);
			}
			r.html = jQuery(jQuery('#template_domain_registration_2').html());
			jQuery('span.domain-name', r.html).html(this.getName());
			jQuery('span.domain-zone', r.html).html(this.getZone());
			jQuery('span.price', r.html).html(r.price);
			if (('period' in tarif) && ('description' in tarif.period))
			{
				jQuery('span.registration-period', r.html).html(' (' + tarif.period.description + ')');
			}
		}
		return r;
	}

	this.isMailIncluded = function()
	{
		return (jQuery('input.enable_mail', this.div).get(0).checked);
	}

	this.getMailCount = function()
	{
		if (!this.isMailIncluded())
		{
			return 0;
		}
		return parseInt(jQuery('select.mail_count', this.div).val());
	}

	this.getMailListCount = function()
	{
		if (!this.isMailIncluded())
		{
			return 0;
		}
		return parseInt(jQuery('select.maillist_count', this.div).val());
	}

	this.isCgiPhp = function()
	{
		return (jQuery('input.cgi_php', this.div).get(0).checked);
	}

	this.isDnsSup = function()
	{
		return (jQuery('input.dns_sup', this.div).get(0).checked);
	}

	this.getAliases = function()
	{
		var r = [];
		jQuery('.domain-aliases', this.div).children().each(function()
		{
			var name = jQuery('input.alias-name', this).val();
			var enabled = jQuery('input.domain-alias-enable', this).get(0).checked;
			var dns = jQuery('input.dns-alias', this).get(0).checked;
			r.push({name: name, enabled: enabled, dns: dns});
		});
		return r;
	}

	this.getName = function()
	{
		return jQuery('input.domain-name:text', this.div).val();
	};

	this.getZone = function()
	{
		return jQuery('select.domain-name', this.div).val();
	};

	this.addServiceInfo = function(result)
	{
		if (!this.getActive()) return;
		var r = new ServiceInfo(this, 'domain');
		r.name = this.getName(); //    .
		r.domain_param = this.getName();
		r.zone = this.getZone();
		r.register = r.domain_register = this.isRegister();
		var http = new ServiceInfo(nothing, 'http'); //    .
		r.services.push(http);
		var aliases = this.getAliases();
		aliasStatuses = [];
		for (var i = 0; i < aliases.length; i++)
		{
			var n = aliases[i].name;
			if (n != '' && aliases[i].enabled)
			{
				var aliasInfo = new ServiceInfo(nothing, 'alias');
				aliasInfo.name = n; //    .
				aliasInfo.param = n;
				if (aliases[i].dns)
				{
					aliasInfo.dns_alias = 1;
				}
				r.services.push(aliasInfo);
			}
		};
		if (this.isMailIncluded())
		{
			var mailInfo = new ServiceInfo(this.mail, 'mail');
			var mails = this.getMailCount();
			mailInfo.mailaccount_count = mails;
			var mailLists = this.getMailListCount();
			mailInfo.maillist_count = mailLists;
			r.services.push(mailInfo);
		}
		if (this.isDnsSup())
		{
			var dns_sup = new ServiceInfo(nothing, 'dns_sup');
			r.services.push(dns_sup);
		}
		if (this.isCgiPhp())
		{
			var cgi_php = new ServiceInfo(nothing, 'cgi_php');
			r.services.push(cgi_php);
		}
		result.domains.push(r);
	}


	this.addBasketInfo = function(result)
	{
		if (!this.getActive()) return;
		var r = { service: [{name: 'http'}] };
		r.domain_param = this.getName() + this.getZone();
		r.domain_register = this.isRegister() ? 'on' : 'off';
		if (tarif != null)
		{
			r.tarif = tarif;
		}
		r.status = status;
		var aliases = this.getAliases();
		for (var i = 0; i < aliases.length; i++)
		{
			var n = aliases[i].name;
			if (n != '' && aliases[i].enabled)
			{
				var aliasInfo = { name: 'alias', param: n };
				if (aliases[i].dns)
				{
					aliasInfo.dns_alias = 1;
				}
				r.service.push(aliasInfo);
			}
		};
		if (this.isMailIncluded())
		{
			var mailInfo = { name: 'mail', mailaccount_count: this.getMailCount(), maillist_count: this.getMailListCount() };
			r.service.push(mailInfo);
		}
		if (this.isDnsSup())
		{
			var dns_sup = {name: 'dns_sup'};
			r.service.push(dns_sup);
		}
		if (this.isCgiPhp())
		{
			var cgi_php = {name: 'cgi_php'};
			r.service.push(cgi_php);
		}
		result.order.domains.push(r);
	}

	this.getPrice = function()
	{
		if (!this.getActive()) return 0;
		var r = 0;
		if (this.isMailIncluded())
		{
			var index = this.owner.getMailedDomainIndex(this);
			if (index >= PREPAID_DOMAIN_COUNT)
			{
				r += 1;
			}
		}		
		r += this.getMailCount() / 10;
		r += this.getMailListCount() * 3;
		if (this.isCgiPhp())
		{
			r += 2;
		}
		if (this.isDnsSup())
		{
			var index = this.owner.getDnsSupDomainIndex(this);
			if (index >= PREPAID_DOMAIN_COUNT)
			{
				r += 1;
			}
		}		
		var index = this.owner.getActiveDomainIndex(this);
		if (index >= PREPAID_DOMAIN_COUNT)
		{
			r += 0.5;
		}
		return r;
	}

	this.applyInfo = function(sinfo)
	{
		tarif = null;
		status = sinfo.status;
		aliasStatuses = [];
		esc_name = '';
		if ('domain_esc' in sinfo)
		{
			esc_name = sinfo.domain_esc;
		}
		for (var i = 0; i < sinfo.services.length; i++)
		{
			var svc = sinfo.services[i];
			if (svc.service_name != 'alias') continue;
			aliasStatuses.push(svc.status);
		}
		if ('tarif' in sinfo)
		{
			tarif = sinfo.tarif;
		}
		
	}

	this.isDataValid = function()
	{
		if (!this.getActive())
		{
			return true;
		}
		if (this.getName() == '')
		{
			return false;
		}
		var aliases = this.getAliases();
		for (var i = 0; i < aliases.length; i++)
		{
			if (aliases[i].enabled && aliases[i].name == '')
			{
				return false;
			}
		}
		return true;
	}

	this.hideAlertIfChanged = function()
	{
		if (!hasAlerts) return;
		var newName = this.getName();
		var newReg = this.isRegister();
		if (oldName != newName || oldReg != newReg)
		{
			alertsKillAll(getAlertsOnAcceptor(jQuery('input.domain-name:text', this.div).get(0)));

			oldName = newName;
			oldReg = newReg;
			hasAlerts = false;
		}
	}

}

function MySqlDatabaseChapter()
{
	this.base = StaticChapter;
	this.base('template_mysql_database');

	this.setActive(false);

	this.getCount = function()
	{
		return parseInt(jQuery('input.mysqldb_count', this.div).val());
	}

	this.getPrice = function()
	{
		if (!this.getActive()) 
		{
			return 0;
		}
		var c = this.getCount();
		if (c <= PREPAID_MYSQL_COUNT) 
		{
			return 0;
		}
		return (c - PREPAID_MYSQL_COUNT) * 0.5;
	}

	this.addServiceInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var count = this.getCount();
		if (isNaN(count) || count <= 0) 
		{
			return;
		}
		var r = new ServiceInfo(this, 'mysqldb');
		r.count = count;
		result.services.push(r);
	}

	this.addBasketInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var count = this.getCount();
		if (isNaN(count) || count <= 0) 
		{
			return;
		}
		var r = {name: 'mysqldb', count: count };
		result.order.user.service.push(r);
	}
}

function MySqlLoginChapter()
{
	this.base = StaticChapter;
	this.base('template_mysql_login');

	this.setActive(false);

	this.getCount = function()
	{
		return parseInt(jQuery('input.mysql_count', this.div).val());
	}

	this.getPrice = function()
	{
		if (!this.getActive()) return 0;
		return this.getCount() * 4;
	}

	this.addServiceInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var count = this.getCount();
		if (isNaN(count) || count <= 0) 
		{
			return;
		}
		var r = new ServiceInfo(this, 'mysqllogin');
		r.count = count;
		result.services.push(r);
	}

	this.addBasketInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var count = this.getCount();
		if (isNaN(count) || count <= 0) 
		{
			return;
		}
		var r = {name: 'mysql', count: count };
		result.order.user.service.push(r);
	}
}


function MailQuotaChapter()
{
	this.base = StaticChapter;
	this.base('template_mailquota');

	this.setActive(false);

	this.getCount = function()
	{
		return parseInt(jQuery('select.mailquota_count', this.div).val());
	}

	this.getPrice = function()
	{
		if (!this.getActive()) return 0;
		return this.getCount() / 50;
	}

	this.addServiceInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var count = this.getCount();
		if (isNaN(count) || count <= 0) 
		{
			return;
		}
		var r = new ServiceInfo(this, 'mailquota');
		r.count = count;
		result.services.push(r);
	}

	this.addBasketInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var count = this.getCount();
		if (isNaN(count) || count <= 0) 
		{
			return;
		}
		var r = {name: 'mailquota', param: count};
		result.order.user.service.push(r);
	}

	this.getViewHtml = function(ok)
	{
		if (!this.getActive())
		{
			return '';
		}
		var r = jQuery(this.getViewHtmlCore('template_userquota'));
		jQuery('span.count', r).html(this.getCount());

		return r;
	}
}

function FtpChapter()
{
	this.base = StaticChapter;
	this.base('template_ftp');

	this.setActive(false);

	this.getCount = function()
	{
		return parseInt(jQuery('input.ftp_count', this.div).val());
	}

	this.getPrice = function()
	{
		if (!this.getActive()) return 0;
		var count = this.getCount();
		if (count <= 2) return 0;
		return (count - 2) * 0.5;
	}

	this.addServiceInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var count = this.getCount();
		if (isNaN(count) || count <= 0) 
		{
			return;
		}
		var r = new ServiceInfo(this, 'ftp');
		r.count = count;
		result.services.push(r);
	}

	this.addBasketInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var count = this.getCount();
		if (isNaN(count) || count <= 0) 
		{
			return;
		}
		var r = {name: 'ftp', count: count};
		result.order.user.service.push(r);
	}
}

function SshChapter()
{
	this.base = StaticChapter;
	this.base('template_ssh');

	this.setActive(false);

	this.getPrice = function()
	{
		if (!this.getActive()) return 0;
		return 1;
	}

	this.addServiceInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var r = new ServiceInfo(this, 'ssh');
		result.services.push(r);
	}

	this.addBasketInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var r = {name: 'ssh'};
		result.order.user.service.push(r);
	}
}

function StatChapter()
{
	this.base = StaticChapter;
	this.base('template_stat');

	this.setActive(false);

	this.getPrice = function()
	{
		if (!this.getActive()) return 0;
		return 0.5;
	}

	this.addServiceInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var r = new ServiceInfo(this, 'stat');
		result.services.push(r);
	}

	this.addBasketInfo = function(result)
	{
		if (!this.getActive())
		{
			return;
		}
		var r = {name: 'u_stat'};
		result.order.user.service.push(r);
	}
}

function FloatPriceChapter()
{
	this.base = StaticChapter;
	this.base('template_floatprice');

	this.getActiveInputs = function()
	{
		return jQuery('#no-element-of-this-id');
	}

	this.setActive(false);
	this.div.css('position', 'absolute');
}

function FooterChapter()
{
	this.base = StaticChapter;
	this.base('template_footer');
	var $ = jQuery;
	
	this.baseGetViewHtml = this.getViewHtml;

	this.provideHtml = function()
	{
		var r = this.provideHtmlCore('template_footer');
		$('div.text ul.list-0 li', $('#template_footer')).removeAttr('id');
		$('div.text ul.list-0 li a', $('#template_footer')).removeAttr('name');
		return r;
	}


	this.getViewHtml = function(ok)
	{
		if (!ok) return $('#template_footer_error_view').html();
		var html = $(this.baseGetViewHtml(ok));
		$('input.tracker_code', html).val(tracker_id);
		return html;
	}
}

function Constructor()
{
	var aSelf = this;
	var ready = false;

	var header = new StaticChapter('template_header');
	var footer = new FooterChapter();
	var baseServices = new BaseServicesChapter();
	var userQuota = new UserQuotaChapter();
	var domainSupportHeader = new StaticChapter('template_domain_support_header');
	var domainSupportFooter = new StaticChapter('template_domain_support_footer');
	var mailHeader = new StaticChapter('template_mail_header');
	var mailbase = new MailBaseChapter();
	var mailquota = new MailQuotaChapter();
	var accessHeader = new StaticChapter('template_access_header');
	var ftp = new FtpChapter();
	var ssh = new SshChapter();
	var stat = new StatChapter();
	var mysqlHeader = new StaticChapter('template_mysql_header');
	var mySqlDatabase = new MySqlDatabaseChapter();
	var mySqlLogin = new MySqlLoginChapter();
	var totals = new StaticChapter('template_totals');
	var floatPrice = new FloatPriceChapter();
	var calcTotals = {usd: 0, rur: 0};

	mySqlDatabase.addActiveChain(mySqlLogin);
	mySqlLogin.addActiveChain(mySqlDatabase);

	mailHeader.needActiveViewsToView([mailbase, mailquota]);
	accessHeader.needActiveViewsToView([ftp, ssh, stat]);
	mysqlHeader.needActiveViewsToView([mySqlDatabase, mySqlLogin]);

	var chapters = [
		header, 
		baseServices, 
		userQuota, 
		domainSupportHeader, 
		domainSupportFooter, 
		mailHeader, 
		mailbase,
		mailquota,
		accessHeader, 
		ftp,
		ssh,
		stat,
		mysqlHeader, 
		mySqlDatabase,
		mySqlLogin,
		totals,
		footer,
		floatPrice
		];

	var dropper = jQuery('<div></div>');

	this.provideOwner = function()
	{
		for (var i = 0; i < chapters.length; i++)
		{
			var chapter = chapters[i];
			chapter.owner = this;
		}
	}

	this.provideOwner();

	this.provideHtml = function()
	{
		for (var i = 0; i < chapters.length; i++)
		{
			var chapter = chapters[i];
			if (!('rendered' in chapter))
			{
				chapter.provideHtml();
				chapter.rendered = true;
			}
		}
	}

	this.setupChaptersHtml = function()
	{
		dropper.append(this.div.children());
		for (var i = 0; i < chapters.length; i++)
		{
			this.div.append(chapters[i].div);
		}
	}

	this.render = function()
	{
		this.setupChaptersHtml();
		this.provideHtml();
	}

	this.afterConstruction = function()
	{
		var getWindowWidth = function()
		{
			if (typeof(window.innerWidth) == 'number')
			{
				//Non-IE
				return window.innerWidth;
			}
			else if (document.documentElement && (document.documentElement.clientWidth || document.documentElement.clientHeight))
			{
				//IE 6+ in 'standards compliant mode'
				return document.documentElement.clientWidth;
			}
			else if (document.body && (document.body.clientWidth || document.body.clientHeight))
			{
				//IE 4 compatible
				return document.body.clientWidth;
			}
			return 0;
		}

		var getScrollY = function()
		{
			return jQuery.browser.msie ? document.documentElement.scrollTop : window.pageYOffset;
		};

		floatPrice.div
			.css('position', 'absolute')
			.css('top', '0px')
			.css('left', '0px')
			.css('left', (getWindowWidth() - 300 - this.div.offset().left) + 'px')
			.draggable()
			.get(0).className = 'summ-float';				
			;
		if (jQuery.browser.msie)
		{
			floatPrice.div.bgiframe();
		}
		var yShift = 0;
		var osy = -1;
		setInterval(function()
		{
			var nsy = getScrollY();
			if (osy != nsy)
			{
				var newPos = nsy + yShift;
				floatPrice.div
					.queue('fx', [])
					.stop();
				if (osy != -1)
				{
					if (Math.abs(nsy - osy) > 250)
					{
						if (nsy > osy)
						{
							osy = nsy - 250;
						}
						else
						{
							osy = nsy + 250;
						}
						floatPrice.div.css('top', (osy + yShift).toString() + 'px');
					}
					floatPrice.div.animate({top: newPos.toString() + 'px'}, 'normal', 'swing');
				}
				else
				{
					floatPrice.div.css('top', newPos.toString() + 'px');
				}
			}
			osy = nsy;
		}, 200);
		jQuery('div.switchBlockVisibility a').click(function()
		{
			jQuery('div.switchBlockVisibility').css('visibility', 'hidden');
			floatPrice.div
				.queue('fx', [])
				.stop()
				.show(jQuery.browser.msie ? null : 'slow');
		});
		ready = true;
		this.configureDomains();
	}

	this.getChaptersOfGroup = function(group)
	{
		var r = [];
		for (var i = 0; i < chapters.length; i++)
		{
			var chapter = chapters[i];
			if (('group' in chapter) && chapter.group == group)
			{
				r.push(chapter);
			}
		}
		return r;
	}

	this.dropChapter = function(chapterToDrop)
	{
		if ('dispose' in chapterToDrop)
		{
			chapterToDrop.dispose();
		}
		var newChapters = [];
		for (var i = 0; i < chapters.length; i++)
		{
			var chapter = chapters[i];
			if (chapter != chapterToDrop)
			{
				newChapters.push(chapter);
			}
			else
			{
				dropper.append(chapterToDrop.div);
				delete chapterToDrop.owner;
				delete chapterToDrop.div;
			}
		}
		chapters = newChapters;
		for (var i = 0; i < chapters.length; i++)
		{
			var chapter = chapters[i];
			chapter.provideGrouping();
		}
		dropper.empty();
		this.configureDomains();
	}

	this.addChapter = function(chapterToAdd, beforeChapter)
	{
		var newChapters = [];
		for (var i = 0; i < chapters.length; i++)
		{
			var chapter = chapters[i];
			if (chapter == beforeChapter)
			{
				chapterToAdd.owner = this;
				newChapters.push(chapterToAdd);
			}
			newChapters.push(chapter);
		}
		chapters = newChapters;
		this.render();
	}

	this.getServiceInfo = function()
	{
		var result = new ServiceInfo(this, 'all_services');
		result.domains = [];
		for (var i = 0; i < chapters.length; i++)
		{
			chapters[i].addServiceInfo(result);
		}
		return result;
	}

	this.getBasketInfo = function()
	{
		var result = { order: { user: { plan: 'constructor', sum: calcTotals.usd, sum_rub: calcTotals.rur, service: [] }, domains: [] } };
		for (var i = 0; i < chapters.length; i++)
		{
			chapters[i].addBasketInfo(result);
		}
		return result;
	}

	this.addDomain = function()
	{
		var domains = this.getChaptersOfGroup('domain');
		this.addChapter(new DomainChapter(), domainSupportFooter);
		this.configureDomains();
	}

	this.configureDomains = function()
	{
		if (!ready) return;
		if (jQuery.browser.msie)
		{
			jQuery('input.v_domain').validate(false);
		}
		var domains = this.getChaptersOfGroup('domain');
		var addState = 'visible';
		var canSecondStep = true;
		var activeCount = 0;
		var dns_sup = jQuery('input.dns_sup', domains[0].div).get(0);
		if (domains.length == 1)
		{
			dns_sup.checked = true;
			dns_sup.disabled = true;
			if(!domains[0].getActive())
			{
				if (jQuery.browser.msie)
				{
					jQuery('input.chapter_activator', domains[0].div).get(0).disabled = false;
				}
				domains[0].setActive(true);
				if (jQuery.browser.msie)
				{
					jQuery('input.chapter_activator', domains[0].div).get(0).disabled = true;
				}
			}
		}
		else
		{
			dns_sup.disabled = false;
		}
		for (var i = 0; i < domains.length; i++)
		{
			var d = domains[i];
			jQuery('input.chapter_activator', d.div).get(0).disabled = (domains.length < 2);
			var closer = jQuery('a.closer', d.div);
			if (domains.length < 2) 
			{
				closer.hide();
			}
			else
			{
				closer.show();
			}
			canSecondStep &= d.isDataValid();
			if (!d.getActive())
			{
				addState = 'hidden';
			}
			else
			{
				activeCount++;
				d.refreshPrice(false);
			}
		}
		canSecondStep &= (activeCount > 0);
		jQuery('div.add_domain_text').css('visibility', addState);
		var toSecondStep = jQuery('input.toSecondStep', this.div);
		var notifySecondStep = jQuery('div.nextlink-notify', this.div);
		if (canSecondStep)
		{
			toSecondStep.removeAttr('disabled').each(function()
			{
				this.disabled = false;
			});
			notifySecondStep.hide();
		}
		else
		{
			toSecondStep.attr('disabled', 'yes').each(function()
			{
				this.disabled = true;
			});
			notifySecondStep.show();
		}
		this.refreshTotals();
	}

	this.getMailedDomainIndex = function(domainChapter)
	{
		var index = 0;
		var domains = this.getChaptersOfGroup('domain');
		for (var i = 0; i < domains.length; i++)
		{
			if (domains[i] == domainChapter)
			{
				return index;
			}
			if (domains[i].getActive() && domains[i].isMailIncluded())
			{
				index++;
			}
		}
		return -1;
	}

	this.getDnsSupDomainIndex = function(domainChapter)
	{
		var index = 0;
		var domains = this.getChaptersOfGroup('domain');
		for (var i = 0; i < domains.length; i++)
		{
			if (domains[i] == domainChapter)
			{
				return index;
			}
			if (domains[i].getActive() && domains[i].isDnsSup())
			{
				index++;
			}
		}
		return -1;
	}

	this.getActiveDomainIndex = function(domainChapter)
	{
		var index = 0;
		var domains = this.getChaptersOfGroup('domain');
		for (var i = 0; i < domains.length; i++)
		{
			if (domains[i] == domainChapter)
			{
				return index;
			}
			if (domains[i].getActive())
			{
				index++;
			}
		}
		return -1;
	}

	this.refreshTotals = function()
	{
		var usd = 0;
		var additives = 0;
		for (var i = 0; i < chapters.length; i++)
		{
			var chapter = chapters[i];
			usd += chapter.getPrice();
			if (('getTarif' in chapter) && (chapter.getTarif() != null) && ('price' in chapter.getTarif()))
			{
				additives += parseFloat(chapter.getTarif().price);
			}
		}
		calcTotals.usd = usd;
		jQuery('span.totals-usd').html(usd.toString());
		var rur = Math.floor(usd * USD_TO_RUR * 100 + 0.5) / 100;
		jQuery('span.totals-rur').html(rur.toString());
		calcTotals.rur = rur;

		usd += (additives / USD_TO_RUR);
		rur += additives;


		jQuery('span.totals-all-usd').html(usd.toString());
		jQuery('span.totals-all-rur').html(rur.toString());
	}

	this.renewMail = function()
	{
		var yes = false;
		var domains = this.getChaptersOfGroup('domain');
		for (var i = 0; i < domains.length; i++)
		{
			if (domains[i].isMailIncluded())
			{
				yes = true;
				break;
			}
		}
		mailbase.setActive(yes);
	}

	this.onLostView = function(textStatus)
	{
		var cview = jQuery('#cview');
		cview.html(jQuery('#template_view_request_error').html());
		jQuery('span.text', cview).html(textStatus);
	}

	this.view = function()
	{
		var aSelf = this;
		var vdiv = jQuery('#cview');
		jQuery('div.alert').replaceWith('');
		jQuery('#surface').hide();
		vdiv.html(jQuery('#view_wait').html()).show();
		var oldInfo = this.getServiceInfo();
		var onGetView = function(jsonData)
		{
			var vdiv = jQuery('#cview');
			jQuery('#debug').html(json.serialize(jsonData));
			tracker_id = jsonData.tracker_code;
			delete jsonData.tracker_code;
			vdiv.empty();
			//    .
			setTimeout(function() { handleHelpRefs(jQuery('#cview')) }, 10);
			makeServiceInfoFromServer(jsonData, oldInfo);
			jsonData.apply();
			aSelf.refreshTotals();
			var ok = true;
			var rprice = 0;
			var rhtml = jQuery('#non-existent-element');
			for (var i = 0; i < chapters.length; i++)
			{
				var chapter = chapters[i];
				var what = chapter.getViewHtml(ok);
				var rdata = chapter.getRegisterData();
				rhtml = rhtml.add(rdata.html);
				rprice += rdata.price;
				if (what)
				{
					vdiv.append(what);
				}
				var okHere = chapter.isViewOk();
				ok &= okHere;
				if (!okHere)
				{
					hideConstructorView();
				 	chapter.showViewError();
				}
			}
			if (!ok)
			{
				return;
			}
			if (rprice > 0)
			{
				var place = jQuery('div.registration-place', vdiv);
				place.append(jQuery('#template_domain_registration_header_2').html());
				place.append(rhtml);
				var rtotals = jQuery('div.registration-totals', vdiv);
//				jQuery('span.totals-reg-usd', rtotals).html(rprice);
				jQuery('span.totals-reg-rur', rtotals).html(rprice);
				rtotals.show();
			}
			handleHelpRefs(vdiv);
			jQuery('#surface').hide();
		};

		cannot_submit = false;
		jQuery('#debug').empty();
		if (!client_debug_mode)
		{
			jQuery.getJSON(
				'/constructor/', 
				{
					action: 'step2',
					data: json.serialize(oldInfo),
					tracker: tracker_id,
					s_type: 'constructor'
				}, 
				onGetView
				);
		}
		else
		{
			onGetView(oldInfo);
		}
	}
}

function handleHelpRefs(where)
{

	var helpWin = function(href)
	{
		window.open(href, 'helpWin','menubar=no,directories=no,location=no,resizable=yes,scrollbars=yes,width=300,height=200');
	}

	jQuery('a.helpref', where).addClass('helpref2').removeClass('helpref').each(function()
	{
		var el = jQuery(this);
		el.attr('rel', el.attr('href')).attr('href', 'javascript:;');
	}).click(function(e)
	{
		var el = jQuery(this);
		var href = el.attr('rel');
		helpWin(href);
	});
}

function run()
{
	constructor = new Constructor();
	if (jQuery.browser.msie) setInterval(function() { constructor.configureDomains(); }, 800);
}

function viewConstructor()
{
		alertsKillAll();
		constructor.view();
}

function hideConstructorView()
{
	jQuery('#cview').hide();
	jQuery('#surface').show();
	alertsKillAll();
}

function secondPass()
{
	constructor.div.empty();
	constructor.addDomain();
	constructor.render();
	constructor.afterConstruction();
}

run();

jQuery(document).ready(function()
{
	var jsonErrorHandler = function(req, textStatus, errorThrown)
	{
		if (textStatus == 'error' || textStatus == '')
		{
			textStatus = req.statusText;
		}
		if (textStatus == 'error' || textStatus == '')
		{
			textStatus = req.status;
		}
		if (textStatus == 'error' || textStatus == '')
		{
			textStatus = '  .';
		}
		constructor.onLostView(textStatus);
	};

	constructor.div = jQuery('#surface');
	jQuery('#cview').ajaxError(jsonErrorHandler);
	jQuery.ajaxSetup({
		ajaxError: jsonErrorHandler,
		error: jsonErrorHandler,
		timeout: 2 * 60 * 1000
		});
	setTimeout(secondPass, 10);
});
