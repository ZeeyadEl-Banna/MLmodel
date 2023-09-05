
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

z04_persist_ind = 'N';

if update_signature = 'Y' then do; 
        if z04_content_id_version = " " then do;
        call missing(z04_frst_rqo_utc_trx_dttm);
        z04_content_id_version="BENE_0101";
        end;
        
    
    trx_dttm = rqo_tran_date * 86400 + rqo_tran_time;

    **************************************************************************************************************************;
    /*** Start                                                                                                             ***/
    /*** Update the variable z04_frst_rqo_utc_trx_dttm based on the first ever transaction at Customer Beneficiary Level   ***/
    **************************************************************************************************************************;

    if z04_frst_rqo_utc_trx_dttm = . then do;
        z04_frst_rqo_utc_trx_dttm = trx_dttm;
    end;

    if z04_Bene_max_amount_1 = . then do;
        z04_Bene_max_amount_1 = TBT_TRAN_AMT;
        end;

     if z04_Bene_max_amount_1 < tbt_tran_amt then do;
            z04_Bene_max_amount_1 = tbt_tran_amt;
   end; 

    ***********************************t_tran_amt then do;
           ***************************************************************************************;
    /*** END                                                                                                               ***/
    /*** Update the variable z04_frst_rqo_utc_trx_dttm based on the first ever transaction at Customer Beneficiary Level   ***/
    **************************************************************************************************************************;

    z04_persist_ind = 'Y';
end;


putlog "z04_BENE_0101_update START";
putlog "update_signature = " update_signature;
putlog "smh_acct_type = " smh_acct_type;
putlog "smh_activity_type = " smh_activity_type;
putlog "XQO_CUST_NUM = " XQO_CUST_NUM;
putlog "DUA_80BYTE_STRING_001 = " DUA_80BYTE_STRING_001;
putlog "trx_dttm = " trx_dttm;
putlog "TBT_TRAN_AMT = " TBT_TRAN_AMT;
putlog "SMH_CLIENT_TRAN_TYPE = " SMH_CLIENT_TRAN_TYPE;
putlog "z04_content_id_version = " z04_content_id_version;
putlog "z04_frst_rqo_utc_trx_dttm = " z04_frst_rqo_utc_trx_dttm;
putlog "z04_persist_ind = " z04_persist_ind;
putlog "z04_lookup_key = " z04_lookup_key; 
putlog "z04_BENE_0101_update END";






