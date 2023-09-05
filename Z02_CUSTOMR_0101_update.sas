
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

	z02_persist_ind = 'N';

	if update_signature = 'Y' then do; 

		if z02_content_id_version= " " then do;
			call missing(z02_content_id_version); 
			call missing(z02_prev_rqo_tran_dttm); 
			call missing(z02_curr_rqo_tran_dttm); 
			call missing(z02_pointer_dttm_hr);
			call missing(z02_pointer_dttm_3day);
			call missing(of z02_sum6hr_(*));
			call missing(of z02_sum_log_amt_(*));
			call missing(of z02_sum_cnt_(*));
			z02_content_id_version="CUSTOMR_0101";
		end; 

		*****************************************************************************************************************;
		/*** Start                                                                                                    ***/
		/*** Update the z02_prev_rqo_tran_dttm field, this will be used in the calculation of min_diff in Score Code  ***/
		*****************************************************************************************************************;

		trx_dttm = rqo_tran_date * 86400 + rqo_tran_time;
		
		z02_prev_rqo_tran_dttm = z02_curr_rqo_tran_dttm; 

		z02_curr_rqo_tran_dttm = trx_dttm;

		log_TBT_TRAN_AMT = log10(TBT_TRAN_AMT);

		*****************************************************************************************************************;
		/*** End                                                                                                      ***/
		/*** Update the z02_prev_rqo_tran_dttm field, this will be used in the calculation of min_diff in Score Code  ***/
		*****************************************************************************************************************;

		******************************************************************************************************************;
		*** Hour Calculation - Array to hold last 6 hour data START                                                    ***;
		*** The variables z02_sum6hr_* hold the hourly accumulation of TBT_TRAN_AMT                                    ***;
		******************************************************************************************************************;

		if z02_pointer_dttm_hr = . then do;
		    z02_pointer_dttm_hr = trx_dttm;
		    idx_to_updt_cust_hr = 6;
		end;
		else if z02_pointer_dttm_hr ne . then do;
			idx_to_updt_cust_hr = intck("HOUR",z02_pointer_dttm_hr, trx_dttm);
			z02_pointer_dttm_hr = trx_dttm;
		end;

		if (idx_to_updt_cust_hr > 5) then do;
					do kk = 1 to 5;
						z02_sum6hr_{kk} = 0;
					end;
					z02_sum6hr_{6} = TBT_TRAN_AMT;
		end;
		else if (0 < idx_to_updt_cust_hr <= 5) then do;
				do ii = 1 to 6 - idx_to_updt_cust_hr;
					z02_sum6hr_{ii} = z02_sum6hr_{ii + idx_to_updt_cust_hr};
				end;
				do mm = 7 - idx_to_updt_cust_hr to 5;
						z02_sum6hr_{mm} = 0;
				end;
				z02_sum6hr_{6} = TBT_TRAN_AMT;
		end;
		else do;  
		    z02_sum6hr_{6} = sum(z02_sum6hr_{6},TBT_TRAN_AMT);
		end;

		********************************************************************************************************************;
		*** Hour Calculation - - Array to hold last 6 hour data END                                                      ***;
		********************************************************************************************************************;

		********************************************************************************************************************;
		*** Create Buckets to hold 3 Day Summary, 3 Day Buckets are fixed starting with the first transaction - START    ***;
		*** The variables z02_sum_log_amt_* hold the 3 day accumulation of log_TBT_TRAN_AMT                              ***;
		*** The variables z02_sum_cnt_* hold the 3 day accumulation of Tranaction count                                  ***;
		********************************************************************************************************************;

		if z02_pointer_dttm_3day = . then do;
		    z02_pointer_dttm_3day = trx_dttm;
			idx_to_updt_cust_day = 90;
		end;
		else if z02_pointer_dttm_3day ne . then do;
			idx_to_updt_cust_day = intck("DTDAY",z02_pointer_dttm_3day, trx_dttm);
			if idx_to_updt_cust_day > 2 then do;
				z02_pointer_dttm_3day = intnx("DTDAY",z02_pointer_dttm_3day, (floor(idx_to_updt_cust_day / 3)*3));
			end;
		end;

		idx_to_updt_cust_day = ceil((idx_to_updt_cust_day + 1)/3) - 1;

		if (idx_to_updt_cust_day > 29) then do;
					do kw = 1 to 29;
						z02_sum_log_amt_{kw} = 0;
						z02_sum_cnt_{kw} = 0;
					end;
					z02_sum_log_amt_{30} = log_TBT_TRAN_AMT;
					z02_sum_cnt_{30} = 1;
		end;
		else if (0 < idx_to_updt_cust_day <= 29)  then do;
					do ir = 1 to 30 - idx_to_updt_cust_day;
						z02_sum_log_amt_{ir} = z02_sum_log_amt_{ir + idx_to_updt_cust_day};
						z02_sum_cnt_{ir} = z02_sum_cnt_{ir + idx_to_updt_cust_day};
					end;
					do mn = 31 - idx_to_updt_cust_day to 29;
							z02_sum_log_amt_{mn} = 0;
							z02_sum_cnt_{mn} = 0;
					end;
					z02_sum_log_amt_{30} = log_TBT_TRAN_AMT;
					z02_sum_cnt_{30} = 1;
		end;
		else do;  
		    z02_sum_log_amt_{30} = sum(z02_sum_log_amt_{30},log_TBT_TRAN_AMT);
			z02_sum_cnt_{30} = sum(z02_sum_cnt_{30},1);
		end;

		********************************************************************************************************************;
		*** Create Buckets to hold 3 Day Summary, 3 Day Buckets are fixed starting with the first transaction - END      ***;
		********************************************************************************************************************;

		z02_persist_ind = 'Y';

	end;

	/*
	putlog "Z02_CUSTOMR_0101_update START";
	putlog "update_signature = " update_signature;
	putlog "smh_acct_type = " smh_acct_type;
	putlog "smh_activity_type = " smh_activity_type;
	putlog "XQO_CUST_NUM = " XQO_CUST_NUM;
	putlog "DUA_80BYTE_STRING_001 = " DUA_80BYTE_STRING_001;
	putlog "trx_dttm = " trx_dttm;
	putlog "TBT_TRAN_AMT = " TBT_TRAN_AMT;
	putlog "SMH_CLIENT_TRAN_TYPE = " SMH_CLIENT_TRAN_TYPE;
	putlog "z02_content_id_version = " z02_content_id_version;
	putlog "z02_prev_rqo_tran_dttm = " z02_prev_rqo_tran_dttm;
	putlog "z02_curr_rqo_tran_dttm = " z02_curr_rqo_tran_dttm;
	putlog "z02_pointer_dttm_hr = " z02_pointer_dttm_hr;
	putlog "z02_pointer_dttm_3day = " z02_pointer_dttm_3day;
	putlog "z02_persist_ind = " z02_persist_ind;
	putlog "z02_lookup_key = " z02_lookup_key;
	putlog "z02_sum6hr_1 = " z02_sum6hr_1; 
	putlog "z02_sum6hr_2 = " z02_sum6hr_2;
	putlog "z02_sum6hr_3 = " z02_sum6hr_3;
	putlog "z02_sum6hr_4 = " z02_sum6hr_4;
	putlog "z02_sum6hr_5 = " z02_sum6hr_5;
	putlog "z02_sum6hr_6 = " z02_sum6hr_6;
	putlog  "z02_sum_cnt_1 = " z02_sum_cnt_1;
	putlog  "z02_sum_cnt_2 = " z02_sum_cnt_2;
	putlog  "z02_sum_cnt_3 = " z02_sum_cnt_3;
	putlog  "z02_sum_cnt_4 = " z02_sum_cnt_4;
	putlog  "z02_sum_cnt_5 = " z02_sum_cnt_5;
	putlog  "z02_sum_cnt_6 = " z02_sum_cnt_6;
	putlog  "z02_sum_cnt_7 = " z02_sum_cnt_7;
	putlog  "z02_sum_cnt_8 = " z02_sum_cnt_8;
	putlog  "z02_sum_cnt_9 = " z02_sum_cnt_9;
	putlog  "z02_sum_cnt_10 = " z02_sum_cnt_10;
	putlog  "z02_sum_cnt_11 = " z02_sum_cnt_11;
	putlog  "z02_sum_cnt_12 = " z02_sum_cnt_12;
	putlog  "z02_sum_cnt_13 = " z02_sum_cnt_13;
	putlog  "z02_sum_cnt_14 = " z02_sum_cnt_14;
	putlog  "z02_sum_cnt_15 = " z02_sum_cnt_15;
	putlog  "z02_sum_cnt_16 = " z02_sum_cnt_16;
	putlog  "z02_sum_cnt_17 = " z02_sum_cnt_17;
	putlog  "z02_sum_cnt_18 = " z02_sum_cnt_18;
	putlog  "z02_sum_cnt_19 = " z02_sum_cnt_19;
	putlog  "z02_sum_cnt_20 = " z02_sum_cnt_20;
	putlog  "z02_sum_cnt_21 = " z02_sum_cnt_21;
	putlog  "z02_sum_cnt_22 = " z02_sum_cnt_22;
	putlog  "z02_sum_cnt_23 = " z02_sum_cnt_23;
	putlog  "z02_sum_cnt_24 = " z02_sum_cnt_24;
	putlog  "z02_sum_cnt_25 = " z02_sum_cnt_25;
	putlog  "z02_sum_cnt_26 = " z02_sum_cnt_26;
	putlog  "z02_sum_cnt_27 = " z02_sum_cnt_27;
	putlog  "z02_sum_cnt_28 = " z02_sum_cnt_28;
	putlog  "z02_sum_cnt_29 = " z02_sum_cnt_29;
	putlog  "z02_sum_cnt_30 = " z02_sum_cnt_30;
	putlog  "z02_sum_log_amt_1 = " z02_sum_log_amt_1;
	putlog  "z02_sum_log_amt_2 = " z02_sum_log_amt_2;
	putlog  "z02_sum_log_amt_3 = " z02_sum_log_amt_3;
	putlog  "z02_sum_log_amt_4 = " z02_sum_log_amt_4;
	putlog  "z02_sum_log_amt_5 = " z02_sum_log_amt_5;
	putlog  "z02_sum_log_amt_6 = " z02_sum_log_amt_6;
	putlog  "z02_sum_log_amt_7 = " z02_sum_log_amt_7;
	putlog  "z02_sum_log_amt_8 = " z02_sum_log_amt_8;
	putlog  "z02_sum_log_amt_9 = " z02_sum_log_amt_9;
	putlog  "z02_sum_log_amt_10 = " z02_sum_log_amt_10;
	putlog  "z02_sum_log_amt_11 = " z02_sum_log_amt_11;
	putlog  "z02_sum_log_amt_12 = " z02_sum_log_amt_12;
	putlog  "z02_sum_log_amt_13 = " z02_sum_log_amt_13;
	putlog  "z02_sum_log_amt_14 = " z02_sum_log_amt_14;
	putlog  "z02_sum_log_amt_15 = " z02_sum_log_amt_15;
	putlog  "z02_sum_log_amt_16 = " z02_sum_log_amt_16;
	putlog  "z02_sum_log_amt_17 = " z02_sum_log_amt_17;
	putlog  "z02_sum_log_amt_18 = " z02_sum_log_amt_18;
	putlog  "z02_sum_log_amt_19 = " z02_sum_log_amt_19;
	putlog  "z02_sum_log_amt_20 = " z02_sum_log_amt_20;
	putlog  "z02_sum_log_amt_21 = " z02_sum_log_amt_21;
	putlog  "z02_sum_log_amt_22 = " z02_sum_log_amt_22;
	putlog  "z02_sum_log_amt_23 = " z02_sum_log_amt_23;
	putlog  "z02_sum_log_amt_24 = " z02_sum_log_amt_24;
	putlog  "z02_sum_log_amt_25 = " z02_sum_log_amt_25;
	putlog  "z02_sum_log_amt_26 = " z02_sum_log_amt_26;
	putlog  "z02_sum_log_amt_27 = " z02_sum_log_amt_27;
	putlog  "z02_sum_log_amt_28 = " z02_sum_log_amt_28;
	putlog  "z02_sum_log_amt_29 = " z02_sum_log_amt_29;
	putlog  "z02_sum_log_amt_30 = " z02_sum_log_amt_30;
	putlog "Z02_CUSTOMR_0101_update START";
	*/









