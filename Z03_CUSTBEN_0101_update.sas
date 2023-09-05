
	%update_signature_flag(Y);

	if not (smh_acct_type = "CS" and smh_activity_type = "BF") then do;
		%update_signature_flag(N);
	end;
	else if missing(XQO_CUST_NUM) then do;
		%update_signature_flag(N);
	end;
	else if missing(rqo_tran_date) or missing(rqo_tran_time) then do;
		%update_signature_flag(N);
	end;
	else if (smh_acct_type = "CS" and smh_activity_type = "BF") and (missing(TBT_TRAN_AMT) or TBT_TRAN_AMT < 0) then do;
		%update_signature_flag(N);
	end;
	else if not (SMH_CLIENT_TRAN_TYPE in ('RFTF_MT','RFTF_WBT','RFTF_WCT')) then do;
		%update_signature_flag(N);
	end;

	z03_persist_ind = 'N';

	if update_signature = 'Y' then do; 

		if z03_content_id_version= " " then do; 
			call missing(z03_frst_rqo_utc_trx_dttm);
			z03_content_id_version="CUSTBEN_0101";
		end; 

		trx_dttm = rqo_tran_date * 86400 + rqo_tran_time;

		**************************************************************************************************************************;
		/*** Start                                                                                                             ***/
		/*** Update the variable z03_frst_rqo_utc_trx_dttm based on the first ever transaction at Customer Beneficiary Level   ***/
		**************************************************************************************************************************;

		if z03_frst_rqo_utc_trx_dttm = . then do;
			z03_frst_rqo_utc_trx_dttm = trx_dttm;
		end;

		**************************************************************************************************************************;
		/*** END                                                                                                               ***/
		/*** Update the variable z03_frst_rqo_utc_trx_dttm based on the first ever transaction at Customer Beneficiary Level   ***/
		**************************************************************************************************************************;

		z03_persist_ind = 'Y';
	end;

	/*
	putlog "Z03_CUSTBEN_0101_update START";
	putlog "update_signature = " update_signature;
	putlog "smh_acct_type = " smh_acct_type;
	putlog "smh_activity_type = " smh_activity_type;
	putlog "XQO_CUST_NUM = " XQO_CUST_NUM;
	putlog "DUA_80BYTE_STRING_001 = " DUA_80BYTE_STRING_001;
	putlog "trx_dttm = " trx_dttm;
	putlog "TBT_TRAN_AMT = " TBT_TRAN_AMT;
	putlog "SMH_CLIENT_TRAN_TYPE = " SMH_CLIENT_TRAN_TYPE;
	putlog "z03_content_id_version = " z03_content_id_version;
	putlog "z03_frst_rqo_utc_trx_dttm = " z03_frst_rqo_utc_trx_dttm;
	putlog "z03_persist_ind = " z03_persist_ind;
	putlog "z03_lookup_key = " z03_lookup_key; 
	putlog "Z03_CUSTBEN_0101_update END";
	*/





