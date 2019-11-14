String.prototype.quote = function() 
{
    var c, i, l = this.length, o = '"';
    for (i = 0; i < l; i += 1) {
        c = this.charAt(i);
        if (c >= ' ') {
            if (c === '\\' || c === '"') {
                o += '\\';
            }
            o += c;
        } else {
            switch (c) {
            case '\b':
                o += '\\b';
                break;
            case '\f':
                o += '\\f';
                break;
            case '\n':
                o += '\\n';
                break;
            case '\r':
                o += '\\r';
                break;
            case '\t':
                o += '\\t';
                break;
            default:
                c = c.charCodeAt();
                o += '\\u00' + Math.floor(c / 16).toString(16) +
                    (c % 16).toString(16);
            }
        }
    }
    return o + '"';
};

function Json()
{
	var self = this;

	this.unserialize = function(s) { return eval('(' + s + ')'); };

	var addslashesRepl = {'\r': '\\r', '\n': '\\n', '\t': '\\t', '\0': '\\0', '\\': '\\\\', '\b': '\\b', '\f': '\\f'};

	var addslashes = function(s)
	{
		return s.toString().quote();
	}

	var isArray = function(testObject) 
	{
	    return testObject && !(testObject.propertyIsEnumerable('length')) && typeof testObject === 'object' && typeof testObject.length === 'number';
	}

	var serializeArray = function(o)
	{
		var s = ['['];
		var first = true;
		for (var i = 0; i < o.length; i++)
		{
			var v = o[i];
			if (typeof(v) == 'function')
			{
				continue;
			}
			if (first) first = false; else s.push(',');
			s.push(self.serialize(v));
		}
		s.push(']');
		return s.join('');
	}

	var serializeObject = function(o)
	{
		var s = ['{'];
		var first = true;
		for (var i in o)
		{
			var v = o[i];
			if (typeof(v) == 'function')
			{
				continue;
			}
			if (first) first = false; else s.push(',');
			s.push(addslashes(i));
			s.push(':');
			s.push(self.serialize(v));
		}
		s.push('}');
		return s.join('');
	}

	this.serialize = function(o) 
	{
		switch (typeof(o))
		{
		case 'string':
			return addslashes(o);
		case 'number':
			return o.toString();
		case 'object':
			if (isArray(o)) return serializeArray(o);
			return serializeObject(o);
		case 'boolean':
			return o ? 'true' : 'false';
		}
		return '"jsonTypeError"';
	}
}

var json = new Json();
