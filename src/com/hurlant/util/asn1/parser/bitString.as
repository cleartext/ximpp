package com.hurlant.util.asn1.parser {
	import com.hurlant.util.asn1.type.ASN1Type;
	import com.hurlant.util.asn1.type.BitStringType;
	
	public function bitString():ASN1Type {
		return new BitStringType;
	}
}