
	mdl_model_trace = '0000';
	mdl_score = 0;

	%set_score_txn_flag(Y,0000);

	if not (smh_acct_type = "CS" and smh_activity_type = "BF") then do;
		%set_score_txn_flag(N,4000,msg='Account type not in scope');
	end;
	else if missing(XQO_CUST_NUM) then do;
		%set_score_txn_flag(N,4001,msg='Account Number is Missing');
	end;
	else if missing(rqo_tran_date) or missing(rqo_tran_time) then do;
		%set_score_txn_flag(N,4002,msg='Transaction Date or Time is Missing');
	end;
	else if (smh_acct_type = "CS" and smh_activity_type = "BF") and (missing(TBT_TRAN_AMT) or TBT_TRAN_AMT < 0) then do;
		%set_score_txn_flag(N,4003,msg='Transaction Amount is Missing');
	end;
	else if not (SMH_CLIENT_TRAN_TYPE in ('RFTF_MT','RFTF_WBT','RFTF_WCT')) then do;
		%set_score_txn_flag(N,4004,msg='SMH_CLIENT_TRAN_TYPE not in scope');
	end;

	if score_transaction = 'Y' then do;	

		trx_dttm = rqo_tran_date * 86400 + rqo_tran_time;

		*****************************************************************************************************************;
		/*** START of Feature Creation                                                                                ***/
		*****************************************************************************************************************;

		IF TPP_STATE=' ' and RUA_IND_001='Y' then bene_bank_name_G='G1';
		ELSE IF TPP_STATE=' ' and RUA_IND_001='N' then bene_bank_name_G='G2'; 
		ELSE IF TPP_STATE='015' then bene_bank_name_G='G2';
		ELSE IF TPP_STATE in ('030', '020', '045') then bene_bank_name_G='G3';
		ELSE IF TPP_STATE in ('010', '055') then bene_bank_name_G='G4';
		ELSE IF TPP_STATE in ('065', '005') then bene_bank_name_G='G5';
		ELSE IF TPP_STATE in ('060', '090') then bene_bank_name_G='G6';
		ELSE bene_bank_name_G = 'G0';

		IF RUA_IND_006 = 'B' then RUA_IND_006_G='G1';
		ELSE IF RUA_IND_006 = 'A' then RUA_IND_006_G='G2';
		ELSE IF RUA_IND_006 = 'E' then RUA_IND_006_G='G3';
		ELSE IF RUA_IND_006 = 'D' then RUA_IND_006_G='G3';
		ELSE IF RUA_IND_006 = 'C' then RUA_IND_006_G='G3';
		ELSE RUA_IND_006_G = 'G0';

		IF RUA_3BYTE_STRING_006 ='4'  then RUA_3BYTE_STRING_006_G='G2';
		ELSE IF RUA_3BYTE_STRING_006 ='52' then RUA_3BYTE_STRING_006_G='G2';
		ELSE IF RUA_3BYTE_STRING_006 ='04' then RUA_3BYTE_STRING_006_G='G3';
		ELSE IF RUA_3BYTE_STRING_006 ='5'  then RUA_3BYTE_STRING_006_G='G3';
		ELSE IF RUA_3BYTE_STRING_006 ='B'  then RUA_3BYTE_STRING_006_G='G4';
		ELSE IF RUA_3BYTE_STRING_006 ='6'  then RUA_3BYTE_STRING_006_G='G4';
		ELSE IF RUA_3BYTE_STRING_006 ='E'  then RUA_3BYTE_STRING_006_G='G5';
		ELSE IF RUA_3BYTE_STRING_006 ='07' then RUA_3BYTE_STRING_006_G='G5';
		ELSE IF RUA_3BYTE_STRING_006 ='1'  then RUA_3BYTE_STRING_006_G='G6';
		ELSE IF RUA_3BYTE_STRING_006 ='F'  then RUA_3BYTE_STRING_006_G='G6';
		ELSE IF RUA_3BYTE_STRING_006 ='06' then RUA_3BYTE_STRING_006_G='G7';
		ELSE IF RUA_3BYTE_STRING_006 ='D'  then RUA_3BYTE_STRING_006_G='G7';
		ELSE IF RUA_3BYTE_STRING_006 ='9'  then RUA_3BYTE_STRING_006_G='G8';
		ELSE IF RUA_3BYTE_STRING_006 ='C'  then RUA_3BYTE_STRING_006_G='G8';
		ELSE IF RUA_3BYTE_STRING_006 ='3'  then RUA_3BYTE_STRING_006_G='G8';
		ELSE IF RUA_3BYTE_STRING_006 ='01' then RUA_3BYTE_STRING_006_G='G8';
		ELSE IF RUA_3BYTE_STRING_006 ='09' then RUA_3BYTE_STRING_006_G='G9';
		ELSE IF RUA_3BYTE_STRING_006 ='02' then RUA_3BYTE_STRING_006_G='G1';
		ELSE IF RUA_3BYTE_STRING_006 ='03' then RUA_3BYTE_STRING_006_G='G1';
		ELSE IF RUA_3BYTE_STRING_006 ='05' then RUA_3BYTE_STRING_006_G='G1';
		ELSE IF RUA_3BYTE_STRING_006 ='08' then RUA_3BYTE_STRING_006_G='G1';
		ELSE IF RUA_3BYTE_STRING_006 ='0A' then RUA_3BYTE_STRING_006_G='G1';
		ELSE IF RUA_3BYTE_STRING_006 ='2'  then RUA_3BYTE_STRING_006_G='G1';
		ELSE IF RUA_3BYTE_STRING_006 ='7'  then RUA_3BYTE_STRING_006_G='G1';
		ELSE IF RUA_3BYTE_STRING_006 ='8'  then RUA_3BYTE_STRING_006_G='G1';
		ELSE IF RUA_3BYTE_STRING_006 ='A'  then RUA_3BYTE_STRING_006_G='G1';
		ELSE RUA_3BYTE_STRING_006_G='G0';

		log_TBT_TRAN_AMT = log10(TBT_TRAN_AMT);

		min_diff = intck('minute',z02_prev_rqo_tran_dttm, z02_curr_rqo_tran_dttm); 
		if min_diff = . then min_diff =0;

		sum_amthr6_2 = sum(of z02_sum6hr_(*)) - TBT_TRAN_AMT;
		if sum_amthr6_2 = . then sum_amthr6_2 = 0;

		sum_cnt = sum(of z02_sum_cnt_1 - z02_sum_cnt_29);
		sum_amt = sum(of z02_sum_log_amt_1 - z02_sum_log_amt_29);

		if (sum_cnt > 0) then do;
			if ((sum_amt / sum_cnt) > 0) then do;
				tx_div_avg_log_amtday90_2 = (log_TBT_TRAN_AMT / (sum_amt / sum_cnt));
			end;
			else tx_div_avg_log_amtday90_2 = .;
		end;
		else tx_div_avg_log_amtday90_2 = .;

		if tx_div_avg_log_amtday90_2 = . then tx_div_avg_log_amtday90_2 = 0;

		if intck('second',z03_frst_rqo_utc_trx_dttm, trx_dttm) <= 7200 then do; 
				first_bene_flag_2 = '1';
		end;
		else first_bene_flag_2 = '0';

		*****************************************************************************************************************;
		/*** END of Feature Creation                                                                                  ***/
		*****************************************************************************************************************;

		*------------------------------------------------------------*;
		* DMCAS Release:         8.5;
		* SAS Release:           V.03.05M0P111119;
		* Site Number:           70289724;
		* Host:                  p1fmsprdweb2lxv;
		* Encoding:              utf-8;
		* Java Encoding:         UTF8;
		* Locale:                en_US;
		* Project GUID:          27d5fa90-4237-4a6c-9c2a-b114a8a074eb;
		* Node GUID:             3bd4a5fa-9918-4e4c-9aa3-cccb6c6a1c84;
		* Generated by:          sasinst;
		* Date:                  11AUG2023:04:26:19
		*------------------------------------------------------------*;
		*------------------------------------------------------------*;
		*Nodeid: _3JIL4ZCRUOGN0IJ0WZNP9H7D0;
		*------------------------------------------------------------*;
		   length _strfmt_ $12; drop _strfmt_;
		   _strfmt_ = ' ';

		   array _tlevname_39630203_{2} $1 _temporary_ ( '0'
		   '1');

		   array _dt_fi_39630203_{2} _temporary_;

		   _node_id_ =  0;
		   _new_id_  = -1;
		   nextnode_39630203:
		   if _node_id_ eq 0 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 1;
		               goto ruleend_39630203_node_0;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 2;
		               goto ruleend_39630203_node_0;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 1;
		               goto ruleend_39630203_node_0;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) then do;

		               _new_id_ = 2;
		               goto ruleend_39630203_node_0;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 2;
		               goto ruleend_39630203_node_0;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 1;
		               goto ruleend_39630203_node_0;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 2;
		            goto ruleend_39630203_node_0;
		            end;
		            ruleend_39630203_node_0:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2.69897000433601 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 1;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 2.69897000433601) then do;

		            _new_id_ = 2;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 2;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 1;
		         end;
		         else do;
		         _new_id_ = 2;
		         end;
		   end;
		   else if _node_id_ eq 1 then do;
		         _strfmt_ = left(trim(put(first_bene_flag_2,$1.)));
		         if missing(first_bene_flag_2) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) then do;

		               _new_id_ = 3;
		               goto ruleend_39630203_node_1;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 3;
		               goto ruleend_39630203_node_1;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 4;
		               goto ruleend_39630203_node_1;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 4;
		               goto ruleend_39630203_node_1;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 3;
		               goto ruleend_39630203_node_1;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 4;
		               goto ruleend_39630203_node_1;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 4;
		            goto ruleend_39630203_node_1;
		            end;
		            ruleend_39630203_node_1:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('1') then do;

		         _new_id_ = 3;
		         end;
		         else if _strfmt_ in ('0') then do;

		         _new_id_ = 4;
		         end;
		         else do;
		         _new_id_ = 4;
		         end;
		   end;
		   else if _node_id_ eq 2 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G3',
		               'G1') then do;

		               _new_id_ = 5;
		               goto ruleend_39630203_node_2;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G0') then do;

		               _new_id_ = 6;
		               goto ruleend_39630203_node_2;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 6;
		            goto ruleend_39630203_node_2;
		            end;
		            ruleend_39630203_node_2:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G2',
		         'G3',
		         'G6',
		         'G4',
		         'G5') then do;

		         _new_id_ = 5;
		         end;
		         else if _strfmt_ in ('G1',
		         'G7',
		         'G8',
		         'G9') then do;

		         _new_id_ = 6;
		         end;
		         else do;
		         _new_id_ = 6;
		         end;
		   end;
		   else if _node_id_ eq 3 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G0') then do;

		               _new_id_ = 7;
		               goto ruleend_39630203_node_3;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G3',
		               'G1') then do;

		               _new_id_ = 8;
		               goto ruleend_39630203_node_3;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 7;
		            goto ruleend_39630203_node_3;
		            end;
		            ruleend_39630203_node_3:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G2',
		         'G3',
		         'G0',
		         'G1') then do;

		         _new_id_ = 7;
		         end;
		         else if _strfmt_ in ('G6',
		         'G4',
		         'G5') then do;

		         _new_id_ = 8;
		         end;
		         else do;
		         _new_id_ = 7;
		         end;
		   end;
		   else if _node_id_ eq 4 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) then do;

		               _new_id_ = 9;
		               goto ruleend_39630203_node_4;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 9;
		               goto ruleend_39630203_node_4;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 10;
		               goto ruleend_39630203_node_4;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 10;
		               goto ruleend_39630203_node_4;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 9;
		               goto ruleend_39630203_node_4;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 10;
		               goto ruleend_39630203_node_4;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 10;
		            goto ruleend_39630203_node_4;
		            end;
		            ruleend_39630203_node_4:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 10000 and _numval_ lt 7590170) then do;

		            _new_id_ = 9;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 10000) then do;

		            _new_id_ = 10;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 10;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 9;
		         end;
		         else do;
		         _new_id_ = 10;
		         end;
		   end;
		   else if _node_id_ eq 5 then do;
		         _strfmt_ = left(trim(put(first_bene_flag_2,$1.)));
		         if missing(first_bene_flag_2) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) then do;

		               _new_id_ = 11;
		               goto ruleend_39630203_node_5;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 11;
		               goto ruleend_39630203_node_5;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 12;
		               goto ruleend_39630203_node_5;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 12;
		               goto ruleend_39630203_node_5;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 11;
		               goto ruleend_39630203_node_5;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 12;
		               goto ruleend_39630203_node_5;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 12;
		            goto ruleend_39630203_node_5;
		            end;
		            ruleend_39630203_node_5:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('1') then do;

		         _new_id_ = 11;
		         end;
		         else if _strfmt_ in ('0') then do;

		         _new_id_ = 12;
		         end;
		         else do;
		         _new_id_ = 12;
		         end;
		   end;
		   else if _node_id_ eq 6 then do;
		         _leaf_id_ = 6;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.99862284245317;
		         _dt_fi_39630203_{1} =     0.99862284245317;
		         _dt_fi_39630203_{2} =     0.00137715754682;
		   end;
		   else if _node_id_ eq 7 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G3',
		               'G1') then do;

		               _new_id_ = 13;
		               goto ruleend_39630203_node_7;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G0') then do;

		               _new_id_ = 14;
		               goto ruleend_39630203_node_7;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 14;
		            goto ruleend_39630203_node_7;
		            end;
		            ruleend_39630203_node_7:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G2',
		         'G3',
		         'G6',
		         'G4',
		         'G5') then do;

		         _new_id_ = 13;
		         end;
		         else if _strfmt_ in ('G1',
		         'G7',
		         'G8',
		         'G9') then do;

		         _new_id_ = 14;
		         end;
		         else do;
		         _new_id_ = 14;
		         end;
		   end;
		   else if _node_id_ eq 8 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 15;
		               goto ruleend_39630203_node_8;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 15;
		               goto ruleend_39630203_node_8;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 15;
		               goto ruleend_39630203_node_8;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 15;
		            goto ruleend_39630203_node_8;
		            end;
		            ruleend_39630203_node_8:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G6',
		         'G7',
		         'G5',
		         'G8') then do;

		         _new_id_ = 15;
		         end;
		         else if _strfmt_ in ('G2',
		         'G4') then do;

		         _new_id_ = 16;
		         end;
		         else do;
		         _new_id_ = 15;
		         end;
		   end;
		   else if _node_id_ eq 9 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 17;
		               goto ruleend_39630203_node_9;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 17;
		               goto ruleend_39630203_node_9;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 17;
		               goto ruleend_39630203_node_9;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 17;
		            goto ruleend_39630203_node_9;
		            end;
		            ruleend_39630203_node_9:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G1',
		         'G6',
		         'G7',
		         'G8',
		         'G9') then do;

		         _new_id_ = 17;
		         end;
		         else if _strfmt_ in ('G2',
		         'G3',
		         'G4',
		         'G5') then do;

		         _new_id_ = 18;
		         end;
		         else do;
		         _new_id_ = 17;
		         end;
		   end;
		   else if _node_id_ eq 10 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 19;
		               goto ruleend_39630203_node_10;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 19;
		               goto ruleend_39630203_node_10;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 19;
		               goto ruleend_39630203_node_10;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 20;
		               goto ruleend_39630203_node_10;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 19;
		               goto ruleend_39630203_node_10;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 19;
		               goto ruleend_39630203_node_10;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 20;
		            goto ruleend_39630203_node_10;
		            end;
		            ruleend_39630203_node_10:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1594 and _numval_ lt 187958) then do;

		            _new_id_ = 19;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 1594) then do;

		            _new_id_ = 20;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 20;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 19;
		         end;
		         else do;
		         _new_id_ = 20;
		         end;
		   end;
		   else if _node_id_ eq 11 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 21;
		               goto ruleend_39630203_node_11;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 21;
		               goto ruleend_39630203_node_11;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 21;
		               goto ruleend_39630203_node_11;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 21;
		            goto ruleend_39630203_node_11;
		            end;
		            ruleend_39630203_node_11:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G2',
		         'G3',
		         'G0',
		         'G1',
		         'G4') then do;

		         _new_id_ = 21;
		         end;
		         else if _strfmt_ in ('G6',
		         'G5') then do;

		         _new_id_ = 22;
		         end;
		         else do;
		         _new_id_ = 21;
		         end;
		   end;
		   else if _node_id_ eq 12 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 23;
		               goto ruleend_39630203_node_12;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 24;
		               goto ruleend_39630203_node_12;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 23;
		               goto ruleend_39630203_node_12;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) then do;

		               _new_id_ = 24;
		               goto ruleend_39630203_node_12;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 24;
		               goto ruleend_39630203_node_12;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 23;
		               goto ruleend_39630203_node_12;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 24;
		            goto ruleend_39630203_node_12;
		            end;
		            ruleend_39630203_node_12:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 422 and _numval_ lt 7590170) then do;

		            _new_id_ = 23;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 422) then do;

		            _new_id_ = 24;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 24;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 23;
		         end;
		         else do;
		         _new_id_ = 24;
		         end;
		   end;
		   else if _node_id_ eq 13 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 25;
		               goto ruleend_39630203_node_13;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 25;
		               goto ruleend_39630203_node_13;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 25;
		               goto ruleend_39630203_node_13;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 25;
		            goto ruleend_39630203_node_13;
		            end;
		            ruleend_39630203_node_13:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G6',
		         'G4',
		         'G5') then do;

		         _new_id_ = 25;
		         end;
		         else if _strfmt_ in ('G2',
		         'G3') then do;

		         _new_id_ = 26;
		         end;
		         else do;
		         _new_id_ = 25;
		         end;
		   end;
		   else if _node_id_ eq 14 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 27;
		               goto ruleend_39630203_node_14;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 27;
		               goto ruleend_39630203_node_14;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 27;
		               goto ruleend_39630203_node_14;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) then do;

		               _new_id_ = 28;
		               goto ruleend_39630203_node_14;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 27;
		               goto ruleend_39630203_node_14;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 27;
		               goto ruleend_39630203_node_14;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 28;
		            goto ruleend_39630203_node_14;
		            end;
		            ruleend_39630203_node_14:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.25205179605377 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 27;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.25205179605377) then do;

		            _new_id_ = 28;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 28;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 27;
		         end;
		         else do;
		         _new_id_ = 28;
		         end;
		   end;
		   else if _node_id_ eq 15 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 29;
		               goto ruleend_39630203_node_15;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 29;
		               goto ruleend_39630203_node_15;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 29;
		               goto ruleend_39630203_node_15;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 29;
		            goto ruleend_39630203_node_15;
		            end;
		            ruleend_39630203_node_15:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G4',
		         'G5') then do;

		         _new_id_ = 29;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 30;
		         end;
		         else do;
		         _new_id_ = 29;
		         end;
		   end;
		   else if _node_id_ eq 16 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) then do;

		               _new_id_ = 31;
		               goto ruleend_39630203_node_16;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 31;
		               goto ruleend_39630203_node_16;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 32;
		               goto ruleend_39630203_node_16;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 32;
		               goto ruleend_39630203_node_16;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 31;
		               goto ruleend_39630203_node_16;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 32;
		               goto ruleend_39630203_node_16;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 32;
		            goto ruleend_39630203_node_16;
		            end;
		            ruleend_39630203_node_16:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G6',
		         'G5') then do;

		         _new_id_ = 31;
		         end;
		         else if _strfmt_ in ('G4') then do;

		         _new_id_ = 32;
		         end;
		         else do;
		         _new_id_ = 32;
		         end;
		   end;
		   else if _node_id_ eq 17 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G3',
		               'G0') then do;

		               _new_id_ = 33;
		               goto ruleend_39630203_node_17;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G1') then do;

		               _new_id_ = 34;
		               goto ruleend_39630203_node_17;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 33;
		            goto ruleend_39630203_node_17;
		            end;
		            ruleend_39630203_node_17:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G2',
		         'G3',
		         'G0',
		         'G1',
		         'G5') then do;

		         _new_id_ = 33;
		         end;
		         else if _strfmt_ in ('G6',
		         'G4') then do;

		         _new_id_ = 34;
		         end;
		         else do;
		         _new_id_ = 33;
		         end;
		   end;
		   else if _node_id_ eq 18 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G0') then do;

		               _new_id_ = 35;
		               goto ruleend_39630203_node_18;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G3',
		               'G1') then do;

		               _new_id_ = 36;
		               goto ruleend_39630203_node_18;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 35;
		            goto ruleend_39630203_node_18;
		            end;
		            ruleend_39630203_node_18:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G2',
		         'G3',
		         'G1',
		         'G6') then do;

		         _new_id_ = 35;
		         end;
		         else if _strfmt_ in ('G4',
		         'G5') then do;

		         _new_id_ = 36;
		         end;
		         else do;
		         _new_id_ = 35;
		         end;
		   end;
		   else if _node_id_ eq 19 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 37;
		               goto ruleend_39630203_node_19;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 37;
		               goto ruleend_39630203_node_19;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 37;
		               goto ruleend_39630203_node_19;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 37;
		            goto ruleend_39630203_node_19;
		            end;
		            ruleend_39630203_node_19:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G3',
		         'G1',
		         'G6',
		         'G7',
		         'G4',
		         'G5',
		         'G8',
		         'G9') then do;

		         _new_id_ = 37;
		         end;
		         else if _strfmt_ in ('G2') then do;

		         _new_id_ = 38;
		         end;
		         else do;
		         _new_id_ = 37;
		         end;
		   end;
		   else if _node_id_ eq 20 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 39;
		               goto ruleend_39630203_node_20;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 39;
		               goto ruleend_39630203_node_20;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 39;
		               goto ruleend_39630203_node_20;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 39;
		            goto ruleend_39630203_node_20;
		            end;
		            ruleend_39630203_node_20:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G1',
		         'G6',
		         'G7',
		         'G8',
		         'G9') then do;

		         _new_id_ = 39;
		         end;
		         else if _strfmt_ in ('G2',
		         'G3',
		         'G4',
		         'G5') then do;

		         _new_id_ = 40;
		         end;
		         else do;
		         _new_id_ = 39;
		         end;
		   end;
		   else if _node_id_ eq 21 then do;
		         _leaf_id_ = 21;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.98800827015851;
		         _dt_fi_39630203_{1} =     0.98800827015851;
		         _dt_fi_39630203_{2} =     0.01199172984148;
		   end;
		   else if _node_id_ eq 22 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 41;
		               goto ruleend_39630203_node_22;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 41;
		               goto ruleend_39630203_node_22;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 41;
		               goto ruleend_39630203_node_22;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 41;
		            goto ruleend_39630203_node_22;
		            end;
		            ruleend_39630203_node_22:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G5') then do;

		         _new_id_ = 41;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 42;
		         end;
		         else do;
		         _new_id_ = 41;
		         end;
		   end;
		   else if _node_id_ eq 23 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 43;
		               goto ruleend_39630203_node_23;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 44;
		               goto ruleend_39630203_node_23;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 43;
		               goto ruleend_39630203_node_23;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) then do;

		               _new_id_ = 44;
		               goto ruleend_39630203_node_23;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 44;
		               goto ruleend_39630203_node_23;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 43;
		               goto ruleend_39630203_node_23;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 44;
		            goto ruleend_39630203_node_23;
		            end;
		            ruleend_39630203_node_23:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 10000 and _numval_ lt 7590170) then do;

		            _new_id_ = 43;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 10000) then do;

		            _new_id_ = 44;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 44;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 43;
		         end;
		         else do;
		         _new_id_ = 44;
		         end;
		   end;
		   else if _node_id_ eq 24 then do;
		         _leaf_id_ = 24;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.99844495400753;
		         _dt_fi_39630203_{1} =     0.99844495400753;
		         _dt_fi_39630203_{2} =     0.00155504599246;
		   end;
		   else if _node_id_ eq 25 then do;
		         _leaf_id_ = 25;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.94731444686578;
		         _dt_fi_39630203_{1} =     0.94731444686578;
		         _dt_fi_39630203_{2} =     0.05268555313421;
		   end;
		   else if _node_id_ eq 26 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 45;
		               goto ruleend_39630203_node_26;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 45;
		               goto ruleend_39630203_node_26;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 45;
		               goto ruleend_39630203_node_26;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 46;
		               goto ruleend_39630203_node_26;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 45;
		               goto ruleend_39630203_node_26;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 45;
		               goto ruleend_39630203_node_26;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 46;
		            goto ruleend_39630203_node_26;
		            end;
		            ruleend_39630203_node_26:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.69897000433601 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 45;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.69897000433601) then do;

		            _new_id_ = 46;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 46;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 45;
		         end;
		         else do;
		         _new_id_ = 46;
		         end;
		   end;
		   else if _node_id_ eq 27 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) then do;

		               _new_id_ = 47;
		               goto ruleend_39630203_node_27;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 47;
		               goto ruleend_39630203_node_27;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 48;
		               goto ruleend_39630203_node_27;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 48;
		               goto ruleend_39630203_node_27;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 47;
		               goto ruleend_39630203_node_27;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 48;
		               goto ruleend_39630203_node_27;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 48;
		            goto ruleend_39630203_node_27;
		            end;
		            ruleend_39630203_node_27:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 10000 and _numval_ lt 7590170) then do;

		            _new_id_ = 47;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 10000) then do;

		            _new_id_ = 48;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 48;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 47;
		         end;
		         else do;
		         _new_id_ = 48;
		         end;
		   end;
		   else if _node_id_ eq 28 then do;
		         _leaf_id_ = 28;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.98915119566047;
		         _dt_fi_39630203_{1} =     0.98915119566047;
		         _dt_fi_39630203_{2} =     0.01084880433952;
		   end;
		   else if _node_id_ eq 29 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) then do;

		               _new_id_ = 49;
		               goto ruleend_39630203_node_29;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 49;
		               goto ruleend_39630203_node_29;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 50;
		               goto ruleend_39630203_node_29;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 50;
		               goto ruleend_39630203_node_29;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 49;
		               goto ruleend_39630203_node_29;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 50;
		               goto ruleend_39630203_node_29;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 50;
		            goto ruleend_39630203_node_29;
		            end;
		            ruleend_39630203_node_29:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 4 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 49;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 4) then do;

		            _new_id_ = 50;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 50;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 49;
		         end;
		         else do;
		         _new_id_ = 50;
		         end;
		   end;
		   else if _node_id_ eq 30 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 51;
		               goto ruleend_39630203_node_30;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 51;
		               goto ruleend_39630203_node_30;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 51;
		               goto ruleend_39630203_node_30;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) then do;

		               _new_id_ = 52;
		               goto ruleend_39630203_node_30;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 51;
		               goto ruleend_39630203_node_30;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 51;
		               goto ruleend_39630203_node_30;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 51;
		            goto ruleend_39630203_node_30;
		            end;
		            ruleend_39630203_node_30:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.37401627704963 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 51;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.37401627704963) then do;

		            _new_id_ = 52;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 52;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 51;
		         end;
		         else do;
		         _new_id_ = 51;
		         end;
		   end;
		   else if _node_id_ eq 31 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 53;
		               goto ruleend_39630203_node_31;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 53;
		               goto ruleend_39630203_node_31;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 53;
		               goto ruleend_39630203_node_31;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 53;
		            goto ruleend_39630203_node_31;
		            end;
		            ruleend_39630203_node_31:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G5') then do;

		         _new_id_ = 53;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 54;
		         end;
		         else do;
		         _new_id_ = 53;
		         end;
		   end;
		   else if _node_id_ eq 32 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 55;
		               goto ruleend_39630203_node_32;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 55;
		               goto ruleend_39630203_node_32;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 55;
		               goto ruleend_39630203_node_32;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 56;
		               goto ruleend_39630203_node_32;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 55;
		               goto ruleend_39630203_node_32;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 55;
		               goto ruleend_39630203_node_32;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 56;
		            goto ruleend_39630203_node_32;
		            end;
		            ruleend_39630203_node_32:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 4 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 55;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 4) then do;

		            _new_id_ = 56;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 56;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 55;
		         end;
		         else do;
		         _new_id_ = 56;
		         end;
		   end;
		   else if _node_id_ eq 33 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 57;
		               goto ruleend_39630203_node_33;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 57;
		               goto ruleend_39630203_node_33;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 57;
		               goto ruleend_39630203_node_33;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) then do;

		               _new_id_ = 58;
		               goto ruleend_39630203_node_33;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 57;
		               goto ruleend_39630203_node_33;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 57;
		               goto ruleend_39630203_node_33;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 57;
		            goto ruleend_39630203_node_33;
		            end;
		            ruleend_39630203_node_33:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.36172783601759 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 57;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.36172783601759) then do;

		            _new_id_ = 58;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 58;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 57;
		         end;
		         else do;
		         _new_id_ = 57;
		         end;
		   end;
		   else if _node_id_ eq 34 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 59;
		               goto ruleend_39630203_node_34;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 59;
		               goto ruleend_39630203_node_34;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 59;
		               goto ruleend_39630203_node_34;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) then do;

		               _new_id_ = 60;
		               goto ruleend_39630203_node_34;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 59;
		               goto ruleend_39630203_node_34;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 59;
		               goto ruleend_39630203_node_34;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 59;
		            goto ruleend_39630203_node_34;
		            end;
		            ruleend_39630203_node_34:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.47712125471966 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 59;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.47712125471966) then do;

		            _new_id_ = 60;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 60;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 59;
		         end;
		         else do;
		         _new_id_ = 59;
		         end;
		   end;
		   else if _node_id_ eq 35 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 61;
		               goto ruleend_39630203_node_35;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 61;
		               goto ruleend_39630203_node_35;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 61;
		               goto ruleend_39630203_node_35;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) then do;

		               _new_id_ = 62;
		               goto ruleend_39630203_node_35;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 61;
		               goto ruleend_39630203_node_35;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 61;
		               goto ruleend_39630203_node_35;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 62;
		            goto ruleend_39630203_node_35;
		            end;
		            ruleend_39630203_node_35:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.27841031940134 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 61;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.27841031940134) then do;

		            _new_id_ = 62;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 62;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 61;
		         end;
		         else do;
		         _new_id_ = 62;
		         end;
		   end;
		   else if _node_id_ eq 36 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 63;
		               goto ruleend_39630203_node_36;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 63;
		               goto ruleend_39630203_node_36;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 63;
		               goto ruleend_39630203_node_36;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) then do;

		               _new_id_ = 64;
		               goto ruleend_39630203_node_36;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 63;
		               goto ruleend_39630203_node_36;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 63;
		               goto ruleend_39630203_node_36;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 63;
		            goto ruleend_39630203_node_36;
		            end;
		            ruleend_39630203_node_36:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.18279775531683 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 63;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.18279775531683) then do;

		            _new_id_ = 64;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 64;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 63;
		         end;
		         else do;
		         _new_id_ = 63;
		         end;
		   end;
		   else if _node_id_ eq 37 then do;
		         _leaf_id_ = 37;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.99755479242704;
		         _dt_fi_39630203_{1} =     0.99755479242704;
		         _dt_fi_39630203_{2} =     0.00244520757295;
		   end;
		   else if _node_id_ eq 38 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 65;
		               goto ruleend_39630203_node_38;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 65;
		               goto ruleend_39630203_node_38;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 65;
		               goto ruleend_39630203_node_38;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 1594 and _numval_ lt 1725) then do;

		               _new_id_ = 66;
		               goto ruleend_39630203_node_38;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 65;
		               goto ruleend_39630203_node_38;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 65;
		               goto ruleend_39630203_node_38;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 65;
		            goto ruleend_39630203_node_38;
		            end;
		            ruleend_39630203_node_38:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G2',
		         'G3',
		         'G1',
		         'G4') then do;

		         _new_id_ = 65;
		         end;
		         else if _strfmt_ in ('G6',
		         'G5') then do;

		         _new_id_ = 66;
		         end;
		         else do;
		         _new_id_ = 65;
		         end;
		   end;
		   else if _node_id_ eq 39 then do;
		         _leaf_id_ = 39;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.99164462282222;
		         _dt_fi_39630203_{1} =     0.99164462282222;
		         _dt_fi_39630203_{2} =     0.00835537717777;
		   end;
		   else if _node_id_ eq 40 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G3',
		               'G1') then do;

		               _new_id_ = 67;
		               goto ruleend_39630203_node_40;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G0') then do;

		               _new_id_ = 68;
		               goto ruleend_39630203_node_40;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 68;
		            goto ruleend_39630203_node_40;
		            end;
		            ruleend_39630203_node_40:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G6',
		         'G4',
		         'G5') then do;

		         _new_id_ = 67;
		         end;
		         else if _strfmt_ in ('G2',
		         'G3',
		         'G1') then do;

		         _new_id_ = 68;
		         end;
		         else do;
		         _new_id_ = 68;
		         end;
		   end;
		   else if _node_id_ eq 41 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 69;
		               goto ruleend_39630203_node_41;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 70;
		               goto ruleend_39630203_node_41;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 69;
		               goto ruleend_39630203_node_41;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) then do;

		               _new_id_ = 70;
		               goto ruleend_39630203_node_41;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 70;
		               goto ruleend_39630203_node_41;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 69;
		               goto ruleend_39630203_node_41;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 69;
		            goto ruleend_39630203_node_41;
		            end;
		            ruleend_39630203_node_41:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 69;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 2) then do;

		            _new_id_ = 70;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 70;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 69;
		         end;
		         else do;
		         _new_id_ = 69;
		         end;
		   end;
		   else if _node_id_ eq 42 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 71;
		               goto ruleend_39630203_node_42;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 72;
		               goto ruleend_39630203_node_42;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 71;
		               goto ruleend_39630203_node_42;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) then do;

		               _new_id_ = 72;
		               goto ruleend_39630203_node_42;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 72;
		               goto ruleend_39630203_node_42;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 71;
		               goto ruleend_39630203_node_42;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 72;
		            goto ruleend_39630203_node_42;
		            end;
		            ruleend_39630203_node_42:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 990 and _numval_ lt 7590170) then do;

		            _new_id_ = 71;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 990) then do;

		            _new_id_ = 72;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 72;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 71;
		         end;
		         else do;
		         _new_id_ = 72;
		         end;
		   end;
		   else if _node_id_ eq 43 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G3',
		               'G0',
		               'G1') then do;

		               _new_id_ = 73;
		               goto ruleend_39630203_node_43;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G2') then do;

		               _new_id_ = 74;
		               goto ruleend_39630203_node_43;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 73;
		            goto ruleend_39630203_node_43;
		            end;
		            ruleend_39630203_node_43:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G3',
		         'G6',
		         'G5') then do;

		         _new_id_ = 73;
		         end;
		         else if _strfmt_ in ('G2',
		         'G4') then do;

		         _new_id_ = 74;
		         end;
		         else do;
		         _new_id_ = 73;
		         end;
		   end;
		   else if _node_id_ eq 44 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 75;
		               goto ruleend_39630203_node_44;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 76;
		               goto ruleend_39630203_node_44;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 75;
		               goto ruleend_39630203_node_44;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) then do;

		               _new_id_ = 76;
		               goto ruleend_39630203_node_44;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 76;
		               goto ruleend_39630203_node_44;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 75;
		               goto ruleend_39630203_node_44;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 75;
		            goto ruleend_39630203_node_44;
		            end;
		            ruleend_39630203_node_44:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 0.29133857216946 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 75;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 0.29133857216946) then do;

		            _new_id_ = 76;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 76;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 75;
		         end;
		         else do;
		         _new_id_ = 75;
		         end;
		   end;
		   else if _node_id_ eq 45 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) then do;

		               _new_id_ = 77;
		               goto ruleend_39630203_node_45;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 77;
		               goto ruleend_39630203_node_45;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 78;
		               goto ruleend_39630203_node_45;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 78;
		               goto ruleend_39630203_node_45;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 77;
		               goto ruleend_39630203_node_45;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 78;
		               goto ruleend_39630203_node_45;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 78;
		            goto ruleend_39630203_node_45;
		            end;
		            ruleend_39630203_node_45:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1342 and _numval_ lt 187958) then do;

		            _new_id_ = 77;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 1342) then do;

		            _new_id_ = 78;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 78;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 77;
		         end;
		         else do;
		         _new_id_ = 78;
		         end;
		   end;
		   else if _node_id_ eq 46 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		            if not (missing(RUA_3BYTE_STRING_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G1',
		               'G6',
		               'G7',
		               'G4',
		               'G5',
		               'G8',
		               'G9') then do;

		               _new_id_ = 79;
		               goto ruleend_39630203_node_46;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		            if not (missing(RUA_3BYTE_STRING_006_G)) then do;
		               if _strfmt_ in ('G3') then do;

		               _new_id_ = 80;
		               goto ruleend_39630203_node_46;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 80;
		            goto ruleend_39630203_node_46;
		            end;
		            ruleend_39630203_node_46:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G3',
		         'G1') then do;

		         _new_id_ = 79;
		         end;
		         else if _strfmt_ in ('G2') then do;

		         _new_id_ = 80;
		         end;
		         else do;
		         _new_id_ = 80;
		         end;
		   end;
		   else if _node_id_ eq 47 then do;
		         _strfmt_ = left(trim(put(XQO_LANGUAGE,$12.)));
		         if missing(XQO_LANGUAGE) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) then do;

		               _new_id_ = 81;
		               goto ruleend_39630203_node_47;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 81;
		               goto ruleend_39630203_node_47;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 82;
		               goto ruleend_39630203_node_47;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 82;
		               goto ruleend_39630203_node_47;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 81;
		               goto ruleend_39630203_node_47;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 82;
		               goto ruleend_39630203_node_47;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 82;
		            goto ruleend_39630203_node_47;
		            end;
		            ruleend_39630203_node_47:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('EN') then do;

		         _new_id_ = 81;
		         end;
		         else if _strfmt_ in ('AR') then do;

		         _new_id_ = 82;
		         end;
		         else do;
		         _new_id_ = 82;
		         end;
		   end;
		   else if _node_id_ eq 48 then do;
		         _leaf_id_ = 48;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =      0.9753166753427;
		         _dt_fi_39630203_{1} =      0.9753166753427;
		         _dt_fi_39630203_{2} =     0.02468332465729;
		   end;
		   else if _node_id_ eq 49 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) then do;

		               _new_id_ = 83;
		               goto ruleend_39630203_node_49;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 83;
		               goto ruleend_39630203_node_49;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 84;
		               goto ruleend_39630203_node_49;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 84;
		               goto ruleend_39630203_node_49;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 83;
		               goto ruleend_39630203_node_49;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 84;
		               goto ruleend_39630203_node_49;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 84;
		            goto ruleend_39630203_node_49;
		            end;
		            ruleend_39630203_node_49:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 10000 and _numval_ lt 7590170) then do;

		            _new_id_ = 83;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 10000) then do;

		            _new_id_ = 84;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 84;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 83;
		         end;
		         else do;
		         _new_id_ = 84;
		         end;
		   end;
		   else if _node_id_ eq 50 then do;
		         _leaf_id_ = 50;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.91190974297668;
		         _dt_fi_39630203_{1} =     0.91190974297668;
		         _dt_fi_39630203_{2} =     0.08809025702331;
		   end;
		   else if _node_id_ eq 51 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 85;
		               goto ruleend_39630203_node_51;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 85;
		               goto ruleend_39630203_node_51;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 85;
		               goto ruleend_39630203_node_51;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 85;
		            goto ruleend_39630203_node_51;
		            end;
		            ruleend_39630203_node_51:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G6',
		         'G7',
		         'G5') then do;

		         _new_id_ = 85;
		         end;
		         else if _strfmt_ in ('G8') then do;

		         _new_id_ = 86;
		         end;
		         else do;
		         _new_id_ = 85;
		         end;
		   end;
		   else if _node_id_ eq 52 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 87;
		               goto ruleend_39630203_node_52;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 87;
		               goto ruleend_39630203_node_52;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 87;
		               goto ruleend_39630203_node_52;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) then do;

		               _new_id_ = 88;
		               goto ruleend_39630203_node_52;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 87;
		               goto ruleend_39630203_node_52;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 87;
		               goto ruleend_39630203_node_52;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 87;
		            goto ruleend_39630203_node_52;
		            end;
		            ruleend_39630203_node_52:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 0.98075993480971 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 87;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 0.98075993480971) then do;

		            _new_id_ = 88;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 88;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 87;
		         end;
		         else do;
		         _new_id_ = 87;
		         end;
		   end;
		   else if _node_id_ eq 53 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 89;
		               goto ruleend_39630203_node_53;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 89;
		               goto ruleend_39630203_node_53;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 89;
		               goto ruleend_39630203_node_53;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 90;
		               goto ruleend_39630203_node_53;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 89;
		               goto ruleend_39630203_node_53;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 89;
		               goto ruleend_39630203_node_53;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 90;
		            goto ruleend_39630203_node_53;
		            end;
		            ruleend_39630203_node_53:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.30102999566398 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 89;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.30102999566398) then do;

		            _new_id_ = 90;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 90;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 89;
		         end;
		         else do;
		         _new_id_ = 90;
		         end;
		   end;
		   else if _node_id_ eq 54 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 91;
		               goto ruleend_39630203_node_54;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 91;
		               goto ruleend_39630203_node_54;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 91;
		               goto ruleend_39630203_node_54;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) then do;

		               _new_id_ = 92;
		               goto ruleend_39630203_node_54;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 91;
		               goto ruleend_39630203_node_54;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 91;
		               goto ruleend_39630203_node_54;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 91;
		            goto ruleend_39630203_node_54;
		            end;
		            ruleend_39630203_node_54:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.20440687492471 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 91;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.20440687492471) then do;

		            _new_id_ = 92;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 92;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 91;
		         end;
		         else do;
		         _new_id_ = 91;
		         end;
		   end;
		   else if _node_id_ eq 55 then do;
		         _strfmt_ = left(trim(put(XQO_LANGUAGE,$12.)));
		         if missing(XQO_LANGUAGE) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 93;
		               goto ruleend_39630203_node_55;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 93;
		               goto ruleend_39630203_node_55;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 93;
		               goto ruleend_39630203_node_55;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 94;
		               goto ruleend_39630203_node_55;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 93;
		               goto ruleend_39630203_node_55;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 93;
		               goto ruleend_39630203_node_55;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 94;
		            goto ruleend_39630203_node_55;
		            end;
		            ruleend_39630203_node_55:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('EN') then do;

		         _new_id_ = 93;
		         end;
		         else if _strfmt_ in ('AR') then do;

		         _new_id_ = 94;
		         end;
		         else do;
		         _new_id_ = 94;
		         end;
		   end;
		   else if _node_id_ eq 56 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 95;
		               goto ruleend_39630203_node_56;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 95;
		               goto ruleend_39630203_node_56;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 95;
		               goto ruleend_39630203_node_56;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 95;
		            goto ruleend_39630203_node_56;
		            end;
		            ruleend_39630203_node_56:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G4') then do;

		         _new_id_ = 95;
		         end;
		         else if _strfmt_ in ('G2') then do;

		         _new_id_ = 96;
		         end;
		         else do;
		         _new_id_ = 95;
		         end;
		   end;
		   else if _node_id_ eq 57 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 97;
		               goto ruleend_39630203_node_57;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 97;
		               goto ruleend_39630203_node_57;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 97;
		               goto ruleend_39630203_node_57;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 97;
		            goto ruleend_39630203_node_57;
		            end;
		            ruleend_39630203_node_57:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.22752805207252 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 97;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.22752805207252) then do;

		            _new_id_ = 98;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 98;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 97;
		         end;
		         else do;
		         _new_id_ = 97;
		         end;
		   end;
		   else if _node_id_ eq 58 then do;
		         _leaf_id_ = 58;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.98504672897196;
		         _dt_fi_39630203_{1} =     0.98504672897196;
		         _dt_fi_39630203_{2} =     0.01495327102803;
		   end;
		   else if _node_id_ eq 59 then do;
		         _strfmt_ = left(trim(put(XQO_LANGUAGE,$12.)));
		         if missing(XQO_LANGUAGE) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) then do;

		               _new_id_ = 99;
		               goto ruleend_39630203_node_59;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 99;
		               goto ruleend_39630203_node_59;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 100;
		               goto ruleend_39630203_node_59;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 100;
		               goto ruleend_39630203_node_59;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 99;
		               goto ruleend_39630203_node_59;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 100;
		               goto ruleend_39630203_node_59;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 100;
		            goto ruleend_39630203_node_59;
		            end;
		            ruleend_39630203_node_59:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('EN') then do;

		         _new_id_ = 99;
		         end;
		         else if _strfmt_ in ('AR') then do;

		         _new_id_ = 100;
		         end;
		         else do;
		         _new_id_ = 100;
		         end;
		   end;
		   else if _node_id_ eq 60 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 101;
		               goto ruleend_39630203_node_60;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 101;
		               goto ruleend_39630203_node_60;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 101;
		               goto ruleend_39630203_node_60;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 101;
		            goto ruleend_39630203_node_60;
		            end;
		            ruleend_39630203_node_60:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G4') then do;

		         _new_id_ = 101;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 102;
		         end;
		         else do;
		         _new_id_ = 101;
		         end;
		   end;
		   else if _node_id_ eq 61 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 103;
		               goto ruleend_39630203_node_61;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 103;
		               goto ruleend_39630203_node_61;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 103;
		               goto ruleend_39630203_node_61;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 103;
		            goto ruleend_39630203_node_61;
		            end;
		            ruleend_39630203_node_61:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G3',
		         'G4',
		         'G5') then do;

		         _new_id_ = 103;
		         end;
		         else if _strfmt_ in ('G2') then do;

		         _new_id_ = 104;
		         end;
		         else do;
		         _new_id_ = 103;
		         end;
		   end;
		   else if _node_id_ eq 62 then do;
		         _leaf_id_ = 62;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.98076923076923;
		         _dt_fi_39630203_{1} =     0.98076923076923;
		         _dt_fi_39630203_{2} =     0.01923076923076;
		   end;
		   else if _node_id_ eq 63 then do;
		         _strfmt_ = left(trim(put(XQO_LANGUAGE,$12.)));
		         if missing(XQO_LANGUAGE) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) then do;

		               _new_id_ = 105;
		               goto ruleend_39630203_node_63;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 105;
		               goto ruleend_39630203_node_63;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 106;
		               goto ruleend_39630203_node_63;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 106;
		               goto ruleend_39630203_node_63;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 105;
		               goto ruleend_39630203_node_63;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 106;
		               goto ruleend_39630203_node_63;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 106;
		            goto ruleend_39630203_node_63;
		            end;
		            ruleend_39630203_node_63:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('EN') then do;

		         _new_id_ = 105;
		         end;
		         else if _strfmt_ in ('AR') then do;

		         _new_id_ = 106;
		         end;
		         else do;
		         _new_id_ = 106;
		         end;
		   end;
		   else if _node_id_ eq 64 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 107;
		               goto ruleend_39630203_node_64;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 107;
		               goto ruleend_39630203_node_64;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 107;
		               goto ruleend_39630203_node_64;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 1594 and _numval_ lt 1725) then do;

		               _new_id_ = 108;
		               goto ruleend_39630203_node_64;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 107;
		               goto ruleend_39630203_node_64;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 107;
		               goto ruleend_39630203_node_64;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 107;
		            goto ruleend_39630203_node_64;
		            end;
		            ruleend_39630203_node_64:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G4',
		         'G5') then do;

		         _new_id_ = 107;
		         end;
		         else if _strfmt_ in ('G2') then do;

		         _new_id_ = 108;
		         end;
		         else do;
		         _new_id_ = 107;
		         end;
		   end;
		   else if _node_id_ eq 65 then do;
		         _leaf_id_ = 65;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.97222222222222;
		         _dt_fi_39630203_{1} =     0.97222222222222;
		         _dt_fi_39630203_{2} =     0.02777777777777;
		   end;
		   else if _node_id_ eq 66 then do;
		         _leaf_id_ = 66;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                0.625;
		         _dt_fi_39630203_{1} =                0.375;
		         _dt_fi_39630203_{2} =                0.625;
		   end;
		   else if _node_id_ eq 67 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 109;
		               goto ruleend_39630203_node_67;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 109;
		               goto ruleend_39630203_node_67;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 109;
		               goto ruleend_39630203_node_67;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) then do;

		               _new_id_ = 110;
		               goto ruleend_39630203_node_67;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 109;
		               goto ruleend_39630203_node_67;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 109;
		               goto ruleend_39630203_node_67;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 110;
		            goto ruleend_39630203_node_67;
		            end;
		            ruleend_39630203_node_67:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.27841031940134 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 109;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.27841031940134) then do;

		            _new_id_ = 110;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 110;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 109;
		         end;
		         else do;
		         _new_id_ = 110;
		         end;
		   end;
		   else if _node_id_ eq 68 then do;
		         _leaf_id_ = 68;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.97833037300177;
		         _dt_fi_39630203_{1} =     0.97833037300177;
		         _dt_fi_39630203_{2} =     0.02166962699822;
		   end;
		   else if _node_id_ eq 69 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 111;
		               goto ruleend_39630203_node_69;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 111;
		               goto ruleend_39630203_node_69;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 111;
		               goto ruleend_39630203_node_69;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 111;
		            goto ruleend_39630203_node_69;
		            end;
		            ruleend_39630203_node_69:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G6',
		         'G5') then do;

		         _new_id_ = 111;
		         end;
		         else if _strfmt_ in ('G2',
		         'G4') then do;

		         _new_id_ = 112;
		         end;
		         else do;
		         _new_id_ = 111;
		         end;
		   end;
		   else if _node_id_ eq 70 then do;
		         _leaf_id_ = 70;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.98397040690505;
		         _dt_fi_39630203_{1} =     0.98397040690505;
		         _dt_fi_39630203_{2} =     0.01602959309494;
		   end;
		   else if _node_id_ eq 71 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 113;
		               goto ruleend_39630203_node_71;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 113;
		               goto ruleend_39630203_node_71;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 113;
		               goto ruleend_39630203_node_71;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0.29133857216946) then do;

		               _new_id_ = 114;
		               goto ruleend_39630203_node_71;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 113;
		               goto ruleend_39630203_node_71;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 113;
		               goto ruleend_39630203_node_71;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 113;
		            goto ruleend_39630203_node_71;
		            end;
		            ruleend_39630203_node_71:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 0.65321251377534 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 113;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 0.65321251377534) then do;

		            _new_id_ = 114;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 114;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 113;
		         end;
		         else do;
		         _new_id_ = 113;
		         end;
		   end;
		   else if _node_id_ eq 72 then do;
		         _leaf_id_ = 72;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.82933333333333;
		         _dt_fi_39630203_{1} =     0.82933333333333;
		         _dt_fi_39630203_{2} =     0.17066666666666;
		   end;
		   else if _node_id_ eq 73 then do;
		         _leaf_id_ = 73;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.97514340344168;
		         _dt_fi_39630203_{1} =     0.97514340344168;
		         _dt_fi_39630203_{2} =     0.02485659655831;
		   end;
		   else if _node_id_ eq 74 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 115;
		               goto ruleend_39630203_node_74;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 116;
		               goto ruleend_39630203_node_74;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 115;
		               goto ruleend_39630203_node_74;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) then do;

		               _new_id_ = 116;
		               goto ruleend_39630203_node_74;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 116;
		               goto ruleend_39630203_node_74;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 115;
		               goto ruleend_39630203_node_74;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 115;
		            goto ruleend_39630203_node_74;
		            end;
		            ruleend_39630203_node_74:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 0.87759302401866 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 115;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 0.87759302401866) then do;

		            _new_id_ = 116;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 116;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 115;
		         end;
		         else do;
		         _new_id_ = 115;
		         end;
		   end;
		   else if _node_id_ eq 75 then do;
		         _leaf_id_ = 75;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.99043443603029;
		         _dt_fi_39630203_{1} =     0.99043443603029;
		         _dt_fi_39630203_{2} =      0.0095655639697;
		   end;
		   else if _node_id_ eq 76 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 117;
		               goto ruleend_39630203_node_76;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 117;
		               goto ruleend_39630203_node_76;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 117;
		               goto ruleend_39630203_node_76;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 117;
		            goto ruleend_39630203_node_76;
		            end;
		            ruleend_39630203_node_76:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G2',
		         'G3',
		         'G4',
		         'G5') then do;

		         _new_id_ = 117;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 118;
		         end;
		         else do;
		         _new_id_ = 117;
		         end;
		   end;
		   else if _node_id_ eq 77 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) then do;

		               _new_id_ = 119;
		               goto ruleend_39630203_node_77;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 119;
		               goto ruleend_39630203_node_77;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 120;
		               goto ruleend_39630203_node_77;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 120;
		               goto ruleend_39630203_node_77;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 119;
		               goto ruleend_39630203_node_77;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 120;
		               goto ruleend_39630203_node_77;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 119;
		            goto ruleend_39630203_node_77;
		            end;
		            ruleend_39630203_node_77:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 4 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 119;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 4) then do;

		            _new_id_ = 120;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 120;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 119;
		         end;
		         else do;
		         _new_id_ = 119;
		         end;
		   end;
		   else if _node_id_ eq 78 then do;
		         _leaf_id_ = 78;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.93103448275862;
		         _dt_fi_39630203_{1} =     0.93103448275862;
		         _dt_fi_39630203_{2} =     0.06896551724137;
		   end;
		   else if _node_id_ eq 79 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 121;
		               goto ruleend_39630203_node_79;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 121;
		               goto ruleend_39630203_node_79;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 121;
		               goto ruleend_39630203_node_79;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) then do;

		               _new_id_ = 122;
		               goto ruleend_39630203_node_79;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 121;
		               goto ruleend_39630203_node_79;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 121;
		               goto ruleend_39630203_node_79;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 122;
		            goto ruleend_39630203_node_79;
		            end;
		            ruleend_39630203_node_79:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.33880155571007 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 121;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.33880155571007) then do;

		            _new_id_ = 122;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 122;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 121;
		         end;
		         else do;
		         _new_id_ = 122;
		         end;
		   end;
		   else if _node_id_ eq 80 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 123;
		               goto ruleend_39630203_node_80;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 123;
		               goto ruleend_39630203_node_80;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 123;
		               goto ruleend_39630203_node_80;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) then do;

		               _new_id_ = 124;
		               goto ruleend_39630203_node_80;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 123;
		               goto ruleend_39630203_node_80;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 123;
		               goto ruleend_39630203_node_80;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 123;
		            goto ruleend_39630203_node_80;
		            end;
		            ruleend_39630203_node_80:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 19 and _numval_ lt 187958) then do;

		            _new_id_ = 123;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 19) then do;

		            _new_id_ = 124;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 124;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 123;
		         end;
		         else do;
		         _new_id_ = 123;
		         end;
		   end;
		   else if _node_id_ eq 81 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		            if not (missing(RUA_3BYTE_STRING_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G3',
		               'G6',
		               'G7',
		               'G4',
		               'G5',
		               'G8',
		               'G9') then do;

		               _new_id_ = 125;
		               goto ruleend_39630203_node_81;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		            if not (missing(RUA_3BYTE_STRING_006_G)) then do;
		               if _strfmt_ in ('G1') then do;

		               _new_id_ = 126;
		               goto ruleend_39630203_node_81;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 125;
		            goto ruleend_39630203_node_81;
		            end;
		            ruleend_39630203_node_81:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G2',
		         'G3') then do;

		         _new_id_ = 125;
		         end;
		         else if _strfmt_ in ('G1') then do;

		         _new_id_ = 126;
		         end;
		         else do;
		         _new_id_ = 125;
		         end;
		   end;
		   else if _node_id_ eq 82 then do;
		         _leaf_id_ = 82;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.90438695163104;
		         _dt_fi_39630203_{1} =     0.90438695163104;
		         _dt_fi_39630203_{2} =     0.09561304836895;
		   end;
		   else if _node_id_ eq 83 then do;
		         _strfmt_ = left(trim(put(XQO_LANGUAGE,$12.)));
		         if missing(XQO_LANGUAGE) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		            if not (missing(RUA_3BYTE_STRING_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G3',
		               'G1',
		               'G4',
		               'G8',
		               'G9') then do;

		               _new_id_ = 127;
		               goto ruleend_39630203_node_83;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		            if not (missing(RUA_3BYTE_STRING_006_G)) then do;
		               if _strfmt_ in ('G6',
		               'G7',
		               'G5') then do;

		               _new_id_ = 128;
		               goto ruleend_39630203_node_83;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 128;
		            goto ruleend_39630203_node_83;
		            end;
		            ruleend_39630203_node_83:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('EN') then do;

		         _new_id_ = 127;
		         end;
		         else if _strfmt_ in ('AR') then do;

		         _new_id_ = 128;
		         end;
		         else do;
		         _new_id_ = 128;
		         end;
		   end;
		   else if _node_id_ eq 84 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 129;
		               goto ruleend_39630203_node_84;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 129;
		               goto ruleend_39630203_node_84;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 129;
		               goto ruleend_39630203_node_84;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) then do;

		               _new_id_ = 130;
		               goto ruleend_39630203_node_84;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 129;
		               goto ruleend_39630203_node_84;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 129;
		               goto ruleend_39630203_node_84;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 129;
		            goto ruleend_39630203_node_84;
		            end;
		            ruleend_39630203_node_84:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.33880155571007 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 129;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.33880155571007) then do;

		            _new_id_ = 130;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 130;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 129;
		         end;
		         else do;
		         _new_id_ = 129;
		         end;
		   end;
		   else if _node_id_ eq 85 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 131;
		               goto ruleend_39630203_node_85;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 131;
		               goto ruleend_39630203_node_85;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 131;
		               goto ruleend_39630203_node_85;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) then do;

		               _new_id_ = 132;
		               goto ruleend_39630203_node_85;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 131;
		               goto ruleend_39630203_node_85;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 131;
		               goto ruleend_39630203_node_85;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 132;
		            goto ruleend_39630203_node_85;
		            end;
		            ruleend_39630203_node_85:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 10000 and _numval_ lt 7590170) then do;

		            _new_id_ = 131;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 10000) then do;

		            _new_id_ = 132;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 132;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 131;
		         end;
		         else do;
		         _new_id_ = 132;
		         end;
		   end;
		   else if _node_id_ eq 86 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 133;
		               goto ruleend_39630203_node_86;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 133;
		               goto ruleend_39630203_node_86;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 133;
		               goto ruleend_39630203_node_86;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) then do;

		               _new_id_ = 134;
		               goto ruleend_39630203_node_86;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 133;
		               goto ruleend_39630203_node_86;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 133;
		               goto ruleend_39630203_node_86;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 134;
		            goto ruleend_39630203_node_86;
		            end;
		            ruleend_39630203_node_86:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.69057272462515 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 133;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.69057272462515) then do;

		            _new_id_ = 134;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 134;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 133;
		         end;
		         else do;
		         _new_id_ = 134;
		         end;
		   end;
		   else if _node_id_ eq 87 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 135;
		               goto ruleend_39630203_node_87;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 135;
		               goto ruleend_39630203_node_87;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 135;
		               goto ruleend_39630203_node_87;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 136;
		               goto ruleend_39630203_node_87;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 135;
		               goto ruleend_39630203_node_87;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 135;
		               goto ruleend_39630203_node_87;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 136;
		            goto ruleend_39630203_node_87;
		            end;
		            ruleend_39630203_node_87:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.47712125471966 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 135;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.47712125471966) then do;

		            _new_id_ = 136;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 136;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 135;
		         end;
		         else do;
		         _new_id_ = 136;
		         end;
		   end;
		   else if _node_id_ eq 88 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 137;
		               goto ruleend_39630203_node_88;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 137;
		               goto ruleend_39630203_node_88;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 137;
		               goto ruleend_39630203_node_88;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 137;
		            goto ruleend_39630203_node_88;
		            end;
		            ruleend_39630203_node_88:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G6',
		         'G7',
		         'G5') then do;

		         _new_id_ = 137;
		         end;
		         else if _strfmt_ in ('G8') then do;

		         _new_id_ = 138;
		         end;
		         else do;
		         _new_id_ = 137;
		         end;
		   end;
		   else if _node_id_ eq 89 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 139;
		               goto ruleend_39630203_node_89;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 139;
		               goto ruleend_39630203_node_89;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 139;
		               goto ruleend_39630203_node_89;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 139;
		            goto ruleend_39630203_node_89;
		            end;
		            ruleend_39630203_node_89:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G4') then do;

		         _new_id_ = 139;
		         end;
		         else if _strfmt_ in ('G2') then do;

		         _new_id_ = 140;
		         end;
		         else do;
		         _new_id_ = 139;
		         end;
		   end;
		   else if _node_id_ eq 90 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 141;
		               goto ruleend_39630203_node_90;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 141;
		               goto ruleend_39630203_node_90;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 141;
		               goto ruleend_39630203_node_90;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) then do;

		               _new_id_ = 142;
		               goto ruleend_39630203_node_90;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 141;
		               goto ruleend_39630203_node_90;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 141;
		               goto ruleend_39630203_node_90;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 141;
		            goto ruleend_39630203_node_90;
		            end;
		            ruleend_39630203_node_90:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 141;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3) then do;

		            _new_id_ = 142;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 142;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 141;
		         end;
		         else do;
		         _new_id_ = 141;
		         end;
		   end;
		   else if _node_id_ eq 91 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 143;
		               goto ruleend_39630203_node_91;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 143;
		               goto ruleend_39630203_node_91;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 143;
		               goto ruleend_39630203_node_91;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 144;
		               goto ruleend_39630203_node_91;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 143;
		               goto ruleend_39630203_node_91;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 143;
		               goto ruleend_39630203_node_91;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 144;
		            goto ruleend_39630203_node_91;
		            end;
		            ruleend_39630203_node_91:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.36172783601759 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 143;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.36172783601759) then do;

		            _new_id_ = 144;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 144;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 143;
		         end;
		         else do;
		         _new_id_ = 144;
		         end;
		   end;
		   else if _node_id_ eq 92 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 145;
		               goto ruleend_39630203_node_92;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 145;
		               goto ruleend_39630203_node_92;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 145;
		               goto ruleend_39630203_node_92;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 145;
		            goto ruleend_39630203_node_92;
		            end;
		            ruleend_39630203_node_92:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2.77815125038364 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 145;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 2.77815125038364) then do;

		            _new_id_ = 146;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 146;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 145;
		         end;
		         else do;
		         _new_id_ = 145;
		         end;
		   end;
		   else if _node_id_ eq 93 then do;
		         _leaf_id_ = 93;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.95138888888888;
		         _dt_fi_39630203_{1} =     0.04861111111111;
		         _dt_fi_39630203_{2} =     0.95138888888888;
		   end;
		   else if _node_id_ eq 94 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            3725 and _numval_ lt 4116) then do;

		               _new_id_ = 147;
		               goto ruleend_39630203_node_94;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 147;
		               goto ruleend_39630203_node_94;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 148;
		               goto ruleend_39630203_node_94;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 148;
		               goto ruleend_39630203_node_94;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 147;
		               goto ruleend_39630203_node_94;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 148;
		               goto ruleend_39630203_node_94;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 148;
		            goto ruleend_39630203_node_94;
		            end;
		            ruleend_39630203_node_94:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 10000 and _numval_ lt 7590170) then do;

		            _new_id_ = 147;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 10000) then do;

		            _new_id_ = 148;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 148;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 147;
		         end;
		         else do;
		         _new_id_ = 148;
		         end;
		   end;
		   else if _node_id_ eq 95 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 149;
		               goto ruleend_39630203_node_95;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 149;
		               goto ruleend_39630203_node_95;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 149;
		               goto ruleend_39630203_node_95;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) then do;

		               _new_id_ = 150;
		               goto ruleend_39630203_node_95;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 149;
		               goto ruleend_39630203_node_95;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 149;
		               goto ruleend_39630203_node_95;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 150;
		            goto ruleend_39630203_node_95;
		            end;
		            ruleend_39630203_node_95:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 10000 and _numval_ lt 7590170) then do;

		            _new_id_ = 149;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 10000) then do;

		            _new_id_ = 150;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 150;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 149;
		         end;
		         else do;
		         _new_id_ = 150;
		         end;
		   end;
		   else if _node_id_ eq 96 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 151;
		               goto ruleend_39630203_node_96;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 151;
		               goto ruleend_39630203_node_96;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 151;
		               goto ruleend_39630203_node_96;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) then do;

		               _new_id_ = 152;
		               goto ruleend_39630203_node_96;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 151;
		               goto ruleend_39630203_node_96;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 151;
		               goto ruleend_39630203_node_96;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 151;
		            goto ruleend_39630203_node_96;
		            end;
		            ruleend_39630203_node_96:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.04066299138769 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 151;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.04066299138769) then do;

		            _new_id_ = 152;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 152;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 151;
		         end;
		         else do;
		         _new_id_ = 151;
		         end;
		   end;
		   else if _node_id_ eq 97 then do;
		         _leaf_id_ = 97;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.97624521072796;
		         _dt_fi_39630203_{1} =     0.97624521072796;
		         _dt_fi_39630203_{2} =     0.02375478927203;
		   end;
		   else if _node_id_ eq 98 then do;
		         _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		         if missing(RUA_IND_006_G) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		            if not (missing(bene_bank_name_G)) then do;
		               if _strfmt_ in ('G3',
		               'G0',
		               'G6',
		               'G4',
		               'G5') then do;

		               _new_id_ = 153;
		               goto ruleend_39630203_node_98;
		               end;
		            end;
		            _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		            if not (missing(bene_bank_name_G)) then do;
		               if _strfmt_ in ('G2',
		               'G1') then do;

		               _new_id_ = 154;
		               goto ruleend_39630203_node_98;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 154;
		            goto ruleend_39630203_node_98;
		            end;
		            ruleend_39630203_node_98:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G0',
		         'G1') then do;

		         _new_id_ = 153;
		         end;
		         else if _strfmt_ in ('G2') then do;

		         _new_id_ = 154;
		         end;
		         else do;
		         _new_id_ = 154;
		         end;
		   end;
		   else if _node_id_ eq 99 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) then do;

		               _new_id_ = 155;
		               goto ruleend_39630203_node_99;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 155;
		               goto ruleend_39630203_node_99;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 156;
		               goto ruleend_39630203_node_99;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 156;
		               goto ruleend_39630203_node_99;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 155;
		               goto ruleend_39630203_node_99;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 156;
		               goto ruleend_39630203_node_99;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 156;
		            goto ruleend_39630203_node_99;
		            end;
		            ruleend_39630203_node_99:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.51774507303653 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 155;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.51774507303653) then do;

		            _new_id_ = 156;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 156;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 155;
		         end;
		         else do;
		         _new_id_ = 156;
		         end;
		   end;
		   else if _node_id_ eq 100 then do;
		         _leaf_id_ = 100;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.97807757166947;
		         _dt_fi_39630203_{1} =     0.97807757166947;
		         _dt_fi_39630203_{2} =     0.02192242833052;
		   end;
		   else if _node_id_ eq 101 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 157;
		               goto ruleend_39630203_node_101;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 157;
		               goto ruleend_39630203_node_101;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 157;
		               goto ruleend_39630203_node_101;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) then do;

		               _new_id_ = 158;
		               goto ruleend_39630203_node_101;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 157;
		               goto ruleend_39630203_node_101;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 157;
		               goto ruleend_39630203_node_101;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 158;
		            goto ruleend_39630203_node_101;
		            end;
		            ruleend_39630203_node_101:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.20440687492471 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 157;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.20440687492471) then do;

		            _new_id_ = 158;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 158;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 157;
		         end;
		         else do;
		         _new_id_ = 158;
		         end;
		   end;
		   else if _node_id_ eq 102 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 159;
		               goto ruleend_39630203_node_102;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 159;
		               goto ruleend_39630203_node_102;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 159;
		               goto ruleend_39630203_node_102;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) then do;

		               _new_id_ = 160;
		               goto ruleend_39630203_node_102;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 159;
		               goto ruleend_39630203_node_102;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 159;
		               goto ruleend_39630203_node_102;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 159;
		            goto ruleend_39630203_node_102;
		            end;
		            ruleend_39630203_node_102:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.0097417351308 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 159;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.0097417351308) then do;

		            _new_id_ = 160;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 160;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 159;
		         end;
		         else do;
		         _new_id_ = 159;
		         end;
		   end;
		   else if _node_id_ eq 103 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 161;
		               goto ruleend_39630203_node_103;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 161;
		               goto ruleend_39630203_node_103;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 161;
		               goto ruleend_39630203_node_103;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 161;
		            goto ruleend_39630203_node_103;
		            end;
		            ruleend_39630203_node_103:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.09691001300805 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 161;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.09691001300805) then do;

		            _new_id_ = 162;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 162;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 161;
		         end;
		         else do;
		         _new_id_ = 161;
		         end;
		   end;
		   else if _node_id_ eq 104 then do;
		         _leaf_id_ = 104;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                0.875;
		         _dt_fi_39630203_{1} =                0.125;
		         _dt_fi_39630203_{2} =                0.875;
		   end;
		   else if _node_id_ eq 105 then do;
		         _leaf_id_ = 105;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    0;
		         _dt_fi_39630203_{2} =                    1;
		   end;
		   else if _node_id_ eq 106 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 163;
		               goto ruleend_39630203_node_106;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 163;
		               goto ruleend_39630203_node_106;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 163;
		               goto ruleend_39630203_node_106;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) then do;

		               _new_id_ = 164;
		               goto ruleend_39630203_node_106;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 163;
		               goto ruleend_39630203_node_106;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 163;
		               goto ruleend_39630203_node_106;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 163;
		            goto ruleend_39630203_node_106;
		            end;
		            ruleend_39630203_node_106:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 4 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 163;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 4) then do;

		            _new_id_ = 164;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 164;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 163;
		         end;
		         else do;
		         _new_id_ = 163;
		         end;
		   end;
		   else if _node_id_ eq 107 then do;
		         _leaf_id_ = 107;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =      0.9381443298969;
		         _dt_fi_39630203_{1} =      0.9381443298969;
		         _dt_fi_39630203_{2} =     0.06185567010309;
		   end;
		   else if _node_id_ eq 108 then do;
		         _leaf_id_ = 108;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.83333333333333;
		         _dt_fi_39630203_{1} =     0.16666666666666;
		         _dt_fi_39630203_{2} =     0.83333333333333;
		   end;
		   else if _node_id_ eq 109 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 165;
		               goto ruleend_39630203_node_109;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 165;
		               goto ruleend_39630203_node_109;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 165;
		               goto ruleend_39630203_node_109;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) then do;

		               _new_id_ = 166;
		               goto ruleend_39630203_node_109;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 165;
		               goto ruleend_39630203_node_109;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 165;
		               goto ruleend_39630203_node_109;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 166;
		            goto ruleend_39630203_node_109;
		            end;
		            ruleend_39630203_node_109:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 4 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 165;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 4) then do;

		            _new_id_ = 166;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 166;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 165;
		         end;
		         else do;
		         _new_id_ = 166;
		         end;
		   end;
		   else if _node_id_ eq 110 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 167;
		               goto ruleend_39630203_node_110;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 167;
		               goto ruleend_39630203_node_110;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 167;
		               goto ruleend_39630203_node_110;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 167;
		            goto ruleend_39630203_node_110;
		            end;
		            ruleend_39630203_node_110:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 0.29133857216946 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 167;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 0.29133857216946) then do;

		            _new_id_ = 168;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 168;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 167;
		         end;
		         else do;
		         _new_id_ = 167;
		         end;
		   end;
		   else if _node_id_ eq 111 then do;
		         _leaf_id_ = 111;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.94668820678513;
		         _dt_fi_39630203_{1} =     0.94668820678513;
		         _dt_fi_39630203_{2} =     0.05331179321486;
		   end;
		   else if _node_id_ eq 112 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 169;
		               goto ruleend_39630203_node_112;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 169;
		               goto ruleend_39630203_node_112;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 169;
		               goto ruleend_39630203_node_112;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge 2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) then do;

		               _new_id_ = 170;
		               goto ruleend_39630203_node_112;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 169;
		               goto ruleend_39630203_node_112;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 169;
		               goto ruleend_39630203_node_112;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 170;
		            goto ruleend_39630203_node_112;
		            end;
		            ruleend_39630203_node_112:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 0.99588664142607 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 169;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 0.99588664142607) then do;

		            _new_id_ = 170;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 170;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 169;
		         end;
		         else do;
		         _new_id_ = 170;
		         end;
		   end;
		   else if _node_id_ eq 113 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 171;
		               goto ruleend_39630203_node_113;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 171;
		               goto ruleend_39630203_node_113;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 171;
		               goto ruleend_39630203_node_113;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) then do;

		               _new_id_ = 172;
		               goto ruleend_39630203_node_113;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 171;
		               goto ruleend_39630203_node_113;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 171;
		               goto ruleend_39630203_node_113;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 171;
		            goto ruleend_39630203_node_113;
		            end;
		            ruleend_39630203_node_113:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 0.83076779785676 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 171;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 0.83076779785676) then do;

		            _new_id_ = 172;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 172;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 171;
		         end;
		         else do;
		         _new_id_ = 171;
		         end;
		   end;
		   else if _node_id_ eq 114 then do;
		         _leaf_id_ = 114;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.92307692307692;
		         _dt_fi_39630203_{1} =     0.07692307692307;
		         _dt_fi_39630203_{2} =     0.92307692307692;
		   end;
		   else if _node_id_ eq 115 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 173;
		               goto ruleend_39630203_node_115;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 173;
		               goto ruleend_39630203_node_115;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 173;
		               goto ruleend_39630203_node_115;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) then do;

		               _new_id_ = 174;
		               goto ruleend_39630203_node_115;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 173;
		               goto ruleend_39630203_node_115;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 173;
		               goto ruleend_39630203_node_115;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 174;
		            goto ruleend_39630203_node_115;
		            end;
		            ruleend_39630203_node_115:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 60 and _numval_ lt 187958) then do;

		            _new_id_ = 173;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 60) then do;

		            _new_id_ = 174;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 174;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 173;
		         end;
		         else do;
		         _new_id_ = 174;
		         end;
		   end;
		   else if _node_id_ eq 116 then do;
		         _leaf_id_ = 116;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    1;
		         _dt_fi_39630203_{2} =                    0;
		   end;
		   else if _node_id_ eq 117 then do;
		         _leaf_id_ = 117;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.94189602446483;
		         _dt_fi_39630203_{1} =     0.94189602446483;
		         _dt_fi_39630203_{2} =     0.05810397553516;
		   end;
		   else if _node_id_ eq 118 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 175;
		               goto ruleend_39630203_node_118;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 176;
		               goto ruleend_39630203_node_118;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 175;
		               goto ruleend_39630203_node_118;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) then do;

		               _new_id_ = 176;
		               goto ruleend_39630203_node_118;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 176;
		               goto ruleend_39630203_node_118;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 175;
		               goto ruleend_39630203_node_118;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 175;
		            goto ruleend_39630203_node_118;
		            end;
		            ruleend_39630203_node_118:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G4',
		         'G5') then do;

		         _new_id_ = 175;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 176;
		         end;
		         else do;
		         _new_id_ = 175;
		         end;
		   end;
		   else if _node_id_ eq 119 then do;
		         _leaf_id_ = 119;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.86666666666666;
		         _dt_fi_39630203_{1} =     0.86666666666666;
		         _dt_fi_39630203_{2} =     0.13333333333333;
		   end;
		   else if _node_id_ eq 120 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) then do;

		               _new_id_ = 177;
		               goto ruleend_39630203_node_120;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 177;
		               goto ruleend_39630203_node_120;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 178;
		               goto ruleend_39630203_node_120;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 178;
		               goto ruleend_39630203_node_120;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 177;
		               goto ruleend_39630203_node_120;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 178;
		               goto ruleend_39630203_node_120;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 177;
		            goto ruleend_39630203_node_120;
		            end;
		            ruleend_39630203_node_120:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 4397 and _numval_ lt 187958) then do;

		            _new_id_ = 177;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 4397) then do;

		            _new_id_ = 178;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 178;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 177;
		         end;
		         else do;
		         _new_id_ = 177;
		         end;
		   end;
		   else if _node_id_ eq 121 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            990 and _numval_ lt 1300) then do;

		               _new_id_ = 179;
		               goto ruleend_39630203_node_121;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 179;
		               goto ruleend_39630203_node_121;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 180;
		               goto ruleend_39630203_node_121;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 150 and _numval_ lt 200) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 180;
		               goto ruleend_39630203_node_121;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 179;
		               goto ruleend_39630203_node_121;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 180;
		               goto ruleend_39630203_node_121;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 179;
		            goto ruleend_39630203_node_121;
		            end;
		            ruleend_39630203_node_121:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 970 and _numval_ lt 187958) then do;

		            _new_id_ = 179;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 970) then do;

		            _new_id_ = 180;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 180;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 179;
		         end;
		         else do;
		         _new_id_ = 179;
		         end;
		   end;
		   else if _node_id_ eq 122 then do;
		         _leaf_id_ = 122;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.93617021276595;
		         _dt_fi_39630203_{1} =     0.93617021276595;
		         _dt_fi_39630203_{2} =     0.06382978723404;
		   end;
		   else if _node_id_ eq 123 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 181;
		               goto ruleend_39630203_node_123;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 181;
		               goto ruleend_39630203_node_123;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 181;
		               goto ruleend_39630203_node_123;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 181;
		            goto ruleend_39630203_node_123;
		            end;
		            ruleend_39630203_node_123:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.05653992633193 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 181;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.05653992633193) then do;

		            _new_id_ = 182;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 182;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 181;
		         end;
		         else do;
		         _new_id_ = 181;
		         end;
		   end;
		   else if _node_id_ eq 124 then do;
		         _leaf_id_ = 124;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                 0.76;
		         _dt_fi_39630203_{1} =                 0.76;
		         _dt_fi_39630203_{2} =                 0.24;
		   end;
		   else if _node_id_ eq 125 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) then do;

		               _new_id_ = 183;
		               goto ruleend_39630203_node_125;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 183;
		               goto ruleend_39630203_node_125;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 184;
		               goto ruleend_39630203_node_125;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge 3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 184;
		               goto ruleend_39630203_node_125;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 183;
		               goto ruleend_39630203_node_125;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 184;
		               goto ruleend_39630203_node_125;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 184;
		            goto ruleend_39630203_node_125;
		            end;
		            ruleend_39630203_node_125:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 9 and _numval_ lt 187958) then do;

		            _new_id_ = 183;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 9) then do;

		            _new_id_ = 184;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 184;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 183;
		         end;
		         else do;
		         _new_id_ = 184;
		         end;
		   end;
		   else if _node_id_ eq 126 then do;
		         _leaf_id_ = 126;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    1;
		         _dt_fi_39630203_{2} =                    0;
		   end;
		   else if _node_id_ eq 127 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 185;
		               goto ruleend_39630203_node_127;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 185;
		               goto ruleend_39630203_node_127;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 185;
		               goto ruleend_39630203_node_127;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 185;
		            goto ruleend_39630203_node_127;
		            end;
		            ruleend_39630203_node_127:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.20440687492471 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 185;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.20440687492471) then do;

		            _new_id_ = 186;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 186;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 185;
		         end;
		         else do;
		         _new_id_ = 185;
		         end;
		   end;
		   else if _node_id_ eq 128 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		            if not (missing(RUA_3BYTE_STRING_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G3',
		               'G1',
		               'G6',
		               'G7',
		               'G4',
		               'G5',
		               'G9') then do;

		               _new_id_ = 187;
		               goto ruleend_39630203_node_128;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		            if not (missing(RUA_3BYTE_STRING_006_G)) then do;
		               if _strfmt_ in ('G8') then do;

		               _new_id_ = 188;
		               goto ruleend_39630203_node_128;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 187;
		            goto ruleend_39630203_node_128;
		            end;
		            ruleend_39630203_node_128:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2 and _numval_ lt 187958) then do;

		            _new_id_ = 187;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 2) then do;

		            _new_id_ = 188;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 188;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 187;
		         end;
		         else do;
		         _new_id_ = 187;
		         end;
		   end;
		   else if _node_id_ eq 129 then do;
		         _strfmt_ = left(trim(put(XQO_LANGUAGE,$12.)));
		         if missing(XQO_LANGUAGE) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) then do;

		               _new_id_ = 189;
		               goto ruleend_39630203_node_129;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 189;
		               goto ruleend_39630203_node_129;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 190;
		               goto ruleend_39630203_node_129;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 190;
		               goto ruleend_39630203_node_129;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 189;
		               goto ruleend_39630203_node_129;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 190;
		               goto ruleend_39630203_node_129;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 190;
		            goto ruleend_39630203_node_129;
		            end;
		            ruleend_39630203_node_129:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('EN') then do;

		         _new_id_ = 189;
		         end;
		         else if _strfmt_ in ('AR') then do;

		         _new_id_ = 190;
		         end;
		         else do;
		         _new_id_ = 190;
		         end;
		   end;
		   else if _node_id_ eq 130 then do;
		         _leaf_id_ = 130;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.91935483870967;
		         _dt_fi_39630203_{1} =     0.91935483870967;
		         _dt_fi_39630203_{2} =     0.08064516129032;
		   end;
		   else if _node_id_ eq 131 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 191;
		               goto ruleend_39630203_node_131;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 191;
		               goto ruleend_39630203_node_131;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 191;
		               goto ruleend_39630203_node_131;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 191;
		            goto ruleend_39630203_node_131;
		            end;
		            ruleend_39630203_node_131:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.09691001300805 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 191;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.09691001300805) then do;

		            _new_id_ = 192;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 192;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 191;
		         end;
		         else do;
		         _new_id_ = 191;
		         end;
		   end;
		   else if _node_id_ eq 132 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 193;
		               goto ruleend_39630203_node_132;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 193;
		               goto ruleend_39630203_node_132;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 193;
		               goto ruleend_39630203_node_132;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) then do;

		               _new_id_ = 194;
		               goto ruleend_39630203_node_132;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 193;
		               goto ruleend_39630203_node_132;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 193;
		               goto ruleend_39630203_node_132;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 194;
		            goto ruleend_39630203_node_132;
		            end;
		            ruleend_39630203_node_132:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.36172783601759 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 193;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.36172783601759) then do;

		            _new_id_ = 194;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 194;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 193;
		         end;
		         else do;
		         _new_id_ = 194;
		         end;
		   end;
		   else if _node_id_ eq 133 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 195;
		               goto ruleend_39630203_node_133;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 195;
		               goto ruleend_39630203_node_133;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 196;
		               goto ruleend_39630203_node_133;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 200 and _numval_ lt 300) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 196;
		               goto ruleend_39630203_node_133;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 195;
		               goto ruleend_39630203_node_133;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 196;
		               goto ruleend_39630203_node_133;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 196;
		            goto ruleend_39630203_node_133;
		            end;
		            ruleend_39630203_node_133:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 36 and _numval_ lt 187958) then do;

		            _new_id_ = 195;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 36) then do;

		            _new_id_ = 196;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 196;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 195;
		         end;
		         else do;
		         _new_id_ = 196;
		         end;
		   end;
		   else if _node_id_ eq 134 then do;
		         _leaf_id_ = 134;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.96774193548387;
		         _dt_fi_39630203_{1} =     0.96774193548387;
		         _dt_fi_39630203_{2} =     0.03225806451612;
		   end;
		   else if _node_id_ eq 135 then do;
		         _leaf_id_ = 135;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =               0.8375;
		         _dt_fi_39630203_{1} =               0.8375;
		         _dt_fi_39630203_{2} =               0.1625;
		   end;
		   else if _node_id_ eq 136 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 197;
		               goto ruleend_39630203_node_136;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 197;
		               goto ruleend_39630203_node_136;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 197;
		               goto ruleend_39630203_node_136;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 197;
		            goto ruleend_39630203_node_136;
		            end;
		            ruleend_39630203_node_136:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1 and _numval_ lt 187958) then do;

		            _new_id_ = 197;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 1) then do;

		            _new_id_ = 198;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 198;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 197;
		         end;
		         else do;
		         _new_id_ = 197;
		         end;
		   end;
		   else if _node_id_ eq 137 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 199;
		               goto ruleend_39630203_node_137;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 199;
		               goto ruleend_39630203_node_137;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 199;
		               goto ruleend_39630203_node_137;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0.29133857216946) then do;

		               _new_id_ = 200;
		               goto ruleend_39630203_node_137;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 199;
		               goto ruleend_39630203_node_137;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 199;
		               goto ruleend_39630203_node_137;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 199;
		            goto ruleend_39630203_node_137;
		            end;
		            ruleend_39630203_node_137:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1 and _numval_ lt 187958) then do;

		            _new_id_ = 199;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 1) then do;

		            _new_id_ = 200;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 200;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 199;
		         end;
		         else do;
		         _new_id_ = 199;
		         end;
		   end;
		   else if _node_id_ eq 138 then do;
		         _leaf_id_ = 138;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    1;
		         _dt_fi_39630203_{2} =                    0;
		   end;
		   else if _node_id_ eq 139 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 201;
		               goto ruleend_39630203_node_139;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 201;
		               goto ruleend_39630203_node_139;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 201;
		               goto ruleend_39630203_node_139;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) then do;

		               _new_id_ = 202;
		               goto ruleend_39630203_node_139;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 201;
		               goto ruleend_39630203_node_139;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 201;
		               goto ruleend_39630203_node_139;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 201;
		            goto ruleend_39630203_node_139;
		            end;
		            ruleend_39630203_node_139:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.33880155571007 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 201;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.33880155571007) then do;

		            _new_id_ = 202;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 202;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 201;
		         end;
		         else do;
		         _new_id_ = 201;
		         end;
		   end;
		   else if _node_id_ eq 140 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 203;
		               goto ruleend_39630203_node_140;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 203;
		               goto ruleend_39630203_node_140;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 203;
		               goto ruleend_39630203_node_140;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) then do;

		               _new_id_ = 204;
		               goto ruleend_39630203_node_140;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 203;
		               goto ruleend_39630203_node_140;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 203;
		               goto ruleend_39630203_node_140;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 204;
		            goto ruleend_39630203_node_140;
		            end;
		            ruleend_39630203_node_140:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.41421648081794 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 203;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.41421648081794) then do;

		            _new_id_ = 204;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 204;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 203;
		         end;
		         else do;
		         _new_id_ = 204;
		         end;
		   end;
		   else if _node_id_ eq 141 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) then do;

		               _new_id_ = 205;
		               goto ruleend_39630203_node_141;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 205;
		               goto ruleend_39630203_node_141;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 206;
		               goto ruleend_39630203_node_141;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 206;
		               goto ruleend_39630203_node_141;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 205;
		               goto ruleend_39630203_node_141;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 206;
		               goto ruleend_39630203_node_141;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 206;
		            goto ruleend_39630203_node_141;
		            end;
		            ruleend_39630203_node_141:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.09691001300805 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 205;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.09691001300805) then do;

		            _new_id_ = 206;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 206;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 205;
		         end;
		         else do;
		         _new_id_ = 206;
		         end;
		   end;
		   else if _node_id_ eq 142 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 207;
		               goto ruleend_39630203_node_142;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 207;
		               goto ruleend_39630203_node_142;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 207;
		               goto ruleend_39630203_node_142;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) then do;

		               _new_id_ = 208;
		               goto ruleend_39630203_node_142;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 207;
		               goto ruleend_39630203_node_142;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 207;
		               goto ruleend_39630203_node_142;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 207;
		            goto ruleend_39630203_node_142;
		            end;
		            ruleend_39630203_node_142:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.04066299138769 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 207;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.04066299138769) then do;

		            _new_id_ = 208;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 208;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 207;
		         end;
		         else do;
		         _new_id_ = 207;
		         end;
		   end;
		   else if _node_id_ eq 143 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) then do;

		               _new_id_ = 209;
		               goto ruleend_39630203_node_143;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 209;
		               goto ruleend_39630203_node_143;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 210;
		               goto ruleend_39630203_node_143;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 210;
		               goto ruleend_39630203_node_143;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 209;
		               goto ruleend_39630203_node_143;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 210;
		               goto ruleend_39630203_node_143;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 209;
		            goto ruleend_39630203_node_143;
		            end;
		            ruleend_39630203_node_143:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 4 and _numval_ lt 187958) then do;

		            _new_id_ = 209;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 4) then do;

		            _new_id_ = 210;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 210;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 209;
		         end;
		         else do;
		         _new_id_ = 209;
		         end;
		   end;
		   else if _node_id_ eq 144 then do;
		         _leaf_id_ = 144;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.86538461538461;
		         _dt_fi_39630203_{1} =     0.13461538461538;
		         _dt_fi_39630203_{2} =     0.86538461538461;
		   end;
		   else if _node_id_ eq 145 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            200 and _numval_ lt 300) then do;

		               _new_id_ = 211;
		               goto ruleend_39630203_node_145;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 211;
		               goto ruleend_39630203_node_145;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 212;
		               goto ruleend_39630203_node_145;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 150 and _numval_ lt 200) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 212;
		               goto ruleend_39630203_node_145;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 211;
		               goto ruleend_39630203_node_145;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 212;
		               goto ruleend_39630203_node_145;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 212;
		            goto ruleend_39630203_node_145;
		            end;
		            ruleend_39630203_node_145:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 730 and _numval_ lt 187958) then do;

		            _new_id_ = 211;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 730) then do;

		            _new_id_ = 212;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 212;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 211;
		         end;
		         else do;
		         _new_id_ = 212;
		         end;
		   end;
		   else if _node_id_ eq 146 then do;
		         _leaf_id_ = 146;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.91666666666666;
		         _dt_fi_39630203_{1} =     0.08333333333333;
		         _dt_fi_39630203_{2} =     0.91666666666666;
		   end;
		   else if _node_id_ eq 147 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 213;
		               goto ruleend_39630203_node_147;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 213;
		               goto ruleend_39630203_node_147;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 213;
		               goto ruleend_39630203_node_147;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 213;
		            goto ruleend_39630203_node_147;
		            end;
		            ruleend_39630203_node_147:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 0.29133857216946 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 213;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 0.29133857216946) then do;

		            _new_id_ = 214;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 214;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 213;
		         end;
		         else do;
		         _new_id_ = 213;
		         end;
		   end;
		   else if _node_id_ eq 148 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            3725 and _numval_ lt 4116) then do;

		               _new_id_ = 215;
		               goto ruleend_39630203_node_148;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 215;
		               goto ruleend_39630203_node_148;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 216;
		               goto ruleend_39630203_node_148;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 2456 and _numval_ lt 2665) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 216;
		               goto ruleend_39630203_node_148;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 215;
		               goto ruleend_39630203_node_148;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 216;
		               goto ruleend_39630203_node_148;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 215;
		            goto ruleend_39630203_node_148;
		            end;
		            ruleend_39630203_node_148:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.46108620255947 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 215;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.46108620255947) then do;

		            _new_id_ = 216;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 216;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 215;
		         end;
		         else do;
		         _new_id_ = 215;
		         end;
		   end;
		   else if _node_id_ eq 149 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 217;
		               goto ruleend_39630203_node_149;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 217;
		               goto ruleend_39630203_node_149;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 217;
		               goto ruleend_39630203_node_149;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) then do;

		               _new_id_ = 218;
		               goto ruleend_39630203_node_149;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 217;
		               goto ruleend_39630203_node_149;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 217;
		               goto ruleend_39630203_node_149;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 218;
		            goto ruleend_39630203_node_149;
		            end;
		            ruleend_39630203_node_149:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.30695031829154 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 217;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.30695031829154) then do;

		            _new_id_ = 218;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 218;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 217;
		         end;
		         else do;
		         _new_id_ = 218;
		         end;
		   end;
		   else if _node_id_ eq 150 then do;
		         _leaf_id_ = 150;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.85483870967741;
		         _dt_fi_39630203_{1} =     0.85483870967741;
		         _dt_fi_39630203_{2} =     0.14516129032258;
		   end;
		   else if _node_id_ eq 151 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 219;
		               goto ruleend_39630203_node_151;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 219;
		               goto ruleend_39630203_node_151;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 219;
		               goto ruleend_39630203_node_151;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) then do;

		               _new_id_ = 220;
		               goto ruleend_39630203_node_151;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 219;
		               goto ruleend_39630203_node_151;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 219;
		               goto ruleend_39630203_node_151;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 220;
		            goto ruleend_39630203_node_151;
		            end;
		            ruleend_39630203_node_151:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.69057272462515 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 219;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.69057272462515) then do;

		            _new_id_ = 220;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 220;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 219;
		         end;
		         else do;
		         _new_id_ = 220;
		         end;
		   end;
		   else if _node_id_ eq 152 then do;
		         _leaf_id_ = 152;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.85714285714285;
		         _dt_fi_39630203_{1} =     0.85714285714285;
		         _dt_fi_39630203_{2} =     0.14285714285714;
		   end;
		   else if _node_id_ eq 153 then do;
		         _leaf_id_ = 153;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.97311827956989;
		         _dt_fi_39630203_{1} =     0.97311827956989;
		         _dt_fi_39630203_{2} =      0.0268817204301;
		   end;
		   else if _node_id_ eq 154 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 221;
		               goto ruleend_39630203_node_154;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 221;
		               goto ruleend_39630203_node_154;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 221;
		               goto ruleend_39630203_node_154;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 221;
		            goto ruleend_39630203_node_154;
		            end;
		            ruleend_39630203_node_154:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G1',
		         'G7',
		         'G8',
		         'G9') then do;

		         _new_id_ = 221;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 222;
		         end;
		         else do;
		         _new_id_ = 221;
		         end;
		   end;
		   else if _node_id_ eq 155 then do;
		         _leaf_id_ = 155;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                  0.8;
		         _dt_fi_39630203_{1} =                  0.2;
		         _dt_fi_39630203_{2} =                  0.8;
		   end;
		   else if _node_id_ eq 156 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 223;
		               goto ruleend_39630203_node_156;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 223;
		               goto ruleend_39630203_node_156;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 223;
		               goto ruleend_39630203_node_156;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) then do;

		               _new_id_ = 224;
		               goto ruleend_39630203_node_156;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 223;
		               goto ruleend_39630203_node_156;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 223;
		               goto ruleend_39630203_node_156;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 224;
		            goto ruleend_39630203_node_156;
		            end;
		            ruleend_39630203_node_156:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G8') then do;

		         _new_id_ = 223;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 224;
		         end;
		         else do;
		         _new_id_ = 224;
		         end;
		   end;
		   else if _node_id_ eq 157 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 225;
		               goto ruleend_39630203_node_157;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 225;
		               goto ruleend_39630203_node_157;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 225;
		               goto ruleend_39630203_node_157;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 225;
		            goto ruleend_39630203_node_157;
		            end;
		            ruleend_39630203_node_157:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2 and _numval_ lt 187958) then do;

		            _new_id_ = 225;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 2) then do;

		            _new_id_ = 226;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 226;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 225;
		         end;
		         else do;
		         _new_id_ = 225;
		         end;
		   end;
		   else if _node_id_ eq 158 then do;
		         _leaf_id_ = 158;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.98689956331877;
		         _dt_fi_39630203_{1} =     0.98689956331877;
		         _dt_fi_39630203_{2} =     0.01310043668122;
		   end;
		   else if _node_id_ eq 159 then do;
		         _leaf_id_ = 159;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =      0.9090909090909;
		         _dt_fi_39630203_{1} =      0.9090909090909;
		         _dt_fi_39630203_{2} =     0.09090909090909;
		   end;
		   else if _node_id_ eq 160 then do;
		         _leaf_id_ = 160;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.86666666666666;
		         _dt_fi_39630203_{1} =     0.13333333333333;
		         _dt_fi_39630203_{2} =     0.86666666666666;
		   end;
		   else if _node_id_ eq 161 then do;
		         _leaf_id_ = 161;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.88702928870292;
		         _dt_fi_39630203_{1} =     0.88702928870292;
		         _dt_fi_39630203_{2} =     0.11297071129707;
		   end;
		   else if _node_id_ eq 162 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 227;
		               goto ruleend_39630203_node_162;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 227;
		               goto ruleend_39630203_node_162;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 227;
		               goto ruleend_39630203_node_162;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) then do;

		               _new_id_ = 228;
		               goto ruleend_39630203_node_162;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 227;
		               goto ruleend_39630203_node_162;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 227;
		               goto ruleend_39630203_node_162;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 228;
		            goto ruleend_39630203_node_162;
		            end;
		            ruleend_39630203_node_162:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 36 and _numval_ lt 187958) then do;

		            _new_id_ = 227;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 36) then do;

		            _new_id_ = 228;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 228;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 227;
		         end;
		         else do;
		         _new_id_ = 228;
		         end;
		   end;
		   else if _node_id_ eq 163 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) then do;

		               _new_id_ = 229;
		               goto ruleend_39630203_node_163;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 229;
		               goto ruleend_39630203_node_163;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 230;
		               goto ruleend_39630203_node_163;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 230;
		               goto ruleend_39630203_node_163;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 229;
		               goto ruleend_39630203_node_163;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 230;
		               goto ruleend_39630203_node_163;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 230;
		            goto ruleend_39630203_node_163;
		            end;
		            ruleend_39630203_node_163:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G5') then do;

		         _new_id_ = 229;
		         end;
		         else if _strfmt_ in ('G4') then do;

		         _new_id_ = 230;
		         end;
		         else do;
		         _new_id_ = 230;
		         end;
		   end;
		   else if _node_id_ eq 164 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 231;
		               goto ruleend_39630203_node_164;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 231;
		               goto ruleend_39630203_node_164;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 231;
		               goto ruleend_39630203_node_164;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) then do;

		               _new_id_ = 232;
		               goto ruleend_39630203_node_164;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 231;
		               goto ruleend_39630203_node_164;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 231;
		               goto ruleend_39630203_node_164;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 232;
		            goto ruleend_39630203_node_164;
		            end;
		            ruleend_39630203_node_164:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G5') then do;

		         _new_id_ = 231;
		         end;
		         else if _strfmt_ in ('G4') then do;

		         _new_id_ = 232;
		         end;
		         else do;
		         _new_id_ = 232;
		         end;
		   end;
		   else if _node_id_ eq 165 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 233;
		               goto ruleend_39630203_node_165;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 233;
		               goto ruleend_39630203_node_165;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 233;
		               goto ruleend_39630203_node_165;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 233;
		            goto ruleend_39630203_node_165;
		            end;
		            ruleend_39630203_node_165:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.33880155571007 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 233;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.33880155571007) then do;

		            _new_id_ = 234;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 234;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 233;
		         end;
		         else do;
		         _new_id_ = 233;
		         end;
		   end;
		   else if _node_id_ eq 166 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 235;
		               goto ruleend_39630203_node_166;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 235;
		               goto ruleend_39630203_node_166;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 235;
		               goto ruleend_39630203_node_166;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 236;
		               goto ruleend_39630203_node_166;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 235;
		               goto ruleend_39630203_node_166;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 235;
		               goto ruleend_39630203_node_166;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 235;
		            goto ruleend_39630203_node_166;
		            end;
		            ruleend_39630203_node_166:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 9 and _numval_ lt 187958) then do;

		            _new_id_ = 235;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 9) then do;

		            _new_id_ = 236;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 236;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 235;
		         end;
		         else do;
		         _new_id_ = 235;
		         end;
		   end;
		   else if _node_id_ eq 167 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 237;
		               goto ruleend_39630203_node_167;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 237;
		               goto ruleend_39630203_node_167;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 237;
		               goto ruleend_39630203_node_167;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 237;
		            goto ruleend_39630203_node_167;
		            end;
		            ruleend_39630203_node_167:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G4',
		         'G5') then do;

		         _new_id_ = 237;
		         end;
		         else if _strfmt_ in ('G2') then do;

		         _new_id_ = 238;
		         end;
		         else do;
		         _new_id_ = 237;
		         end;
		   end;
		   else if _node_id_ eq 168 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 239;
		               goto ruleend_39630203_node_168;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 239;
		               goto ruleend_39630203_node_168;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 239;
		               goto ruleend_39630203_node_168;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) then do;

		               _new_id_ = 240;
		               goto ruleend_39630203_node_168;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 239;
		               goto ruleend_39630203_node_168;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 239;
		               goto ruleend_39630203_node_168;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 240;
		            goto ruleend_39630203_node_168;
		            end;
		            ruleend_39630203_node_168:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.09691001300805 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 239;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.09691001300805) then do;

		            _new_id_ = 240;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 240;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 239;
		         end;
		         else do;
		         _new_id_ = 240;
		         end;
		   end;
		   else if _node_id_ eq 169 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            70 and _numval_ lt 100) then do;

		               _new_id_ = 241;
		               goto ruleend_39630203_node_169;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 241;
		               goto ruleend_39630203_node_169;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 242;
		               goto ruleend_39630203_node_169;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 242;
		               goto ruleend_39630203_node_169;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 241;
		               goto ruleend_39630203_node_169;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 242;
		               goto ruleend_39630203_node_169;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 241;
		            goto ruleend_39630203_node_169;
		            end;
		            ruleend_39630203_node_169:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 89 and _numval_ lt 187958) then do;

		            _new_id_ = 241;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 89) then do;

		            _new_id_ = 242;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 242;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 241;
		         end;
		         else do;
		         _new_id_ = 241;
		         end;
		   end;
		   else if _node_id_ eq 170 then do;
		         _leaf_id_ = 170;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.89235127478753;
		         _dt_fi_39630203_{1} =     0.89235127478753;
		         _dt_fi_39630203_{2} =     0.10764872521246;
		   end;
		   else if _node_id_ eq 171 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G2',
		               'G0',
		               'G1') then do;

		               _new_id_ = 243;
		               goto ruleend_39630203_node_171;
		               end;
		            end;
		            _strfmt_ = left(trim(put(RUA_IND_006_G,$2.)));
		            if not (missing(RUA_IND_006_G)) then do;
		               if _strfmt_ in ('G3') then do;

		               _new_id_ = 244;
		               goto ruleend_39630203_node_171;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 243;
		            goto ruleend_39630203_node_171;
		            end;
		            ruleend_39630203_node_171:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 4 and _numval_ lt 187958) then do;

		            _new_id_ = 243;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 4) then do;

		            _new_id_ = 244;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 244;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 243;
		         end;
		         else do;
		         _new_id_ = 243;
		         end;
		   end;
		   else if _node_id_ eq 172 then do;
		         _leaf_id_ = 172;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                 0.84;
		         _dt_fi_39630203_{1} =                 0.84;
		         _dt_fi_39630203_{2} =                 0.16;
		   end;
		   else if _node_id_ eq 173 then do;
		         _leaf_id_ = 173;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.93103448275862;
		         _dt_fi_39630203_{1} =     0.93103448275862;
		         _dt_fi_39630203_{2} =     0.06896551724137;
		   end;
		   else if _node_id_ eq 174 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 245;
		               goto ruleend_39630203_node_174;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 245;
		               goto ruleend_39630203_node_174;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 245;
		               goto ruleend_39630203_node_174;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge 2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) then do;

		               _new_id_ = 246;
		               goto ruleend_39630203_node_174;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 245;
		               goto ruleend_39630203_node_174;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 245;
		               goto ruleend_39630203_node_174;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 246;
		            goto ruleend_39630203_node_174;
		            end;
		            ruleend_39630203_node_174:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.05653992633193 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 245;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.05653992633193) then do;

		            _new_id_ = 246;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 246;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 245;
		         end;
		         else do;
		         _new_id_ = 246;
		         end;
		   end;
		   else if _node_id_ eq 175 then do;
		         _leaf_id_ = 175;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    0;
		         _dt_fi_39630203_{2} =                    1;
		   end;
		   else if _node_id_ eq 176 then do;
		         _leaf_id_ = 176;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    1;
		         _dt_fi_39630203_{2} =                    0;
		   end;
		   else if _node_id_ eq 177 then do;
		         _leaf_id_ = 177;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.77777777777777;
		         _dt_fi_39630203_{1} =     0.77777777777777;
		         _dt_fi_39630203_{2} =     0.22222222222222;
		   end;
		   else if _node_id_ eq 178 then do;
		         _leaf_id_ = 178;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                  0.8;
		         _dt_fi_39630203_{1} =                  0.2;
		         _dt_fi_39630203_{2} =                  0.8;
		   end;
		   else if _node_id_ eq 179 then do;
		         _leaf_id_ = 179;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.83333333333333;
		         _dt_fi_39630203_{1} =     0.83333333333333;
		         _dt_fi_39630203_{2} =     0.16666666666666;
		   end;
		   else if _node_id_ eq 180 then do;
		         _leaf_id_ = 180;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                  0.8;
		         _dt_fi_39630203_{1} =                  0.2;
		         _dt_fi_39630203_{2} =                  0.8;
		   end;
		   else if _node_id_ eq 181 then do;
		         _leaf_id_ = 181;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.60869565217391;
		         _dt_fi_39630203_{1} =     0.39130434782608;
		         _dt_fi_39630203_{2} =     0.60869565217391;
		   end;
		   else if _node_id_ eq 182 then do;
		         _leaf_id_ = 182;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.73684210526315;
		         _dt_fi_39630203_{1} =     0.73684210526315;
		         _dt_fi_39630203_{2} =     0.26315789473684;
		   end;
		   else if _node_id_ eq 183 then do;
		         _leaf_id_ = 183;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    1;
		         _dt_fi_39630203_{2} =                    0;
		   end;
		   else if _node_id_ eq 184 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) then do;

		               _new_id_ = 247;
		               goto ruleend_39630203_node_184;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 247;
		               goto ruleend_39630203_node_184;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 248;
		               goto ruleend_39630203_node_184;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 248;
		               goto ruleend_39630203_node_184;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 247;
		               goto ruleend_39630203_node_184;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 248;
		               goto ruleend_39630203_node_184;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 247;
		            goto ruleend_39630203_node_184;
		            end;
		            ruleend_39630203_node_184:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2 and _numval_ lt 187958) then do;

		            _new_id_ = 247;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 2) then do;

		            _new_id_ = 248;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 248;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 247;
		         end;
		         else do;
		         _new_id_ = 247;
		         end;
		   end;
		   else if _node_id_ eq 185 then do;
		         _leaf_id_ = 185;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.96551724137931;
		         _dt_fi_39630203_{1} =     0.03448275862068;
		         _dt_fi_39630203_{2} =     0.96551724137931;
		   end;
		   else if _node_id_ eq 186 then do;
		         _leaf_id_ = 186;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.76923076923076;
		         _dt_fi_39630203_{1} =     0.76923076923076;
		         _dt_fi_39630203_{2} =     0.23076923076923;
		   end;
		   else if _node_id_ eq 187 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 249;
		               goto ruleend_39630203_node_187;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 249;
		               goto ruleend_39630203_node_187;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 249;
		               goto ruleend_39630203_node_187;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) then do;

		               _new_id_ = 250;
		               goto ruleend_39630203_node_187;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 249;
		               goto ruleend_39630203_node_187;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 249;
		               goto ruleend_39630203_node_187;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 250;
		            goto ruleend_39630203_node_187;
		            end;
		            ruleend_39630203_node_187:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G7',
		         'G5',
		         'G8') then do;

		         _new_id_ = 249;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 250;
		         end;
		         else do;
		         _new_id_ = 250;
		         end;
		   end;
		   else if _node_id_ eq 188 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		            if not (missing(bene_bank_name_G)) then do;
		               if _strfmt_ in ('G2',
		               'G3',
		               'G0',
		               'G1',
		               'G6',
		               'G4') then do;

		               _new_id_ = 251;
		               goto ruleend_39630203_node_188;
		               end;
		            end;
		            _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		            if not (missing(bene_bank_name_G)) then do;
		               if _strfmt_ in ('G5') then do;

		               _new_id_ = 252;
		               goto ruleend_39630203_node_188;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 251;
		            goto ruleend_39630203_node_188;
		            end;
		            ruleend_39630203_node_188:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.51774507303653 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 251;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.51774507303653) then do;

		            _new_id_ = 252;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 252;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 251;
		         end;
		         else do;
		         _new_id_ = 251;
		         end;
		   end;
		   else if _node_id_ eq 189 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 253;
		               goto ruleend_39630203_node_189;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 253;
		               goto ruleend_39630203_node_189;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 253;
		               goto ruleend_39630203_node_189;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 100 and _numval_ lt 150) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 254;
		               goto ruleend_39630203_node_189;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 253;
		               goto ruleend_39630203_node_189;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 253;
		               goto ruleend_39630203_node_189;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 253;
		            goto ruleend_39630203_node_189;
		            end;
		            ruleend_39630203_node_189:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2456 and _numval_ lt 187958) then do;

		            _new_id_ = 253;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 2456) then do;

		            _new_id_ = 254;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 254;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 253;
		         end;
		         else do;
		         _new_id_ = 253;
		         end;
		   end;
		   else if _node_id_ eq 190 then do;
		         _leaf_id_ = 190;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.78215767634854;
		         _dt_fi_39630203_{1} =     0.78215767634854;
		         _dt_fi_39630203_{2} =     0.21784232365145;
		   end;
		   else if _node_id_ eq 191 then do;
		         _leaf_id_ = 191;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.90322580645161;
		         _dt_fi_39630203_{1} =     0.09677419354838;
		         _dt_fi_39630203_{2} =     0.90322580645161;
		   end;
		   else if _node_id_ eq 192 then do;
		         _leaf_id_ = 192;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.66666666666666;
		         _dt_fi_39630203_{1} =     0.66666666666666;
		         _dt_fi_39630203_{2} =     0.33333333333333;
		   end;
		   else if _node_id_ eq 193 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 255;
		               goto ruleend_39630203_node_193;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 255;
		               goto ruleend_39630203_node_193;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 255;
		               goto ruleend_39630203_node_193;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) then do;

		               _new_id_ = 256;
		               goto ruleend_39630203_node_193;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 255;
		               goto ruleend_39630203_node_193;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 255;
		               goto ruleend_39630203_node_193;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 256;
		            goto ruleend_39630203_node_193;
		            end;
		            ruleend_39630203_node_193:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 4 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 255;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 4) then do;

		            _new_id_ = 256;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 256;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 255;
		         end;
		         else do;
		         _new_id_ = 256;
		         end;
		   end;
		   else if _node_id_ eq 194 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 257;
		               goto ruleend_39630203_node_194;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 257;
		               goto ruleend_39630203_node_194;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 257;
		               goto ruleend_39630203_node_194;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 257;
		            goto ruleend_39630203_node_194;
		            end;
		            ruleend_39630203_node_194:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2.77815125038364 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 257;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 2.77815125038364) then do;

		            _new_id_ = 258;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 258;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 257;
		         end;
		         else do;
		         _new_id_ = 257;
		         end;
		   end;
		   else if _node_id_ eq 195 then do;
		         _leaf_id_ = 195;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.85714285714285;
		         _dt_fi_39630203_{1} =     0.85714285714285;
		         _dt_fi_39630203_{2} =     0.14285714285714;
		   end;
		   else if _node_id_ eq 196 then do;
		         _leaf_id_ = 196;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                 0.75;
		         _dt_fi_39630203_{1} =                 0.25;
		         _dt_fi_39630203_{2} =                 0.75;
		   end;
		   else if _node_id_ eq 197 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 259;
		               goto ruleend_39630203_node_197;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 259;
		               goto ruleend_39630203_node_197;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 259;
		               goto ruleend_39630203_node_197;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) then do;

		               _new_id_ = 260;
		               goto ruleend_39630203_node_197;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 259;
		               goto ruleend_39630203_node_197;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 259;
		               goto ruleend_39630203_node_197;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 260;
		            goto ruleend_39630203_node_197;
		            end;
		            ruleend_39630203_node_197:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G7',
		         'G8') then do;

		         _new_id_ = 259;
		         end;
		         else if _strfmt_ in ('G6',
		         'G5') then do;

		         _new_id_ = 260;
		         end;
		         else do;
		         _new_id_ = 260;
		         end;
		   end;
		   else if _node_id_ eq 198 then do;
		         _leaf_id_ = 198;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                 0.76;
		         _dt_fi_39630203_{1} =                 0.24;
		         _dt_fi_39630203_{2} =                 0.76;
		   end;
		   else if _node_id_ eq 199 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) then do;

		               _new_id_ = 261;
		               goto ruleend_39630203_node_199;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 261;
		               goto ruleend_39630203_node_199;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 262;
		               goto ruleend_39630203_node_199;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 262;
		               goto ruleend_39630203_node_199;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 261;
		               goto ruleend_39630203_node_199;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 262;
		               goto ruleend_39630203_node_199;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 262;
		            goto ruleend_39630203_node_199;
		            end;
		            ruleend_39630203_node_199:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.69897000433601 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 261;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.69897000433601) then do;

		            _new_id_ = 262;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 262;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 261;
		         end;
		         else do;
		         _new_id_ = 262;
		         end;
		   end;
		   else if _node_id_ eq 200 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) then do;

		               _new_id_ = 263;
		               goto ruleend_39630203_node_200;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 263;
		               goto ruleend_39630203_node_200;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 264;
		               goto ruleend_39630203_node_200;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 264;
		               goto ruleend_39630203_node_200;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 263;
		               goto ruleend_39630203_node_200;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 264;
		               goto ruleend_39630203_node_200;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 264;
		            goto ruleend_39630203_node_200;
		            end;
		            ruleend_39630203_node_200:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G7',
		         'G5') then do;

		         _new_id_ = 263;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 264;
		         end;
		         else do;
		         _new_id_ = 264;
		         end;
		   end;
		   else if _node_id_ eq 201 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 265;
		               goto ruleend_39630203_node_201;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 265;
		               goto ruleend_39630203_node_201;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 265;
		               goto ruleend_39630203_node_201;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 266;
		               goto ruleend_39630203_node_201;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 265;
		               goto ruleend_39630203_node_201;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 265;
		               goto ruleend_39630203_node_201;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 266;
		            goto ruleend_39630203_node_201;
		            end;
		            ruleend_39630203_node_201:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.69897000433601 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 265;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.69897000433601) then do;

		            _new_id_ = 266;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 266;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 265;
		         end;
		         else do;
		         _new_id_ = 266;
		         end;
		   end;
		   else if _node_id_ eq 202 then do;
		         _leaf_id_ = 202;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.87121212121212;
		         _dt_fi_39630203_{1} =     0.87121212121212;
		         _dt_fi_39630203_{2} =     0.12878787878787;
		   end;
		   else if _node_id_ eq 203 then do;
		         _leaf_id_ = 203;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.94117647058823;
		         _dt_fi_39630203_{1} =     0.05882352941176;
		         _dt_fi_39630203_{2} =     0.94117647058823;
		   end;
		   else if _node_id_ eq 204 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) then do;

		               _new_id_ = 267;
		               goto ruleend_39630203_node_204;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 267;
		               goto ruleend_39630203_node_204;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 268;
		               goto ruleend_39630203_node_204;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 268;
		               goto ruleend_39630203_node_204;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 267;
		               goto ruleend_39630203_node_204;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 268;
		               goto ruleend_39630203_node_204;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 268;
		            goto ruleend_39630203_node_204;
		            end;
		            ruleend_39630203_node_204:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 10000 and _numval_ lt 7590170) then do;

		            _new_id_ = 267;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 10000) then do;

		            _new_id_ = 268;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 268;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 267;
		         end;
		         else do;
		         _new_id_ = 268;
		         end;
		   end;
		   else if _node_id_ eq 205 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 269;
		               goto ruleend_39630203_node_205;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 269;
		               goto ruleend_39630203_node_205;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 270;
		               goto ruleend_39630203_node_205;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 270;
		               goto ruleend_39630203_node_205;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 269;
		               goto ruleend_39630203_node_205;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 270;
		               goto ruleend_39630203_node_205;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 269;
		            goto ruleend_39630203_node_205;
		            end;
		            ruleend_39630203_node_205:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.17609125905568 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 269;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.17609125905568) then do;

		            _new_id_ = 270;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 270;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 269;
		         end;
		         else do;
		         _new_id_ = 269;
		         end;
		   end;
		   else if _node_id_ eq 206 then do;
		         _leaf_id_ = 206;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.77808219178082;
		         _dt_fi_39630203_{1} =     0.22191780821917;
		         _dt_fi_39630203_{2} =     0.77808219178082;
		   end;
		   else if _node_id_ eq 207 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 271;
		               goto ruleend_39630203_node_207;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 271;
		               goto ruleend_39630203_node_207;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 271;
		               goto ruleend_39630203_node_207;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) then do;

		               _new_id_ = 272;
		               goto ruleend_39630203_node_207;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 271;
		               goto ruleend_39630203_node_207;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 271;
		               goto ruleend_39630203_node_207;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 272;
		            goto ruleend_39630203_node_207;
		            end;
		            ruleend_39630203_node_207:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2.77815125038364 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 271;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 2.77815125038364) then do;

		            _new_id_ = 272;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 272;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 271;
		         end;
		         else do;
		         _new_id_ = 272;
		         end;
		   end;
		   else if _node_id_ eq 208 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 273;
		               goto ruleend_39630203_node_208;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 273;
		               goto ruleend_39630203_node_208;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 273;
		               goto ruleend_39630203_node_208;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) then do;

		               _new_id_ = 274;
		               goto ruleend_39630203_node_208;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 273;
		               goto ruleend_39630203_node_208;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 273;
		               goto ruleend_39630203_node_208;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 274;
		            goto ruleend_39630203_node_208;
		            end;
		            ruleend_39630203_node_208:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 990 and _numval_ lt 7590170) then do;

		            _new_id_ = 273;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 990) then do;

		            _new_id_ = 274;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 274;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 273;
		         end;
		         else do;
		         _new_id_ = 274;
		         end;
		   end;
		   else if _node_id_ eq 209 then do;
		         _leaf_id_ = 209;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.80821917808219;
		         _dt_fi_39630203_{1} =      0.1917808219178;
		         _dt_fi_39630203_{2} =     0.80821917808219;
		   end;
		   else if _node_id_ eq 210 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 275;
		               goto ruleend_39630203_node_210;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 275;
		               goto ruleend_39630203_node_210;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 275;
		               goto ruleend_39630203_node_210;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 10) then do;

		               _new_id_ = 276;
		               goto ruleend_39630203_node_210;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 275;
		               goto ruleend_39630203_node_210;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 275;
		               goto ruleend_39630203_node_210;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 275;
		            goto ruleend_39630203_node_210;
		            end;
		            ruleend_39630203_node_210:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.46108620255947 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 275;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.46108620255947) then do;

		            _new_id_ = 276;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 276;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 275;
		         end;
		         else do;
		         _new_id_ = 275;
		         end;
		   end;
		   else if _node_id_ eq 211 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) then do;

		               _new_id_ = 277;
		               goto ruleend_39630203_node_211;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 277;
		               goto ruleend_39630203_node_211;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 278;
		               goto ruleend_39630203_node_211;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 278;
		               goto ruleend_39630203_node_211;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 277;
		               goto ruleend_39630203_node_211;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 278;
		               goto ruleend_39630203_node_211;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 278;
		            goto ruleend_39630203_node_211;
		            end;
		            ruleend_39630203_node_211:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 13565 and _numval_ lt 187958) then do;

		            _new_id_ = 277;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 13565) then do;

		            _new_id_ = 278;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 278;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 277;
		         end;
		         else do;
		         _new_id_ = 278;
		         end;
		   end;
		   else if _node_id_ eq 212 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 279;
		               goto ruleend_39630203_node_212;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 279;
		               goto ruleend_39630203_node_212;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 279;
		               goto ruleend_39630203_node_212;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) then do;

		               _new_id_ = 280;
		               goto ruleend_39630203_node_212;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 279;
		               goto ruleend_39630203_node_212;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 279;
		               goto ruleend_39630203_node_212;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 280;
		            goto ruleend_39630203_node_212;
		            end;
		            ruleend_39630203_node_212:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 10000 and _numval_ lt 7590170) then do;

		            _new_id_ = 279;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 10000) then do;

		            _new_id_ = 280;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 280;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 279;
		         end;
		         else do;
		         _new_id_ = 280;
		         end;
		   end;
		   else if _node_id_ eq 213 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 281;
		               goto ruleend_39630203_node_213;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 281;
		               goto ruleend_39630203_node_213;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 281;
		               goto ruleend_39630203_node_213;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 281;
		            goto ruleend_39630203_node_213;
		            end;
		            ruleend_39630203_node_213:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.27841031940134 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 281;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.27841031940134) then do;

		            _new_id_ = 282;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 282;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 281;
		         end;
		         else do;
		         _new_id_ = 281;
		         end;
		   end;
		   else if _node_id_ eq 214 then do;
		         _leaf_id_ = 214;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    0;
		         _dt_fi_39630203_{2} =                    1;
		   end;
		   else if _node_id_ eq 215 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 283;
		               goto ruleend_39630203_node_215;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 283;
		               goto ruleend_39630203_node_215;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 283;
		               goto ruleend_39630203_node_215;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 300 and _numval_ lt 422) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 284;
		               goto ruleend_39630203_node_215;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 283;
		               goto ruleend_39630203_node_215;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 283;
		               goto ruleend_39630203_node_215;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 283;
		            goto ruleend_39630203_node_215;
		            end;
		            ruleend_39630203_node_215:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 36 and _numval_ lt 187958) then do;

		            _new_id_ = 283;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 36) then do;

		            _new_id_ = 284;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 284;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 283;
		         end;
		         else do;
		         _new_id_ = 283;
		         end;
		   end;
		   else if _node_id_ eq 216 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) then do;

		               _new_id_ = 285;
		               goto ruleend_39630203_node_216;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 285;
		               goto ruleend_39630203_node_216;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 286;
		               goto ruleend_39630203_node_216;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 286;
		               goto ruleend_39630203_node_216;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 285;
		               goto ruleend_39630203_node_216;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 286;
		               goto ruleend_39630203_node_216;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 285;
		            goto ruleend_39630203_node_216;
		            end;
		            ruleend_39630203_node_216:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G4') then do;

		         _new_id_ = 285;
		         end;
		         else if _strfmt_ in ('G2') then do;

		         _new_id_ = 286;
		         end;
		         else do;
		         _new_id_ = 285;
		         end;
		   end;
		   else if _node_id_ eq 217 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 287;
		               goto ruleend_39630203_node_217;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 287;
		               goto ruleend_39630203_node_217;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 287;
		               goto ruleend_39630203_node_217;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) then do;

		               _new_id_ = 288;
		               goto ruleend_39630203_node_217;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 287;
		               goto ruleend_39630203_node_217;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 287;
		               goto ruleend_39630203_node_217;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 288;
		            goto ruleend_39630203_node_217;
		            end;
		            ruleend_39630203_node_217:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.46108620255947 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 287;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.46108620255947) then do;

		            _new_id_ = 288;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 288;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 287;
		         end;
		         else do;
		         _new_id_ = 288;
		         end;
		   end;
		   else if _node_id_ eq 218 then do;
		         _leaf_id_ = 218;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.78431372549019;
		         _dt_fi_39630203_{1} =     0.78431372549019;
		         _dt_fi_39630203_{2} =      0.2156862745098;
		   end;
		   else if _node_id_ eq 219 then do;
		         _leaf_id_ = 219;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.85714285714285;
		         _dt_fi_39630203_{1} =     0.14285714285714;
		         _dt_fi_39630203_{2} =     0.85714285714285;
		   end;
		   else if _node_id_ eq 220 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) then do;

		               _new_id_ = 289;
		               goto ruleend_39630203_node_220;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 289;
		               goto ruleend_39630203_node_220;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 290;
		               goto ruleend_39630203_node_220;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 10 and _numval_ lt 26) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 290;
		               goto ruleend_39630203_node_220;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 289;
		               goto ruleend_39630203_node_220;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 290;
		               goto ruleend_39630203_node_220;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 289;
		            goto ruleend_39630203_node_220;
		            end;
		            ruleend_39630203_node_220:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 89 and _numval_ lt 187958) then do;

		            _new_id_ = 289;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 89) then do;

		            _new_id_ = 290;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 290;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 289;
		         end;
		         else do;
		         _new_id_ = 289;
		         end;
		   end;
		   else if _node_id_ eq 221 then do;
		         _leaf_id_ = 221;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.93333333333333;
		         _dt_fi_39630203_{1} =     0.93333333333333;
		         _dt_fi_39630203_{2} =     0.06666666666666;
		   end;
		   else if _node_id_ eq 222 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 291;
		               goto ruleend_39630203_node_222;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 291;
		               goto ruleend_39630203_node_222;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 291;
		               goto ruleend_39630203_node_222;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 291;
		            goto ruleend_39630203_node_222;
		            end;
		            ruleend_39630203_node_222:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.47712125471966 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 291;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.47712125471966) then do;

		            _new_id_ = 292;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 292;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 291;
		         end;
		         else do;
		         _new_id_ = 291;
		         end;
		   end;
		   else if _node_id_ eq 223 then do;
		         _leaf_id_ = 223;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                  0.6;
		         _dt_fi_39630203_{1} =                  0.4;
		         _dt_fi_39630203_{2} =                  0.6;
		   end;
		   else if _node_id_ eq 224 then do;
		         _leaf_id_ = 224;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.85714285714285;
		         _dt_fi_39630203_{1} =     0.85714285714285;
		         _dt_fi_39630203_{2} =     0.14285714285714;
		   end;
		   else if _node_id_ eq 225 then do;
		         _leaf_id_ = 225;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =      0.8955223880597;
		         _dt_fi_39630203_{1} =      0.8955223880597;
		         _dt_fi_39630203_{2} =     0.10447761194029;
		   end;
		   else if _node_id_ eq 226 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 293;
		               goto ruleend_39630203_node_226;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 293;
		               goto ruleend_39630203_node_226;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 293;
		               goto ruleend_39630203_node_226;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) then do;

		               _new_id_ = 294;
		               goto ruleend_39630203_node_226;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 293;
		               goto ruleend_39630203_node_226;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 293;
		               goto ruleend_39630203_node_226;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 294;
		            goto ruleend_39630203_node_226;
		            end;
		            ruleend_39630203_node_226:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.46108620255947 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 293;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.46108620255947) then do;

		            _new_id_ = 294;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 294;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 293;
		         end;
		         else do;
		         _new_id_ = 294;
		         end;
		   end;
		   else if _node_id_ eq 227 then do;
		         _leaf_id_ = 227;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =      0.9090909090909;
		         _dt_fi_39630203_{1} =      0.9090909090909;
		         _dt_fi_39630203_{2} =     0.09090909090909;
		   end;
		   else if _node_id_ eq 228 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 295;
		               goto ruleend_39630203_node_228;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 295;
		               goto ruleend_39630203_node_228;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 295;
		               goto ruleend_39630203_node_228;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) then do;

		               _new_id_ = 296;
		               goto ruleend_39630203_node_228;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 295;
		               goto ruleend_39630203_node_228;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 295;
		               goto ruleend_39630203_node_228;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 295;
		            goto ruleend_39630203_node_228;
		            end;
		            ruleend_39630203_node_228:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G5') then do;

		         _new_id_ = 295;
		         end;
		         else if _strfmt_ in ('G4') then do;

		         _new_id_ = 296;
		         end;
		         else do;
		         _new_id_ = 295;
		         end;
		   end;
		   else if _node_id_ eq 229 then do;
		         _leaf_id_ = 229;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =      0.9090909090909;
		         _dt_fi_39630203_{1} =     0.09090909090909;
		         _dt_fi_39630203_{2} =      0.9090909090909;
		   end;
		   else if _node_id_ eq 230 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 297;
		               goto ruleend_39630203_node_230;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 297;
		               goto ruleend_39630203_node_230;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 297;
		               goto ruleend_39630203_node_230;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) then do;

		               _new_id_ = 298;
		               goto ruleend_39630203_node_230;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 297;
		               goto ruleend_39630203_node_230;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 297;
		               goto ruleend_39630203_node_230;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 297;
		            goto ruleend_39630203_node_230;
		            end;
		            ruleend_39630203_node_230:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G2',
		         'G5') then do;

		         _new_id_ = 297;
		         end;
		         else if _strfmt_ in ('G4') then do;

		         _new_id_ = 298;
		         end;
		         else do;
		         _new_id_ = 297;
		         end;
		   end;
		   else if _node_id_ eq 231 then do;
		         _leaf_id_ = 231;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =      0.9090909090909;
		         _dt_fi_39630203_{1} =      0.9090909090909;
		         _dt_fi_39630203_{2} =     0.09090909090909;
		   end;
		   else if _node_id_ eq 232 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 299;
		               goto ruleend_39630203_node_232;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 299;
		               goto ruleend_39630203_node_232;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 299;
		               goto ruleend_39630203_node_232;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 299;
		            goto ruleend_39630203_node_232;
		            end;
		            ruleend_39630203_node_232:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.09691001300805 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 299;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.09691001300805) then do;

		            _new_id_ = 300;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 300;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 299;
		         end;
		         else do;
		         _new_id_ = 299;
		         end;
		   end;
		   else if _node_id_ eq 233 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 301;
		               goto ruleend_39630203_node_233;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 301;
		               goto ruleend_39630203_node_233;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 301;
		               goto ruleend_39630203_node_233;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 301;
		            goto ruleend_39630203_node_233;
		            end;
		            ruleend_39630203_node_233:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 123 and _numval_ lt 187958) then do;

		            _new_id_ = 301;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 123) then do;

		            _new_id_ = 302;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 302;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 301;
		         end;
		         else do;
		         _new_id_ = 301;
		         end;
		   end;
		   else if _node_id_ eq 234 then do;
		         _leaf_id_ = 234;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.81818181818181;
		         _dt_fi_39630203_{1} =     0.81818181818181;
		         _dt_fi_39630203_{2} =     0.18181818181818;
		   end;
		   else if _node_id_ eq 235 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 303;
		               goto ruleend_39630203_node_235;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 303;
		               goto ruleend_39630203_node_235;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 303;
		               goto ruleend_39630203_node_235;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) then do;

		               _new_id_ = 304;
		               goto ruleend_39630203_node_235;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 303;
		               goto ruleend_39630203_node_235;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 303;
		               goto ruleend_39630203_node_235;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 304;
		            goto ruleend_39630203_node_235;
		            end;
		            ruleend_39630203_node_235:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 300 and _numval_ lt 7590170) then do;

		            _new_id_ = 303;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 300) then do;

		            _new_id_ = 304;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 304;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 303;
		         end;
		         else do;
		         _new_id_ = 304;
		         end;
		   end;
		   else if _node_id_ eq 236 then do;
		         _leaf_id_ = 236;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.92537313432835;
		         _dt_fi_39630203_{1} =     0.92537313432835;
		         _dt_fi_39630203_{2} =     0.07462686567164;
		   end;
		   else if _node_id_ eq 237 then do;
		         _leaf_id_ = 237;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.96587030716723;
		         _dt_fi_39630203_{1} =     0.96587030716723;
		         _dt_fi_39630203_{2} =     0.03412969283276;
		   end;
		   else if _node_id_ eq 238 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 305;
		               goto ruleend_39630203_node_238;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 305;
		               goto ruleend_39630203_node_238;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 305;
		               goto ruleend_39630203_node_238;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            162 and _numval_ lt 208) then do;

		               _new_id_ = 306;
		               goto ruleend_39630203_node_238;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 305;
		               goto ruleend_39630203_node_238;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 305;
		               goto ruleend_39630203_node_238;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 305;
		            goto ruleend_39630203_node_238;
		            end;
		            ruleend_39630203_node_238:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.09691001300805 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 305;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.09691001300805) then do;

		            _new_id_ = 306;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 306;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 305;
		         end;
		         else do;
		         _new_id_ = 305;
		         end;
		   end;
		   else if _node_id_ eq 239 then do;
		         _leaf_id_ = 239;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                 0.75;
		         _dt_fi_39630203_{1} =                 0.25;
		         _dt_fi_39630203_{2} =                 0.75;
		   end;
		   else if _node_id_ eq 240 then do;
		         _leaf_id_ = 240;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.85714285714285;
		         _dt_fi_39630203_{1} =     0.85714285714285;
		         _dt_fi_39630203_{2} =     0.14285714285714;
		   end;
		   else if _node_id_ eq 241 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 307;
		               goto ruleend_39630203_node_241;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 307;
		               goto ruleend_39630203_node_241;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 307;
		               goto ruleend_39630203_node_241;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge 2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) then do;

		               _new_id_ = 308;
		               goto ruleend_39630203_node_241;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 307;
		               goto ruleend_39630203_node_241;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 307;
		               goto ruleend_39630203_node_241;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 308;
		            goto ruleend_39630203_node_241;
		            end;
		            ruleend_39630203_node_241:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.87205887742353 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 307;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.87205887742353) then do;

		            _new_id_ = 308;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 308;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 307;
		         end;
		         else do;
		         _new_id_ = 308;
		         end;
		   end;
		   else if _node_id_ eq 242 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 309;
		               goto ruleend_39630203_node_242;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 309;
		               goto ruleend_39630203_node_242;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 309;
		               goto ruleend_39630203_node_242;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 10 and _numval_ lt 26) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) then do;

		               _new_id_ = 310;
		               goto ruleend_39630203_node_242;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 309;
		               goto ruleend_39630203_node_242;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 309;
		               goto ruleend_39630203_node_242;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 310;
		            goto ruleend_39630203_node_242;
		            end;
		            ruleend_39630203_node_242:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2.43136376415898 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 309;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 2.43136376415898) then do;

		            _new_id_ = 310;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 310;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 309;
		         end;
		         else do;
		         _new_id_ = 310;
		         end;
		   end;
		   else if _node_id_ eq 243 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 311;
		               goto ruleend_39630203_node_243;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 311;
		               goto ruleend_39630203_node_243;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 311;
		               goto ruleend_39630203_node_243;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) then do;

		               _new_id_ = 312;
		               goto ruleend_39630203_node_243;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 311;
		               goto ruleend_39630203_node_243;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 311;
		               goto ruleend_39630203_node_243;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 312;
		            goto ruleend_39630203_node_243;
		            end;
		            ruleend_39630203_node_243:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 89 and _numval_ lt 187958) then do;

		            _new_id_ = 311;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 89) then do;

		            _new_id_ = 312;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 312;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 311;
		         end;
		         else do;
		         _new_id_ = 312;
		         end;
		   end;
		   else if _node_id_ eq 244 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 313;
		               goto ruleend_39630203_node_244;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 313;
		               goto ruleend_39630203_node_244;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 313;
		               goto ruleend_39630203_node_244;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 314;
		               goto ruleend_39630203_node_244;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 313;
		               goto ruleend_39630203_node_244;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 313;
		               goto ruleend_39630203_node_244;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 314;
		            goto ruleend_39630203_node_244;
		            end;
		            ruleend_39630203_node_244:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2.57287160220048 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 313;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 2.57287160220048) then do;

		            _new_id_ = 314;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 314;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 313;
		         end;
		         else do;
		         _new_id_ = 314;
		         end;
		   end;
		   else if _node_id_ eq 245 then do;
		         _leaf_id_ = 245;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    1;
		         _dt_fi_39630203_{2} =                    0;
		   end;
		   else if _node_id_ eq 246 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 315;
		               goto ruleend_39630203_node_246;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 315;
		               goto ruleend_39630203_node_246;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 315;
		               goto ruleend_39630203_node_246;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge 2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) then do;

		               _new_id_ = 316;
		               goto ruleend_39630203_node_246;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 315;
		               goto ruleend_39630203_node_246;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 315;
		               goto ruleend_39630203_node_246;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 315;
		            goto ruleend_39630203_node_246;
		            end;
		            ruleend_39630203_node_246:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 0.96571655047913 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 315;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 0.96571655047913) then do;

		            _new_id_ = 316;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 316;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 315;
		         end;
		         else do;
		         _new_id_ = 315;
		         end;
		   end;
		   else if _node_id_ eq 247 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 317;
		               goto ruleend_39630203_node_247;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 317;
		               goto ruleend_39630203_node_247;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 317;
		               goto ruleend_39630203_node_247;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 317;
		            goto ruleend_39630203_node_247;
		            end;
		            ruleend_39630203_node_247:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.30695031829154 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 317;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.30695031829154) then do;

		            _new_id_ = 318;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 318;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 317;
		         end;
		         else do;
		         _new_id_ = 317;
		         end;
		   end;
		   else if _node_id_ eq 248 then do;
		         _leaf_id_ = 248;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.92307692307692;
		         _dt_fi_39630203_{1} =     0.07692307692307;
		         _dt_fi_39630203_{2} =     0.92307692307692;
		   end;
		   else if _node_id_ eq 249 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 319;
		               goto ruleend_39630203_node_249;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 319;
		               goto ruleend_39630203_node_249;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 319;
		               goto ruleend_39630203_node_249;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            162 and _numval_ lt 208) then do;

		               _new_id_ = 320;
		               goto ruleend_39630203_node_249;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 319;
		               goto ruleend_39630203_node_249;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 319;
		               goto ruleend_39630203_node_249;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 320;
		            goto ruleend_39630203_node_249;
		            end;
		            ruleend_39630203_node_249:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.87205887742353 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 319;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.87205887742353) then do;

		            _new_id_ = 320;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 320;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 319;
		         end;
		         else do;
		         _new_id_ = 320;
		         end;
		   end;
		   else if _node_id_ eq 250 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) then do;

		               _new_id_ = 321;
		               goto ruleend_39630203_node_250;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 321;
		               goto ruleend_39630203_node_250;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 322;
		               goto ruleend_39630203_node_250;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) or (_numval_ ge
		            1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 322;
		               goto ruleend_39630203_node_250;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 321;
		               goto ruleend_39630203_node_250;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 322;
		               goto ruleend_39630203_node_250;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 322;
		            goto ruleend_39630203_node_250;
		            end;
		            ruleend_39630203_node_250:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 123 and _numval_ lt 187958) then do;

		            _new_id_ = 321;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 123) then do;

		            _new_id_ = 322;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 322;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 321;
		         end;
		         else do;
		         _new_id_ = 322;
		         end;
		   end;
		   else if _node_id_ eq 251 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 323;
		               goto ruleend_39630203_node_251;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 323;
		               goto ruleend_39630203_node_251;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 323;
		               goto ruleend_39630203_node_251;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) then do;

		               _new_id_ = 324;
		               goto ruleend_39630203_node_251;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 323;
		               goto ruleend_39630203_node_251;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 323;
		               goto ruleend_39630203_node_251;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 324;
		            goto ruleend_39630203_node_251;
		            end;
		            ruleend_39630203_node_251:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G5',
		         'G8') then do;

		         _new_id_ = 323;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 324;
		         end;
		         else do;
		         _new_id_ = 324;
		         end;
		   end;
		   else if _node_id_ eq 252 then do;
		         _leaf_id_ = 252;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =               0.8125;
		         _dt_fi_39630203_{1} =               0.8125;
		         _dt_fi_39630203_{2} =               0.1875;
		   end;
		   else if _node_id_ eq 253 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) then do;

		               _new_id_ = 325;
		               goto ruleend_39630203_node_253;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 325;
		               goto ruleend_39630203_node_253;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 326;
		               goto ruleend_39630203_node_253;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 326;
		               goto ruleend_39630203_node_253;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 325;
		               goto ruleend_39630203_node_253;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 326;
		               goto ruleend_39630203_node_253;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 326;
		            goto ruleend_39630203_node_253;
		            end;
		            ruleend_39630203_node_253:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 6835 and _numval_ lt 187958) then do;

		            _new_id_ = 325;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 6835) then do;

		            _new_id_ = 326;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 326;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 325;
		         end;
		         else do;
		         _new_id_ = 326;
		         end;
		   end;
		   else if _node_id_ eq 254 then do;
		         _leaf_id_ = 254;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.85714285714285;
		         _dt_fi_39630203_{1} =     0.14285714285714;
		         _dt_fi_39630203_{2} =     0.85714285714285;
		   end;
		   else if _node_id_ eq 255 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            8625 and _numval_ lt 9950) then do;

		               _new_id_ = 327;
		               goto ruleend_39630203_node_255;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 327;
		               goto ruleend_39630203_node_255;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 328;
		               goto ruleend_39630203_node_255;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 328;
		               goto ruleend_39630203_node_255;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 327;
		               goto ruleend_39630203_node_255;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 328;
		               goto ruleend_39630203_node_255;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 328;
		            goto ruleend_39630203_node_255;
		            end;
		            ruleend_39630203_node_255:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G5') then do;

		         _new_id_ = 327;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 328;
		         end;
		         else do;
		         _new_id_ = 328;
		         end;
		   end;
		   else if _node_id_ eq 256 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 329;
		               goto ruleend_39630203_node_256;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 329;
		               goto ruleend_39630203_node_256;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 329;
		               goto ruleend_39630203_node_256;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) then do;

		               _new_id_ = 330;
		               goto ruleend_39630203_node_256;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 329;
		               goto ruleend_39630203_node_256;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 329;
		               goto ruleend_39630203_node_256;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 330;
		            goto ruleend_39630203_node_256;
		            end;
		            ruleend_39630203_node_256:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G5') then do;

		         _new_id_ = 329;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 330;
		         end;
		         else do;
		         _new_id_ = 330;
		         end;
		   end;
		   else if _node_id_ eq 257 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 331;
		               goto ruleend_39630203_node_257;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 331;
		               goto ruleend_39630203_node_257;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 331;
		               goto ruleend_39630203_node_257;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 331;
		            goto ruleend_39630203_node_257;
		            end;
		            ruleend_39630203_node_257:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2.97772360528884 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 331;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 2.97772360528884) then do;

		            _new_id_ = 332;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 332;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 331;
		         end;
		         else do;
		         _new_id_ = 331;
		         end;
		   end;
		   else if _node_id_ eq 258 then do;
		         _leaf_id_ = 258;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.85454545454545;
		         _dt_fi_39630203_{1} =     0.14545454545454;
		         _dt_fi_39630203_{2} =     0.85454545454545;
		   end;
		   else if _node_id_ eq 259 then do;
		         _leaf_id_ = 259;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                0.875;
		         _dt_fi_39630203_{1} =                0.875;
		         _dt_fi_39630203_{2} =                0.125;
		   end;
		   else if _node_id_ eq 260 then do;
		         _strfmt_ = left(trim(put(RUA_3BYTE_STRING_006_G,$2.)));
		         if missing(RUA_3BYTE_STRING_006_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 333;
		               goto ruleend_39630203_node_260;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 333;
		               goto ruleend_39630203_node_260;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 333;
		               goto ruleend_39630203_node_260;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) then do;

		               _new_id_ = 334;
		               goto ruleend_39630203_node_260;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 333;
		               goto ruleend_39630203_node_260;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 333;
		               goto ruleend_39630203_node_260;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 334;
		            goto ruleend_39630203_node_260;
		            end;
		            ruleend_39630203_node_260:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G5') then do;

		         _new_id_ = 333;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 334;
		         end;
		         else do;
		         _new_id_ = 334;
		         end;
		   end;
		   else if _node_id_ eq 261 then do;
		         _leaf_id_ = 261;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.71428571428571;
		         _dt_fi_39630203_{1} =     0.28571428571428;
		         _dt_fi_39630203_{2} =     0.71428571428571;
		   end;
		   else if _node_id_ eq 262 then do;
		         _leaf_id_ = 262;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.77027027027027;
		         _dt_fi_39630203_{1} =     0.77027027027027;
		         _dt_fi_39630203_{2} =     0.22972972972972;
		   end;
		   else if _node_id_ eq 263 then do;
		         _leaf_id_ = 263;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.71428571428571;
		         _dt_fi_39630203_{1} =     0.28571428571428;
		         _dt_fi_39630203_{2} =     0.71428571428571;
		   end;
		   else if _node_id_ eq 264 then do;
		         _leaf_id_ = 264;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.92063492063492;
		         _dt_fi_39630203_{1} =     0.92063492063492;
		         _dt_fi_39630203_{2} =     0.07936507936507;
		   end;
		   else if _node_id_ eq 265 then do;
		         _leaf_id_ = 265;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.89130434782608;
		         _dt_fi_39630203_{1} =     0.89130434782608;
		         _dt_fi_39630203_{2} =     0.10869565217391;
		   end;
		   else if _node_id_ eq 266 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) then do;

		               _new_id_ = 335;
		               goto ruleend_39630203_node_266;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 335;
		               goto ruleend_39630203_node_266;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 336;
		               goto ruleend_39630203_node_266;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 336;
		               goto ruleend_39630203_node_266;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 335;
		               goto ruleend_39630203_node_266;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 336;
		               goto ruleend_39630203_node_266;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 335;
		            goto ruleend_39630203_node_266;
		            end;
		            ruleend_39630203_node_266:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2 and _numval_ lt 187958) then do;

		            _new_id_ = 335;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 2) then do;

		            _new_id_ = 336;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 336;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 335;
		         end;
		         else do;
		         _new_id_ = 335;
		         end;
		   end;
		   else if _node_id_ eq 267 then do;
		         _leaf_id_ = 267;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    0;
		         _dt_fi_39630203_{2} =                    1;
		   end;
		   else if _node_id_ eq 268 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 337;
		               goto ruleend_39630203_node_268;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 337;
		               goto ruleend_39630203_node_268;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 337;
		               goto ruleend_39630203_node_268;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            4 and _numval_ lt 9) then do;

		               _new_id_ = 338;
		               goto ruleend_39630203_node_268;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 337;
		               goto ruleend_39630203_node_268;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 337;
		               goto ruleend_39630203_node_268;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 338;
		            goto ruleend_39630203_node_268;
		            end;
		            ruleend_39630203_node_268:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.69897000433601 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 337;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.69897000433601) then do;

		            _new_id_ = 338;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 338;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 337;
		         end;
		         else do;
		         _new_id_ = 338;
		         end;
		   end;
		   else if _node_id_ eq 269 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 339;
		               goto ruleend_39630203_node_269;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 339;
		               goto ruleend_39630203_node_269;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 339;
		               goto ruleend_39630203_node_269;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) then do;

		               _new_id_ = 340;
		               goto ruleend_39630203_node_269;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 339;
		               goto ruleend_39630203_node_269;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 339;
		               goto ruleend_39630203_node_269;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 340;
		            goto ruleend_39630203_node_269;
		            end;
		            ruleend_39630203_node_269:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.46108620255947 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 339;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.46108620255947) then do;

		            _new_id_ = 340;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 340;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 339;
		         end;
		         else do;
		         _new_id_ = 340;
		         end;
		   end;
		   else if _node_id_ eq 270 then do;
		         _leaf_id_ = 270;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                0.825;
		         _dt_fi_39630203_{1} =                0.825;
		         _dt_fi_39630203_{2} =                0.175;
		   end;
		   else if _node_id_ eq 271 then do;
		         _leaf_id_ = 271;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.65486725663716;
		         _dt_fi_39630203_{1} =     0.65486725663716;
		         _dt_fi_39630203_{2} =     0.34513274336283;
		   end;
		   else if _node_id_ eq 272 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 341;
		               goto ruleend_39630203_node_272;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 341;
		               goto ruleend_39630203_node_272;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 341;
		               goto ruleend_39630203_node_272;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) then do;

		               _new_id_ = 342;
		               goto ruleend_39630203_node_272;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 341;
		               goto ruleend_39630203_node_272;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 341;
		               goto ruleend_39630203_node_272;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 342;
		            goto ruleend_39630203_node_272;
		            end;
		            ruleend_39630203_node_272:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.69057272462515 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 341;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.69057272462515) then do;

		            _new_id_ = 342;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 342;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 341;
		         end;
		         else do;
		         _new_id_ = 342;
		         end;
		   end;
		   else if _node_id_ eq 273 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            19 and _numval_ lt 36) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 343;
		               goto ruleend_39630203_node_273;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 343;
		               goto ruleend_39630203_node_273;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 343;
		               goto ruleend_39630203_node_273;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) then do;

		               _new_id_ = 344;
		               goto ruleend_39630203_node_273;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 343;
		               goto ruleend_39630203_node_273;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 343;
		               goto ruleend_39630203_node_273;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 344;
		            goto ruleend_39630203_node_273;
		            end;
		            ruleend_39630203_node_273:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 2.86332286012045 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 343;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 2.86332286012045) then do;

		            _new_id_ = 344;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 344;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 343;
		         end;
		         else do;
		         _new_id_ = 344;
		         end;
		   end;
		   else if _node_id_ eq 274 then do;
		         _leaf_id_ = 274;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.85333333333333;
		         _dt_fi_39630203_{1} =     0.85333333333333;
		         _dt_fi_39630203_{2} =     0.14666666666666;
		   end;
		   else if _node_id_ eq 275 then do;
		         _leaf_id_ = 275;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =               0.8125;
		         _dt_fi_39630203_{1} =               0.8125;
		         _dt_fi_39630203_{2} =               0.1875;
		   end;
		   else if _node_id_ eq 276 then do;
		         _leaf_id_ = 276;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.85714285714285;
		         _dt_fi_39630203_{1} =     0.14285714285714;
		         _dt_fi_39630203_{2} =     0.85714285714285;
		   end;
		   else if _node_id_ eq 277 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 345;
		               goto ruleend_39630203_node_277;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 345;
		               goto ruleend_39630203_node_277;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 345;
		               goto ruleend_39630203_node_277;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) then do;

		               _new_id_ = 346;
		               goto ruleend_39630203_node_277;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 345;
		               goto ruleend_39630203_node_277;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 345;
		               goto ruleend_39630203_node_277;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 346;
		            goto ruleend_39630203_node_277;
		            end;
		            ruleend_39630203_node_277:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.14316480591633 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 345;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.14316480591633) then do;

		            _new_id_ = 346;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 346;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 345;
		         end;
		         else do;
		         _new_id_ = 346;
		         end;
		   end;
		   else if _node_id_ eq 278 then do;
		         _leaf_id_ = 278;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                 0.64;
		         _dt_fi_39630203_{1} =                 0.64;
		         _dt_fi_39630203_{2} =                 0.36;
		   end;
		   else if _node_id_ eq 279 then do;
		         _leaf_id_ = 279;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.72727272727272;
		         _dt_fi_39630203_{1} =     0.72727272727272;
		         _dt_fi_39630203_{2} =     0.27272727272727;
		   end;
		   else if _node_id_ eq 280 then do;
		         _leaf_id_ = 280;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.80327868852459;
		         _dt_fi_39630203_{1} =      0.1967213114754;
		         _dt_fi_39630203_{2} =     0.80327868852459;
		   end;
		   else if _node_id_ eq 281 then do;
		         _leaf_id_ = 281;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.71739130434782;
		         _dt_fi_39630203_{1} =     0.28260869565217;
		         _dt_fi_39630203_{2} =     0.71739130434782;
		   end;
		   else if _node_id_ eq 282 then do;
		         _leaf_id_ = 282;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.88888888888888;
		         _dt_fi_39630203_{1} =     0.88888888888888;
		         _dt_fi_39630203_{2} =     0.11111111111111;
		   end;
		   else if _node_id_ eq 283 then do;
		         _leaf_id_ = 283;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.56097560975609;
		         _dt_fi_39630203_{1} =      0.4390243902439;
		         _dt_fi_39630203_{2} =     0.56097560975609;
		   end;
		   else if _node_id_ eq 284 then do;
		         _leaf_id_ = 284;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                  0.8;
		         _dt_fi_39630203_{1} =                  0.8;
		         _dt_fi_39630203_{2} =                  0.2;
		   end;
		   else if _node_id_ eq 285 then do;
		         _leaf_id_ = 285;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.81081081081081;
		         _dt_fi_39630203_{1} =     0.81081081081081;
		         _dt_fi_39630203_{2} =     0.18918918918918;
		   end;
		   else if _node_id_ eq 286 then do;
		         _leaf_id_ = 286;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                 0.75;
		         _dt_fi_39630203_{1} =                 0.25;
		         _dt_fi_39630203_{2} =                 0.75;
		   end;
		   else if _node_id_ eq 287 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 347;
		               goto ruleend_39630203_node_287;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 347;
		               goto ruleend_39630203_node_287;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 347;
		               goto ruleend_39630203_node_287;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) then do;

		               _new_id_ = 348;
		               goto ruleend_39630203_node_287;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 347;
		               goto ruleend_39630203_node_287;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 347;
		               goto ruleend_39630203_node_287;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 348;
		            goto ruleend_39630203_node_287;
		            end;
		            ruleend_39630203_node_287:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 9 and _numval_ lt 187958) then do;

		            _new_id_ = 347;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 9) then do;

		            _new_id_ = 348;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 348;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 347;
		         end;
		         else do;
		         _new_id_ = 348;
		         end;
		   end;
		   else if _node_id_ eq 288 then do;
		         _leaf_id_ = 288;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.94444444444444;
		         _dt_fi_39630203_{1} =     0.05555555555555;
		         _dt_fi_39630203_{2} =     0.94444444444444;
		   end;
		   else if _node_id_ eq 289 then do;
		         _leaf_id_ = 289;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.76315789473684;
		         _dt_fi_39630203_{1} =     0.23684210526315;
		         _dt_fi_39630203_{2} =     0.76315789473684;
		   end;
		   else if _node_id_ eq 290 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            26 and _numval_ lt 50) or (_numval_ ge
		            50 and _numval_ lt 70) or (_numval_ ge
		            70 and _numval_ lt 100) or (_numval_ ge
		            100 and _numval_ lt 150) or (_numval_ ge
		            150 and _numval_ lt 200) or (_numval_ ge
		            200 and _numval_ lt 300) or (_numval_ ge
		            300 and _numval_ lt 422) or (_numval_ ge
		            10000 and _numval_ lt 7590170) then do;

		               _new_id_ = 349;
		               goto ruleend_39630203_node_290;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 349;
		               goto ruleend_39630203_node_290;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 349;
		               goto ruleend_39630203_node_290;
		            end;
		            end;
		            _numval_ = sum_amthr6_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 10) or (_numval_ ge
		            10 and _numval_ lt 26) or (_numval_ ge
		            422 and _numval_ lt 575) or (_numval_ ge
		            575 and _numval_ lt 990) or (_numval_ ge
		            990 and _numval_ lt 1300) or (_numval_ ge
		            1300 and _numval_ lt 2000) or (_numval_ ge
		            2000 and _numval_ lt 3999.20000000001) or (_numval_ ge
		            3999.20000000001 and _numval_ lt 10000) then do;

		               _new_id_ = 350;
		               goto ruleend_39630203_node_290;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 349;
		               goto ruleend_39630203_node_290;
		            end;
		            else if (_numval_ ge 7590170) then do;
		               _new_id_ = 349;
		               goto ruleend_39630203_node_290;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 350;
		            goto ruleend_39630203_node_290;
		            end;
		            ruleend_39630203_node_290:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.69897000433601 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 349;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.69897000433601) then do;

		            _new_id_ = 350;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 350;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 349;
		         end;
		         else do;
		         _new_id_ = 350;
		         end;
		   end;
		   else if _node_id_ eq 291 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _strfmt_ = left(trim(put(XQO_LANGUAGE,$12.)));
		            if not (missing(XQO_LANGUAGE)) then do;
		               if _strfmt_ in ('AR') then do;

		               _new_id_ = 351;
		               goto ruleend_39630203_node_291;
		               end;
		            end;
		            _strfmt_ = left(trim(put(XQO_LANGUAGE,$12.)));
		            if not (missing(XQO_LANGUAGE)) then do;
		               if _strfmt_ in ('EN') then do;

		               _new_id_ = 352;
		               goto ruleend_39630203_node_291;
		               end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 351;
		            goto ruleend_39630203_node_291;
		            end;
		            ruleend_39630203_node_291:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.69897000433601 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 351;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.69897000433601) then do;

		            _new_id_ = 352;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 352;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 351;
		         end;
		         else do;
		         _new_id_ = 351;
		         end;
		   end;
		   else if _node_id_ eq 292 then do;
		         _leaf_id_ = 292;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    1;
		         _dt_fi_39630203_{2} =                    0;
		   end;
		   else if _node_id_ eq 293 then do;
		         _numval_ = log_TBT_TRAN_AMT;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = tx_div_avg_log_amtday90_2;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2232.14727292634 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0.29133857216946) or (_numval_ ge
		            0.29133857216946 and _numval_ lt 0.4569305616721) or (_numval_ ge
		            0.4569305616721 and _numval_ lt 0.52913496392477) or (_numval_ ge
		            0.52913496392477 and _numval_ lt 0.57849645279993) or (_numval_ ge
		            0.57849645279993 and _numval_ lt 0.61553522972456) or (_numval_ ge
		            0.61553522972456 and _numval_ lt 0.64720305519231) or (_numval_ ge
		            0.64720305519231 and _numval_ lt 0.67455352534295) or (_numval_ ge
		            0.67455352534295 and _numval_ lt 0.69905014194224) or (_numval_ ge
		            0.69905014194224 and _numval_ lt 0.72145266618602) or (_numval_ ge
		            0.72145266618602 and _numval_ lt 0.74225453355428) or (_numval_ ge
		            0.74225453355428 and _numval_ lt 0.76157027338648) or (_numval_ ge
		            0.76157027338648 and _numval_ lt 0.77976702841328) or (_numval_ ge
		            0.77976702841328 and _numval_ lt 0.79756008616055) or (_numval_ ge
		            0.79756008616055 and _numval_ lt 0.81441569941156) or (_numval_ ge
		            0.81441569941156 and _numval_ lt 0.83076779785676) or (_numval_ ge
		            0.83076779785676 and _numval_ lt 0.84702860510047) or (_numval_ ge
		            0.84702860510047 and _numval_ lt 0.86227291852629) or (_numval_ ge
		            0.86227291852629 and _numval_ lt 0.87759302401866) or (_numval_ ge
		            0.87759302401866 and _numval_ lt 0.89241869812256) or (_numval_ ge
		            0.89241869812256 and _numval_ lt 0.90710217656257) or (_numval_ ge
		            0.90710217656257 and _numval_ lt 0.92185178848307) or (_numval_ ge
		            0.92185178848307 and _numval_ lt 0.93662645473922) or (_numval_ ge
		            0.93662645473922 and _numval_ lt 0.9513263597813) or (_numval_ ge
		            0.9513263597813 and _numval_ lt 0.96571655047913) or (_numval_ ge
		            0.96571655047913 and _numval_ lt 0.98075993480971) or (_numval_ ge
		            0.98075993480971 and _numval_ lt 0.99588664142607) or (_numval_ ge
		            0.99588664142607 and _numval_ lt 1.0097417351308) or (_numval_ ge
		            1.0097417351308 and _numval_ lt 1.02511135083803) or (_numval_ ge
		            1.02511135083803 and _numval_ lt 1.04066299138769) or (_numval_ ge
		            1.04066299138769 and _numval_ lt 1.05653992633193) or (_numval_ ge
		            1.05653992633193 and _numval_ lt 1.072744017402) or (_numval_ ge
		            1.072744017402 and _numval_ lt 1.08955909977909) or (_numval_ ge
		            1.08955909977909 and _numval_ lt 1.10682923547595) or (_numval_ ge
		            1.10682923547595 and _numval_ lt 1.12457539815976) or (_numval_ ge
		            1.12457539815976 and _numval_ lt 1.14316480591633) or (_numval_ ge
		            1.14316480591633 and _numval_ lt 1.16273733383074) or (_numval_ ge
		            1.16273733383074 and _numval_ lt 1.18279775531683) or (_numval_ ge
		            1.18279775531683 and _numval_ lt 1.20440687492471) or (_numval_ ge
		            1.20440687492471 and _numval_ lt 1.22752805207252) or (_numval_ ge
		            1.22752805207252 and _numval_ lt 1.25205179605377) or (_numval_ ge
		            1.25205179605377 and _numval_ lt 1.27841031940134) or (_numval_ ge
		            1.27841031940134 and _numval_ lt 1.30695031829154) or (_numval_ ge
		            1.30695031829154 and _numval_ lt 1.33880155571007) or (_numval_ ge
		            1.33880155571007 and _numval_ lt 1.37401627704963) or (_numval_ ge
		            1.37401627704963 and _numval_ lt 1.41421648081794) or (_numval_ ge
		            1.41421648081794 and _numval_ lt 1.46108620255947) or (_numval_ ge
		            1.46108620255947 and _numval_ lt 1.51774507303653) then do;

		               _new_id_ = 353;
		               goto ruleend_39630203_node_293;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 353;
		               goto ruleend_39630203_node_293;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 354;
		               goto ruleend_39630203_node_293;
		            end;
		            end;
		            _numval_ = tx_div_avg_log_amtday90_2;
		if not (missing(_numval_)) then do;if (_numval_ ge 1.51774507303653 and _numval_ lt 1.58859191006777) or (_numval_ ge
		            1.58859191006777 and _numval_ lt 1.69057272462515) or (_numval_ ge
		            1.69057272462515 and _numval_ lt 1.87205887742353) or (_numval_ ge
		            1.87205887742353 and _numval_ lt 683.844513551116) then do;

		               _new_id_ = 354;
		               goto ruleend_39630203_node_293;
		            end;
		            else if (_numval_ lt -2232.14727292634) then do;
		               _new_id_ = 353;
		               goto ruleend_39630203_node_293;
		            end;
		            else if (_numval_ ge 683.844513551116) then do;
		               _new_id_ = 354;
		               goto ruleend_39630203_node_293;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 353;
		            goto ruleend_39630203_node_293;
		            end;
		            ruleend_39630203_node_293:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 3.36172783601759 and _numval_ lt 6.65321251377534) then do;

		            _new_id_ = 353;
		         end;
		         else if (_numval_ ge -2 and _numval_ lt 3.36172783601759) then do;

		            _new_id_ = 354;
		         end;
		         else if (_numval_ lt -2) then do;
		            _new_id_ = 354;
		         end;
		         else if (_numval_ ge 6.65321251377534) then do;
		            _new_id_ = 353;
		         end;
		         else do;
		         _new_id_ = 353;
		         end;
		   end;
		   else if _node_id_ eq 294 then do;
		         _leaf_id_ = 294;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.85964912280701;
		         _dt_fi_39630203_{1} =     0.85964912280701;
		         _dt_fi_39630203_{2} =     0.14035087719298;
		   end;
		   else if _node_id_ eq 295 then do;
		         _leaf_id_ = 295;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.73333333333333;
		         _dt_fi_39630203_{1} =     0.26666666666666;
		         _dt_fi_39630203_{2} =     0.73333333333333;
		   end;
		   else if _node_id_ eq 296 then do;
		         _leaf_id_ = 296;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.57142857142857;
		         _dt_fi_39630203_{1} =     0.57142857142857;
		         _dt_fi_39630203_{2} =     0.42857142857142;
		   end;
		   else if _node_id_ eq 297 then do;
		         _leaf_id_ = 297;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.79310344827586;
		         _dt_fi_39630203_{1} =     0.20689655172413;
		         _dt_fi_39630203_{2} =     0.79310344827586;
		   end;
		   else if _node_id_ eq 298 then do;
		         _numval_ = tx_div_avg_log_amtday90_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 0) or (_numval_ ge
		            0 and _numval_ lt 0) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1) or (_numval_ ge
		            4 and _numval_ lt 9) or (_numval_ ge
		            36 and _numval_ lt 60) or (_numval_ ge
		            60 and _numval_ lt 89) or (_numval_ ge
		            89 and _numval_ lt 123) or (_numval_ ge
		            123 and _numval_ lt 162) or (_numval_ ge
		            162 and _numval_ lt 208) or (_numval_ ge
		            208 and _numval_ lt 262) or (_numval_ ge
		            262 and _numval_ lt 326) or (_numval_ ge
		            326 and _numval_ lt 403) or (_numval_ ge
		            403 and _numval_ lt 494) or (_numval_ ge
		            494 and _numval_ lt 605) or (_numval_ ge
		            605 and _numval_ lt 730) or (_numval_ ge
		            730 and _numval_ lt 854) or (_numval_ ge
		            854 and _numval_ lt 970) or (_numval_ ge
		            970 and _numval_ lt 1075) or (_numval_ ge
		            1075 and _numval_ lt 1170) or (_numval_ ge
		            1170 and _numval_ lt 1259) or (_numval_ ge
		            1259 and _numval_ lt 1342) or (_numval_ ge
		            1342 and _numval_ lt 1419) or (_numval_ ge
		            1419 and _numval_ lt 1496) or (_numval_ ge
		            1496 and _numval_ lt 1594) or (_numval_ ge
		            1594 and _numval_ lt 1725) or (_numval_ ge
		            1725 and _numval_ lt 1914) or (_numval_ ge
		            1914 and _numval_ lt 2187) or (_numval_ ge
		            2187 and _numval_ lt 2456) or (_numval_ ge
		            2456 and _numval_ lt 2665) or (_numval_ ge
		            2665 and _numval_ lt 2837) or (_numval_ ge
		            2837 and _numval_ lt 3005) or (_numval_ ge
		            3005 and _numval_ lt 3265) or (_numval_ ge
		            3265 and _numval_ lt 3725) or (_numval_ ge
		            3725 and _numval_ lt 4116) or (_numval_ ge
		            4116 and _numval_ lt 4397) or (_numval_ ge
		            4397 and _numval_ lt 4833) or (_numval_ ge
		            4833 and _numval_ lt 5508) or (_numval_ ge
		            5508 and _numval_ lt 5960) or (_numval_ ge
		            5960 and _numval_ lt 6835) or (_numval_ ge
		            6835 and _numval_ lt 7512) or (_numval_ ge
		            7512 and _numval_ lt 8625) or (_numval_ ge
		            8625 and _numval_ lt 9950) or (_numval_ ge
		            9950 and _numval_ lt 11489) or (_numval_ ge
		            11489 and _numval_ lt 13565) or (_numval_ ge
		            13565 and _numval_ lt 16744.111111111) or (_numval_ ge
		            16744.111111111 and _numval_ lt 21519.7407407407) or (_numval_ ge
		            21519.7407407407 and _numval_ lt 31407.3703703704) or (_numval_ ge
		            31407.3703703704 and _numval_ lt 187958) then do;

		               _new_id_ = 355;
		               goto ruleend_39630203_node_298;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 355;
		               goto ruleend_39630203_node_298;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 355;
		               goto ruleend_39630203_node_298;
		            end;
		            end;
		            _numval_ = min_diff;
		            if not (missing(_numval_)) then do;if (_numval_ ge 0 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 4) or (_numval_ ge
		            9 and _numval_ lt 19) or (_numval_ ge
		            19 and _numval_ lt 36) then do;

		               _new_id_ = 356;
		               goto ruleend_39630203_node_298;
		            end;
		            else if (_numval_ lt 0) then do;
		               _new_id_ = 355;
		               goto ruleend_39630203_node_298;
		            end;
		            else if (_numval_ ge 187958) then do;
		               _new_id_ = 355;
		               goto ruleend_39630203_node_298;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 356;
		            goto ruleend_39630203_node_298;
		            end;
		            ruleend_39630203_node_298:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 1.41421648081794 and _numval_ lt 683.844513551116) then do;

		            _new_id_ = 355;
		         end;
		         else if (_numval_ ge -2232.14727292634 and _numval_ lt 1.41421648081794) then do;

		            _new_id_ = 356;
		         end;
		         else if (_numval_ lt -2232.14727292634) then do;
		            _new_id_ = 356;
		         end;
		         else if (_numval_ ge 683.844513551116) then do;
		            _new_id_ = 355;
		         end;
		         else do;
		         _new_id_ = 356;
		         end;
		   end;
		   else if _node_id_ eq 299 then do;
		         _numval_ = min_diff;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 357;
		               goto ruleend_39630203_node_299;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 357;
		               goto ruleend_39630203_node_299;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 357;
		               goto ruleend_39630203_node_299;
		            end;
		            end;
		            _numval_ = log_TBT_TRAN_AMT;
		if not (missing(_numval_)) then do;if (_numval_ ge 3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) then do;

		               _new_id_ = 358;
		               goto ruleend_39630203_node_299;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 357;
		               goto ruleend_39630203_node_299;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 357;
		               goto ruleend_39630203_node_299;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 358;
		            goto ruleend_39630203_node_299;
		            end;
		            ruleend_39630203_node_299:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 60 and _numval_ lt 187958) then do;

		            _new_id_ = 357;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 60) then do;

		            _new_id_ = 358;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 358;
		         end;
		         else if (_numval_ ge 187958) then do;
		            _new_id_ = 357;
		         end;
		         else do;
		         _new_id_ = 358;
		         end;
		   end;
		   else if _node_id_ eq 300 then do;
		         _leaf_id_ = 300;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =      0.9090909090909;
		         _dt_fi_39630203_{1} =     0.09090909090909;
		         _dt_fi_39630203_{2} =      0.9090909090909;
		   end;
		   else if _node_id_ eq 301 then do;
		         _leaf_id_ = 301;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.70588235294117;
		         _dt_fi_39630203_{1} =     0.29411764705882;
		         _dt_fi_39630203_{2} =     0.70588235294117;
		   end;
		   else if _node_id_ eq 302 then do;
		         _leaf_id_ = 302;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.83333333333333;
		         _dt_fi_39630203_{1} =     0.83333333333333;
		         _dt_fi_39630203_{2} =     0.16666666666666;
		   end;
		   else if _node_id_ eq 303 then do;
		         _strfmt_ = left(trim(put(bene_bank_name_G,$2.)));
		         if missing(bene_bank_name_G) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 359;
		               goto ruleend_39630203_node_303;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 359;
		               goto ruleend_39630203_node_303;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 359;
		               goto ruleend_39630203_node_303;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 359;
		            goto ruleend_39630203_node_303;
		            end;
		            ruleend_39630203_node_303:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if _strfmt_ in ('G4',
		         'G5') then do;

		         _new_id_ = 359;
		         end;
		         else if _strfmt_ in ('G6') then do;

		         _new_id_ = 360;
		         end;
		         else do;
		         _new_id_ = 359;
		         end;
		   end;
		   else if _node_id_ eq 304 then do;
		         _leaf_id_ = 304;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.88043478260869;
		         _dt_fi_39630203_{1} =     0.88043478260869;
		         _dt_fi_39630203_{2} =      0.1195652173913;
		   end;
		   else if _node_id_ eq 305 then do;
		         _leaf_id_ = 305;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.83333333333333;
		         _dt_fi_39630203_{1} =     0.16666666666666;
		         _dt_fi_39630203_{2} =     0.83333333333333;
		   end;
		   else if _node_id_ eq 306 then do;
		         _leaf_id_ = 306;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.83333333333333;
		         _dt_fi_39630203_{1} =     0.83333333333333;
		         _dt_fi_39630203_{2} =     0.16666666666666;
		   end;
		   else if _node_id_ eq 307 then do;
		         _leaf_id_ = 307;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.66666666666666;
		         _dt_fi_39630203_{1} =     0.33333333333333;
		         _dt_fi_39630203_{2} =     0.66666666666666;
		   end;
		   else if _node_id_ eq 308 then do;
		         _leaf_id_ = 308;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.85833333333333;
		         _dt_fi_39630203_{1} =     0.85833333333333;
		         _dt_fi_39630203_{2} =     0.14166666666666;
		   end;
		   else if _node_id_ eq 309 then do;
		         _leaf_id_ = 309;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.78571428571428;
		         _dt_fi_39630203_{1} =     0.78571428571428;
		         _dt_fi_39630203_{2} =     0.21428571428571;
		   end;
		   else if _node_id_ eq 310 then do;
		         _numval_ = sum_amthr6_2;
		         if missing(_numval_) then do;
		            _new_id_ = -1;
		            _numval_ = log_TBT_TRAN_AMT;
		            if not (missing(_numval_)) then do;if (_numval_ ge -2 and _numval_ lt 0.65321251377534) or (_numval_ ge
		            0.65321251377534 and _numval_ lt 0.95424250943932) or (_numval_ ge
		            0.95424250943932 and _numval_ lt 1) or (_numval_ ge
		            1 and _numval_ lt 1.17609125905568) or (_numval_ ge
		            1.17609125905568 and _numval_ lt 1.23044892137827) or (_numval_ ge
		            1.23044892137827 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.30102999566398) or (_numval_ ge
		            1.30102999566398 and _numval_ lt 1.39794000867203) or (_numval_ ge
		            1.39794000867203 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.47712125471966) or (_numval_ ge
		            1.47712125471966 and _numval_ lt 1.54406804435027) or (_numval_ ge
		            1.54406804435027 and _numval_ lt 1.60205999132796) or (_numval_ ge
		            1.60205999132796 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.69897000433601) or (_numval_ ge
		            1.69897000433601 and _numval_ lt 1.73239375982296) or (_numval_ ge
		            1.73239375982296 and _numval_ lt 1.81291335664285) or (_numval_ ge
		            1.81291335664285 and _numval_ lt 1.90308998699194) or (_numval_ ge
		            1.90308998699194 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2) or (_numval_ ge
		            2 and _numval_ lt 2.09691001300805) or (_numval_ ge
		            2.09691001300805 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.17609125905568) or (_numval_ ge
		            2.17609125905568 and _numval_ lt 2.2552725051033) or (_numval_ ge
		            2.2552725051033 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.30102999566398) or (_numval_ ge
		            2.30102999566398 and _numval_ lt 2.3802112417116) or (_numval_ ge
		            2.3802112417116 and _numval_ lt 2.43136376415898) or (_numval_ ge
		            2.43136376415898 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.47712125471966) or (_numval_ ge
		            2.47712125471966 and _numval_ lt 2.57287160220048) or (_numval_ ge
		            2.57287160220048 and _numval_ lt 2.6232492903979) or (_numval_ ge
		            2.6232492903979 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.69897000433601) or (_numval_ ge
		            2.69897000433601 and _numval_ lt 2.77815125038364) or (_numval_ ge
		            2.77815125038364 and _numval_ lt 2.86332286012045) or (_numval_ ge
		            2.86332286012045 and _numval_ lt 2.97772360528884) or (_numval_ ge
		            2.97772360528884 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3) or (_numval_ ge
		            3 and _numval_ lt 3.09691001300805) or (_numval_ ge
		            3.09691001300805 and _numval_ lt 3.17609125905568) or (_numval_ ge
		            3.17609125905568 and _numval_ lt 3.30102999566398) or (_numval_ ge
		            3.30102999566398 and _numval_ lt 3.36172783601759) or (_numval_ ge
		            3.36172783601759 and _numval_ lt 3.47712125471966) or (_numval_ ge
		            3.47712125471966 and _numval_ lt 3.69897000433601) or (_numval_ ge
		            3.69897000433601 and _numval_ lt 4) or (_numval_ ge
		            4 and _numval_ lt 6.65321251377534) then do;

		               _new_id_ = 361;
		               goto ruleend_39630203_node_310;
		            end;
		            else if (_numval_ lt -2) then do;
		               _new_id_ = 361;
		               goto ruleend_39630203_node_310;
		            end;
		            else if (_numval_ ge 6.65321251377534) then do;
		               _new_id_ = 361;
		               goto ruleend_39630203_node_310;
		            end;
		            end;
		            if (_new_id_ eq -1) then do;
		            _new_id_ = 361;
		            goto ruleend_39630203_node_310;
		            end;
		            ruleend_39630203_node_310:
		             _node_id_ = _new_id_;
		            goto nextnode_39630203;
		         end;
		         if missing(_numval_) then do;
		            _numval_ = -1.7976931348623E308;
		         end;
		         if (_numval_ ge 150 and _numval_ lt 7590170) then do;

		            _new_id_ = 361;
		         end;
		         else if (_numval_ ge 0 and _numval_ lt 150) then do;

		            _new_id_ = 362;
		         end;
		         else if (_numval_ lt 0) then do;
		            _new_id_ = 362;
		         end;
		         else if (_numval_ ge 7590170) then do;
		            _new_id_ = 361;
		         end;
		         else do;
		         _new_id_ = 361;
		         end;
		   end;
		   else if _node_id_ eq 311 then do;
		         _leaf_id_ = 311;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                  0.8;
		         _dt_fi_39630203_{1} =                  0.8;
		         _dt_fi_39630203_{2} =                  0.2;
		   end;
		   else if _node_id_ eq 312 then do;
		         _leaf_id_ = 312;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.77777777777777;
		         _dt_fi_39630203_{1} =     0.22222222222222;
		         _dt_fi_39630203_{2} =     0.77777777777777;
		   end;
		   else if _node_id_ eq 313 then do;
		         _leaf_id_ = 313;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                  0.6;
		         _dt_fi_39630203_{1} =                  0.4;
		         _dt_fi_39630203_{2} =                  0.6;
		   end;
		   else if _node_id_ eq 314 then do;
		         _leaf_id_ = 314;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                  0.8;
		         _dt_fi_39630203_{1} =                  0.8;
		         _dt_fi_39630203_{2} =                  0.2;
		   end;
		   else if _node_id_ eq 315 then do;
		         _leaf_id_ = 315;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.59550561797752;
		         _dt_fi_39630203_{1} =     0.40449438202247;
		         _dt_fi_39630203_{2} =     0.59550561797752;
		   end;
		   else if _node_id_ eq 316 then do;
		         _leaf_id_ = 316;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.72222222222222;
		         _dt_fi_39630203_{1} =     0.72222222222222;
		         _dt_fi_39630203_{2} =     0.27777777777777;
		   end;
		   else if _node_id_ eq 317 then do;
		         _leaf_id_ = 317;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.77777777777777;
		         _dt_fi_39630203_{1} =     0.22222222222222;
		         _dt_fi_39630203_{2} =     0.77777777777777;
		   end;
		   else if _node_id_ eq 318 then do;
		         _leaf_id_ = 318;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                  0.8;
		         _dt_fi_39630203_{1} =                  0.8;
		         _dt_fi_39630203_{2} =                  0.2;
		   end;
		   else if _node_id_ eq 319 then do;
		         _leaf_id_ = 319;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.66666666666666;
		         _dt_fi_39630203_{1} =     0.33333333333333;
		         _dt_fi_39630203_{2} =     0.66666666666666;
		   end;
		   else if _node_id_ eq 320 then do;
		         _leaf_id_ = 320;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.79166666666666;
		         _dt_fi_39630203_{1} =     0.79166666666666;
		         _dt_fi_39630203_{2} =     0.20833333333333;
		   end;
		   else if _node_id_ eq 321 then do;
		         _leaf_id_ = 321;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    1;
		         _dt_fi_39630203_{2} =                    0;
		   end;
		   else if _node_id_ eq 322 then do;
		         _leaf_id_ = 322;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.67647058823529;
		         _dt_fi_39630203_{1} =      0.3235294117647;
		         _dt_fi_39630203_{2} =     0.67647058823529;
		   end;
		   else if _node_id_ eq 323 then do;
		         _leaf_id_ = 323;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.83333333333333;
		         _dt_fi_39630203_{1} =     0.83333333333333;
		         _dt_fi_39630203_{2} =     0.16666666666666;
		   end;
		   else if _node_id_ eq 324 then do;
		         _leaf_id_ = 324;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.53488372093023;
		         _dt_fi_39630203_{1} =     0.46511627906976;
		         _dt_fi_39630203_{2} =     0.53488372093023;
		   end;
		   else if _node_id_ eq 325 then do;
		         _leaf_id_ = 325;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                  0.6;
		         _dt_fi_39630203_{1} =                  0.4;
		         _dt_fi_39630203_{2} =                  0.6;
		   end;
		   else if _node_id_ eq 326 then do;
		         _leaf_id_ = 326;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.66666666666666;
		         _dt_fi_39630203_{1} =     0.66666666666666;
		         _dt_fi_39630203_{2} =     0.33333333333333;
		   end;
		   else if _node_id_ eq 327 then do;
		         _leaf_id_ = 327;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.85714285714285;
		         _dt_fi_39630203_{1} =     0.85714285714285;
		         _dt_fi_39630203_{2} =     0.14285714285714;
		   end;
		   else if _node_id_ eq 328 then do;
		         _leaf_id_ = 328;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.64150943396226;
		         _dt_fi_39630203_{1} =     0.35849056603773;
		         _dt_fi_39630203_{2} =     0.64150943396226;
		   end;
		   else if _node_id_ eq 329 then do;
		         _leaf_id_ = 329;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.53846153846153;
		         _dt_fi_39630203_{1} =     0.46153846153846;
		         _dt_fi_39630203_{2} =     0.53846153846153;
		   end;
		   else if _node_id_ eq 330 then do;
		         _leaf_id_ = 330;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.74418604651162;
		         _dt_fi_39630203_{1} =     0.74418604651162;
		         _dt_fi_39630203_{2} =     0.25581395348837;
		   end;
		   else if _node_id_ eq 331 then do;
		         _leaf_id_ = 331;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.73184357541899;
		         _dt_fi_39630203_{1} =       0.268156424581;
		         _dt_fi_39630203_{2} =     0.73184357541899;
		   end;
		   else if _node_id_ eq 332 then do;
		         _leaf_id_ = 332;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.67857142857142;
		         _dt_fi_39630203_{1} =     0.67857142857142;
		         _dt_fi_39630203_{2} =     0.32142857142857;
		   end;
		   else if _node_id_ eq 333 then do;
		         _leaf_id_ = 333;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.58333333333333;
		         _dt_fi_39630203_{1} =     0.41666666666666;
		         _dt_fi_39630203_{2} =     0.58333333333333;
		   end;
		   else if _node_id_ eq 334 then do;
		         _leaf_id_ = 334;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.58024691358024;
		         _dt_fi_39630203_{1} =     0.58024691358024;
		         _dt_fi_39630203_{2} =     0.41975308641975;
		   end;
		   else if _node_id_ eq 335 then do;
		         _leaf_id_ = 335;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.58888888888888;
		         _dt_fi_39630203_{1} =     0.58888888888888;
		         _dt_fi_39630203_{2} =     0.41111111111111;
		   end;
		   else if _node_id_ eq 336 then do;
		         _leaf_id_ = 336;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.72222222222222;
		         _dt_fi_39630203_{1} =     0.27777777777777;
		         _dt_fi_39630203_{2} =     0.72222222222222;
		   end;
		   else if _node_id_ eq 337 then do;
		         _leaf_id_ = 337;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.71428571428571;
		         _dt_fi_39630203_{1} =     0.28571428571428;
		         _dt_fi_39630203_{2} =     0.71428571428571;
		   end;
		   else if _node_id_ eq 338 then do;
		         _leaf_id_ = 338;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.77777777777777;
		         _dt_fi_39630203_{1} =     0.77777777777777;
		         _dt_fi_39630203_{2} =     0.22222222222222;
		   end;
		   else if _node_id_ eq 339 then do;
		         _leaf_id_ = 339;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.75510204081632;
		         _dt_fi_39630203_{1} =     0.24489795918367;
		         _dt_fi_39630203_{2} =     0.75510204081632;
		   end;
		   else if _node_id_ eq 340 then do;
		         _leaf_id_ = 340;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.53846153846153;
		         _dt_fi_39630203_{1} =     0.53846153846153;
		         _dt_fi_39630203_{2} =     0.46153846153846;
		   end;
		   else if _node_id_ eq 341 then do;
		         _leaf_id_ = 341;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.78947368421052;
		         _dt_fi_39630203_{1} =     0.78947368421052;
		         _dt_fi_39630203_{2} =     0.21052631578947;
		   end;
		   else if _node_id_ eq 342 then do;
		         _leaf_id_ = 342;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.60194174757281;
		         _dt_fi_39630203_{1} =     0.39805825242718;
		         _dt_fi_39630203_{2} =     0.60194174757281;
		   end;
		   else if _node_id_ eq 343 then do;
		         _leaf_id_ = 343;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.66666666666666;
		         _dt_fi_39630203_{1} =     0.33333333333333;
		         _dt_fi_39630203_{2} =     0.66666666666666;
		   end;
		   else if _node_id_ eq 344 then do;
		         _leaf_id_ = 344;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                  0.6;
		         _dt_fi_39630203_{1} =                  0.6;
		         _dt_fi_39630203_{2} =                  0.4;
		   end;
		   else if _node_id_ eq 345 then do;
		         _leaf_id_ = 345;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                  0.6;
		         _dt_fi_39630203_{1} =                  0.6;
		         _dt_fi_39630203_{2} =                  0.4;
		   end;
		   else if _node_id_ eq 346 then do;
		         _leaf_id_ = 346;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                    1;
		         _dt_fi_39630203_{1} =                    0;
		         _dt_fi_39630203_{2} =                    1;
		   end;
		   else if _node_id_ eq 347 then do;
		         _leaf_id_ = 347;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.71428571428571;
		         _dt_fi_39630203_{1} =     0.71428571428571;
		         _dt_fi_39630203_{2} =     0.28571428571428;
		   end;
		   else if _node_id_ eq 348 then do;
		         _leaf_id_ = 348;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                  0.6;
		         _dt_fi_39630203_{1} =                  0.4;
		         _dt_fi_39630203_{2} =                  0.6;
		   end;
		   else if _node_id_ eq 349 then do;
		         _leaf_id_ = 349;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                  0.8;
		         _dt_fi_39630203_{1} =                  0.2;
		         _dt_fi_39630203_{2} =                  0.8;
		   end;
		   else if _node_id_ eq 350 then do;
		         _leaf_id_ = 350;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                 0.64;
		         _dt_fi_39630203_{1} =                 0.64;
		         _dt_fi_39630203_{2} =                 0.36;
		   end;
		   else if _node_id_ eq 351 then do;
		         _leaf_id_ = 351;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.76470588235294;
		         _dt_fi_39630203_{1} =     0.76470588235294;
		         _dt_fi_39630203_{2} =     0.23529411764705;
		   end;
		   else if _node_id_ eq 352 then do;
		         _leaf_id_ = 352;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                0.875;
		         _dt_fi_39630203_{1} =                0.125;
		         _dt_fi_39630203_{2} =                0.875;
		   end;
		   else if _node_id_ eq 353 then do;
		         _leaf_id_ = 353;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.77777777777777;
		         _dt_fi_39630203_{1} =     0.22222222222222;
		         _dt_fi_39630203_{2} =     0.77777777777777;
		   end;
		   else if _node_id_ eq 354 then do;
		         _leaf_id_ = 354;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.66666666666666;
		         _dt_fi_39630203_{1} =     0.66666666666666;
		         _dt_fi_39630203_{2} =     0.33333333333333;
		   end;
		   else if _node_id_ eq 355 then do;
		         _leaf_id_ = 355;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.83333333333333;
		         _dt_fi_39630203_{1} =     0.16666666666666;
		         _dt_fi_39630203_{2} =     0.83333333333333;
		   end;
		   else if _node_id_ eq 356 then do;
		         _leaf_id_ = 356;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.64285714285714;
		         _dt_fi_39630203_{1} =     0.64285714285714;
		         _dt_fi_39630203_{2} =     0.35714285714285;
		   end;
		   else if _node_id_ eq 357 then do;
		         _leaf_id_ = 357;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =      0.9090909090909;
		         _dt_fi_39630203_{1} =     0.09090909090909;
		         _dt_fi_39630203_{2} =      0.9090909090909;
		   end;
		   else if _node_id_ eq 358 then do;
		         _leaf_id_ = 358;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.57142857142857;
		         _dt_fi_39630203_{1} =     0.57142857142857;
		         _dt_fi_39630203_{2} =     0.42857142857142;
		   end;
		   else if _node_id_ eq 359 then do;
		         _leaf_id_ = 359;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =     0.68181818181818;
		         _dt_fi_39630203_{1} =     0.68181818181818;
		         _dt_fi_39630203_{2} =     0.31818181818181;
		   end;
		   else if _node_id_ eq 360 then do;
		         _leaf_id_ = 360;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =                 0.75;
		         _dt_fi_39630203_{1} =                 0.25;
		         _dt_fi_39630203_{2} =                 0.75;
		   end;
		   else if _node_id_ eq 361 then do;
		         _leaf_id_ = 361;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 1;
		         _dt_pred_prob_ =     0.62222222222222;
		         _dt_fi_39630203_{1} =     0.37777777777777;
		         _dt_fi_39630203_{2} =     0.62222222222222;
		   end;
		   else if _node_id_ eq 362 then do;
		         _leaf_id_ = 362;
		         _new_id_ = -1;
		         _dt_pred_lev_ = 0;
		         _dt_pred_prob_ =                  0.9;
		         _dt_fi_39630203_{1} =                  0.9;
		         _dt_fi_39630203_{2} =                  0.1;
		   end;
		   if _new_id_ >= 0 then do;
		       _node_id_ = _new_id_;
		      goto nextnode_39630203;
		   end;

		   I_fraud_ind_2 = _tlevname_39630203_{_dt_pred_lev_+1};
		   label I_fraud_ind_2 = 'Into: fraud_ind_2';
		   _i_ = 1;
		   _dt_predp_ = _dt_fi_39630203_{_i_};
		   P_fraud_ind_20 = _dt_predp_;
		   label P_fraud_ind_20 = 'Predicted: fraud_ind_2=0';
		   _i_+1;
		   _dt_predp_ = _dt_fi_39630203_{_i_};
		   P_fraud_ind_21 = _dt_predp_;
		   label P_fraud_ind_21 = 'Predicted: fraud_ind_2=1';
		   _i_+1;
		   drop _dt_predp_;
		   drop _i_;
		   drop _dt_pred_lev_;
		   drop _dt_pred_prob_;
		   drop _numval_;
		   drop _node_id_;
		   drop _new_id_;



		   *------------------------------------------------------------*;
		   * Initializing missing posterior and classification variables ;
		   *------------------------------------------------------------*;
		   if "P_fraud_ind_20"n = . then "P_fraud_ind_20"n =0.9871876366;
		   if "P_fraud_ind_21"n = . then "P_fraud_ind_21"n =0.0128123634;
		   if missing('I_fraud_ind_2'n) then do;
		      drop _P_;
		      _P_= 0.0 ;
		      if 'P_fraud_ind_21'n > _P_ then do;
		      _P_ = 'P_fraud_ind_21'n;
		      'I_fraud_ind_2'n = '1';
		      end;
		      if 'P_fraud_ind_20'n > _P_ then do;
		      _P_ = 'P_fraud_ind_20'n;
		      'I_fraud_ind_2'n = '0';
		      end;
		   end;
		*------------------------------------------------------------*;
		* Generating fixed output names;
		*------------------------------------------------------------*;
		Length EM_EVENTPROBABILITY 8;
		LABEL EM_EVENTPROBABILITY = "Probability for fraud_ind_2 =1";
		EM_EVENTPROBABILITY ='P_fraud_ind_21'n;
		LENGTH EM_CLASSIFICATION $1;
		LABEL EM_CLASSIFICATION= "Predicted for fraud_ind_2";
		EM_CLASSIFICATION ='I_fraud_ind_2'n;
		Length EM_PROBABILITY 8;
		LABEL EM_PROBABILITY = "Probability of Classification";
		EM_PROBABILITY = max('P_fraud_ind_21'n,'P_fraud_ind_20'n);

		mdl_model_id = 'ALRAJHI_';
		mdl_model_version = '0101';
	
		mdl_score=min(max(round(P_fraud_ind_21 * 1000),1),999); 
		
		*******************************************************************************************************************;
		*** Score Code End                                                                                              ***;
		*******************************************************************************************************************;

	end;
	
	putlog "SCORE START";
	putlog "score_transaction = " score_transaction;
	putlog "smh_acct_type = " smh_acct_type;
	putlog "smh_activity_type = " smh_activity_type;
	putlog "XQO_CUST_NUM = " XQO_CUST_NUM;
	putlog "DUA_80BYTE_STRING_001 = " DUA_80BYTE_STRING_001;
	putlog "trx_dttm = " trx_dttm datetime.;
	putlog "TBT_TRAN_AMT = " TBT_TRAN_AMT;
	putlog "bene_bank_name_G = " bene_bank_name_G;
	putlog "RUA_IND_006_G = " RUA_IND_006_G;
	putlog "RUA_3BYTE_STRING_006_G = " RUA_3BYTE_STRING_006_G;
	putlog "log_TBT_TRAN_AMT = " log_TBT_TRAN_AMT;
	putlog "SMH_CLIENT_TRAN_TYPE = " SMH_CLIENT_TRAN_TYPE;
	putlog "min_diff = " min_diff;
	putlog "sum_amthr6_2 = " sum_amthr6_2 8.2;
	putlog "first_bene_flag_2 = " first_bene_flag_2;
	putlog "tx_div_avg_log_amtday90_2 = " tx_div_avg_log_amtday90_2;
	putlog "mdl_score = " mdl_score;
	putlog "z02_lookup_key = " z02_lookup_key; 
	putlog "z02_lookup_key = " z02_lookup_key; 
	putlog "z03_lookup_key = " z03_lookup_key;
	putlog "update_signature = " update_signature;
	putlog "smh_acct_type = " smh_acct_type;
	putlog "smh_activity_type = " smh_activity_type;
	putlog "XQO_CUST_NUM = " XQO_CUST_NUM;
	putlog "DUA_80BYTE_STRING_001 = " DUA_80BYTE_STRING_001;
	putlog "RQO_PROC_UTC_DATETIME = " RQO_PROC_UTC_DATETIME;
	putlog "TBT_TRAN_AMT = " TBT_TRAN_AMT;
	putlog "SMH_CLIENT_TRAN_TYPE = " SMH_CLIENT_TRAN_TYPE;
	putlog "z02_content_id_version = " z02_content_id_version;
	putlog "z02_prev_rqo_tran_dttm = " z02_prev_rqo_tran_dttm datetime.;
	putlog "z02_curr_rqo_tran_dttm = " z02_curr_rqo_tran_dttm datetime.;
	putlog "z02_pointer_dttm_hr = " z02_pointer_dttm_hr datetime.;
	putlog "z02_pointer_dttm_3day = " z02_pointer_dttm_3day datetime.;
	putlog "idx_to_updt_cust_day = " idx_to_updt_cust_day;
	putlog "z02_persist_ind = " z02_persist_ind;
	putlog "z02_lookup_key = " z02_lookup_key;
	putlog "z04_lookup_key = " z04_lookup_key;
	putlog "z02_sum6hr_1 = " z02_sum6hr_1 8.2;
	putlog "z02_sum6hr_2 = " z02_sum6hr_2 8.2;
	putlog "z02_sum6hr_3 = " z02_sum6hr_3 8.2;
	putlog "z02_sum6hr_4 = " z02_sum6hr_4 8.2;
	putlog "z02_sum6hr_5 = " z02_sum6hr_5 8.2;
	putlog "z02_sum6hr_6 = " z02_sum6hr_6 8.2;
	putlog  "z02_sum_cnt_1 = " z02_sum_cnt_1 8.2;
	putlog  "z02_sum_cnt_2 = " z02_sum_cnt_2 8.2;
	putlog  "z02_sum_cnt_3 = " z02_sum_cnt_3 8.2;
	putlog  "z02_sum_cnt_4 = " z02_sum_cnt_4 8.2;
	putlog  "z02_sum_cnt_5 = " z02_sum_cnt_5 8.2;
	putlog  "z02_sum_cnt_6 = " z02_sum_cnt_6 8.2;
	putlog  "z02_sum_cnt_7 = " z02_sum_cnt_7 8.2;
	putlog  "z02_sum_cnt_8 = " z02_sum_cnt_8 8.2;
	putlog  "z02_sum_cnt_9 = " z02_sum_cnt_9 8.2;
	putlog  "z02_sum_cnt_10 = " z02_sum_cnt_10 8.2;
	putlog  "z02_sum_cnt_11 = " z02_sum_cnt_11 8.2;
	putlog  "z02_sum_cnt_12 = " z02_sum_cnt_12 8.2;
	putlog  "z02_sum_cnt_13 = " z02_sum_cnt_13 8.2;
	putlog  "z02_sum_cnt_14 = " z02_sum_cnt_14 8.2;
	putlog  "z02_sum_cnt_15 = " z02_sum_cnt_15 8.2;
	putlog  "z02_sum_cnt_16 = " z02_sum_cnt_16 8.2;
	putlog  "z02_sum_cnt_17 = " z02_sum_cnt_17 8.2;
	putlog  "z02_sum_cnt_18 = " z02_sum_cnt_18 8.2;
	putlog  "z02_sum_cnt_19 = " z02_sum_cnt_19 8.2;
	putlog  "z02_sum_cnt_20 = " z02_sum_cnt_20 8.2;
	putlog  "z02_sum_cnt_21 = " z02_sum_cnt_21 8.2;
	putlog  "z02_sum_cnt_22 = " z02_sum_cnt_22 8.2;
	putlog  "z02_sum_cnt_23 = " z02_sum_cnt_23 8.2;
	putlog  "z02_sum_cnt_24 = " z02_sum_cnt_24 8.2;
	putlog  "z02_sum_cnt_25 = " z02_sum_cnt_25 8.2;
	putlog  "z02_sum_cnt_26 = " z02_sum_cnt_26 8.2;
	putlog  "z02_sum_cnt_27 = " z02_sum_cnt_27 8.2;
	putlog  "z02_sum_cnt_28 = " z02_sum_cnt_28 8.2;
	putlog  "z02_sum_cnt_29 = " z02_sum_cnt_29 8.2;
	putlog  "z02_sum_cnt_30 = " z02_sum_cnt_30 8.2;
	putlog  "sum_cnt = " sum_cnt 8.2;
	putlog  "z02_sum_log_amt_1 = " z02_sum_log_amt_1 12.8;
	putlog  "z02_sum_log_amt_2 = " z02_sum_log_amt_2 12.8;
	putlog  "z02_sum_log_amt_3 = " z02_sum_log_amt_3 12.8;
	putlog  "z02_sum_log_amt_4 = " z02_sum_log_amt_4 12.8;
	putlog  "z02_sum_log_amt_5 = " z02_sum_log_amt_5 12.8;
	putlog  "z02_sum_log_amt_6 = " z02_sum_log_amt_6 12.8;
	putlog  "z02_sum_log_amt_7 = " z02_sum_log_amt_7 12.8;
	putlog  "z02_sum_log_amt_8 = " z02_sum_log_amt_8 12.8;
	putlog  "z02_sum_log_amt_9 = " z02_sum_log_amt_9 12.8;
	putlog  "z02_sum_log_amt_10 = " z02_sum_log_amt_10 12.8;
	putlog  "z02_sum_log_amt_11 = " z02_sum_log_amt_11 12.8;
	putlog  "z02_sum_log_amt_12 = " z02_sum_log_amt_12 12.8;
	putlog  "z02_sum_log_amt_13 = " z02_sum_log_amt_13 12.8;
	putlog  "z02_sum_log_amt_14 = " z02_sum_log_amt_14 12.8;
	putlog  "z02_sum_log_amt_15 = " z02_sum_log_amt_15 12.8;
	putlog  "z02_sum_log_amt_16 = " z02_sum_log_amt_16 12.8;
	putlog  "z02_sum_log_amt_17 = " z02_sum_log_amt_17 12.8;
	putlog  "z02_sum_log_amt_18 = " z02_sum_log_amt_18 12.8;
	putlog  "z02_sum_log_amt_19 = " z02_sum_log_amt_19 12.8;
	putlog  "z02_sum_log_amt_20 = " z02_sum_log_amt_20 12.8;
	putlog  "z02_sum_log_amt_21 = " z02_sum_log_amt_21 12.8;
	putlog  "z02_sum_log_amt_22 = " z02_sum_log_amt_22 12.8;
	putlog  "z02_sum_log_amt_23 = " z02_sum_log_amt_23 12.8;
	putlog  "z02_sum_log_amt_24 = " z02_sum_log_amt_24 12.8;
	putlog  "z02_sum_log_amt_25 = " z02_sum_log_amt_25 12.8;
	putlog  "z02_sum_log_amt_26 = " z02_sum_log_amt_26 12.8;
	putlog  "z02_sum_log_amt_27 = " z02_sum_log_amt_27 12.8;
	putlog  "z02_sum_log_amt_28 = " z02_sum_log_amt_28 12.8;
	putlog  "z02_sum_log_amt_29 = " z02_sum_log_amt_29 12.8;
	putlog  "z02_sum_log_amt_30 = " z02_sum_log_amt_30 12.8;
	putlog  "sum_amt = " sum_amt 12.8;
	putlog "z03_frst_rqo_utc_trx_dttm = " z03_frst_rqo_utc_trx_dttm datetime.;
	putlog "_leaf_id_ = " _leaf_id_;
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
	 putlog "z04_Bene_max_amount = "  z04_Bene_max_amount_1; 
	putlog "SCORE END";



