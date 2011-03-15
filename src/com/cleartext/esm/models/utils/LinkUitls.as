package com.cleartext.esm.models.utils
{
	import mx.utils.StringUtil;
	
	import org.osmf.layout.RelativeLayoutFacet;
	
	public class LinkUitls
	{
		public static const protocols:Array = ["http://", "https://", "ftp://"];
		public static const tlds:Array = [
			"AC","AD","AE","AERO","AF","AG","AI","AL","AM","AN",
			"AO","AQ","AR","ARPA","AS","ASIA","AT","AU","AW",
			"AX","AZ","BA","BB","BD","BE","BF","BG","BH","BI",
			"BIZ","BJ","BM","BN","BO","BR","BS","BT","BV","BW",
			"BY","BZ","CA","CAT","CC","CD","CF","CG","CH","CI",
			"CK","CL","CM","CN","CO","COM","COOP","CR","CU",
			"CV","CX","CY","CZ","DE","DJ","DK","DM","DO","DZ",
			"EC","EDU","EE","EG","ER","ES","ET","EU","FI","FJ",
			"FK","FM","FO","FR","GA","GB","GD","GE","GF","GG",
			"GH","GI","GL","GM","GN","GOV","GP","GQ","GR","GS",
			"GT","GU","GW","GY","HK","HM","HN","HR","HT","HU",
			"ID","IE","IL","IM","IN","INFO","INT","IO","IQ",
			"IR","IS","IT","JE","JM","JO","JOBS","JP","KE",
			"KG","KH","KI","KM","KN","KP","KR","KW","KY","KZ",
			"LA","LB","LC","LI","LK","LR","LS","LT","LU","LV",
			"LY","MA","MC","MD","ME","MG","MH","MIL","MK","ML",
			"MM","MN","MO","MOBI","MP","MQ","MR","MS","MT",
			"MU","MUSEUM","MV","MW","MX","MY","MZ","NA","NAME",
			"NC","NE","NET","NF","NG","NI","NL","NO","NP","NR",
			"NU","NZ","OM","ORG","PA","PE","PF","PG","PH","PK",
			"PL","PM","PN","PR","PRO","PS","PT","PW","PY","QA",
			"RE","RO","RS","RU","RW","SA","SB","SC","SD","SE",
			"SG","SH","SI","SJ","SK","SL","SM","SN","SO","SR",
			"ST","SU","SV","SY","SZ","TC","TD","TEL","TF","TG",
			"TH","TJ","TK","TL","TM","TN","TO","TP","TR",
			"TRAVEL","TT","TV","TW","TZ","UA","UG","UK","US",
			"UY","UZ","VA","VC","VE","VG","VI","VN","VU","WF",
			"WS","XN--0ZWM56D","XN--11B5BS3A9AJ6G",
			"XN--80AKHBYKNJ4F","XN--9T4B11YI5A","XN--DEBA0AD",
			"XN--G6W251D","XN--HGBK6AJ7F53BBA",
			"XN--HLCJ6AYA9ESC7A","XN--JXALPDLP","XN--KGBECHTV",
			"XN--ZCKZAH","YE","YT","YU","ZA","ZM","ZW"];
		
		public static function escapeHTML(str:String):String
		{
			if(!str)
				return str;
			str = str.replace(/&/g, "&amp;");
			str = str.replace(/</g, "&lt;");
			str = str.replace(/>/g, "&gt;");
			str = str.replace(new RegExp('"', "g"), "&quot;");
			return str;
		}
		
		public static function unescapeHTML(str:String):String
		{
			if(!str)
				return str;
			str = str.replace(/&amp;/g, "&");
			str = str.replace(/&lt;/g, "<");
			str = str.replace(/&gt;/g, ">");
			str = str.replace(/&quot;/g, "&quot;");
			return str;
		}
		
		public static function getStartTag(linkColour:uint=0x0033ff):String
		{
			// this is the start of the text that we want to insert round the link
			// it will look something lke <U><FONT COLOR="#0033FF"><A HREF="
            return '<U><FONT COLOR="#' + String("000000" + linkColour.toString(16).toUpperCase()).substr(-6) + '"><A HREF="event:';
		}

		public static function get endTag():String
		{
			return '</A></FONT></U>';
		}
		
		// find any valid urls, this regex will probably produce false positives
		// find at least 1 non-whitespace char that isn't a " (greedy to get 
		// .com.au and not just .com), then a "." then a valid tld then either 
		// an end of word, or a "/" followed by any amount of non-whitespace chars 
		private static const linkRegExp:RegExp = new RegExp('(((' + protocols.join('|') + ')[^\\s"\']+)|(\\b[^\\s"\'/]+))\\.(' + tlds.join('|') + ')((/|#)[^\\s]*)?\\b/?',"ig");

		public static function createLinks(plainText:String, searchTerms:Array, hashUrlStart:String=null, hashUrlEnd:String=null, atUrlStart:String=null, atUrlEnd:String=null):String
		{
			var startTag:String = getStartTag();
			var linkText:String = plainText;
			
			// remove any existing tags
			linkText = LinkUitls.removeALlTags(linkText);
			
			// trim whitspace off the ends
			linkText = StringUtil.trim(linkText);

			// $& returns the match from the regex
			linkText = linkText.replace(linkRegExp, startTag + '$&">$&' + endTag);
			
			// if the links created don't have a protocol, then give it an http://
			var regex:RegExp = new RegExp(startTag + '(?!(' + protocols.join('|') + '))', 'ig');
			linkText = linkText.replace(regex, startTag + 'http://');

			if(hashUrlStart || hashUrlEnd)
				linkText = createSpecialLinks(linkText, hashUrlStart, hashUrlEnd, "#");

			if(atUrlStart || atUrlEnd)
				linkText = createSpecialLinks(linkText, atUrlStart, atUrlEnd, "@");
			
//			if(searchTerms)
//			{
//				var result:String;
//				for each (var sub:String in linkText.split('<'))
//				{
//					var split:Array = sub.split('>');
//					result += '<' + split[0] + '>';
//					if(split.length > 1)
//					{
//						result  += (split[1] as String).replace(new RegExp('(' + searchTerms.join('|') + ')', 'ig'), '<b>$1</b>');
//					}
//				}
//				trace(linkText, '\n', result);
//			}
			
			// replace line breaks with <br/>
			linkText = LinkUitls.replaceLineBreaks(linkText);

			return linkText;
		}
		
		public static function findLinks(plainText:String):Array
		{
			var results:Array = new Array();
			var temp:Object = linkRegExp.exec(plainText);
			while (temp)
			{
				var link:String = temp[0];

				var needsProtocol:Boolean = true;
				for each(var protocol:String in protocols)
				{
					if(link.indexOf(protocol)==0)
					{
						needsProtocol = false;
						break;
					}
				}

				var result:LinkResult = new LinkResult();
				result.index = temp.index;
				result.originalLink = link;
				result.validLink = ((needsProtocol) ? "http://" : "") + link;
				
				results.push(result);
				temp = linkRegExp.exec(plainText);
			}
			return results;
		}
		
		public static function removeALlTags(str:String):String
		{
			var tmpStr:String;
			while(tmpStr != str)
			{
				tmpStr = str;
				str = str.replace(new RegExp("<([A-Z][A-Z0-9]*)\\b[^>]*?>([\\s\\S]*?)</\\1>", "ig"), "$2");
			}
			return str;
		}
		
		public static function replaceLineBreaks(str:String):String
		{
			return str.replace(new RegExp("\n|\r", "ig"), "<BR />");
		}
		
		public static function createSpecialLinks(str:String, urlStart:String, urlEnd:String, specialChar:String):String
		{
			var inLinkTag:int = 0;
			var inHashTag:Boolean = false;
			var result:String = "";
			var charArray:Array = str.split("");
			var len:int = charArray.length;
			
			for(var i:int=0; i<len; i++)
			{
				var s:String = charArray[i];
				if(inLinkTag == 0)
				{
					if(s == "<" && str.substr(i,17) == '<U><FONT COLOR="#')
					{
						inLinkTag++;
					}
					else if(s == specialChar)
					{
						inHashTag = true;
						result += getStartTag() + urlStart;
						var tag:String = "";
						while(true)
						{
							i++;
							if(i==len)
							{
								s="";
								break;
							}
							s = charArray[i];
							if(!s.match(new RegExp("\\w") || s=="<"))
							{
								s="";
								i--;
								break;
							}
							result += s;
							tag += s;
						}
						result += "\">" + specialChar + tag + endTag;
					}
				}
				else if(s == "<" && str.substr(i,endTag.length) == endTag)
				{
					inLinkTag--;
				}
				result += s;
			}			
			return result;
		} 
		
//		public static function createAtLinks(str:String, urlStart:String, urlEnd:String):String
//		{
//			// avoid the @ already inside any <a>tags
//			var regExp:RegExp = new RegExp("@(\\w+?)\\b", "ig");
//			return str.replace(regExp, getStartTag() + urlStart + "$1" + urlEnd + "\">$&" + endTag);
//		} 
	}
}

