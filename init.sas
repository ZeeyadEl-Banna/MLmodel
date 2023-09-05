
%macro resolve_signature_flag(sig);
		resolve_signature = "&sig";
%mend;

%macro update_signature_flag(sig);
		update_signature = "&sig";
%mend;

%macro set_score_txn_flag(score,trace,msg=);
		score_transaction = "&score";
		mdl_model_trace = "&trace";
		putlog &msg;
%mend;

array z02_sum6hr_{6};
array z02_sum_log_amt_{30};
array z02_sum_cnt_{30};


