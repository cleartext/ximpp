package com.cleartext.ximpp.models.utils
{
	import mx.messaging.AbstractConsumer;
	
	public class LinkUitls
	{
		public static const protocols:Array = ["http", "https", "ftp"];
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
		
//		public static function escapeHTML(str:String):String
//		{
//			str = str.replace(/&/g, "&amp;");
//			str = str.replace(/</g, "&lt;");
//			str = str.replace(/>/g, "&gt;");
////			str = str.replace(new RegExp('"', "g"), "&quot;");
//			return str;
//		}
//		
//		public static function unescapeHTML(str:String):String
//		{
////			str = str.replace(/&amp;/g, "&");
////			str = str.replace(/&lt;/g, "<");
////			str = str.replace(/&gt;/g, ">");
////			str = str.replace(/&quot;/g, "&quot;");
//			return str;
//		}
		
		public static function getStartTag(linkColour:uint=0x0033ff):String
		{
			// this is the start of the text that we want to insert round the link
			// it will look something lke <U><FONT COLOR="#0033FF"><A HREF="
            return '<U><FONT COLOR="#' + String("000000" + linkColour.toString(16).toUpperCase()).substr(-6) + '"><A HREF="';
		}

		public static function get endTag():String
		{
			return '</A></FONT></U>';
		}

		public static function createLinks(plainText:String, escapeHtmlChars:Boolean=true, linkColour:uint=0x0033ff):String
		{
			var startTag:String = getStartTag(linkColour);
			
			var linkText:String = plainText;
			
			// find any valid urls, this regex will probably produce false positives
			// find at least 1 non-whitespace char that isn't a " (greedy to get 
			// .com.au and not just .com), then a "." then a valid tld then either 
			// an end of word, or a "/" followed by any amount of non-whitespace chars 
			var regex:RegExp = new RegExp('\\b[^\\s"\']+\\.(' + tlds.join('|') + ')(/[^\\s]*)?\\b/?',"ig");
			// $& returns the match from the regex
			linkText = linkText.replace(regex, startTag + '$&">$&' + endTag);
			
			// if the links created don't have a protocol, then give it an http://
			regex = new RegExp(startTag + '(?!(' + protocols.join('|') + ')://)', 'ig');
			linkText = linkText.replace(regex, startTag + 'http://');

			return linkText;
		}
		
		public static function findLinks(plainText:String):Array
		{
			// look for the start of the string or a space followed by at least 2
			// now whitespace chars, then a "." then a valid tld then a space or a
			// "/" followed by any amount of non-whitespace chars, then a space
			var regex:RegExp = new RegExp('\\b[^\\s]{1,}\\.(' + tlds.join('|') + ')(/[^\\s]*)?\\b/?',"ig");
			var results:Array = new Array();
			var temp:Object = regex.exec(plainText);
			while (temp)
			{
				var link:String = temp[0];

				var needsProtocol:Boolean = true;
				for each(var protocol:String in protocols)
				{
					if(link.indexOf(protocol+"://")==0)
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
				temp = regex.exec(plainText);
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
		
		public static function createHashTagLinks(str:String, urlStart:String, urlEnd:String):String
		{
			// avoid the # already in font color tags
			var regExp:RegExp = new RegExp("((?<!<FONT COLOR=\")#|^#)([\\w<>]+?)\\b", "ig");
			return str.replace(regExp, getStartTag() + urlStart + "$2" + urlEnd + "\">$&" + endTag);
		} 
		
		public static function createAtLinks(str:String, urlStart:String, urlEnd:String):String
		{
			// avoid the # already in font color tags
			var regExp:RegExp = new RegExp("@(\\w+?)\\b", "ig");
			return str.replace(regExp, getStartTag() + urlStart + "$1" + urlEnd + "\">$&" + endTag);
		} 
		
	}
}

