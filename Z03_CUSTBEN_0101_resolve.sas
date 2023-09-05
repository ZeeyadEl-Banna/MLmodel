
	%resolve_signature_flag(Y);

	if not (smh_acct_type = "CS" and smh_activity_type = "BF") then do;
		%resolve_signature_flag(N);
	end;
	else if missing(XQO_CUST_NUM) then do;
		%resolve_signature_flag(N);
	end;
	else if missing(rqo_tran_date) or missing(rqo_tran_time) then do;
		%resolve_signature_flag(N);
	end;
	else if (smh_acct_type = "CS" and smh_activity_type = "BF") and (missing(TBT_TRAN_AMT) or TBT_TRAN_AMT < 0) then do;
		%resolve_signature_flag(N);
	end;
	else if not (SMH_CLIENT_TRAN_TYPE in ('RFTF_MT','RFTF_WBT','RFTF_WCT')) then do;
		%resolve_signature_flag(N);
	end;

	call missing(z03_lookup_key);
	if resolve_signature = 'Y' then do;
		if not missing(XQO_CUST_NUM) then do;
			z03_lookup_key = trim(left(XQO_CUST_NUM)) ||'-'|| trim(left(DUA_80BYTE_STRING_001));
		end;
	end;

	/*
	putlog "resolve_signature = " resolve_signature;
	putlog "smh_acct_type = " smh_acct_type;
	putlog "smh_activity_type = " smh_activity_type;
	putlog "XQO_CUST_NUM = " XQO_CUST_NUM;
	putlog "DUA_80BYTE_STRING_001 = " DUA_80BYTE_STRING_001;
	putlog "TBT_TRAN_AMT = " TBT_TRAN_AMT;
	putlog "SMH_CLIENT_TRAN_TYPE = " SMH_CLIENT_TRAN_TYPE;
	putlog "z03_lookup_key = " z03_lookup_key; 
	*/

